"""Rate limiting simple en mémoire (process). Suffisant pour V1 mono-instance."""

from __future__ import annotations

import time
from collections import defaultdict
from threading import Lock

from app.core.exceptions import AppException

_lock = Lock()
_buckets: dict[str, list[float]] = defaultdict(list)


def check_rate_limit(
    key: str,
    *,
    max_attempts: int,
    window_seconds: int,
    error_code: str = "RATE_LIMITED",
    message: str = "Trop d'essais. Réessaie dans quelques minutes.",
) -> None:
    now = time.monotonic()
    cutoff = now - window_seconds
    with _lock:
        hits = [t for t in _buckets[key] if t >= cutoff]
        if len(hits) >= max_attempts:
            _buckets[key] = hits
            raise AppException(error_code, message, status_code=429)
        hits.append(now)
        _buckets[key] = hits


def clear_rate_limit(key: str) -> None:
    with _lock:
        _buckets.pop(key, None)
