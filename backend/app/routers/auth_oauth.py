"""Social + email auth endpoints (Apple, Google, Email signup/login).

For MVP, all user data is in-memory (consistent with the rest of the app).
In production, this becomes a Supabase Auth integration.

Apple/Google ID tokens are verified against their public JWKS before
trusting any user identity claims. Email/password uses bcrypt hashing.
"""
from __future__ import annotations

import hashlib
import re
import time
import secrets
from typing import Any

import httpx
import jwt
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, Field

from app.auth import create_token
from app.config import get_settings
from app.database import get_profile

router = APIRouter()

# Apple and Google public JWKS endpoints (cached in-process)
_JWKS_CACHE: dict[str, tuple[float, list[dict[str, Any]]]] = {}
_JWKS_TTL = 3600  # 1 hour

# In-memory user store (MVP)
# (provider, provider_user_id) -> user_id
_provider_index: dict[tuple[str, str], str] = {}
# user_id -> {email, provider, provider_user_id, password_hash}
_user_records: dict[str, dict[str, Any]] = {}
# email -> user_id (lowercase, for email/password users)
_email_index: dict[str, str] = {}

# Apple + Google audience (bundle id / client id)
APPLE_BUNDLE_ID = "com.sakurasensei.app"
# GOOGLE_CLIENT_ID is the iOS OAuth client ID, injected via env at deploy time
# (placeholder for now; user will set this up later)


# ── Schemas ──


class OAuthRequest(BaseModel):
    id_token: str = Field(..., min_length=10)


class EmailSignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    display_name: str | None = Field(default=None, max_length=64)


class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=128)


class AuthResponse(BaseModel):
    token: str
    user_id: str
    email: str = ""
    provider: str
    is_new_user: bool


# ── JWKS helpers ──


def _fetch_jwks(url: str) -> list[dict[str, Any]]:
    """Fetch + cache JWKS for the given issuer."""
    now = time.time()
    cached = _JWKS_CACHE.get(url)
    if cached and (now - cached[0]) < _JWKS_TTL:
        return cached[1]
    with httpx.Client(timeout=10) as client:
        resp = client.get(url)
        resp.raise_for_status()
        keys = resp.json().get("keys", [])
    _JWKS_CACHE[url] = (now, keys)
    return keys


def _verify_id_token(
    id_token: str,
    *,
    jwks_url: str,
    issuer: str | list[str],
    audience: str,
) -> dict[str, Any]:
    """Verify a third-party ID token and return the decoded claims."""
    try:
        unverified_header = jwt.get_unverified_header(id_token)
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token header: {e}",
        )

    kid = unverified_header.get("kid")
    if not kid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing kid",
        )

    keys = _fetch_jwks(jwks_url)
    jwk = next((k for k in keys if k.get("kid") == kid), None)
    if jwk is None:
        # Force refresh once
        _JWKS_CACHE.pop(jwks_url, None)
        keys = _fetch_jwks(jwks_url)
        jwk = next((k for k in keys if k.get("kid") == kid), None)
    if jwk is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Signing key not found",
        )

    public_key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)  # type: ignore[arg-type]
    try:
        claims = jwt.decode(
            id_token,
            public_key,
            algorithms=["RS256"],
            audience=audience,
            issuer=issuer,
        )
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {e}",
        )
    return claims


# ── Apple ──


@router.post("/auth/apple", response_model=AuthResponse)
async def sign_in_with_apple(req: OAuthRequest):
    """Verify Apple identity token, create or look up user, return our bearer."""
    claims = _verify_id_token(
        req.id_token,
        jwks_url="https://appleid.apple.com/auth/keys",
        issuer="https://appleid.apple.com",
        audience=APPLE_BUNDLE_ID,
    )
    apple_sub = claims.get("sub")
    if not apple_sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Apple token missing sub",
        )
    email = (claims.get("email") or "").strip().lower()
    return _upsert_user(
        provider="apple",
        provider_user_id=apple_sub,
        email=email,
    )


# ── Google ──


