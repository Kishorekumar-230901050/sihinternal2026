import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/device_model.dart';
import '../data/models/tamper_event_model.dart';
import '../services/i_device_service.dart';
import '../services/backend_device_service.dart';
import '../services/websocket_service.dart';
import '../services/audit_service.dart';
import '../data/models/audit_log_model.dart';

class DeviceProvider extends ChangeNotifier {
  final IDeviceService _deviceService;
  final WebSocketService _wsService;
  final AuditService _auditService = AuditService();

  List<DeviceModel> _devices = [];
  DeviceModel? _device;
  List<TamperEventModel> _tamperLogs = [];
  TamperEventModel? _latestRealtimeAlert;
  DateTime? _lastHeartbeatReceived;
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _errorMessage;
  bool _isWsConnected = false;
  String? _activeMonitoredDeviceId;

  StreamSubscription<TamperEventModel>? _tamperSub;
  StreamSubscription<BatchTamperAlert>? _batchSub;
  StreamSubscription<bool>? _wsStateSub;
  Timer? _devicePollingTimer;

  DeviceProvider(this._deviceService, [WebSocketService? wsService])
      : _wsService = wsService ?? WebSocketService() {
    _initWebSocket();
  }

  List<DeviceModel> get devices => _devices;
  DeviceModel? get device => _device;
  List<TamperEventModel> get tamperLogs => _tamperLogs;
  TamperEventModel? get latestRealtimeAlert => _latestRealtimeAlert;
  DateTime? get lastHeartbeatReceived => _lastHeartbeatReceived;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  bool get isUnlocking => _isActionInProgress;
  String? get errorMessage => _errorMessage;
  bool get isWsConnected => _isWsConnected;
  String? get activeMonitoredDeviceId => _activeMonitoredDeviceId;

  bool get isBackendReachable => _deviceService is BackendDeviceService 
      ? (_deviceService as BackendDeviceService).isBackendReachable 
      : false;

  bool get isUsingMockFallback => _deviceService is BackendDeviceService
      ? (_deviceService as BackendDeviceService).isUsingMockFallback
      : true;

  String? get lastBackendError => _deviceService is BackendDeviceService
      ? (_deviceService as BackendDeviceService).lastBackendError
      : null;

  int get onlineDevicesCount => _devices.where((d) => d.isOnline).length;
  int get offlineDevicesCount => _devices.where((d) => !d.isOnline).length;
  int get safeModeDevicesCount => _devices.where((d) => d.safeMode || d.backendStatus == 'safe_mode').length;

  bool get isLuckfoxHardwareOnline => _device != null && _device!.isOnline && !isUsingMockFallback;

  void _initWebSocket() {
    _wsService.connect();

    _wsStateSub = _wsService.onConnectionStateChanged.listen((connected) {
      _isWsConnected = connected;
      notifyListeners();
    });

    _tamperSub = _wsService.onTamperAlert.listen((alert) {
      _handleIncomingTamperAlert(alert);
    });

    _batchSub = _wsService.onBatchTamperAlert.listen((batch) {
      for (final log in batch.logs) {
        _handleIncomingTamperAlert(log, notify: false);
      }
      if (batch.logs.isNotEmpty) {
        _latestRealtimeAlert = batch.logs.first;
      }
      _lastHeartbeatReceived = DateTime.now();
      notifyListeners();
    });
  }

