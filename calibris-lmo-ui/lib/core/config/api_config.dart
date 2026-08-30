class ApiConfig {
  // Configurable base URL: can be overridden at build time using:
  // flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
  // (useful for pointing at a local backend during development)
  static const String defaultBaseUrl = 'https://sihinternal2026-production.up.railway.app/api';
  static const String defaultWsUrl = 'https://sihinternal2026-production.up.railway.app';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }

  static String get wsUrl {
    const fromEnv = String.fromEnvironment('WS_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return defaultWsUrl;
  }

  // ── Auth Endpoints ──────────────────────────────────────────────
  static String get authVendorRegister => '$baseUrl/auth/vendor/register';
  static String get authVendorLogin => '$baseUrl/auth/vendor/login';
  static String get authLmoLogin => '$baseUrl/auth/lmo/login';
  static String get authAdminLogin => '$baseUrl/auth/admin/login';

  // ── Vendor Endpoints ────────────────────────────────────────────
  static String get vendorInstrumentTypes => '$baseUrl/vendor/instrument-types';
  static String get vendorInstruments => '$baseUrl/vendor/instruments';
  static String get vendorApplications => '$baseUrl/vendor/applications';
  static String vendorApplication(String id) => '$baseUrl/vendor/applications/$id';
  static String vendorCancelApplication(String id) => '$baseUrl/vendor/applications/$id/cancel';
  static String vendorApplicationDocuments(String applicationId) =>
      '$baseUrl/vendor/applications/$applicationId/documents';

  static String get vendorGatcs => '$baseUrl/vendor/gatcs';
  static String vendorGatc(String id) => '$baseUrl/vendor/gatcs/$id';
  static String get vendorGatcAvailability => '$baseUrl/vendor/gatcs/availability/slots';
  static String get vendorAppointments => '$baseUrl/vendor/appointments';

  static String get vendorPaymentOrders => '$baseUrl/vendor/payments/orders';
  static String get vendorPaymentSimulateCheckout => '$baseUrl/vendor/payments/simulate-checkout';
  static String get vendorPaymentVerify => '$baseUrl/vendor/payments/verify';
  static String vendorPaymentReceipt(String orderRef) => '$baseUrl/vendor/payments/$orderRef/receipt';

  static String vendorCertificate(String applicationId) =>
      '$baseUrl/vendor/applications/$applicationId/certificate';

  // ── LMO Endpoints ───────────────────────────────────────────────
  static String get lmoQueue => '$baseUrl/lmo/queue';
  static String lmoApplication(String id) => '$baseUrl/lmo/applications/$id';
  static String lmoStartInspection(String applicationId) =>
      '$baseUrl/lmo/applications/$applicationId/inspection/start';
  static String lmoDiscrepancies(String applicationId) =>
      '$baseUrl/lmo/applications/$applicationId/inspection/discrepancies';
  static String lmoInspectionPhotos(String applicationId) =>
      '$baseUrl/lmo/applications/$applicationId/inspection/photos';
  static String lmoInspectionResult(String applicationId) =>
      '$baseUrl/lmo/applications/$applicationId/inspection/result';

  // ── Public Endpoints ────────────────────────────────────────────
  static String publicVerifyQr(String qrToken) => '$baseUrl/verify/$qrToken';

  // ── Luckfox IoT Endpoints ───────────────────────────────────────
  static String get devices => '$baseUrl/devices';
  static String device(String id) => '$baseUrl/devices/$id';
  static String deviceStatus(String id) => '$baseUrl/devices/$id/status';
  static String deviceTamper(String id) => '$baseUrl/devices/$id/tamper';
  static String deviceTamperBatch(String id) => '$baseUrl/devices/$id/tamper/batch';
  static String deviceUnlock(String id) => '$baseUrl/devices/$id/unlock';
  static String deviceUnlockStatus(String id) => '$baseUrl/devices/$id/unlock-status';
  static String deviceUnlockConfirm(String id) => '$baseUrl/devices/$id/unlock-confirm';
  static String deviceUnlockHistory(String id) => '$baseUrl/devices/$id/unlock-history';
  static String deviceAuditLogs(String id) => '$baseUrl/devices/$id/audit-logs';
  static String get deviceRecentActivities => '$baseUrl/devices/recent-activities';
  static String get deviceStatsSummary => '$baseUrl/devices/stats/summary';
  static String deviceHeartbeat(String id) => '$baseUrl/devices/$id/heartbeat';
  static String get deviceRegister => '$baseUrl/devices/register';
}
