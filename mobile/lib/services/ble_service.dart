import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/reading.dart';
import 'local_db.dart';

/// UUIDs must match firmware/include/config.h.
const _serviceUuid = '5f1a1b2c-0001-4e6b-9b1a-2f6a0c9d1a01';
const _readingCharacteristicUuid = '5f1a1b2c-0002-4e6b-9b1a-2f6a0c9d1a01';

/// Scans for the wearable, connects, and turns BLE notifications into
/// [VitalReading]s cached locally for the given patient.
class BleService {
  final String patientId;
  StreamSubscription<List<int>>? _notifySubscription;
  BluetoothDevice? _device;

  BleService({required this.patientId});

  final _readingsController = StreamController<VitalReading>.broadcast();
  Stream<VitalReading> get readings => _readingsController.stream;

  Future<void> connectToWearable() async {
    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: const Duration(seconds: 10),
    );

    final result = await FlutterBluePlus.scanResults
        .expand((results) => results)
        .firstWhere((r) => r.advertisementData.serviceUuids.contains(Guid(_serviceUuid)));
    await FlutterBluePlus.stopScan();

    _device = result.device;
    await _device!.connect();
    await _subscribeToReadings(_device!);
  }

  Future<void> _subscribeToReadings(BluetoothDevice device) async {
    final services = await device.discoverServices();
    final service = services.firstWhere((s) => s.uuid == Guid(_serviceUuid));
    final characteristic =
        service.characteristics.firstWhere((c) => c.uuid == Guid(_readingCharacteristicUuid));

    await characteristic.setNotifyValue(true);
    _notifySubscription = characteristic.lastValueStream.listen(_onNotification);
  }

  void _onNotification(List<int> value) {
    if (value.isEmpty) return;
    final json = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
    final reading = VitalReading.fromBleJson(json, patientId: patientId);

    LocalDb.insertReading(reading);
    _readingsController.add(reading);
  }

  Future<void> dispose() async {
    await _notifySubscription?.cancel();
    await _device?.disconnect();
    await _readingsController.close();
  }
}
