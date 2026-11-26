"""Text-to-speech via edge-tts (free, Microsoft Edge TTS)."""

from __future__ import annotations

import asyncio
import hashlib
import os
import tempfile

import edge_tts
from edge_tts import communicate as _edge_communicate
from edge_tts.constants import TRUSTED_CLIENT_TOKEN

# Microsoft retired the old synthesis endpoint
# (speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1) —
# it now returns 403 for every caller regardless of IP or proxy. The migrated
# endpoint is api.msedgeservices.com and wants the trusted client token as a
# query param.
#
# ⚠️ Patch edge_tts.communicate.WSS_URL, NOT edge_tts.constants.WSS_URL:
# communicate.py does `from .constants import WSS_URL`, which shadows the
# constant in its own namespace, so editing constants has no effect.
_edge_communicate.WSS_URL = (
    "wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1"
    f"?Ocp-Apim-Subscription-Key={TRUSTED_CLIENT_TOKEN}"
)

JAPANESE_VOICE = "ja-JP-NanamiNeural"

# ── P0: in-memory TTS cache ──
# The same Japanese phrases (greetings, corrections) are synthesized over and
# over — edge-tts opens a fresh WebSocket per call and rate-limits bursts.
# Cache by sha256(voice + text), FIFO-evicted, so repeats cost zero latency
# and zero upstream calls. Returns bytes; routers expose them as https URLs
# (see GET /audio/{name}) instead of inline base64 data URIs.
_TTS_CACHE: dict[str, bytes] = {}
_TTS_CACHE_MAX_ENTRIES = 200
_TTS_CACHE_MAX_BYTES = 20 * 1024 * 1024  # ~20MB cap


def tts_cache_key(text: str, voice: str = JAPANESE_VOICE) -> str:
    """Stable cache key for a (voice, text) pair."""
    digest = hashlib.sha256(f"{voice}:{text}".encode("utf-8")).hexdigest()
    return digest[:32]


def tts_cache_get(key: str) -> bytes | None:
    """Return cached MP3 bytes, or None on miss."""
    return _TTS_CACHE.get(key)


def tts_cache_put(key: str, data: bytes) -> None:
    """Store MP3 bytes, evicting oldest entries past size/count caps."""
    if key in _TTS_CACHE:
        return
    _TTS_CACHE[key] = data
    while len(_TTS_CACHE) > _TTS_CACHE_MAX_ENTRIES or (
        _TTS_CACHE and sum(len(v) for v in _TTS_CACHE.values()) > _TTS_CACHE_MAX_BYTES
    ):
        _TTS_CACHE.pop(next(iter(_TTS_CACHE)))


async def synthesize(text: str) -> bytes:
    """Synthesize Japanese text -> MP3 bytes with retry on failure.

    edge-tts opens a WebSocket connection per call. On rare occasions the
    connection can stall or be rate-limited, so we retry with backoff.
    """
    last_exception: Exception | None = None
    for attempt in range(3):
        try:
            communicate = edge_tts.Communicate(text, JAPANESE_VOICE)
            with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
                tmp_path = tmp.name

            try:
                await communicate.save(tmp_path)
                with open(tmp_path, "rb") as f:
                    return f.read()
            finally:
                try:
                    os.unlink(tmp_path)
                except OSError:
                    pass
        except Exception as e:
            last_exception = e
            if attempt < 2:
                await asyncio.sleep(1 * (attempt + 1))
                continue
            raise
