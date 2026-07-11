"""FastAPI app factory."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth_router as auth_routes
from app.routers import chat, health, user


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load heavy models on startup, clean up on shutdown."""
    settings = get_settings()

    # ── load Whisper model once ──
    from app.services.stt_service import init_whisper

    init_whisper(settings)
    app.state.whisper_loaded = True

    yield

    # ── cleanup ──
    app.state.whisper_loaded = False


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
    )

    # CORS — allow mobile app from any origin during MVP
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routes
    app.include_router(health.router, prefix="/api/v1", tags=["Health"])
    app.include_router(chat.router, prefix="/api/v1", tags=["Chat"])
    app.include_router(user.router, prefix="/api/v1", tags=["User"])
    app.include_router(auth_routes.router, prefix="/api/v1", tags=["Auth"])

    return app


app = create_app()
