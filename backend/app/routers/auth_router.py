"""Simple auth endpoint for MVP (get a bearer token)."""

from __future__ import annotations

import secrets

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel

from app.auth import check_token_mint_allowed, create_token, get_client_ip

router = APIRouter()


class TokenRequest(BaseModel):
    user_id: str | None = None


class TokenResponse(BaseModel):
    token: str
    user_id: str


@router.post("/auth/token", response_model=TokenResponse)
async def get_token(body: TokenRequest, request: Request):
    """Get a bearer token for development/testing.

    In production, this would be Supabase Auth.
    For MVP, just generates a random token with an optional user_id.
    P0: throttled per IP (20/hour) so anonymous minting can't bypass
    the per-user daily lesson limit.
    """
    client_ip = get_client_ip(request)
    allowed, reason = check_token_mint_allowed(client_ip)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error": reason,
                "message": "Too many sign-ins from this device. Please try again later.",
            },
        )
    user_id = body.user_id or f"user_{secrets.token_hex(8)}"
    token = create_token(user_id)
    return TokenResponse(token=token, user_id=user_id)