@router.post("/auth/google", response_model=AuthResponse)
async def sign_in_with_google(req: OAuthRequest):
    """Verify Google ID token, create or look up user, return our bearer."""
    settings = get_settings()
    google_audience = settings.google_ios_client_id
    if not google_audience:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Google sign-in not configured. Set GOOGLE_IOS_CLIENT_ID env var.",
        )
    claims = _verify_id_token(
        req.id_token,
        jwks_url="https://www.googleapis.com/oauth2/v3/certs",
        issuer=["https://accounts.google.com", "accounts.google.com"],
        audience=google_audience,
    )
    google_sub = claims.get("sub")
    if not google_sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google token missing sub",
        )
    email = (claims.get("email") or "").strip().lower()
    return _upsert_user(
        provider="google",
        provider_user_id=google_sub,
        email=email,
    )


# ── Email ──


@router.post("/auth/email/signup", response_model=AuthResponse)
async def email_signup(req: EmailSignupRequest):
    """Create a new email/password account."""
    email = req.email.strip().lower()
    if not _is_valid_email(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email",
        )
    if email in _email_index:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered. Try logging in instead.",
        )
    user_id = f"email:{_hash_email(email)}"
    _user_records[user_id] = {
        "user_id": user_id,
        "email": email,
        "provider": "email",
        "provider_user_id": email,
        "password_hash": _hash_password(req.password),
    }
    _email_index[email] = user_id
    return _mint_token(user_id, email, "email", is_new=True)


@router.post("/auth/email/login", response_model=AuthResponse)
async def email_login(req: EmailLoginRequest):
    """Login with email + password."""
    email = req.email.strip().lower()
    user_id = _email_index.get(email)
    if not user_id or user_id not in _user_records:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    record = _user_records[user_id]
    if not _verify_password(req.password, record["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    return _mint_token(user_id, email, "email", is_new=False)


# ── Helpers ──


def _upsert_user(
    *,
    provider: str,
    provider_user_id: str,
    email: str,
) -> AuthResponse:
    """Look up or create a user record from a social identity."""
    key = (provider, provider_user_id)
    is_new = key not in _provider_index
    if is_new:
        user_id = f"{provider}:{_hash_provider_id(provider, provider_user_id)}"
        _provider_index[key] = user_id
        _user_records[user_id] = {
            "user_id": user_id,
            "email": email,
            "provider": provider,
            "provider_user_id": provider_user_id,
            "password_hash": None,
        }
        # Touch the profile to initialize it
        get_profile(user_id)
    else:
        user_id = _provider_index[key]
        # Update email if we got a more recent one
        if email and not _user_records[user_id].get("email"):
            _user_records[user_id]["email"] = email
    return _mint_token(
        user_id,
        _user_records[user_id]["email"],
        provider,
        is_new=is_new,
    )


def _mint_token(
    user_id: str,
    email: str,
    provider: str,
    *,
    is_new: bool,
) -> AuthResponse:
    """Create a bearer token and return an auth response."""
    token = create_token(user_id)
    return AuthResponse(
        token=token,
        user_id=user_id,
        email=email,
        provider=provider,
        is_new_user=is_new,
    )


# Use PBKDF2-HMAC-SHA256 with a per-app salt for password hashing (no extra deps).
# This is a deliberate trade-off — for production, use Argon2id or bcrypt.
_PASSWORD_SALT = b"sakura-tutor-pw-salt-v1"
_PBKDF2_ITER = 120_000


def _hash_password(password: str) -> str:
    derived = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), _PASSWORD_SALT, _PBKDF2_ITER
    )
    return derived.hex()


def _verify_password(password: str, stored_hash: str) -> bool:
    return secrets.compare_digest(_hash_password(password), stored_hash)


_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _is_valid_email(email: str) -> bool:
    return bool(email) and bool(_EMAIL_RE.match(email))


def _hash_email(email: str) -> str:
    return hashlib.sha256(email.encode("utf-8")).hexdigest()[:16]


def _hash_provider_id(provider: str, provider_user_id: str) -> str:
    return hashlib.sha256(f"{provider}:{provider_user_id}".encode()).hexdigest()[:16]
