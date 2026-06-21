import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

/// Pairing entry point: a community health worker (or the patient) enters
/// the patient ID issued when the provider registered the patient via the
/// backend (POST /api/v1/patients), then connects to that patient's
/// wearable. A full searchable patient roster synced from the backend is a
/// natural next step once GET /api/v1/patients is wired up here.
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _patientIdController = TextEditingController();
  final _patientNameController = TextEditingController();

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  void _openDashboard() {
    if (_patientIdController.text.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DashboardScreen(
        patientId: _patientIdController.text,
        patientName: _patientNameController.text.isEmpty
            ? _patientIdController.text
            : _patientNameController.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair Patient Wearable')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _patientIdController,
              decoration: const InputDecoration(labelText: 'Patient ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _patientNameController,
              decoration: const InputDecoration(labelText: 'Patient name (optional)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _openDashboard, child: const Text('Connect to wearable')),
          ],
        ),
      ),
    );
  }
}
