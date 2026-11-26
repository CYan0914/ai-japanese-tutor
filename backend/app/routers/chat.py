"""POST /api/v1/chat — the core endpoint."""

from __future__ import annotations

import base64
import logging

import anyio
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status

from app.auth import (
    check_chat_allowed,
    check_usage_limit,
    get_client_ip,
    get_current_user,
    get_user_usage,
)
from app import metrics as op_metrics
from app.config import get_settings
from app.database import append_history, get_history
from app.schemas import (
    ChatRequest,
    ChatResponse,
    Correction,
    Evaluation,
    PronunciationScore,
    TTSRequest,
    TutorResponseContent,
    UsageInfo,
)
from app.services.scoring import compute_score
from app.services.stt_service import transcribe
from app.services.tts_service import (
    synthesize as synthesize_tts,
)
from app.services.tts_service import (
    tts_cache_get,
    tts_cache_key,
    tts_cache_put,
)
from app.services.tutor import JapaneseTutor
from app.services.phoneme_profile import record_phoneme_scores

router = APIRouter()

logger = logging.getLogger("uvicorn.error")

# Singleton tutor (stateless, so safe to share)
_tutor: JapaneseTutor | None = None


def get_tutor() -> JapaneseTutor:
    global _tutor
    if _tutor is None:
        _tutor = JapaneseTutor(get_settings())
    return _tutor


def _audio_base_url(settings, request: Request | None) -> str:
    """Base URL clients use to fetch cached TTS audio.

    Prefers explicit PUBLIC_BASE_URL (set in prod), falls back to the
    incoming request's base URL (works behind Fly.io proxy).
    """
    if settings.public_base_url:
        return settings.public_base_url.rstrip("/")
    if request is not None:
        return str(request.base_url).rstrip("/")
    return ""


