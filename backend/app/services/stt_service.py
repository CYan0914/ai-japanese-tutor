"""Speech-to-text via faster-whisper (local, free)."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path
from typing import Any

import numpy as np

from app.config import Settings

# HF_ENDPOINT can be set via env var (hf-mirror.com for China)
# Default: unset = use huggingface.co directly
_ = os.environ.get("HF_ENDPOINT")  # just reference it, don't override

# Lazy-loaded singleton
_whisper_model: Any = None


def init_whisper(settings: Settings) -> None:
    """Load Whisper model once at server startup."""
    global _whisper_model
    if _whisper_model is not None:
        return

    # HuggingFace mirror for China
    from faster_whisper import WhisperModel

    _whisper_model = WhisperModel(
        settings.whisper_model,
        device=settings.whisper_device,
        compute_type="int8",
    )


def transcribe(
    audio_data: bytes,
    language: str | None = None,
) -> tuple[str, list[dict]]:
    """Transcribe audio bytes → (text, segments_with_confidence).

    If language is None, Whisper auto-detects the language (recommended).
    """
    global _whisper_model
    if _whisper_model is None:
        raise RuntimeError("Whisper model not loaded. Call init_whisper() first.")

    # Write bytes to temp WAV file for faster-whisper
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_data)
        tmp_path = tmp.name

    try:
        segments, _info = _whisper_model.transcribe(
            tmp_path,
            language=language,
            beam_size=5,
        )

        text_parts: list[str] = []
        seg_list: list[dict] = []

        for seg in segments:
            text_parts.append(seg.text)
            for word in (seg.words or []):
                seg_list.append({
                    "word": word.word,
                    "start": word.start,
                    "end": word.end,
                    "probability": word.probability,
                })

        return "".join(text_parts).strip(), seg_list
    finally:
        os.unlink(tmp_path)


def transcribe_from_numpy(
    audio: np.ndarray,
    sample_rate: int = 16000,
    language: str | None = None,
) -> tuple[str, list[dict]]:
    """Transcribe numpy array audio (float32, -1 to 1) → (text, segments)."""
    import soundfile as sf
    import tempfile

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        sf.write(tmp.name, audio, sample_rate)
        tmp_path = tmp.name

    try:
        with open(tmp_path, "rb") as f:
            return transcribe(f.read(), language=language)
    finally:
        os.unlink(tmp_path)
