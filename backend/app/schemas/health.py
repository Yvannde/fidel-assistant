from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(examples=["ok"])
    service: str = Field(examples=["Fidel Assistant"])
    version: str = Field(examples=["0.1.0"])