@router.post("/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Main chat + teaching endpoint.

    Accepts text (and optionally audio). Returns AI teaching response,
    TTS audio URL, pronunciation score (if audio provided), and usage info.
    """
    user_id = current_user["user_id"]
    level = body.level or current_user.get("level", "N5")
    settings = get_settings()

    # P0 second line: per-IP daily cap so minting N users from one IP
    # can't multiply the per-user LLM quota into a bill amplifier.
    ip_allowed, ip_reason = check_chat_allowed(get_client_ip(request))
    if not ip_allowed:
        op_metrics.incr("chat_429_ip")
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error": ip_reason,
                "message": "Too many requests from this device today. Please try again tomorrow.",
            },
        )

    try:
        return await _process_chat(body, user_id, level, settings, request)
    except HTTPException as e:
        if e.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
            op_metrics.incr("chat_429_limit")
        elif e.status_code >= 500:
            op_metrics.incr("chat_5xx")
        raise  # re-raise HTTP exceptions as-is
    except Exception:
        op_metrics.incr("chat_5xx")
        # P0: log server-side only — never ship exception text to clients.
        logger.exception("Unhandled error in chat endpoint")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "internal_error",
                "message": "An unexpected error occurred. Our team has been notified.",
            },
        )


async def _process_chat(
    body: ChatRequest,
    user_id: str,
    level: str,
    settings,
    request: Request | None = None,
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
            # P0: faster-whisper is sync + CPU-bound — run in a worker thread
            # so one voice message doesn't stall the whole event loop.
            # Whisper auto-detects language (user speaks English or Japanese).
            text_from_audio, segments = await anyio.to_thread.run_sync(
                lambda: transcribe(audio_bytes)
            )
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
        except Exception:
            # If STT fails, fall back to text-only gracefully
            logger.warning("STT failed, falling back to text-only", exc_info=True)

    # ── 3. Get conversation history ──
    history = get_history(user_id)

    # ── 4. Call LLM (async — never blocks the event loop) ──
    # P1: one retry on transient LLM failures (rate limit / gateway blip).
    # First failure is logged + counted; only the second surfaces as 502,
    # because a single blip shouldn't kill the user's lesson.
    tutor = get_tutor()
    result = None
    last_llm_error: Exception | None = None
    for attempt in range(2):
        try:
            result = await tutor.chat(
                user_message=transcribed_text,
                history=history,
                level=level,
            )
            if attempt == 1:
                op_metrics.incr("llm_retry_success")
            break
        except Exception as e:
            last_llm_error = e
            if attempt == 0:
                op_metrics.incr("llm_retries")
                logger.warning("LLM call transient failure, retrying once", exc_info=True)
                continue
            logger.error("LLM call failed", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={
                    "error": "ai_service_error",
                    "message": "The AI teaching service is temporarily unavailable. Please try again.",
                },
            )
    assert result is not None  # loop either breaks with result or raises
    # P1 cost watch: accumulate token burn (tutor pops _llm_usage into result).
    _llm_usage = result.pop("_llm_usage", None) or {}
    op_metrics.add_llm_tokens(
        int(_llm_usage.get("prompt_tokens", 0) or 0),
        int(_llm_usage.get("completion_tokens", 0) or 0),
    )
    op_metrics.incr("chat_ok")

    # ── 5. Update pronunciation score with LLM evaluation ──
    if pronunciation_score and result.get("evaluation"):
        # Re-score with LLM evaluation included
        pronunciation_score = compute_score(
            whisper_segments=pronunciation_score.get("details") or [],
            expected_phrase=expected_phrase,
            llm_evaluation=result["evaluation"],
        )

    # ── 6. TTS: cache-first, served as https URL (P0) ──
    # Same phrases get taught repeatedly — synthesizing every time costs a
    # fresh edge-tts WebSocket per call and bursts into their rate limit.
    # Cache by sha256(voice + text); clients fetch via GET /audio/{key}.mp3
    # (Cache-Control: immutable) instead of a ~33%-inflated base64 data URI.
    audio_url = None
    jp_phrase = result.get("japanese_phrase", "")

    # Fallback: if LLM forgot japanese_phrase, reuse the last one from history
    if not jp_phrase:
        for msg in reversed(history):
            if msg["role"] == "assistant" and "[Japanese:" in msg["content"]:
                import re
                match = re.search(r"\[Japanese:\s*([^\]]+)\]", msg["content"])
                if match:
                    jp_phrase = match.group(1)
                    break
    if jp_phrase:
        try:
            cache_key = tts_cache_key(jp_phrase)
            tts_bytes = tts_cache_get(cache_key)
            if tts_bytes is None:
                op_metrics.incr("tts_cache_miss")
                tts_bytes = await synthesize_tts(jp_phrase)
                tts_cache_put(cache_key, tts_bytes)
            else:
                op_metrics.incr("tts_cache_hits")
            base = _audio_base_url(settings, request)
            if base:
                audio_url = f"{base}/api/v1/audio/{cache_key}.mp3"
            else:
                # Last-resort fallback (request context missing): inline data URI.
                audio_b64 = base64.b64encode(tts_bytes).decode()
                audio_url = f"data:audio/mp3;base64,{audio_b64}"
        except Exception:
            # Log TTS failure but don't break the response
            logger.warning("TTS failed for %r", jp_phrase[:50], exc_info=True)
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


@router.get("/audio/{filename}")
async def get_cached_audio(filename: str):
    """Serve cached TTS audio (P0: replaces inline base64 data URIs).

    Keys are 32 hex chars minted server-side by tts_cache_key() — anything
    else is a 404. Note: each uvicorn worker / Fly machine holds its own
    cache, so a miss here just re-synthesizes once. Supabase Storage is the
    follow-up for a shared cache.
    """
    name = filename[:-4] if filename.endswith(".mp3") else filename
    if len(name) != 32 or any(c not in "0123456789abcdef" for c in name):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="not found"
        )
    data = tts_cache_get(name)
    if data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="not found"
        )
    op_metrics.incr("audio_served")
    return Response(
        content=data,
        media_type="audio/mpeg",
        headers={"Cache-Control": "public, max-age=86400, immutable"},
    )


@router.post("/tts")
async def text_to_speech(
    body: TTSRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Synthesize any Japanese text to speech (used by kana audio, etc.).

    Returns a cacheable https URL (P0: was an inline base64 data URI).
    Does NOT count toward daily usage limits.
    """
    try:
        cache_key = tts_cache_key(body.text)
        tts_bytes = tts_cache_get(cache_key)
        if tts_bytes is None:
            tts_bytes = await synthesize_tts(body.text)
            tts_cache_put(cache_key, tts_bytes)
        base = _audio_base_url(get_settings(), request)
        if not base:
            audio_b64 = base64.b64encode(tts_bytes).decode()
            return {"audio_url": f"data:audio/mp3;base64,{audio_b64}"}
        return {"audio_url": f"{base}/api/v1/audio/{cache_key}.mp3"}
    except Exception:
        # P0: generic message to clients, details in server logs only.
        logger.exception("TTS failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "tts_failed", "message": "Speech synthesis failed. Please try again."},
        )
