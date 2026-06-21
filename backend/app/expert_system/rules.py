"""Rule-based clinical thresholds.

Reference ranges are documented in docs/clinical_thresholds.md. These are a starting
point for clinical validation, not a finalized medical protocol.
"""
from dataclasses import dataclass

from app.models import Severity, VitalReading


@dataclass(frozen=True)
class RuleResult:
    rule_code: str
    severity: Severity
    message: str


Rule = "Callable[[VitalReading, list[VitalReading]], RuleResult | None]"


def heart_rate_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    hr = reading.heart_rate_bpm
    if hr is None:
        return None
    if hr > 120 or hr < 50:
        return RuleResult("HEART_RATE_CRITICAL", Severity.CRITICAL, f"Heart rate {hr:.0f} bpm is critical")
    if (100 < hr <= 120) or (50 <= hr < 60):
        return RuleResult("HEART_RATE_WARNING", Severity.WARNING, f"Heart rate {hr:.0f} bpm is abnormal")
    return None


def spo2_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    spo2 = reading.spo2_percent
    if spo2 is None:
        return None
    if spo2 < 92:
        return RuleResult("SPO2_CRITICAL", Severity.CRITICAL, f"SpO2 {spo2:.0f}% indicates hypoxia")
    if spo2 < 95:
        return RuleResult("SPO2_WARNING", Severity.WARNING, f"SpO2 {spo2:.0f}% is below normal")
    return None


def temperature_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    temp = reading.body_temperature_c
    if temp is None:
        return None
    if temp > 38.0:
        return RuleResult("FEVER_CRITICAL", Severity.CRITICAL, f"Body temperature {temp:.1f}C suggests possible infection")
    if temp < 36.0:
        return RuleResult("HYPOTHERMIA_CRITICAL", Severity.CRITICAL, f"Body temperature {temp:.1f}C indicates hypothermia")
    if temp > 37.5 or temp < 36.5:
        return RuleResult("TEMPERATURE_WARNING", Severity.WARNING, f"Body temperature {temp:.1f}C is outside normal range")
    return None


def blood_pressure_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    sys_bp = reading.systolic_bp_mmhg
    dia_bp = reading.diastolic_bp_mmhg
    if sys_bp is None or dia_bp is None:
        return None
    if sys_bp >= 160 or dia_bp >= 110 or sys_bp < 90:
        return RuleResult("BLOOD_PRESSURE_CRITICAL", Severity.CRITICAL, f"BP {sys_bp:.0f}/{dia_bp:.0f} mmHg is critical")
    if sys_bp >= 140 or dia_bp >= 90:
        return RuleResult("PRE_ECLAMPSIA_RISK", Severity.CRITICAL, f"BP {sys_bp:.0f}/{dia_bp:.0f} mmHg suggests pre-eclampsia risk")
    return None


def respiratory_distress_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    rr = reading.respiratory_rate_bpm
    spo2 = reading.spo2_percent
    if rr is None or spo2 is None:
        return None
    if rr > 24 and spo2 < 92:
        return RuleResult(
            "RESPIRATORY_DISTRESS", Severity.CRITICAL,
            f"Respiratory rate {rr:.0f}/min with SpO2 {spo2:.0f}% suggests respiratory distress",
        )
    return None


def possible_sepsis_rule(reading: VitalReading, history: list[VitalReading]) -> RuleResult | None:
    if reading.heart_rate_bpm is None or reading.body_temperature_c is None:
        return None
    if reading.body_temperature_c <= 38.0 or reading.heart_rate_bpm <= 100:
        return None

    recent = [reading, *history[:2]]
    if len(recent) < 3:
        return None
    if all(r.heart_rate_bpm is not None and r.heart_rate_bpm > 100 for r in recent):
        return RuleResult(
            "POSSIBLE_SEPSIS", Severity.CRITICAL,
            "Sustained tachycardia with fever over 3 consecutive readings suggests possible sepsis",
        )
    return None


DEFAULT_RULES: list[Rule] = [
    heart_rate_rule,
    spo2_rule,
    temperature_rule,
    blood_pressure_rule,
    respiratory_distress_rule,
    possible_sepsis_rule,
]
