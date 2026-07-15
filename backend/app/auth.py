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

bearer_scheme = HTTPBearer()


def create_token(user_id: str) -> str:
    """Generate a simple bearer token (MVP only)."""
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
