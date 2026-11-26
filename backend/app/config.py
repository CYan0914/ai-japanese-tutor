"""Pydantic Settings — loads from .env or env vars."""

from __future__ import annotations

import os
from pathlib import Path
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # ── App ──
    app_name: str = "Sakura AI Tutor"
    debug: bool = False

    # ── LLM API (OpenAI-compatible) ──
    llm_api_key: str = ""
    llm_base_url: str = "https://api.deepseek.com"
    llm_model: str = "deepseek-v4-flash"

    # ── STT ──
    whisper_model: str = "base"
    whisper_device: str = "cpu"

    # ── Supabase ──
    supabase_url: str = ""
    supabase_service_key: str = ""
    supabase_jwt_secret: str = ""

    # ── Rate Limit ──
    # Single source of truth for free tier. Mobile displays AppConstants.freeDailyLimit
    # (5) — keep these two in sync when changing.
    free_daily_limit: int = 5

    # ── Public URL ──
    # Origin clients use to fetch cached TTS audio, e.g.
    # "https://sakura.taomindapp.com" (origin only — never include /api/v1,
    # the routers append it). Empty = build from incoming Request.
    public_base_url: str = ""

    # ── Durable state ──
    # Directory for state that must survive a restart (bearer tokens, daily
    # usage, abuse windows). Empty = in-memory only (local dev). In prod set
    # STATE_DIR=/home/ubuntu/backend/state — it lives outside app/ so the
    # deploy rsync never touches it.
    state_dir: str = ""

    # ── OAuth ──
    # iOS OAuth client ID from Google Cloud Console.
    # When empty, /auth/google returns 501 (sign-in button will be disabled).
    google_ios_client_id: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()


# Quick way to load .env manually too
_ENV_LOADED = False


def _load_dotenv(path: str | None = None) -> None:
    global _ENV_LOADED
    if _ENV_LOADED:
        return
    _ENV_LOADED = True
    dotenv_path = path or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", ".env"
    )
    if not os.path.isfile(dotenv_path):
        return
    with open(dotenv_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            key, val = key.strip(), val.strip().strip("'\"")
            if key not in os.environ:
                os.environ[key] = val


_load_dotenv()
