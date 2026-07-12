"""POST /api/v1/chat — the core endpoint."""

from __future__ import annotations

import base64
import io
import os
import tempfile
import wave

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import check_usage_limit, get_current_user, get_user_usage
from app.config import get_settings
from app.database import append_history, get_history
from app.schemas import (
    ChatRequest,
    ChatResponse,
    Correction,
    Evaluation,
    PronunciationScore,
    TutorResponseContent,
    UsageInfo,
)
from app.services.scoring import compute_score
from app.services.stt_service import transcribe
from app.services.tts_service import synthesize as synthesize_tts
from app.services.tutor import JapaneseTutor
from app.services.phoneme_profile import record_phoneme_scores

router = APIRouter()

# Singleton tutor (stateless, so safe to share)
_tutor: JapaneseTutor | None = None


def get_tutor() -> JapaneseTutor:
    global _tutor
    if _tutor is None:
        _tutor = JapaneseTutor(get_settings())
    return _tutor


@router.post("/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """Main chat + teaching endpoint.

    Accepts text (and optionally audio). Returns AI teaching response,
    TTS audio URL, pronunciation score (if audio provided), and usage info.
    """
    user_id = current_user["user_id"]
    level = body.level or current_user.get("level", "N5")
    settings = get_settings()

    try:
        return await _process_chat(body, user_id, level, settings)
    except HTTPException:
        raise  # re-raise HTTP exceptions as-is
    except Exception as e:
        import logging
        import traceback
        logging.getLogger("uvicorn.error").error(
            f"Unhandled error in chat endpoint: {e}\n{traceback.format_exc()}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "internal_error",
                "message": "An unexpected error occurred. Our team has been notified.",
                "debug": str(e)[:200],
            },
        )


async def _process_chat(
    body: ChatRequest,
    user_id: str,
    level: str,
    settings,
):
    # ── 1. Check usage limit ──
    usage_info = check_usage_limit(user_id)
    if usage_info["lessons_remaining"] <= 0 and usage_info["tier"] == "free":
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error": "daily_limit_reached",
                "message": "You've used all your free lessons for today. Upgrade to Pro for unlimited access!",
                "usage": usage_info,
            },
        )

    # ── 2. If audio provided → run STT + scoring ──
    transcribed_text = body.message
    pronunciation_score = None
    expected_phrase = None  # set from tutor's last response if available

    if body.audio:
        try:
            audio_bytes = base64.b64decode(body.audio)
            # Run Whisper STT — auto-detect language (user speaks English or Japanese)
            text_from_audio, segments = transcribe(audio_bytes)
            if text_from_audio:
                transcribed_text = text_from_audio

            # Get expected phrase from conversation history (last AI message)
            history = get_history(user_id)
            for msg in reversed(history):
                if msg["role"] == "assistant":
                    # Try to extract japanese_phrase from stored content
                    # For simplicity, we store it in database as a marker
                    break

            # Compute pronunciation score
            pronunciation_score = compute_score(
                whisper_segments=segments,
                expected_phrase=expected_phrase,
                llm_evaluation=None,  # will be updated after LLM call
            )
        except Exception as e:
            # If STT fails, fall back to text-only gracefully
            pass

    # ── 3. Get conversation history ──
    history = get_history(user_id)

    # ── 4. Call LLM ──
    tutor = get_tutor()
    try:
        result = tutor.chat(
            user_message=transcribed_text,
            history=history,
            level=level,
        )
    except Exception as e:
        import logging
        logging.getLogger("uvicorn.error").error(f"LLM call failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "error": "ai_service_error",
                "message": "The AI teaching service is temporarily unavailable. Please try again.",
            },
        )

    # ── 5. Update pronunciation score with LLM evaluation ──
    if pronunciation_score and result.get("evaluation"):
        # Re-score with LLM evaluation included
        pronunciation_score = compute_score(
            whisper_segments=pronunciation_score.get("details") or [],
            expected_phrase=expected_phrase,
            llm_evaluation=result["evaluation"],
        )

    # ── 6. Generate TTS if there's a Japanese phrase ──
    audio_url = None
    jp_phrase = result.get("japanese_phrase", "")
    if jp_phrase:
        try:
            tts_bytes = await synthesize_tts(jp_phrase)
            # For MVP: store inline as data URI (no Supabase Storage yet)
            audio_b64 = base64.b64encode(tts_bytes).decode()
            audio_url = f"data:audio/mp3;base64,{audio_b64}"
        except Exception as e:
            # Log TTS failure but don't break the response
            import logging
            logging.getLogger("uvicorn.error").warning(f"TTS failed for '{jp_phrase[:50]}': {e}")
    # ── 6.5 Record phoneme scores for pronunciation tracking ──
    eval_data = result.get("evaluation")
    if eval_data and isinstance(eval_data, dict):
        ps = eval_data.get("phoneme_scores")
        if ps and isinstance(ps, dict) and len(ps) > 0:
            try:
                # Convert 0-1 scores to 0-100 scale
                scaled = {k: float(v) * 100 for k, v in ps.items()}
                record_phoneme_scores(user_id, scaled)
            except Exception:
                pass  # non-critical, don't break the response

    # ── 7. Store conversation history ──
    # Include key teaching content (not just jp_phrase) so the LLM has context
    assistant_summary_parts = []
    if result.get("your_message"):
        assistant_summary_parts.append(result["your_message"][:300])
    if jp_phrase:
        assistant_summary_parts.append(f"[Japanese: {jp_phrase}]")
    if result.get("romaji"):
        assistant_summary_parts.append(f"[Romaji: {result['romaji']}]")
    assistant_summary = " ".join(assistant_summary_parts) if assistant_summary_parts else jp_phrase
    if not assistant_summary:
        assistant_summary = transcribed_text  # fallback

    append_history(user_id, "user", transcribed_text)
    append_history(user_id, "assistant", assistant_summary)

    # ── 8. Increment usage ──
    final_usage = get_user_usage(user_id)

    # ── 9. Build response ──
    eval_data = result.get("evaluation")
    evaluation_obj = None
    if eval_data:
        evaluation_obj = Evaluation(
            accurate=eval_data.get("accurate", False),
            what_was_good=eval_data.get("what_was_good", ""),
            what_to_improve=eval_data.get("what_to_improve", ""),
            practice_again=eval_data.get("practice_again", ""),
        )

    corrections = []
    for c in result.get("corrections") or []:
        corrections.append(Correction(**c))

    score_obj = None
    if pronunciation_score:
        score_obj = PronunciationScore(**pronunciation_score)

    return ChatResponse(
        response=TutorResponseContent(
            your_message=result.get("your_message", ""),
            japanese_phrase=jp_phrase,
            romaji=result.get("romaji", ""),
            pronunciation_tips=result.get("pronunciation_tips", ""),
            evaluation=evaluation_obj,
            corrections=corrections,
            encouragement=result.get("encouragement", ""),
        ),
        audio_url=audio_url,
        pronunciation_score=score_obj,
        usage=UsageInfo(
            lessons_used_today=final_usage.get("lessons_used_today", 0),
            lessons_remaining=final_usage.get("lessons_remaining", 0),
            tier=final_usage.get("tier", "free"),
        ),
    )
