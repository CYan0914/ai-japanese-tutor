"""Pronunciation scoring engine.

Combines three signals:
  1. Whisper acoustic confidence (per-segment probabilities)
  2. Text accuracy via Levenshtein distance (expected phrase vs transcribed)
  3. LLM linguistic evaluation (binary accurate flag)
"""

from __future__ import annotations

from typing import Any


def levenshtein_distance(a: str, b: str) -> int:
    """Character-level Levenshtein distance."""
    n, m = len(a), len(b)
    if n == 0:
        return m
    if m == 0:
        return n

    prev = list(range(m + 1))
    curr = [0] * (m + 1)

    for i in range(1, n + 1):
        curr[0] = i
        for j in range(1, m + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            curr[j] = min(
                prev[j] + 1,       # delete
                curr[j - 1] + 1,   # insert
                prev[j - 1] + cost, # substitute
            )
        prev, curr = curr, prev

    return prev[m]


def normalize_to_kana(text: str) -> str:
    """Basic normalization: strip spaces, lowercase romaji for comparison."""
    return text.strip().replace(" ", "").lower()


def compute_score(
    whisper_segments: list[dict],
    expected_phrase: str | None,
    llm_evaluation: dict[str, Any] | None,
) -> dict:
    """Compute pronunciation score → dict matching PronunciationScore schema."""
    # ── Signal 1: Acoustic confidence ──
    confidences = [s.get("probability", 0.0) for s in whisper_segments if s.get("probability")]
    acoustic_conf = sum(confidences) / len(confidences) if confidences else 0.0

    # Per-mora details
    per_mora = []
    for s in whisper_segments:
        per_mora.append({
            "mora": s.get("word", ""),
            "confidence": round(s.get("probability", 0.0), 2),
        })

    # ── Signal 2: Text accuracy ──
    text_accuracy: float | None = None
    if expected_phrase and whisper_segments:
        transcribed = "".join(s.get("word", "") for s in whisper_segments)
        norm_expected = normalize_to_kana(expected_phrase)
        norm_transcribed = normalize_to_kana(transcribed)
        dist = levenshtein_distance(norm_expected, norm_transcribed)
        max_len = max(len(norm_expected), len(norm_transcribed))
        if max_len > 0:
            text_accuracy = 1.0 - (dist / max_len)

    # ── Signal 3: LLM evaluation ──
    llm_score = 1.0
    if llm_evaluation is not None:
        llm_score = 1.0 if llm_evaluation.get("accurate", False) else 0.0

    # ── Composite ──
    if text_accuracy is not None:
        overall = 0.30 * acoustic_conf + 0.30 * text_accuracy + 0.40 * llm_score
    else:
        overall = 0.40 * acoustic_conf + 0.60 * llm_score

    # ── Grade ──
    if overall >= 0.85:
        grade = "excellent"
        feedback = "Excellent pronunciation! Keep it up!"
    elif overall >= 0.70:
        grade = "good"
        feedback = "Good job! A few small areas to polish."
    elif overall >= 0.50:
        grade = "fair"
        feedback = "Getting there! Focus on the sounds marked below."
    else:
        grade = "needs_work"
        feedback = "Keep practicing! Every attempt makes you better."

    return {
        "overall": round(overall * 100),
        "acoustic_confidence": round(acoustic_conf, 2),
        "text_accuracy": round(text_accuracy, 2) if text_accuracy is not None else None,
        "level": grade,
        "details": per_mora[:20] if per_mora else None,  # cap at 20 mora
        "feedback": feedback,
    }
