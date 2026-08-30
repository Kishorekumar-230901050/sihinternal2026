import 'device_model.dart';
import 'tamper_event_model.dart';
import 'unlock_command_model.dart';

class DeviceAuditModel {
  final DeviceModel device;
  final List<TamperEventModel> tamperEvents;
  final List<UnlockCommandModel> unlockCommands;
  final Map<String, dynamic> statistics;

  const DeviceAuditModel({
    required this.device,
    required this.tamperEvents,
    required this.unlockCommands,
    required this.statistics,
  });

  factory DeviceAuditModel.fromJson(Map<String, dynamic> json) {
    final dev = json['device'] != null
        ? DeviceModel.fromBackendJson(json['device'])
        : DeviceModel(
            instrumentId: 'Unknown',
            connected: false,
            health: DeviceHealth.offline,
            tamperDetected: false,
            safeMode: false,
            lastHeartbeat: DateTime.now(),
          );

    final List<TamperEventModel> tampers = [];
    if (json['tamper_events'] is List) {
      for (final t in json['tamper_events']) {
        tampers.add(TamperEventModel.fromBackendJson(t));
      }
    }

    final List<UnlockCommandModel> unlocks = [];
    if (json['unlock_commands'] is List) {
      for (final u in json['unlock_commands']) {
        unlocks.add(UnlockCommandModel.fromJson(u));
      }
    }

    return DeviceAuditModel(
      device: dev,
      tamperEvents: tampers,
      unlockCommands: unlocks,
      statistics: json['statistics'] is Map<String, dynamic> 
          ? json['statistics'] 
          : <String, dynamic>{},
    );
  }
}