  void _handleIncomingTamperAlert(TamperEventModel alert, {bool notify = true}) {
    _latestRealtimeAlert = alert;
    _lastHeartbeatReceived = alert.timestamp;
    
    final targetDevId = alert.instrumentId;
    if (_device != null && (_device!.instrumentId == targetDevId || _device!.deviceId.toString() == targetDevId)) {
      _tamperLogs.insert(0, alert);
      _device = DeviceModel(
        instrumentId: _device!.instrumentId,
        deviceId: _device!.deviceId,
        connected: true,
        health: DeviceHealth.critical,
        tamperDetected: true,
        safeMode: true,
        lastHeartbeat: alert.timestamp,
        firmwareVersion: _device!.firmwareVersion,
        deviceType: _device!.deviceType,
        owner: _device!.owner,
        location: alert.city != null ? '${alert.city}, ${alert.state ?? ""}' : _device!.location,
        city: alert.city ?? _device!.city,
        state: alert.state ?? _device!.state,
        latitude: alert.latitude ?? _device!.latitude,
        longitude: alert.longitude ?? _device!.longitude,
        tamperType: alert.rawTamperType,
        tamperTime: alert.timestamp,
        tamperDetails: alert.details,
        lastSeen: alert.timestamp,
        backendStatus: 'safe_mode',
        currentWeight: _device!.currentWeight,
        integrityStatus: 'Compromised',
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  void clearLatestRealtimeAlert() {
    _latestRealtimeAlert = null;
    notifyListeners();
  }

  /// Start live machine connection & polling for a specific application being verified
  void startLiveDeviceMonitoring(String instrumentId) {
    _activeMonitoredDeviceId = instrumentId;
    fetchDeviceStatus(instrumentId);
    fetchTamperLogs(instrumentId);

    _devicePollingTimer?.cancel();
    _devicePollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_activeMonitoredDeviceId != null) {
        _fetchDeviceStatusSilently(_activeMonitoredDeviceId!);
      }
    });
  }

  /// Stop machine connection & polling when leaving verification page
  void stopLiveDeviceMonitoring() {
    _devicePollingTimer?.cancel();
    _devicePollingTimer = null;
    _activeMonitoredDeviceId = null;
    _device = null;
    _tamperLogs = [];
  }

  Future<void> fetchAllDevices({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _devices = await _deviceService.getAllDevices();
      if (_devices.isNotEmpty && _devices.any((d) => d.isOnline)) {
        _lastHeartbeatReceived = _devices.firstWhere((d) => d.isOnline).lastSeen;
      }
    } catch (_) {} finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchDeviceStatus(String instrumentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _device = await _deviceService.getDeviceStatus(instrumentId);
      if (_device != null && _device!.isOnline) {
        _lastHeartbeatReceived = _device!.lastSeen ?? _device!.lastHeartbeat;
      }
      _auditService.log(
        'USR-001',
        AuditAction.viewDeviceStatus,
        entityId: instrumentId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDeviceStatusSilently(String instrumentId) async {
    try {
      final updated = await _deviceService.getDeviceStatus(instrumentId);
      _device = updated;
      if (updated.isOnline) {
        _lastHeartbeatReceived = updated.lastSeen ?? updated.lastHeartbeat;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTamperLogs(String instrumentId) async {
    try {
      _tamperLogs = await _deviceService.getTamperLogs(instrumentId);
      _tamperLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _auditService.log(
        'USR-001',
        AuditAction.viewTamperLog,
        entityId: instrumentId,
      );
      notifyListeners();
    } catch (_) {}
  }

  /// Lock weighing machine into SAFE MODE (Weighing machines only)
  Future<bool> lockDeviceSafeMode({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _deviceService.lockDevice(
        deviceId: deviceId,
        officerEmail: officerEmail,
        officerId: officerId,
        reason: reason ?? 'Officer initiated safe-mode lock during inspection',
      );

      _auditService.log(
        officerId,
        AuditAction.remoteLock,
        entityId: deviceId,
        details: reason ?? 'Safe Mode lock activated by officer',
      );

      await fetchDeviceStatus(deviceId);
      _isActionInProgress = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  /// Remote Unlock weighing machine (Weighing machines only)
  Future<bool> unlockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final command = await _deviceService.unlockDevice(
        deviceId: deviceId,
        officerEmail: officerEmail,
        officerId: officerId,
        reason: reason,
      );

      _auditService.log(
        officerId,
        AuditAction.remoteUnlock,
        entityId: deviceId,
        details: 'Command #${command.id}: ${command.reason}',
      );

      await fetchDeviceStatus(deviceId);
      _isActionInProgress = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _tamperSub?.cancel();
    _batchSub?.cancel();
    _wsStateSub?.cancel();
    _devicePollingTimer?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
