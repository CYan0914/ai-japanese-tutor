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
    llm_model: str = "deepseek-chat"

    # ── STT ──
    whisper_model: str = "base"
    whisper_device: str = "cpu"

    # ── Supabase ──
    supabase_url: str = ""
    supabase_service_key: str = ""
    supabase_jwt_secret: str = ""

    # ── Rate Limit ──
    free_daily_limit: int = 5

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
