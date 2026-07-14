"""Pydantic request/response schemas."""

from __future__ import annotations

from typing import Any
from pydantic import BaseModel, Field


# ── Chat ──


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    level: str = Field(default="N5", pattern=r"^N[1-5]$")
    audio: str | None = Field(
        default=None,
        description="Base64-encoded WAV audio of user's Japanese attempt",
    )


class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=200)
    voice: str = Field(default="ja-JP-NanamiNeural", max_length=50)


class Correction(BaseModel):
    original: str = ""
    corrected: str = ""
    explanation: str = ""


class Evaluation(BaseModel):
    accurate: bool = False
    what_was_good: str = ""
    what_to_improve: str = ""
    practice_again: str = ""


class TutorResponseContent(BaseModel):
    your_message: str = ""
    japanese_phrase: str = ""
    romaji: str = ""
    pronunciation_tips: str = ""
    evaluation: Evaluation | None = None
    corrections: list[Correction] = []
    encouragement: str = ""


class MoraScore(BaseModel):
    mora: str = ""
    confidence: float = 0.0


class PronunciationScore(BaseModel):
    overall: int = 0
    acoustic_confidence: float = 0.0
    text_accuracy: float | None = None
    level: str = ""
    details: list[MoraScore] | None = None
    feedback: str = ""


class UsageInfo(BaseModel):
    lessons_used_today: int = 0
    lessons_remaining: int = 0
    tier: str = "free"


class ChatResponse(BaseModel):
    response: TutorResponseContent
    audio_url: str | None = None
    pronunciation_score: PronunciationScore | None = None
    usage: UsageInfo = UsageInfo()


# ── User ──


class UserProfile(BaseModel):
    id: str = ""
    email: str = ""
    level: str = "N5"
    subscription_tier: str = "free"
    lessons_today: int = 0
    lessons_reset_at: str = ""
    is_onboarding_complete: bool = True
    created_at: str = ""


class LevelUpdateRequest(BaseModel):
    level: str = Field(..., pattern=r"^N[1-5]$")


class LevelUpdateResponse(BaseModel):
    level: str = ""
    updated: bool = True


# ── Phoneme Profile ──


class PhonemePoint(BaseModel):
    phoneme: str = ""
    avg_score: float = 0.0
    attempts: int = 0
    trend: str = "flat"  # improving | flat | declining
    last_practiced: str = ""  # ISO date


class PhonemeProfile(BaseModel):
    user_id: str = ""
    phonemes: list[PhonemePoint] = []
    weakest: list[str] = []  # bottom 3 phonemes
    most_improved: str = ""  # phoneme with best positive trend
    needs_practice: str = ""  # weakest phoneme, longest since practice
    total_attempts: int = 0
    last_updated: str = ""
