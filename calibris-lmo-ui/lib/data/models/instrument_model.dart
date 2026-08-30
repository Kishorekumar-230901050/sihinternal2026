enum InstrumentType {
  electronicWeighingScale,
  petrolPumpDispenser,
  platformWeighbridge,
  milkMeasuring,
  cylindricalMeasure,
  taxiMeter,
  other
}

class InstrumentInfo {
  final String instrumentId;
  final String? uniqueId; // Official Government Unique ID: CLM-IND-2026-XXXXX
  final InstrumentType type;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String capacity;
  final String accuracyClass;
  final double registeredLocationLat;
  final double registeredLocationLng;
  final String registeredAddress;
  final bool isDigitalCompatible;
  final String? photoUrl;
  final DateTime? lastVerificationDate;
  final String? lastCertificateId;
  final String? backendInstrumentTypeId;

  const InstrumentInfo({
    required this.instrumentId,
    this.uniqueId,
    required this.type,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.capacity,
    required this.accuracyClass,
    required this.registeredLocationLat,
    required this.registeredLocationLng,
    required this.registeredAddress,
    required this.isDigitalCompatible,
    this.photoUrl,
    this.lastVerificationDate,
    this.lastCertificateId,
    this.backendInstrumentTypeId,
  });

  String get effectiveUniqueId => uniqueId ?? 'CLM-IND-2026-${instrumentId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(5, '0')}';

  bool get isWeighingMachine =>
      type == InstrumentType.electronicWeighingScale ||
      type == InstrumentType.platformWeighbridge;

  bool get isWeighbridge => type == InstrumentType.platformWeighbridge;

  bool get isSmallDevice => type != InstrumentType.platformWeighbridge;

  bool get isFuelPump => type == InstrumentType.petrolPumpDispenser;

  /// Maps a raw `Instrument` JSON object as returned by calibris-backend
  /// (see prisma schema `Instrument`/`InstrumentType`) into the app's model.
  /// Backend doesn't track accuracy class or a registered lat/lng for the
  /// instrument itself (only the GATC has coordinates), so those use
  /// reasonable defaults.
  factory InstrumentInfo.fromBackendJson(Map<String, dynamic> json) {
    final typeObj = json['instrumentType'] as Map<String, dynamic>?;
    final code = (typeObj?['code'] ?? '').toString().toUpperCase();
    final name = (typeObj?['name'] ?? '').toString().toUpperCase();
    final InstrumentType type;
    if (code.contains('WB') || code.contains('WEIGHBRIDGE') || name.contains('WEIGHBRIDGE')) {
      type = InstrumentType.platformWeighbridge;
    } else if (code.contains('FDS') || code.contains('FUEL') || name.contains('FUEL')) {
      type = InstrumentType.petrolPumpDispenser;
    } else {
      type = InstrumentType.electronicWeighingScale;
    }
    return InstrumentInfo(
      instrumentId: json['id']?.toString() ?? '',
      uniqueId: json['serialNumber']?.toString(),
      type: type,
      manufacturer: json['manufacturer']?.toString() ?? 'Unknown',
      model: json['model']?.toString() ?? 'Standard',
      serialNumber: json['serialNumber']?.toString() ?? '',
      capacity: json['capacity']?.toString() ?? 'N/A',
      accuracyClass: 'Class III',
      registeredLocationLat: 0.0,
      registeredLocationLng: 0.0,
      registeredAddress: '',
      isDigitalCompatible: true,
      backendInstrumentTypeId: json['instrumentTypeId']?.toString() ?? typeObj?['id']?.toString(),
    );
  }

  factory InstrumentInfo.fromJson(Map<String, dynamic> json) {
    return InstrumentInfo(
      instrumentId: json['instrumentId'],
      uniqueId: json['uniqueId'],
      type: InstrumentType.values.firstWhere((e) => e.name == json['type']),
      manufacturer: json['manufacturer'],
      model: json['model'],
      serialNumber: json['serialNumber'],
      capacity: json['capacity'],
      accuracyClass: json['accuracyClass'],
      registeredLocationLat: json['registeredLocationLat'],
      registeredLocationLng: json['registeredLocationLng'],
      registeredAddress: json['registeredAddress'],
      isDigitalCompatible: json['isDigitalCompatible'],
      photoUrl: json['photoUrl'],
      lastVerificationDate: json['lastVerificationDate'] != null ? DateTime.parse(json['lastVerificationDate']) : null,
      lastCertificateId: json['lastCertificateId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'instrumentId': instrumentId,
    'uniqueId': uniqueId,
    'type': type.name,
    'manufacturer': manufacturer,
    'model': model,
    'serialNumber': serialNumber,
    'capacity': capacity,
    'accuracyClass': accuracyClass,
    'registeredLocationLat': registeredLocationLat,
    'registeredLocationLng': registeredLocationLng,
    'registeredAddress': registeredAddress,
    'isDigitalCompatible': isDigitalCompatible,
    'photoUrl': photoUrl,
    'lastVerificationDate': lastVerificationDate?.toIso8601String(),
    'lastCertificateId': lastCertificateId,
  };

  InstrumentInfo copyWith({
    String? instrumentId,
    String? uniqueId,
    InstrumentType? type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? capacity,
    String? accuracyClass,
    double? registeredLocationLat,
    double? registeredLocationLng,
    String? registeredAddress,
    bool? isDigitalCompatible,
    String? photoUrl,
    DateTime? lastVerificationDate,
    String? lastCertificateId,
  }) {
    return InstrumentInfo(
      instrumentId: instrumentId ?? this.instrumentId,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      capacity: capacity ?? this.capacity,
      accuracyClass: accuracyClass ?? this.accuracyClass,
      registeredLocationLat: registeredLocationLat ?? this.registeredLocationLat,
      registeredLocationLng: registeredLocationLng ?? this.registeredLocationLng,
      registeredAddress: registeredAddress ?? this.registeredAddress,
      isDigitalCompatible: isDigitalCompatible ?? this.isDigitalCompatible,
      photoUrl: photoUrl ?? this.photoUrl,
      lastVerificationDate: lastVerificationDate ?? this.lastVerificationDate,
      lastCertificateId: lastCertificateId ?? this.lastCertificateId,
    );
  }
}
