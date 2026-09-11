"""Schemas Sync V2 — push / pull (Phase 4)."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field


class SyncMutationIn(BaseModel):
    mutation_id: UUID
    entity: str
    entity_id: UUID | None = None
    op: str
    payload: dict[str, Any] = Field(default_factory=dict)
    client_ts: datetime | None = None


class SyncPushIn(BaseModel):
    mutations: list[SyncMutationIn]


class SyncPushResultOut(BaseModel):
    mutation_id: UUID
    status: Literal["applied", "duplicate", "rejected"]
    reason: str | None = None


class SyncPushOut(BaseModel):
    results: list[SyncPushResultOut]


class SyncPullOut(BaseModel):
    entities: list[dict[str, Any]]
    next_cursor: str | None = None
    server_time: datetime
