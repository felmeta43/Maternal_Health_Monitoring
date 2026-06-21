import 'package:flutter/material.dart';

import '../models/reading.dart';
import '../services/ble_service.dart';
import '../services/local_rules.dart';

class DashboardScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DashboardScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final BleService _bleService;
  VitalReading? _latestReading;
  List<LocalAlert> _activeAlerts = const [];

  @override
  void initState() {
    super.initState();
    _bleService = BleService(patientId: widget.patientId);
    _bleService.readings.listen(_onReading);
    _bleService.connectToWearable();
  }

  void _onReading(VitalReading reading) {
    setState(() {
      _latestReading = reading;
      _activeAlerts = checkLocalThresholds(reading);
    });
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reading = _latestReading;
    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VitalCard(label: 'Heart rate', value: reading?.heartRateBpm, unit: 'bpm'),
          _VitalCard(label: 'SpO2', value: reading?.spo2Percent, unit: '%'),
          _VitalCard(label: 'Body temperature', value: reading?.bodyTemperatureC, unit: 'C'),
          const SizedBox(height: 16),
          if (_activeAlerts.isNotEmpty) ...[
            const Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._activeAlerts.map((a) => Card(
                  color: a.severity == LocalSeverity.critical ? Colors.red[100] : Colors.orange[100],
                  child: ListTile(title: Text(a.message)),
                )),
          ],
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _VitalCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value != null ? '${value!.toStringAsFixed(1)} $unit' : '--'),
      ),
    );
  }
}
