from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.expert_system.engine import evaluate
from app.models import Alert, Patient, User, VitalReading
from app.schemas import IngestResult, VitalReadingCreate, VitalReadingOut
from app.services.alerts_service import dispatch_alert

router = APIRouter(prefix="/api/v1/readings", tags=["readings"])

HISTORY_WINDOW = 10


@router.post("", response_model=IngestResult, status_code=status.HTTP_201_CREATED)
def ingest_reading(
    payload: VitalReadingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> IngestResult:
    patient = db.get(Patient, payload.patient_id)
    if patient is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    reading = VitalReading(**payload.model_dump())
    db.add(reading)
    db.flush()

    history = list(
        db.scalars(
            select(VitalReading)
            .where(VitalReading.patient_id == patient.id, VitalReading.id != reading.id)
            .order_by(VitalReading.recorded_at.desc())
            .limit(HISTORY_WINDOW)
        )
    )

    rule_results = evaluate(reading, history)
    alerts: list[Alert] = []
    for result in rule_results:
        alert = Alert(
            patient_id=patient.id,
            reading_id=reading.id,
            rule_code=result.rule_code,
            severity=result.severity,
            message=result.message,
        )
        db.add(alert)
        alerts.append(alert)

    db.commit()
    for alert in alerts:
        db.refresh(alert)
        dispatch_alert(alert, patient)
    db.refresh(reading)

    return IngestResult(reading=reading, alerts=alerts)


@router.get("/{patient_id}", response_model=list[VitalReadingOut])
def list_readings(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[VitalReading]:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    return list(
        db.scalars(
            select(VitalReading)
            .where(VitalReading.patient_id == patient_id)
            .order_by(VitalReading.recorded_at.desc())
        )
    )
