"""In-memory operational counters (P1 observability until Supabase lands).

Everything here is best-effort process-local state: each uvicorn worker and
each Fly machine holds its own copy. /metrics sums nothing across machines —
treat values as per-instance samples, enough to spot abuse spikes and track
LLM token burn until real persistence arrives.
"""

from __future__ import annotations

import logging
import time

logger = logging.getLogger("uvicorn.error")

_START_TIME = time.time()
_DAY = time.strftime("%Y-%m-%d")

_total: dict[str, int] = {}
_daily: dict[str, int] = {}
_llm_tokens_total = {"prompt": 0, "completion": 0}
_llm_tokens_daily = {"prompt": 0, "completion": 0}


def _rollover() -> None:
    """Reset daily buckets at midnight; log yesterday for the cost watch."""
    global _DAY, _daily, _llm_tokens_daily
    today = time.strftime("%Y-%m-%d")
    if today == _DAY:
        return
    logger.info(
        "daily usage %s: %s tokens=%s",
        _DAY,
        dict(_daily),
        dict(_llm_tokens_daily),
    )
    _DAY = today
    _daily = {}
    _llm_tokens_daily = {"prompt": 0, "completion": 0}


def incr(name: str, n: int = 1) -> None:
    """Increment a counter (both all-time and daily buckets)."""
    _rollover()
    _total[name] = _total.get(name, 0) + n
    _daily[name] = _daily.get(name, 0) + n


def add_llm_tokens(prompt: int, completion: int) -> None:
    """Accumulate LLM token burn for the cost watch."""
    _rollover()
    for store in (_llm_tokens_total, _llm_tokens_daily):
        store["prompt"] += prompt
        store["completion"] += completion


def snapshot() -> dict:
    """Per-instance counters for GET /metrics (no PII in here)."""
    _rollover()
    return {
        "uptime_s": int(time.time() - _START_TIME),
        "day": _DAY,
        "total": dict(_total),
        "today": dict(_daily),
        "llm_tokens_total": dict(_llm_tokens_total),
        "llm_tokens_today": dict(_llm_tokens_daily),
    }
