"""Simple in-memory auth (MVP stage — no Supabase dependency yet)."""

from __future__ import annotations

import hashlib
import secrets
import time
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings
from app.database import get_profile

# ── Simple token store for MVP ──
# In production, this would be Supabase Auth + JWT verification.
# For now: generate bearer tokens, store in dict, expire after 24h.

_tokens: dict[str, dict[str, Any]] = {}
_usage: dict[str, dict[str, int]] = {}  # user_id → {date: count}
_ip_mints: dict[str, list[float]] = {}  # client ip → mint timestamps (P0 anti-abuse)
_ip_chat: dict[str, list[float]] = {}  # client ip → chat timestamps (P0 second line)

_TOKEN_TTL_SECONDS = 24 * 3600
_TOKEN_MAX_ENTRIES = 20000  # hard cap so a restart-less process can't grow unbounded

# P0: anonymous /auth/token minting was unlimited — anyone could mint fresh
# user_ids forever and bypass the per-user daily LLM quota. Throttle by IP.
_TOKEN_MINTS_PER_IP_PER_HOUR = 20
_TOKEN_MINT_WINDOW_SECONDS = 3600

# P0 second line: even with per-user limits, one IP minting N users × limit
# lessons each is still an LLM bill amplifier. Cap lessons per IP per day.
# 20 mints/hour × 5 lessons = 100/day would still be too much; this caps the
# IP aggregate well below that while normal users (1 device = 1 IP) never hit it.
_CHAT_PER_IP_PER_DAY = 50
_CHAT_IP_WINDOW_SECONDS = 24 * 3600

bearer_scheme = HTTPBearer()


def _prune_tokens() -> None:
    """Evict expired tokens; if still over cap, drop oldest first."""
    now = time.time()
    expired = [t for t, v in _tokens.items() if now - v.get("created_at", 0) > _TOKEN_TTL_SECONDS]
    for t in expired:
        _tokens.pop(t, None)
    if len(_tokens) > _TOKEN_MAX_ENTRIES:
        # dicts preserve insertion order — oldest first
        for t in list(_tokens.keys())[: len(_tokens) - _TOKEN_MAX_ENTRIES]:
            _tokens.pop(t, None)


def check_token_mint_allowed(client_ip: str | None) -> tuple[bool, str]:
    """Per-IP throttle for /auth/token. Returns (allowed, reason)."""
    if not client_ip:
        return True, ""
    now = time.time()
    window_start = now - _TOKEN_MINT_WINDOW_SECONDS
    stamps = [s for s in _ip_mints.get(client_ip, []) if s > window_start]
    if len(stamps) >= _TOKEN_MINTS_PER_IP_PER_HOUR:
        _ip_mints[client_ip] = stamps
        return False, "too_many_tokens"
    stamps.append(now)
    _ip_mints[client_ip] = stamps[-_TOKEN_MINTS_PER_IP_PER_HOUR * 2 :]
    # opportunistic prune of idle IPs (keeps dict bounded without a sweeper)
    if len(_ip_mints) > 5000:
        _ip_mints.clear()
    if len(_ip_chat) > 5000:
        _ip_chat.clear()
    return True, ""


def check_chat_allowed(client_ip: str | None) -> tuple[bool, str]:
    """Per-IP daily cap on chat calls (second line behind per-user limit)."""
    if not client_ip:
        return True, ""
    now = time.time()
    window_start = now - _CHAT_IP_WINDOW_SECONDS
    stamps = [s for s in _ip_chat.get(client_ip, []) if s > window_start]
    if len(stamps) >= _CHAT_PER_IP_PER_DAY:
        _ip_chat[client_ip] = stamps
        return False, "ip_daily_limit_reached"
    stamps.append(now)
    # keep bounded: at most _CHAT_PER_IP_PER_DAY entries per IP
    _ip_chat[client_ip] = stamps[-_CHAT_PER_IP_PER_DAY:]
    return True, ""


def get_client_ip(request) -> str | None:
    """Best-effort client IP behind Fly.io proxy."""
    # Fly.io sets Fly-Client-IP; standard proxies set X-Forwarded-For.
    for header in ("fly-client-ip", "x-forwarded-for", "x-real-ip"):
        val = request.headers.get(header)
        if val:
            # XFF can be a chain — leftmost is the original client
            return val.split(",")[0].strip() or None
    client = getattr(request, "client", None)
    if client is not None:
        return client.host
    return None


def create_token(user_id: str) -> str:
    """Generate a simple bearer token (MVP only)."""
    _prune_tokens()
    token = secrets.token_hex(32)
    _tokens[token] = {
        "user_id": user_id,
        "created_at": time.time(),
        "level": "N5",
        "tier": "free",
    }
    return token


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict[str, Any]:
    """Dependency: validate bearer token, return user info."""
    token = credentials.credentials
    user = _tokens.get(token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    # P0: tokens were documented "expire after 24h" but never actually checked.
    if time.time() - user.get("created_at", 0) > _TOKEN_TTL_SECONDS:
        _tokens.pop(token, None)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    return user


def get_user_usage(user_id: str) -> dict:
    """Get and increment daily usage counter."""
    today = time.strftime("%Y-%m-%d")
    if user_id not in _usage:
        _usage[user_id] = {}
    daily = _usage[user_id]
    if today not in daily:
        daily[today] = 0
    daily[today] += 1
    return {
        "lessons_used_today": daily[today],
        "lessons_remaining": max(0, get_settings().free_daily_limit - daily[today]),
    }


def check_usage_limit(user_id: str) -> dict:
    """Check if user has exceeded daily limit without incrementing."""
    today = time.strftime("%Y-%m-%d")
    count = _usage.get(user_id, {}).get(today, 0)
    limit = get_settings().free_daily_limit
    tier = _get_user_tier(user_id)
    if tier != "free":
        return {"lessons_used_today": count, "lessons_remaining": 999, "tier": tier}
    return {
        "lessons_used_today": count,
        "lessons_remaining": max(0, limit - count),
        "tier": tier,
    }


def _get_user_tier(user_id: str) -> str:
    """Get user's subscription tier from profile."""
    profile = get_profile(user_id)
    return profile.get("subscription_tier", "free")
