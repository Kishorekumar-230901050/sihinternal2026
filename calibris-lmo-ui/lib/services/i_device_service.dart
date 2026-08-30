import '../data/models/device_model.dart';
import '../data/models/tamper_event_model.dart';
import '../data/models/unlock_command_model.dart';
import '../data/models/device_audit_model.dart';

abstract class IDeviceService {
  Future<List<DeviceModel>> getAllDevices();
  Future<DeviceModel> getDeviceStatus(String instrumentId);
  Future<List<TamperEventModel>> getTamperLogs(String instrumentId);
  Future<UnlockCommandModel> unlockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  });
  Future<bool> lockDevice({
    required String deviceId,
    required String officerEmail,
    required String officerId,
    String? reason,
  });
  Future<List<UnlockCommandModel>> getUnlockHistory(String deviceId);
  Future<DeviceAuditModel> getDeviceAuditLogs(String deviceId);
  Future<void> sendHeartbeat(String deviceId);
}
