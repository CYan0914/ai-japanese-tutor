"""User profile endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.auth import get_current_user
from app.database import get_profile, update_level
from app.schemas import LevelUpdateRequest, LevelUpdateResponse, UserProfile

router = APIRouter()


@router.get("/user/profile", response_model=UserProfile)
async def get_user_profile(
    current_user: dict = Depends(get_current_user),
):
    profile = get_profile(current_user["user_id"])
    return UserProfile(
        id=profile["id"],
        email="",
        level=profile["level"],
        subscription_tier=profile["subscription_tier"],
        lessons_today=profile.get("lessons_today", 0),
        lessons_reset_at="",
        is_onboarding_complete=True,
        created_at=profile.get("created_at", ""),
    )


@router.post("/user/level", response_model=LevelUpdateResponse)
async def update_user_level(
    body: LevelUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    profile = update_level(current_user["user_id"], body.level)
    return LevelUpdateResponse(level=profile["level"], updated=True)
