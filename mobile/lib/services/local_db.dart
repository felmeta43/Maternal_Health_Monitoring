import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/reading.dart';

/// Offline-first local cache. Readings are written here immediately on
/// arrival from BLE and synced to the backend opportunistically by
/// [SyncService] — see docs/architecture.md for why connectivity can't be
/// assumed in the Gedeo Zone deployment context.
class LocalDb {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'mhm_cache.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id TEXT NOT NULL,
            heart_rate_bpm REAL,
            spo2_percent REAL,
            body_temperature_c REAL,
            systolic_bp_mmhg REAL,
            diastolic_bp_mmhg REAL,
            recorded_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<int> insertReading(VitalReading reading) async {
    final db = await _open();
    return db.insert('readings', reading.toDbMap());
  }

  static Future<List<VitalReading>> unsyncedReadings() async {
    final db = await _open();
    final rows = await db.query('readings', where: 'synced = 0', orderBy: 'recorded_at ASC');
    return rows.map(VitalReading.fromDb).toList();
  }

  static Future<void> markSynced(int localId) async {
    final db = await _open();
    await db.update('readings', {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
  }

  static Future<List<VitalReading>> recentReadings(String patientId, {int limit = 20}) async {
    final db = await _open();
    final rows = await db.query(
      'readings',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return rows.map(VitalReading.fromDb).toList();
  }
}
