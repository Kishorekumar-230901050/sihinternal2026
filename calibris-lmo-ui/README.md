# LMO Portal — Flutter App

**Legal Metrology Officer Portal**  
SIH 2026 | Ministry of Consumer Affairs, Food & Public Distribution

---

## Prerequisites

Install before running:

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows  
   After install, run: `flutter doctor`

2. **Android Studio** (for Android emulator) — https://developer.android.com/studio  
   OR connect a physical Android device.

3. **VS Code** with the Flutter extension (recommended).

---

## Setup & Run

```bash
# 1. Navigate to app directory
cd lmo_app

# 2. Install dependencies
flutter pub get

# 3. Run on connected device / emulator
flutter run

# 4. Run on web (Chrome)
flutter run -d chrome

# 5. Build APK for Android
flutter build apk --release
```

---

## Demo Login

| Field | Value |
|---|---|
| Employee ID | `officer001` |
| Password | `Lmo@1234` |

---

## Complete Demo Workflow

```
Login (officer001 / Lmo@1234)
  └─ Dashboard
       ├─ Notification bell → Notifications screen (8 notifications, 4 unread)
       ├─ Profile avatar → Profile screen
       └─ Recent Applications
            │
            ├─ APP-1001 [SUBMITTED] — ABC Traders — Electronic Weighing Scale
            │    └─ Review Documents → Approve for Verification
            │         └─ Verification Mode screen
            │              ├─ Digital Verification (INST-001 is compatible)
            │              │    ├─ Device Status (Warning — tamper detected)
            │              │    ├─ View Tamper Logs (3 events)
            │              │    └─ Proceed to Inspection Form → Submit → Summary → Certificate
            │              └─ Field Verification
            │                   ├─ Schedule date/time
            │                   ├─ Capture GPS location (100m geofence)
            │                   └─ Proceed to Inspection Form → Submit → Summary
            │
            ├─ APP-1004 [VERIFICATION_SCHEDULED] — Modern Measurements (digital)
            │    └─ Start Digital Verification → INST-004 (NORMAL health, no tamper)
            │
            ├─ APP-1008 [REJECTED] — Bharat Scales (shows rejection reason)
            │
            └─ APP-1010 [CERTIFICATE_ISSUED] — View Certificate → QR Code
                  └─ Scan QR → /verify/CERT-2026-00001 → Certificate details
```

---

## Architecture

```
lib/
├── main.dart                        Entry point
├── app.dart                         MultiProvider + GoRouter
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       GPS radius (100m), cert validity, URLs
│   │   ├── app_colors.dart          Government color palette
│   │   └── app_routes.dart          All named route strings
│   ├── theme/app_theme.dart         Material 3 government theme
│   └── utils/                       Formatters, validators, status helpers
├── data/
│   ├── mock/mock_data.dart          ← ONLY source of mock data
│   ├── models/                      12 model classes (fromJson/toJson)
│   └── repositories/
│       ├── i_*.dart                 Abstract interfaces
│       └── mock_*.dart              Mock implementations (read from MockDataStore)
├── services/
│   ├── i_device_service.dart        Calibris hardware interface
│   ├── i_certificate_service.dart   Certificate module interface
│   ├── mock_device_service.dart     Mock Calibris responses
│   ├── mock_certificate_service.dart
│   ├── location_service.dart        GPS + geofencing (100m radius)
│   ├── audit_service.dart           In-memory audit log
│   └── api_client.dart              Future Dio REST client stub
├── providers/                       5 ChangeNotifier providers
│   ├── auth_provider.dart
│   ├── application_provider.dart
│   ├── inspection_provider.dart
│   ├── notification_provider.dart
│   └── device_provider.dart
├── screens/                         16 screens
│   ├── auth/lmo_login_screen.dart
│   ├── dashboard/lmo_dashboard_screen.dart
│   ├── notifications/notifications_screen.dart
│   ├── applications/
│   │   ├── application_list_screen.dart
│   │   ├── application_details_screen.dart
│   │   └── document_review_screen.dart
│   ├── verification/
│   │   ├── verification_mode_screen.dart
│   │   ├── digital_verification_screen.dart
│   │   ├── tamper_logs_screen.dart
│   │   ├── field_verification_screen.dart
│   │   ├── inspection_form_screen.dart
│   │   ├── verification_summary_screen.dart
│   │   └── verification_history_screen.dart
│   ├── certificate/
│   │   ├── certificate_request_screen.dart
│   │   └── qr_verification_screen.dart
│   └── profile/profile_screen.dart
└── widgets/                         10 reusable widgets
```

---

## Swapping Mock Data for Real API

1. Implement `IAuthRepository`, `IApplicationRepository`, etc. using `ApiClient` (Dio).
2. In `app.dart`, replace `MockXxxRepository()` with `ApiXxxRepository(apiClient)`.
3. The UI screens require **zero changes** — they only talk to Providers.

To swap Calibris hardware:
- Implement `IDeviceService` using real HTTP calls.
- Replace `MockDeviceService()` in `app.dart`.

To integrate teammate certificate module:
- Implement `ICertificateService` with your module logic.
- Replace `MockCertificateService()` in `app.dart`.

---

## Key Configuration

| Setting | File | Value |
|---|---|---|
| GPS geofence radius | `core/constants/app_constants.dart` | `100.0` metres |
| Certificate validity | same | `12` months |
| Re-verification lead | same | `1` month |
| Backend API URL | same | `http://localhost:3000/api` |
| Mock login | `data/mock/mock_data.dart` | `officer001 / Lmo@1234` |
