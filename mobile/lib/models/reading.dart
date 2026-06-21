class VitalReading {
  final String patientId;
  final double? heartRateBpm;
  final double? spo2Percent;
  final double? bodyTemperatureC;
  final double? systolicBpMmhg;
  final double? diastolicBpMmhg;
  final DateTime recordedAt;
  final bool synced;
  final int? localId;

  const VitalReading({
    required this.patientId,
    required this.recordedAt,
    this.heartRateBpm,
    this.spo2Percent,
    this.bodyTemperatureC,
    this.systolicBpMmhg,
    this.diastolicBpMmhg,
    this.synced = false,
    this.localId,
  });

  /// Parses the JSON payload notified by the wearable's BLE characteristic
  /// (see firmware/src/ble_transport.cpp). `patientId` is supplied by the
  /// app rather than the device, since the wearable only knows its own
  /// device_id, not the backend's patient identifier. The device's
  /// `timestamp_ms` is its own relative uptime (not wall-clock), so the
  /// phone stamps arrival time instead.
  factory VitalReading.fromBleJson(Map<String, dynamic> json, {required String patientId}) {
    return VitalReading(
      patientId: patientId,
      heartRateBpm: (json['heart_rate_bpm'] as num?)?.toDouble(),
      spo2Percent: (json['spo2_percent'] as num?)?.toDouble(),
      bodyTemperatureC: (json['body_temperature_c'] as num?)?.toDouble(),
      recordedAt: DateTime.now().toUtc(),
    );
  }

  factory VitalReading.fromDb(Map<String, dynamic> row) {
    return VitalReading(
      localId: row['id'] as int?,
      patientId: row['patient_id'] as String,
      heartRateBpm: row['heart_rate_bpm'] as double?,
      spo2Percent: row['spo2_percent'] as double?,
      bodyTemperatureC: row['body_temperature_c'] as double?,
      systolicBpMmhg: row['systolic_bp_mmhg'] as double?,
      diastolicBpMmhg: row['diastolic_bp_mmhg'] as double?,
      recordedAt: DateTime.parse(row['recorded_at'] as String),
      synced: (row['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'patient_id': patientId,
      'heart_rate_bpm': heartRateBpm,
      'spo2_percent': spo2Percent,
      'body_temperature_c': bodyTemperatureC,
      'systolic_bp_mmhg': systolicBpMmhg,
      'diastolic_bp_mmhg': diastolicBpMmhg,
      'recorded_at': recordedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  /// Matches `VitalReadingCreate` in backend/app/schemas.py.
  Map<String, dynamic> toApiJson() {
    return {
      'patient_id': patientId,
      'heart_rate_bpm': heartRateBpm,
      'spo2_percent': spo2Percent,
      'body_temperature_c': bodyTemperatureC,
      'systolic_bp_mmhg': systolicBpMmhg,
      'diastolic_bp_mmhg': diastolicBpMmhg,
      'source': 'wearable',
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  VitalReading copyWith({bool? synced, int? localId}) {
    return VitalReading(
      localId: localId ?? this.localId,
      patientId: patientId,
      heartRateBpm: heartRateBpm,
      spo2Percent: spo2Percent,
      bodyTemperatureC: bodyTemperatureC,
      systolicBpMmhg: systolicBpMmhg,
      diastolicBpMmhg: diastolicBpMmhg,
      recordedAt: recordedAt,
      synced: synced ?? this.synced,
    );
  }
}
