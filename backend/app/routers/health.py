"""Health + readiness + metrics endpoints (P1 observability)."""

from __future__ import annotations

from fastapi import APIRouter, Request

router = APIRouter()


@router.get("/health")
async def health_check():
    """Liveness: process is up. Cheap — Fly hits this often.

    Fly http_service.checks points here; keep it dependency-free so a
    sick Whisper or expired LLM key never fails the liveness probe.
    """
    return {"status": "ok", "version": "0.2.0"}


@router.get("/ready")
async def readiness_check():
    """Readiness: can this instance actually serve a lesson?

    Reports per-dependency status so load-balancing can tell a cold or
    degraded instance (Whisper still loading, LLM key missing) apart from a
    healthy one. Never 500s on a degraded dep — callers need the detail.
    """
    import time

    from app.config import get_settings
    from app.services import stt_service

    settings = get_settings()
    whisper_ready = getattr(stt_service, "_whisper_model", None) is not None
    checks = {
        "whisper_loaded": whisper_ready,
        "llm_configured": bool(settings.llm_api_key),
        # edge-tts needs no key; synthesis failures degrade gracefully to
        # text-only inside /chat, so it is not a readiness gate.
        "tts": "degraded-ok",
    }
    ready = bool(checks["whisper_loaded"] and checks["llm_configured"])
    return {
        "ready": ready,
        "version": "0.2.0",
        "uptime_probe_ts": int(time.time()),
        "checks": checks,
    }


@router.get("/metrics")
async def metrics_snapshot(request: Request):
    """P1: per-instance operational counters (no PII inside).

    What to watch after deploy:
      today.chat_429_ip        — abuse-cap hits (sustained >0 = someone minting)
      today.chat_429_limit     — free-tier exhaustions (organic demand signal)
      today.chat_5xx           — unexpected errors (alert if climbing)
      today.llm_retries        — transient LLM failures masking as 502s
      llm_tokens_today         — token burn → DeepSeek bill (alert on jump)
      tts_cache_hit_rate       — https:// rewrites paying off?
    Rollup per worker/machine only; summing across Fly machines happens in
    whatever dashboard scrapes this (or after Supabase persistence lands).
    """
    from app import metrics as op_metrics

    snap = op_metrics.snapshot()

    total_hits = (snap["total"].get("tts_cache_hits", 0)) + (
        snap["total"].get("tts_cache_miss", 0)
    )
    snap["tts_cache_hit_rate"] = (
        round(snap["total"].get("tts_cache_hits", 0) / total_hits, 3)
        if total_hits
        else None
    )
    return snap
