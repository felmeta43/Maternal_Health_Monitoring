import 'dart:async';

import 'api_service.dart';
import 'local_db.dart';

/// Periodically drains the local cache of unsynced readings to the backend.
/// Designed to be a no-op (and cheap to call) when offline — failed POSTs
/// just leave the row unsynced for the next attempt.
class SyncService {
  final ApiService apiService;
  Timer? _timer;

  SyncService({required this.apiService});

  void start({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncOnce());
  }

  void stop() => _timer?.cancel();

  Future<void> syncOnce() async {
    final pending = await LocalDb.unsyncedReadings();
    for (final reading in pending) {
      try {
        final accepted = await apiService.submitReading(reading);
        if (accepted && reading.localId != null) {
          await LocalDb.markSynced(reading.localId!);
        }
      } on Exception {
        // Network/backend unavailable — leave unsynced and retry next cycle.
        break;
      }
    }
  }
}
