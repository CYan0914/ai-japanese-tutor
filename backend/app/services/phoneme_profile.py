"""Phoneme-level pronunciation tracking.

Stores per-phoneme scores over time so we can identify each user's
weaknesses, track improvement trends, and recommend what to practice next.
"""

from __future__ import annotations

import time
from collections import defaultdict

# ── In-memory store (MVP — replaced by DB later) ──
# user_id → {phoneme: [score1, score2, ...]}
_phoneme_history: dict[str, dict[str, list[float]]] = defaultdict(lambda: defaultdict(list))


def record_phoneme_scores(
    user_id: str,
    phoneme_scores: dict[str, float],  # {"ら": 0.82, "つ": 0.45, ...}
) -> None:
    """Record phoneme scores from a single evaluation."""
    for phoneme, score in phoneme_scores.items():
        _phoneme_history[user_id][phoneme].append(float(score))


def get_phoneme_profile(user_id: str) -> dict:
    """Build the user's phoneme profile from accumulated history."""
    user_data = _phoneme_history.get(user_id, {})
    if not user_data:
        return {
            "user_id": user_id,
            "phonemes": [],
            "weakest": [],
            "most_improved": "",
            "needs_practice": "",
            "total_attempts": 0,
            "last_updated": "",
        }

    phonemes = []
    for phoneme, scores in user_data.items():
        avg = sum(scores) / len(scores)
        # Determine trend from last 5 scores
        recent = scores[-5:]
        trend = "flat"
        if len(recent) >= 2:
            if recent[-1] > recent[0] + 5:
                trend = "improving"
            elif recent[-1] < recent[0] - 5:
                trend = "declining"

        phonemes.append({
            "phoneme": phoneme,
            "avg_score": round(avg, 1),
            "attempts": len(scores),
            "trend": trend,
            "last_practiced": time.strftime("%Y-%m-%d"),
        })

    # Sort by score ascending (weakest first)
    phonemes.sort(key=lambda p: p["avg_score"])

    # Weakest 3
    weakest = [p["phoneme"] for p in phonemes[:3]]

    # Most improved (biggest positive trend)
    improving = [p for p in phonemes if p["trend"] == "improving"]
    most_improved = ""
    if improving:
        improving.sort(key=lambda p: p["avg_score"], reverse=True)
        most_improved = improving[0]["phoneme"]

    # Needs practice (weakest that hasn't been practiced recently)
    needs = phonemes[0]["phoneme"] if phonemes else ""

    total_attempts = sum(p["attempts"] for p in phonemes)

    return {
        "user_id": user_id,
        "phonemes": phonemes,
        "weakest": weakest,
        "most_improved": most_improved,
        "needs_practice": needs,
        "total_attempts": total_attempts,
        "last_updated": time.strftime("%Y-%m-%dT%H:%M:%S"),
    }
