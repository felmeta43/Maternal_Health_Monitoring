import 'package:flutter/material.dart';

import 'screens/patient_list_screen.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';

const _backendBaseUrl = 'http://localhost:8000';

void main() {
  final apiService = ApiService(baseUrl: _backendBaseUrl);
  SyncService(apiService: apiService).start();
  runApp(const MaternalHealthApp());
}

class MaternalHealthApp extends StatelessWidget {
  const MaternalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maternal Health Monitoring',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const PatientListScreen(),
    );
  }
}
