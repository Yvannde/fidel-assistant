from app.core.config import settings
from app.schemas.health import HealthResponse


def test_health_response_schema() -> None:
    body = HealthResponse(status="ok", service=settings.app_name, version="0.1.0")
    assert body.status == "ok"
    assert body.service == settings.app_name
