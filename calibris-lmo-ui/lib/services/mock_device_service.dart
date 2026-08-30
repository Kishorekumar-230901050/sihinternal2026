import 'i_device_service.dart';
import '../data/models/device_model.dart';
import '../data/models/tamper_event_model.dart';
import '../data/models/unlock_command_model.dart';
import '../data/models/device_audit_model.dart';
import '../data/mock/mock_data.dart';

class MockDeviceService implements IDeviceService {
  final List<UnlockCommandModel> _mockUnlockCommands = [];

  @override
  Future<List<DeviceModel>> getAllDevices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataStore.devices;
  }

  @override
  Future<DeviceModel> getDeviceStatus(String instrumentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return MockDataStore.devices.firstWhere(
        (d) => d.instrumentId == instrumentId || d.deviceId.toString() == instrumentId,
      );
    } catch (e) {
      return MockDataStore.devices.first;
    }
  }

  @override
  Future<List<TamperEventModel>> getTamperLogs(String instrumentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockDataStore.tamperEvents
        .where((t) => t.instrumentId == instrumentId || t.instrumentId == 'DEV-001')
        .toList();
  }

  @override
  Future<UnlockCommandModel> unlockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final cmd = UnlockCommandModel(
      id: _mockUnlockCommands.length + 1,
      deviceId: deviceId,
      officerId: officerId,
      officerEmail: officerEmail,
      reason: reason ?? 'Testing remote unlock',
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _mockUnlockCommands.add(cmd);
    return cmd;
  }

  @override
  Future<bool> lockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<List<UnlockCommandModel>> getUnlockHistory(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockUnlockCommands.where((u) => u.deviceId == deviceId).toList();
  }

  @override
  Future<DeviceAuditModel> getDeviceAuditLogs(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final dev = await getDeviceStatus(deviceId);
    final tampers = await getTamperLogs(deviceId);
    final unlocks = await getUnlockHistory(deviceId);
    return DeviceAuditModel(
      device: dev,
      tamperEvents: tampers,
      unlockCommands: unlocks,
      statistics: {
        'total_tamper_events': tampers.length,
        'total_unlocks': unlocks.where((u) => u.isExecuted).length,
        'pending_unlocks': unlocks.where((u) => u.isPending).length,
      },
    );
  }

  @override
  Future<void> sendHeartbeat(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
