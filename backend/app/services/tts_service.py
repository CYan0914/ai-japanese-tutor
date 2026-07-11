"""Text-to-speech via edge-tts (free, Microsoft Edge TTS)."""

from __future__ import annotations

import os
import tempfile

import edge_tts

JAPANESE_VOICE = "ja-JP-NanamiNeural"


async def synthesize(text: str) -> bytes:
    """Synthesize Japanese text -> MP3 bytes."""
    communicate = edge_tts.Communicate(text, JAPANESE_VOICE)
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        await communicate.save(tmp_path)
        with open(tmp_path, "rb") as f:
            return f.read()
    finally:
        os.unlink(tmp_path)
