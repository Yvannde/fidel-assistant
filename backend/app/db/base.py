from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base ORM — les modèles (User, Patient, …) hériteront de cette classe."""

    pass
