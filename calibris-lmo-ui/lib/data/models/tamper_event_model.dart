enum TamperEventType {
  enclosureOpened,
  sealBroken,
  unauthorizedAccess,
  powerInterruption,
  calibrationChange,
  weightDrift,
  safeModeTriggered,
  other
}

enum TamperSeverity { low, medium, high, critical }

class TamperEventModel {
  final String id;
  final String instrumentId;
  final DateTime timestamp;
  final TamperEventType eventType;
  final TamperSeverity severity;
  final String? notes;

  // Extended backend / Luckfox fields
  final String? rawTamperType;
  final String? details;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final double? drift;
  final double? settlingTime;
  final int? renewalCycle;
  final String? prevHash;
  final String? currHash;
  final String? luckfoxLogId;

  const TamperEventModel({
    required this.id,
    required this.instrumentId,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    this.notes,
    this.rawTamperType,
    this.details,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.drift,
    this.settlingTime,
    this.renewalCycle,
    this.prevHash,
    this.currHash,
    this.luckfoxLogId,
  });

  static TamperEventType parseEventType(String? type) {
    if (type == null) return TamperEventType.other;
    final normalized = type.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (normalized.contains('enclosure') || normalized.contains('door') || normalized.contains('case')) {
      return TamperEventType.enclosureOpened;
    } else if (normalized.contains('seal')) {
      return TamperEventType.sealBroken;
    } else if (normalized.contains('unauthorized') || normalized.contains('access')) {
      return TamperEventType.unauthorizedAccess;
    } else if (normalized.contains('power') || normalized.contains('battery')) {
      return TamperEventType.powerInterruption;
    } else if (normalized.contains('calibration') || normalized.contains('scale')) {
      return TamperEventType.calibrationChange;
    } else if (normalized.contains('drift') || normalized.contains('load')) {
      return TamperEventType.weightDrift;
    } else if (normalized.contains('safe') || normalized.contains('lock')) {
      return TamperEventType.safeModeTriggered;
    }
    return TamperEventType.other;
  }

  static TamperSeverity parseSeverity(String? sev) {
    if (sev == null) return TamperSeverity.medium;
    final normalized = sev.toLowerCase().trim();
    if (normalized == 'low') return TamperSeverity.low;
    if (normalized == 'medium' || normalized == 'med' || normalized == 'warning') return TamperSeverity.medium;
    if (normalized == 'high' || normalized == 'severe') return TamperSeverity.high;
    if (normalized == 'critical' || normalized == 'danger') return TamperSeverity.critical;
    return TamperSeverity.high;
  }

  factory TamperEventModel.fromJson(Map<String, dynamic> json) {
    return TamperEventModel(
      id: json['id']?.toString() ?? '',
      instrumentId: json['instrumentId']?.toString() ?? json['device_id']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : (json['event_time'] != null ? DateTime.parse(json['event_time']) : DateTime.now()),
      eventType: json['eventType'] != null
          ? TamperEventType.values.firstWhere((e) => e.name == json['eventType'], orElse: () => TamperEventType.other)
          : parseEventType(json['tamper_type']),
      severity: json['severity'] != null
          ? (json['severity'] is String && TamperSeverity.values.any((e) => e.name == json['severity'])
              ? TamperSeverity.values.firstWhere((e) => e.name == json['severity'])
              : parseSeverity(json['severity']?.toString()))
          : TamperSeverity.high,
      notes: json['notes'] ?? json['details'],
      rawTamperType: json['tamper_type']?.toString(),
      details: json['details']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      drift: json['drift'] != null ? double.tryParse(json['drift'].toString()) : null,
      settlingTime: json['settling_time'] != null ? double.tryParse(json['settling_time'].toString()) : null,
      renewalCycle: json['renewal_cycle'] != null ? int.tryParse(json['renewal_cycle'].toString()) : null,
      prevHash: json['prev_hash']?.toString(),
      currHash: json['curr_hash']?.toString(),
      luckfoxLogId: json['luckfox_log_id']?.toString(),
    );
  }

  factory TamperEventModel.fromBackendJson(Map<String, dynamic> json) {
    final rawType = json['tamper_type']?.toString() ?? 'Tamper Detected';
    final detailsText = json['details']?.toString() ?? '';
    final eventTime = json['event_time'] != null 
        ? (DateTime.tryParse(json['event_time'].toString()) ?? DateTime.now())
        : DateTime.now();

    return TamperEventModel(
      id: json['id']?.toString() ?? 'TMP-${DateTime.now().millisecondsSinceEpoch}',
      instrumentId: json['device_id']?.toString() ?? '1',
      timestamp: eventTime,
      eventType: parseEventType(rawType),
      severity: parseSeverity(json['severity']?.toString()),
      notes: detailsText.isNotEmpty ? detailsText : rawType,
      rawTamperType: rawType,
      details: detailsText,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      drift: json['drift'] != null ? double.tryParse(json['drift'].toString()) : null,
      settlingTime: json['settling_time'] != null ? double.tryParse(json['settling_time'].toString()) : null,
      renewalCycle: json['renewal_cycle'] != null ? int.tryParse(json['renewal_cycle'].toString()) : null,
      prevHash: json['prev_hash']?.toString(),
      currHash: json['curr_hash']?.toString(),
      luckfoxLogId: json['luckfox_log_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'instrumentId': instrumentId,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType.name,
    'severity': severity.name,
    'notes': notes,
    'tamper_type': rawTamperType,
    'details': details,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'state': state,
    'drift': drift,
    'settling_time': settlingTime,
    'renewal_cycle': renewalCycle,
    'prev_hash': prevHash,
    'curr_hash': currHash,
    'luckfox_log_id': luckfoxLogId,
  };
}
