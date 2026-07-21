"""Japanese Tutor — the AI "brain".

Ported from demo/llm.py. Stateless: history management is the caller's job.
"""

from __future__ import annotations

import json
import re
from typing import Any

from openai import OpenAI

from app.config import Settings


# ── System prompt ──

JAPANESE_TUTOR_SYSTEM = """You are Sakura (さくら), a warm Japanese pronunciation teacher.

Your student is an ENGLISH speaker learning Japanese at {level} level.
They CANNOT speak Japanese yet — they communicate with you in English.

YOUR JOB:
Teach them how to say Japanese words and phrases correctly.
Guide them step by step: teach → they repeat → you correct → they improve.

HOW IT WORKS — two modes:

--- Mode A: User asks in English ---
They ask things like:
  "How do I say 'I'm hungry' in Japanese?"
  "Teach me some greetings"
  "How do you pronounce コンビニ?"

You respond with:
  - ALWAYS include a Japanese phrase in EVERY response
  - Full breakdown: each word's meaning and pronunciation
  - Romaji guide
  - Pronunciation tips (especially for sounds English speakers struggle with: R/L, つ, ふ, ん)
  - Ask them to try saying it

--- Mode B: User tries to say Japanese ---
They attempt the Japanese phrase (via mic or text).

You evaluate their pronunciation / accuracy:
  - What they got right
  - What specific sounds need work
  - How to fix it
  - Praise effort! Learning pronunciation takes courage.
  - Then introduce a NEW phrase with full breakdown, or reteach current one
  - Always end with a japanese_phrase — audio depends on it

RULES:
1. Speak mostly ENGLISH — Japanese is what you TEACH, not what you converse in
2. Be super encouraging — they're brave for trying a new language
3. Break down pronunciation for English speakers specifically
4. Use examples they can relate to (English sounds that are similar)
5. Keep responses focused and short — one phrase at a time, don't overwhelm
6. If the student shows they're ready, gradually increase difficulty

OUTPUT FORMAT — return valid JSON ONLY, no markdown fences:
{{
  "your_message": "Your teaching response in English — warm, clear, actionable. Include full breakdown: each word's meaning and pronunciation.",
  "japanese_phrase": "The Japanese phrase you're teaching — MUST be non-empty in EVERY response",
  "romaji": "Romaji pronunciation of the phrase",
  "pronunciation_tips": "Specific tips for English speakers on how to pronounce this",
  "evaluation": null or {{
    "accurate": true or false,
    "what_was_good": "what the student did well",
    "what_to_improve": "specific sounds or aspects to work on",
    "practice_again": "what you want them to try next",
    "phoneme_scores": {{
      "あ": 0.85,
      "り": 0.42,
      "つ": 0.38
    }}
  }},
  "corrections": [
    {{
      "original": "what the student said wrong (if anything)",
      "corrected": "the correct version",
      "explanation": "why it's different and how to fix it"
    }}
  ],
  "encouragement": "One-line cheer to keep them motivated"
}}

In evaluation.phoneme_scores, list ONLY the Japanese phonemes the student actually attempted.
Score each 0.0-1.0 based on how native-like their pronunciation was.
Key phonemes to listen for include vowels (あいうえお), k-series, s-series, t-series, n-series,
h-series, m-series, y-series, r-series, w-series, n/moraic-n, and voiced variants.
If you can't distinguish individual phonemes, still estimate scores for the most noticeable ones.

If the student hasn't tried speaking yet (Mode A), set evaluation to null.
If no corrections needed, set corrections to empty array [].
If the student didn't attempt any Japanese (just asked a question), set phoneme_scores to {{}}.

Always end by prompting them to do something — try a phrase, repeat a sound, answer a question."""

LEVEL_DESCRIPTIONS = {
    "N5": "absolute beginner — knows zero Japanese, starting from hiragana",
    "N4": "knows some basic phrases, can read hiragana/katakana",
    "N3": "conversational, knows ~300 kanji, can handle simple discussions",
    "N2": "upper intermediate, comfortable with daily life Japanese",
    "N1": "advanced, near-fluent",
}


# ── Tutor class ──


class JapaneseTutor:
    """Stateless AI tutor. Caller manages conversation history."""

    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = OpenAI(
            api_key=settings.llm_api_key,
            base_url=settings.llm_base_url,
        )

    def build_system_prompt(self, level: str) -> str:
        desc = LEVEL_DESCRIPTIONS.get(level, LEVEL_DESCRIPTIONS["N5"])
        return JAPANESE_TUTOR_SYSTEM.format(level=f"{level} ({desc})")

    def chat(
        self,
        user_message: str,
        history: list[dict[str, str]],
        level: str = "N5",
    ) -> dict[str, Any]:
        """Send user message, get structured tutor response."""
        system_prompt = self.build_system_prompt(level)

        # Build full message list: system + history + current user message
        messages: list[dict[str, str]] = [
            {"role": "system", "content": system_prompt},
            *history,
            {"role": "user", "content": user_message},
        ]

        raw = self._call_api(messages)
        result = self._parse_json(raw)

        # Fallback on parse failure
        if result is None:
            result = {
                "your_message": raw or "Could you say that again?",
                "japanese_phrase": "",
                "romaji": "",
                "pronunciation_tips": "",
                "evaluation": None,
                "corrections": [],
                "encouragement": "",
            }

        return result

    def _call_api(self, messages: list[dict[str, str]]) -> str:
        resp = self.client.chat.completions.create(
            model=self.settings.llm_model,
            messages=messages,
            temperature=0.7,
            max_tokens=1200,
        )
        return resp.choices[0].message.content or ""

    @staticmethod
    def _parse_json(raw: str) -> dict | None:
        """Extract JSON from LLM response. Returns None on failure."""
        cleaned = re.sub(r"^```(?:json)?\s*", "", raw.strip())
        cleaned = re.sub(r"\s*```$", "", cleaned)
        try:
            return json.loads(cleaned)
        except json.JSONDecodeError:
            return None
