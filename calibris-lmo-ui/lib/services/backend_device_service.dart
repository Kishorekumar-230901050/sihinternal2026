import 'api_service.dart';
import 'i_device_service.dart';
import 'mock_device_service.dart';
import '../core/config/api_config.dart';
import '../data/models/device_model.dart';
import '../data/models/tamper_event_model.dart';
import '../data/models/unlock_command_model.dart';
import '../data/models/device_audit_model.dart';

class BackendDeviceService implements IDeviceService {
  final ApiService _api = ApiService();
  final MockDeviceService _fallbackMock = MockDeviceService();

  bool _isBackendReachable = false;
  bool _isUsingMockFallback = false;
  String? _lastBackendError;

  bool get isBackendReachable => _isBackendReachable;
  bool get isUsingMockFallback => _isUsingMockFallback;
  String? get lastBackendError => _lastBackendError;

  Future<bool> pingBackend() async {
    final res = await _api.get<Map<String, dynamic>>('${ApiConfig.baseUrl.replaceAll("/devices", "")}/../health');
    if (res.success) {
      _isBackendReachable = true;
      _lastBackendError = null;
      return true;
    }
    final devRes = await _api.get<dynamic>(ApiConfig.devices);
    if (devRes.success) {
      _isBackendReachable = true;
      _lastBackendError = null;
      return true;
    }
    _isBackendReachable = false;
    _lastBackendError = devRes.errorMessage ?? res.errorMessage ?? 'Backend server not responding';
    return false;
  }

  @override
  Future<List<DeviceModel>> getAllDevices() async {
    final response = await _api.get<List<DeviceModel>>(
      ApiConfig.devices,
      transform: (json) {
        if (json is List) {
          return json.map((item) => DeviceModel.fromBackendJson(Map<String, dynamic>.from(item))).toList();
        }
        return <DeviceModel>[];
      },
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _isBackendReachable = true;
      _isUsingMockFallback = false;
      _lastBackendError = null;
      return response.data!;
    }

    _isBackendReachable = false;
    _isUsingMockFallback = true;
    _lastBackendError = response.errorMessage ?? 'Backend server unreachable at ${ApiConfig.devices}';

    final mocks = await _fallbackMock.getAllDevices();
    return mocks.map((d) => DeviceModel(
      instrumentId: d.instrumentId,
      deviceId: d.deviceId,
      connected: false,
      health: DeviceHealth.offline,
      tamperDetected: d.tamperDetected,
      safeMode: d.safeMode,
      lastHeartbeat: d.lastHeartbeat,
      firmwareVersion: '${d.firmwareVersion ?? "Luckfox"} [OFFLINE DEMO]',
      deviceType: d.deviceType,
      owner: '${d.owner ?? ""} [DEMO FALLBACK]',
      location: d.location,
      city: d.city,
      state: d.state,
      latitude: d.latitude,
      longitude: d.longitude,
      tamperType: d.tamperType,
      tamperTime: d.tamperTime,
      tamperDetails: d.tamperDetails,
      lastSeen: d.lastSeen,
      backendStatus: 'offline_mock',
      currentWeight: 0.0,
      integrityStatus: 'Offline',
    )).toList();
  }

  @override
  Future<DeviceModel> getDeviceStatus(String instrumentId) async {
    final cleanId = _extractNumericId(instrumentId);
    
    final response = await _api.get<DeviceModel>(
      ApiConfig.device(cleanId),
      transform: (json) {
        if (json is Map && json.containsKey('device')) {
          return DeviceModel.fromBackendJson(Map<String, dynamic>.from(json['device']));
        } else if (json is Map) {
          return DeviceModel.fromBackendJson(Map<String, dynamic>.from(json));
        }
        throw Exception('Unexpected device payload');
      },
    );

    if (response.success && response.data != null) {
      _isBackendReachable = true;
      _isUsingMockFallback = false;
      return response.data!;
    }

    final statusResponse = await _api.get<Map<String, dynamic>>(ApiConfig.deviceStatus(cleanId));
    if (statusResponse.success && statusResponse.data != null) {
      _isBackendReachable = true;
      _isUsingMockFallback = false;
      final isSafe = statusResponse.data!['status'] == 'safe_mode' || statusResponse.data!['is_tampered'] == true;
      return DeviceModel(
        instrumentId: cleanId,
        deviceId: int.tryParse(cleanId),
        connected: true,
        health: isSafe ? DeviceHealth.critical : DeviceHealth.normal,
        tamperDetected: isSafe,
        safeMode: isSafe,
        lastHeartbeat: DateTime.now(),
        firmwareVersion: 'Luckfox Pico Plus',
        backendStatus: statusResponse.data!['status']?.toString(),
        currentWeight: 0.0,
        integrityStatus: isSafe ? 'Compromised' : 'Verified',
      );
    }

    _isBackendReachable = false;
    _isUsingMockFallback = true;
    final mockDev = await _fallbackMock.getDeviceStatus(instrumentId);
    return DeviceModel(
      instrumentId: mockDev.instrumentId,
      deviceId: mockDev.deviceId,
      connected: false,
      health: DeviceHealth.offline,
      tamperDetected: mockDev.tamperDetected,
      safeMode: mockDev.safeMode,
      lastHeartbeat: mockDev.lastHeartbeat,
      firmwareVersion: '${mockDev.firmwareVersion ?? "Luckfox"} [OFFLINE DEMO]',
      deviceType: mockDev.deviceType,
      owner: '${mockDev.owner ?? ""} [DEMO FALLBACK]',
      location: mockDev.location,
      city: mockDev.city,
      state: mockDev.state,
      latitude: mockDev.latitude,
      longitude: mockDev.longitude,
      tamperType: mockDev.tamperType,
      tamperTime: mockDev.tamperTime,
      tamperDetails: mockDev.tamperDetails,
      lastSeen: mockDev.lastSeen,
      backendStatus: 'offline_mock',
      currentWeight: 0.0,
      integrityStatus: 'Offline',
    );
  }

