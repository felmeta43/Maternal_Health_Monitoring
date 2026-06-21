# Mobile App — Flutter

Companion app that pairs with the ESP32 wearable over BLE, caches readings offline, and
syncs them to the backend when connectivity allows. See `docs/architecture.md` for why
this offline-first, phone-as-relay design fits the target deployment environment.

## Setup

Requires the Flutter SDK (not included in this scaffold's dev container).

```bash
flutter pub get
flutter run
```

Set the backend URL in `lib/main.dart` (`_backendBaseUrl`) — defaults to
`http://localhost:8000` for local development against `backend/`.

## Structure

- `lib/models/reading.dart` — `VitalReading`, with JSON (BLE + backend API) and SQLite
  mapping.
- `lib/services/ble_service.dart` — scans for and connects to the wearable
  (UUIDs must match `firmware/include/config.h`), turns notifications into readings.
- `lib/services/local_db.dart` — sqflite-backed offline cache.
- `lib/services/local_rules.dart` — on-device mirror of the single-vital thresholds in
  `docs/clinical_thresholds.md`, for an immediate warning before a sync succeeds.
- `lib/services/sync_service.dart` — periodically pushes unsynced cached readings to the
  backend via `api_service.dart`.
- `lib/screens/patient_list_screen.dart` — pairing entry point.
- `lib/screens/dashboard_screen.dart` — live vitals + active local alerts for the paired
  patient.

## Known gaps to fill in before field use

- `ApiService` requires a logged-in provider/CHW token before `submitReading` will be
  accepted by the backend; `main.dart` does not yet prompt for login.
- `PatientListScreen` takes a manually-entered patient ID rather than pulling the
  provider's roster from `GET /api/v1/patients`.
