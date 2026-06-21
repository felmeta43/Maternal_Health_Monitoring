import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class UserRole(str, enum.Enum):
    PROVIDER = "provider"
    COMMUNITY_HEALTH_WORKER = "chw"
    ADMIN = "admin"


class Severity(str, enum.Enum):
    NORMAL = "normal"
    WARNING = "warning"
    CRITICAL = "critical"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    full_name: Mapped[str] = mapped_column(String, nullable=False)
    email: Mapped[str] = mapped_column(String, unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String, nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.PROVIDER)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class Patient(Base):
    __tablename__ = "patients"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    full_name: Mapped[str] = mapped_column(String, nullable=False)
    date_of_birth: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    gestational_age_weeks: Mapped[int | None] = mapped_column(nullable=True)
    phone_number: Mapped[str | None] = mapped_column(String, nullable=True)
    assigned_provider_id: Mapped[str | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    device_id: Mapped[str | None] = mapped_column(String, nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    readings: Mapped[list["VitalReading"]] = relationship(
        back_populates="patient", cascade="all, delete-orphan"
    )
    alerts: Mapped[list["Alert"]] = relationship(
        back_populates="patient", cascade="all, delete-orphan"
    )


class VitalReading(Base):
    __tablename__ = "vital_readings"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(ForeignKey("patients.id"), nullable=False)

    heart_rate_bpm: Mapped[float | None] = mapped_column(Float, nullable=True)
    spo2_percent: Mapped[float | None] = mapped_column(Float, nullable=True)
    body_temperature_c: Mapped[float | None] = mapped_column(Float, nullable=True)
    respiratory_rate_bpm: Mapped[float | None] = mapped_column(Float, nullable=True)
    systolic_bp_mmhg: Mapped[float | None] = mapped_column(Float, nullable=True)
    diastolic_bp_mmhg: Mapped[float | None] = mapped_column(Float, nullable=True)

    source: Mapped[str] = mapped_column(String, default="wearable")
    recorded_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    received_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    patient: Mapped["Patient"] = relationship(back_populates="readings")


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(ForeignKey("patients.id"), nullable=False)
    reading_id: Mapped[str | None] = mapped_column(
        ForeignKey("vital_readings.id"), nullable=True
    )

    rule_code: Mapped[str] = mapped_column(String, nullable=False)
    severity: Mapped[Severity] = mapped_column(Enum(Severity), nullable=False)
    message: Mapped[str] = mapped_column(String, nullable=False)

    acknowledged: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    patient: Mapped["Patient"] = relationship(back_populates="alerts")
