from datetime import datetime, timedelta

from app.expert_system.engine import evaluate
from app.models import VitalReading


def make_reading(**kwargs) -> VitalReading:
    defaults = dict(
        id="r",
        patient_id="p",
        recorded_at=datetime.utcnow(),
        heart_rate_bpm=None,
        spo2_percent=None,
        body_temperature_c=None,
        respiratory_rate_bpm=None,
        systolic_bp_mmhg=None,
        diastolic_bp_mmhg=None,
    )
    defaults.update(kwargs)
    return VitalReading(**defaults)


def test_normal_vitals_produce_no_alerts():
    reading = make_reading(heart_rate_bpm=75, spo2_percent=98, body_temperature_c=37.0)
    assert evaluate(reading, []) == []


def test_tachycardia_triggers_warning():
    reading = make_reading(heart_rate_bpm=110)
    results = evaluate(reading, [])
    assert any(r.rule_code == "HEART_RATE_WARNING" for r in results)


def test_severe_tachycardia_triggers_critical():
    reading = make_reading(heart_rate_bpm=130)
    results = evaluate(reading, [])
    assert any(r.rule_code == "HEART_RATE_CRITICAL" for r in results)


def test_low_spo2_triggers_critical():
    reading = make_reading(spo2_percent=88)
    results = evaluate(reading, [])
    assert any(r.rule_code == "SPO2_CRITICAL" for r in results)


def test_high_bp_triggers_pre_eclampsia_risk():
    reading = make_reading(systolic_bp_mmhg=145, diastolic_bp_mmhg=95)
    results = evaluate(reading, [])
    assert any(r.rule_code == "PRE_ECLAMPSIA_RISK" for r in results)


def test_respiratory_distress_requires_both_signs():
    reading = make_reading(respiratory_rate_bpm=28, spo2_percent=90)
    results = evaluate(reading, [])
    assert any(r.rule_code == "RESPIRATORY_DISTRESS" for r in results)

    reading_partial = make_reading(respiratory_rate_bpm=28, spo2_percent=98)
    results_partial = evaluate(reading_partial, [])
    assert not any(r.rule_code == "RESPIRATORY_DISTRESS" for r in results_partial)


def test_sustained_tachycardia_with_fever_triggers_sepsis_alert():
    now = datetime.utcnow()
    history = [
        make_reading(heart_rate_bpm=105, body_temperature_c=38.5, recorded_at=now - timedelta(minutes=10)),
        make_reading(heart_rate_bpm=108, body_temperature_c=38.6, recorded_at=now - timedelta(minutes=5)),
    ]
    reading = make_reading(heart_rate_bpm=110, body_temperature_c=38.4, recorded_at=now)
    results = evaluate(reading, history)
    assert any(r.rule_code == "POSSIBLE_SEPSIS" for r in results)


def test_single_tachycardia_fever_reading_does_not_trigger_sepsis_alone():
    reading = make_reading(heart_rate_bpm=110, body_temperature_c=38.4)
    results = evaluate(reading, [])
    assert not any(r.rule_code == "POSSIBLE_SEPSIS" for r in results)
