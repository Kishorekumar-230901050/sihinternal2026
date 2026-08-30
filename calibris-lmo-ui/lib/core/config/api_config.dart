class ApiConfig {
  // Configurable base URL: can be overridden at build time using:
  // flutter run --dart-define=API_BASE_URL=https://your-backend.com/api
  static const String defaultBaseUrl = 'http://localhost:3000/api';
  static const String defaultWsUrl = 'http://localhost:3000';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }

  static String get wsUrl {
    const fromEnv = String.fromEnvironment('WS_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Derive WS URL from baseUrl if not specified
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return defaultWsUrl;
  }

  // Endpoints
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
