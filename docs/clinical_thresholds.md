# Rule-Based Expert System: Clinical Thresholds (v1)

These thresholds drive the v1 rule-based diagnostic/alert engine
(`backend/app/expert_system/rules.py`). They are based on commonly cited WHO/obstetric
danger-sign reference ranges for pregnant women and are intended as a **starting point
for clinical validation by qualified obstetric staff** before any field deployment —
they are not a substitute for clinical judgement.

| Vital | Normal range | Warning | Critical |
|---|---|---|---|
| Heart rate (bpm) | 60–100 | 100–120 or 50–60 | >120 or <50 |
| SpO2 (%) | ≥ 95 | 92–94 | < 92 |
| Body temperature (°C) | 36.5–37.5 | 37.5–38.0 or 36.0–36.5 | > 38.0 (possible infection/sepsis) or < 36.0 (hypothermia) |
| Systolic BP (mmHg, manual entry) | 90–139 | 140–159 | ≥ 160 or < 90 (pre-eclampsia / hypotension risk) |
| Diastolic BP (mmHg, manual entry) | 60–89 | 90–109 | ≥ 110 or < 60 |
| Respiratory rate (breaths/min, optional) | 12–20 | 20–24 | > 24 or < 12 |

## Composite danger signs

Beyond single-vital thresholds, the engine flags **combination patterns** associated with
pre-eclampsia / eclampsia risk, the leading preventable cause of maternal mortality in
this context:

- Systolic ≥ 140 **and** diastolic ≥ 90 → `PRE_ECLAMPSIA_RISK` (critical if also reported
  with severe headache/visual disturbance fields, once symptom self-report is added).
- Sustained tachycardia (HR > 100 for 3+ consecutive readings) **and** fever (> 38.0°C) →
  `POSSIBLE_SEPSIS`.
- SpO2 < 92% **and** respiratory rate > 24 → `RESPIRATORY_DISTRESS`.

## Severity levels

- `NORMAL` — no action.
- `WARNING` — logged, visible on dashboard, no push notification by default.
- `CRITICAL` — `Alert` row created, provider notification dispatched (SMS/push).

## Extensibility

`expert_system/engine.py` evaluates an ordered list of `Rule` objects against a
`VitalReading` plus recent history for the same patient. New rules (e.g. once fetal heart
rate or contraction sensing is added) can be added without touching the ingestion API.
