"""Simple auth endpoint for MVP (get a bearer token)."""

from __future__ import annotations

import secrets

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.auth import create_token

router = APIRouter()


class TokenRequest(BaseModel):
    user_id: str | None = None


class TokenResponse(BaseModel):
    token: str
    user_id: str


@router.post("/auth/token", response_model=TokenResponse)
async def get_token(body: TokenRequest):
    """Get a bearer token for development/testing.

    In production, this would be Supabase Auth.
    For MVP, just generates a random token with an optional user_id.
    """
    user_id = body.user_id or f"user_{secrets.token_hex(8)}"
    token = create_token(user_id)
    return TokenResponse(token=token, user_id=user_id)
