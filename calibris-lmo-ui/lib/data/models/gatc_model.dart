/// Government Approved Test Centre model.
class GatcModel {
  final String id;
  final String name;
  final String addressLine;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final String? contactPhone;
  final bool isActive;
  final int dailyCapacity;
  final List<String> supportedInstrumentTypes;
  final double? distanceKm; // computed at runtime

  const GatcModel({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.contactPhone,
    this.isActive = true,
    this.dailyCapacity = 20,
    this.supportedInstrumentTypes = const [],
    this.distanceKm,
  });

  GatcModel copyWith({double? distanceKm}) {
    return GatcModel(
      id: id,
      name: name,
      addressLine: addressLine,
      district: district,
      state: state,
      latitude: latitude,
      longitude: longitude,
      contactPhone: contactPhone,
      isActive: isActive,
      dailyCapacity: dailyCapacity,
      supportedInstrumentTypes: supportedInstrumentTypes,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
