enum DeviceHealth { normal, warning, critical, offline }

class DeviceModel {
  final String instrumentId;
  final bool connected;
  final DeviceHealth health;
  final bool tamperDetected;
  final bool safeMode;
  final DateTime lastHeartbeat;
  final String? firmwareVersion;

  // Extended fields from 2025 Backend / Luckfox
  final int? deviceId;
  final String? deviceType;
  final String? owner;
  final String? location;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? tamperType;
  final DateTime? tamperTime;
  final String? tamperDetails;
  final DateTime? lastSeen;
  final String? backendStatus;
  final double? currentWeight;
  final String? integrityStatus;

  const DeviceModel({
    required this.instrumentId,
    required this.connected,
    required this.health,
    required this.tamperDetected,
    required this.safeMode,
    required this.lastHeartbeat,
    this.firmwareVersion,
    this.deviceId,
    this.deviceType,
    this.owner,
    this.location,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.tamperType,
    this.tamperTime,
    this.tamperDetails,
    this.lastSeen,
    this.backendStatus,
    this.currentWeight,
    this.integrityStatus,
  });

  bool get isOnline {
    if (lastSeen == null) return connected;
    return DateTime.now().difference(lastSeen!).inMinutes < 2;
  }

  bool get isTampered => tamperDetected || safeMode || backendStatus == 'safe_mode';

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      instrumentId: json['instrumentId']?.toString() ?? json['device_id']?.toString() ?? '',
      connected: json['connected'] ?? (json['last_seen'] != null ? DateTime.now().difference(DateTime.parse(json['last_seen'])).inMinutes < 2 : false),
      health: json['health'] != null 
          ? DeviceHealth.values.firstWhere((e) => e.name == json['health'], orElse: () => DeviceHealth.normal)
          : (json['status'] == 'safe_mode' ? DeviceHealth.critical : DeviceHealth.normal),
      tamperDetected: json['tamperDetected'] ?? (json['tamper_type'] != null || json['status'] == 'safe_mode'),
      safeMode: json['safeMode'] ?? (json['status'] == 'safe_mode'),
      lastHeartbeat: json['lastHeartbeat'] != null 
          ? DateTime.parse(json['lastHeartbeat']) 
          : (json['last_seen'] != null ? DateTime.parse(json['last_seen']) : DateTime.now()),
      firmwareVersion: json['firmwareVersion'] ?? 'Luckfox-v2.1',
      deviceId: json['device_id'] != null ? int.tryParse(json['device_id'].toString()) : null,
      deviceType: json['device_type']?.toString(),
      owner: json['owner']?.toString(),
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      tamperType: json['tamper_type']?.toString(),
      tamperTime: json['tamper_time'] != null ? DateTime.tryParse(json['tamper_time'].toString()) : null,
      tamperDetails: json['tamper_details']?.toString(),
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null,
      backendStatus: json['status']?.toString(),
      currentWeight: json['current_weight'] != null ? double.tryParse(json['current_weight'].toString()) : null,
      integrityStatus: json['integrity_status']?.toString() ?? 'Verified',
    );
  }

  factory DeviceModel.fromBackendJson(Map<String, dynamic> json) {
    final devId = json['device_id']?.toString() ?? json['id']?.toString() ?? '';
    final lastSeenDate = json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null;
    final isOnlineNow = lastSeenDate != null && DateTime.now().difference(lastSeenDate).inMinutes < 2;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    final hasTamper = json['tamper_type'] != null || statusStr == 'safe_mode';
    final isSafe = statusStr == 'safe_mode';

    DeviceHealth calcHealth;
    if (isSafe || hasTamper) {
      calcHealth = DeviceHealth.critical;
    } else if (!isOnlineNow) {
      calcHealth = DeviceHealth.offline;
    } else {
      calcHealth = DeviceHealth.normal;
    }

    return DeviceModel(
      instrumentId: devId.isNotEmpty ? devId : '1',
      deviceId: int.tryParse(devId),
      connected: isOnlineNow,
      health: calcHealth,
      tamperDetected: hasTamper,
      safeMode: isSafe,
      lastHeartbeat: lastSeenDate ?? DateTime.now(),
      firmwareVersion: 'Luckfox Pico Plus',
      deviceType: json['device_type']?.toString() ?? 'electronicWeighingScale',
      owner: json['owner']?.toString(),
      location: json['location']?.toString() ?? '${json['city'] ?? ""}, ${json['state'] ?? ""}'.trim(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      tamperType: json['tamper_type']?.toString(),
      tamperTime: json['tamper_time'] != null ? DateTime.tryParse(json['tamper_time'].toString()) : null,
      tamperDetails: json['tamper_details']?.toString(),
      lastSeen: lastSeenDate,
      backendStatus: statusStr,
      currentWeight: json['current_weight'] != null ? double.tryParse(json['current_weight'].toString()) : null,
      integrityStatus: hasTamper ? 'Compromised' : 'Verified',
    );
  }

  Map<String, dynamic> toJson() => {
    'instrumentId': instrumentId,
    'connected': connected,
    'health': health.name,
    'tamperDetected': tamperDetected,
    'safeMode': safeMode,
    'lastHeartbeat': lastHeartbeat.toIso8601String(),
    'firmwareVersion': firmwareVersion,
    'device_id': deviceId,
    'device_type': deviceType,
    'owner': owner,
    'location': location,
    'city': city,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'tamper_type': tamperType,
    'tamper_time': tamperTime?.toIso8601String(),
    'tamper_details': tamperDetails,
    'last_seen': lastSeen?.toIso8601String(),
    'status': backendStatus,
    'current_weight': currentWeight,
    'integrity_status': integrityStatus,
  };
}
