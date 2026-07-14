"""Text-to-speech via edge-tts (free, Microsoft Edge TTS)."""

from __future__ import annotations

import asyncio
import os
import tempfile

import edge_tts

JAPANESE_VOICE = "ja-JP-NanamiNeural"


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
