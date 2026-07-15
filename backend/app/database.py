"""Supabase database client (MVP: stubs for now).

In production, this module manages:
  - Async Supabase client singleton
  - User profile CRUD
  - Conversation history persistence
  - Daily lesson limit enforcement via DB

For MVP Phase 1 (before Supabase is set up), all data is in-memory.
"""

from __future__ import annotations

from typing import Any

from app.config import get_settings

# In-memory store for MVP (replaced by Supabase queries later)
_profiles: dict[str, dict[str, Any]] = {}
_history: dict[str, list[dict[str, str]]] = {}  # user_id → message list


# ── Profile ──


def get_profile(user_id: str) -> dict[str, Any]:
    """Get or create user profile."""
    if user_id not in _profiles:
        _profiles[user_id] = {
            "id": user_id,
            "level": "N5",
            "subscription_tier": "free",
            "lessons_today": 0,
            "created_at": "2026-07-09T00:00:00Z",
        }
    return _profiles[user_id]


def update_level(user_id: str, level: str) -> dict[str, Any]:
    """Update user's JLPT level."""
    profile = get_profile(user_id)
    profile["level"] = level
    return profile


def update_subscription_tier(user_id: str, tier: str) -> dict[str, Any]:
    """Update user's subscription tier (free / pro)."""
    profile = get_profile(user_id)
    profile["subscription_tier"] = tier
    return profile


# ── Conversation History ──


def get_history(user_id: str) -> list[dict[str, str]]:
    """Get last ~20 exchanges for conversation context."""
    return _history.get(user_id, [])


def append_history(user_id: str, role: str, content: str) -> None:
    """Append a message to user's conversation history."""
    if user_id not in _history:
        _history[user_id] = []
    _history[user_id].append({"role": role, "content": content})
    # Prune to last 20 messages (10 exchanges)
    if len(_history[user_id]) > 20:
        _history[user_id] = _history[user_id][-20:]
