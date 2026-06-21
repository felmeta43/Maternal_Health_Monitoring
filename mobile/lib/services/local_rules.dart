import '../models/reading.dart';

enum LocalSeverity { normal, warning, critical }

class LocalAlert {
  final String ruleCode;
  final LocalSeverity severity;
  final String message;

  const LocalAlert(this.ruleCode, this.severity, this.message);
}

/// On-device mirror of the single-vital thresholds in
/// backend/app/expert_system/rules.py (see docs/clinical_thresholds.md).
/// This gives an immediate warning even before a reading has synced to the
/// backend; the backend remains the source of truth and also evaluates
/// multi-reading/composite rules (e.g. sustained tachycardia + fever) that
/// require history this on-device check does not have.
List<LocalAlert> checkLocalThresholds(VitalReading reading) {
  final alerts = <LocalAlert>[];

  final hr = reading.heartRateBpm;
  if (hr != null) {
    if (hr > 120 || hr < 50) {
      alerts.add(LocalAlert('HEART_RATE_CRITICAL', LocalSeverity.critical,
          'Heart rate ${hr.toStringAsFixed(0)} bpm is critical'));
    } else if ((hr > 100 && hr <= 120) || (hr >= 50 && hr < 60)) {
      alerts.add(LocalAlert('HEART_RATE_WARNING', LocalSeverity.warning,
          'Heart rate ${hr.toStringAsFixed(0)} bpm is abnormal'));
    }
  }

  final spo2 = reading.spo2Percent;
  if (spo2 != null) {
    if (spo2 < 92) {
      alerts.add(LocalAlert(
          'SPO2_CRITICAL', LocalSeverity.critical, 'SpO2 ${spo2.toStringAsFixed(0)}% indicates hypoxia'));
    } else if (spo2 < 95) {
      alerts.add(LocalAlert(
          'SPO2_WARNING', LocalSeverity.warning, 'SpO2 ${spo2.toStringAsFixed(0)}% is below normal'));
    }
  }

  final temp = reading.bodyTemperatureC;
  if (temp != null) {
    if (temp > 38.0) {
      alerts.add(LocalAlert('FEVER_CRITICAL', LocalSeverity.critical,
          'Body temperature ${temp.toStringAsFixed(1)}C suggests possible infection'));
    } else if (temp < 36.0) {
      alerts.add(LocalAlert('HYPOTHERMIA_CRITICAL', LocalSeverity.critical,
          'Body temperature ${temp.toStringAsFixed(1)}C indicates hypothermia'));
    } else if (temp > 37.5 || temp < 36.5) {
      alerts.add(LocalAlert('TEMPERATURE_WARNING', LocalSeverity.warning,
          'Body temperature ${temp.toStringAsFixed(1)}C is outside normal range'));
    }
  }

  final sys = reading.systolicBpMmhg;
  final dia = reading.diastolicBpMmhg;
  if (sys != null && dia != null) {
    if (sys >= 160 || dia >= 110 || sys < 90) {
      alerts.add(LocalAlert('BLOOD_PRESSURE_CRITICAL', LocalSeverity.critical,
          'BP ${sys.toStringAsFixed(0)}/${dia.toStringAsFixed(0)} mmHg is critical'));
    } else if (sys >= 140 || dia >= 90) {
      alerts.add(LocalAlert('PRE_ECLAMPSIA_RISK', LocalSeverity.critical,
          'BP ${sys.toStringAsFixed(0)}/${dia.toStringAsFixed(0)} mmHg suggests pre-eclampsia risk'));
    }
  }

  return alerts;
}
