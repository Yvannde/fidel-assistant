"""Fixtures pour la batterie de tests auth (SQLite en mémoire + OTP mock)."""

from __future__ import annotations

from collections.abc import AsyncIterator
from typing import Any

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import Uuid, event
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models import (  # noqa: F401 — register metadata
    CheckIn,
    Constante,
    ContactUrgence,
    Maladie,
    MaladieConfig,
    Medicament,
    MedicamentHoraire,
    NotificationLog,
    Patient,
    PatientAidant,
    PatientTraitement,
    PatientTraitementAttribut,
    PreferenceConsentement,
    Prise,
    ProtocoleMedicamentSuggere,
    ProtocoleTraitement,
    SosAlerte,
    SyncCode,
    User,
    VoixRappel,
)
from app.models.user import CguAcceptance, ConsentementSante, OtpCode, Session  # noqa: F401


@compiles(JSONB, "sqlite")
def _compile_jsonb_sqlite(_type: Any, _compiler: Any, **_kw: Any) -> str:
    return "JSON"


@compiles(PGUUID, "sqlite")
def _compile_pguuid_sqlite(type_: Any, compiler: Any, **kw: Any) -> str:
    return compiler.visit_uuid(Uuid(as_uuid=getattr(type_, "as_uuid", True)), **kw)


@pytest.fixture
def otp_inbox() -> dict[str, str]:
    """Dernier OTP envoyé par email (clé = destinataire)."""
    return {}


@pytest.fixture(autouse=True)
def _mock_otp_email(monkeypatch: pytest.MonkeyPatch, otp_inbox: dict[str, str]) -> None:
    async def _fake_send(*, to_email: str, code: str, purpose: str) -> None:
        otp_inbox[to_email.lower()] = code

    monkeypatch.setattr("app.services.otp_service.send_otp_email", _fake_send)


@pytest.fixture(autouse=True)
def _rate_limit_isolation(monkeypatch: pytest.MonkeyPatch) -> None:
    """Isole les buckets mémoire et désactive les limiteurs HTTP /auth en test."""
    from app.core.config import settings
    from app.core.rate_limit import clear_all_rate_limits

    monkeypatch.setattr(settings, "app_env", "test")
    clear_all_rate_limits()
    yield
    clear_all_rate_limits()


@pytest_asyncio.fixture
async def db_session() -> AsyncIterator[AsyncSession]:
    engine = create_async_engine(
        "sqlite+aiosqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    # SQLite ne comprend pas les server_default Postgres jsonb / bool
    cols_to_clear = [
        User.__table__.c.auth_providers,
        PatientAidant.__table__.c.niveau_permission,
        MaladieConfig.__table__.c.questions_onboarding,
        MaladieConfig.__table__.c.constantes_prioritaires,
        ProtocoleMedicamentSuggere.__table__.c.horaires_suggestion,
        MedicamentHoraire.__table__.c.jours,
    ]
    previous_defaults = {c: c.server_default for c in cols_to_clear}
    for col in cols_to_clear:
        col.server_default = None

    @event.listens_for(engine.sync_engine, "connect")
    def _fk_on(dbapi_conn: Any, _connection_record: Any) -> None:
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        session_factory = async_sessionmaker(
            engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )
        async with session_factory() as session:
            yield session
    finally:
        for col, default in previous_defaults.items():
            col.server_default = default
        await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncIterator[AsyncClient]:
    async def _override_get_db() -> AsyncIterator[AsyncSession]:
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
def auth_prefix() -> str:
    from app.core.config import settings

    return f"{settings.api_v1_prefix}/auth"


@pytest.fixture
def onboarding_prefix() -> str:
    from app.core.config import settings

    return f"{settings.api_v1_prefix}/onboarding"


@pytest.fixture
def cgu_version() -> str:
    from app.core.config import settings

    return settings.cgu_current_version
