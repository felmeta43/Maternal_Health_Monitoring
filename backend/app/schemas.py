from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models import Severity, UserRole


class PatientCreate(BaseModel):
    full_name: str
    date_of_birth: datetime | None = None
    gestational_age_weeks: int | None = None
    phone_number: str | None = None
    device_id: str | None = None


class PatientOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    full_name: str
    gestational_age_weeks: int | None
    phone_number: str | None
    device_id: str | None
    created_at: datetime


class VitalReadingCreate(BaseModel):
    patient_id: str
    heart_rate_bpm: float | None = None
    spo2_percent: float | None = None
    body_temperature_c: float | None = None
    respiratory_rate_bpm: float | None = None
    systolic_bp_mmhg: float | None = None
    diastolic_bp_mmhg: float | None = None
    source: str = "wearable"
    recorded_at: datetime


class VitalReadingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    patient_id: str
    heart_rate_bpm: float | None
    spo2_percent: float | None
    body_temperature_c: float | None
    respiratory_rate_bpm: float | None
    systolic_bp_mmhg: float | None
    diastolic_bp_mmhg: float | None
    source: str
    recorded_at: datetime
    received_at: datetime


class AlertOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    patient_id: str
    reading_id: str | None
    rule_code: str
    severity: Severity
    message: str
    acknowledged: bool
    created_at: datetime


class IngestResult(BaseModel):
    reading: VitalReadingOut
    alerts: list[AlertOut]


class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str
    role: UserRole = UserRole.PROVIDER


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    full_name: str
    email: str
    role: UserRole


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