  @override
  Future<List<TamperEventModel>> getTamperLogs(String instrumentId) async {
    final cleanId = _extractNumericId(instrumentId);

    final response = await _api.get<List<TamperEventModel>>(
      ApiConfig.deviceTamper(cleanId),
      transform: (json) {
        if (json is List) {
          return json.map((item) => TamperEventModel.fromBackendJson(Map<String, dynamic>.from(item))).toList();
        }
        return <TamperEventModel>[];
      },
    );

    if (response.success && response.data != null) {
      _isBackendReachable = true;
      _isUsingMockFallback = false;
      return response.data!;
    }

    _isBackendReachable = false;
    _isUsingMockFallback = true;
    return _fallbackMock.getTamperLogs(instrumentId);
  }

  @override
  Future<UnlockCommandModel> unlockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    final cleanId = _extractNumericId(deviceId);

    final response = await _api.post<UnlockCommandModel>(
      ApiConfig.deviceUnlock(cleanId),
      body: {
        'officer_id': officerId,
        'officer_email': officerEmail,
        'reason': reason ?? 'Remote unlock requested via LMO Portal',
      },
      transform: (json) {
        if (json is Map && json.containsKey('command')) {
          return UnlockCommandModel.fromJson(Map<String, dynamic>.from(json['command']));
        }
        throw Exception(json['error']?.toString() ?? json['message']?.toString() ?? 'Unlock command failed');
      },
    );

    if (response.success && response.data != null) {
      _isBackendReachable = true;
      return response.data!;
    }

    if (response.errorMessage != null && !response.errorMessage!.contains('Connection failed')) {
      throw Exception(response.errorMessage);
    }

    _isBackendReachable = false;
    _isUsingMockFallback = true;
    return _fallbackMock.unlockDevice(
      deviceId: cleanId,
      officerEmail: officerEmail,
      officerId: officerId,
      reason: reason,
    );
  }

  @override
  Future<bool> lockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    final cleanId = _extractNumericId(deviceId);

    final response = await _api.post<Map<String, dynamic>>(
      ApiConfig.deviceTamper(cleanId),
      body: {
        'device_id': cleanId,
        'tamper_type': 'Officer Safe-Mode Lock',
        'severity': 'critical',
        'details': reason ?? 'Officer locked weighing machine into safe mode',
        'officer_id': officerId,
      },
      transform: (json) => json is Map<String, dynamic> ? json : <String, dynamic>{},
    );

    if (response.success) {
      _isBackendReachable = true;
      return true;
    }

    _isBackendReachable = false;
    _isUsingMockFallback = true;
    return _fallbackMock.lockDevice(
      deviceId: cleanId,
      officerEmail: officerEmail,
      officerId: officerId,
      reason: reason,
    );
  }

  @override
  Future<List<UnlockCommandModel>> getUnlockHistory(String deviceId) async {
    final cleanId = _extractNumericId(deviceId);

    final response = await _api.get<List<UnlockCommandModel>>(
      ApiConfig.deviceUnlockHistory(cleanId),
      transform: (json) {
        if (json is Map && json['unlock_commands'] is List) {
          return (json['unlock_commands'] as List)
              .map((item) => UnlockCommandModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
        return <UnlockCommandModel>[];
      },
    );

    if (response.success && response.data != null) {
      _isBackendReachable = true;
      return response.data!;
    }

    return _fallbackMock.getUnlockHistory(deviceId);
  }

  @override
  Future<DeviceAuditModel> getDeviceAuditLogs(String deviceId) async {
    final cleanId = _extractNumericId(deviceId);

    final response = await _api.get<DeviceAuditModel>(
      ApiConfig.deviceAuditLogs(cleanId),
      transform: (json) {
        if (json is Map) {
          return DeviceAuditModel.fromJson(Map<String, dynamic>.from(json));
        }
        throw Exception('Invalid audit log format');
      },
    );

    if (response.success && response.data != null) {
      _isBackendReachable = true;
      return response.data!;
    }

    return _fallbackMock.getDeviceAuditLogs(deviceId);
  }

  @override
  Future<void> sendHeartbeat(String deviceId) async {
    final cleanId = _extractNumericId(deviceId);
    await _api.post(ApiConfig.deviceHeartbeat(cleanId));
  }

  String _extractNumericId(String id) {
    if (id.isEmpty) return '1';
    final numeric = RegExp(r'\d+').stringMatch(id);
    if (numeric != null && numeric.isNotEmpty) return numeric;
    return id;
  }
}
