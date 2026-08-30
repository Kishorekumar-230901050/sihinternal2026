import 'measurement_model.dart';
import 'photo_evidence_model.dart';

enum VerificationMode { digital, field }
enum InspectionResult { pass, fail, pending }

class InspectionModel {
  final String id;
  final String applicationId;
  final String officerId;
  final String officerName;
  final VerificationMode mode;
  final InspectionResult result;
  final String? physicalCondition;
  final String? sealCondition;
  final String? displayCondition;
  final bool tamperDetected;
  final String? tamperNotes;
  final String? observations;
  final String? failureReason;
  final double? inspectionLat;
  final double? inspectionLng;
  final double? gpsAccuracy;
  final double? distanceFromRegistered;
  final bool? withinGeofence;
  final DateTime? scheduledDate;
  final DateTime? inspectedAt;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final List<MeasurementModel> measurements;
  final List<PhotoEvidenceModel> photos;

  const InspectionModel({
    required this.id,
    required this.applicationId,
    required this.officerId,
    required this.officerName,
    required this.mode,
    required this.result,
    this.physicalCondition,
    this.sealCondition,
    this.displayCondition,
    this.tamperDetected = false,
    this.tamperNotes,
    this.observations,
    this.failureReason,
    this.inspectionLat,
    this.inspectionLng,
    this.gpsAccuracy,
    this.distanceFromRegistered,
    this.withinGeofence,
    this.scheduledDate,
    this.inspectedAt,
    this.submittedAt,
    required this.createdAt,
    this.measurements = const [],
    this.photos = const [],
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'],
      applicationId: json['applicationId'],
      officerId: json['officerId'],
      officerName: json['officerName'],
      mode: VerificationMode.values.firstWhere((e) => e.name == json['mode']),
      result: InspectionResult.values.firstWhere((e) => e.name == json['result']),
      physicalCondition: json['physicalCondition'],
      sealCondition: json['sealCondition'],
      displayCondition: json['displayCondition'],
      tamperDetected: json['tamperDetected'] ?? false,
      tamperNotes: json['tamperNotes'],
      observations: json['observations'],
      failureReason: json['failureReason'],
      inspectionLat: json['inspectionLat'],
      inspectionLng: json['inspectionLng'],
      gpsAccuracy: json['gpsAccuracy'],
      distanceFromRegistered: json['distanceFromRegistered'],
      withinGeofence: json['withinGeofence'],
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      inspectedAt: json['inspectedAt'] != null ? DateTime.parse(json['inspectedAt']) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      measurements: (json['measurements'] as List?)?.map((e) => MeasurementModel.fromJson(e)).toList() ?? [],
      photos: (json['photos'] as List?)?.map((e) => PhotoEvidenceModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'applicationId': applicationId,
    'officerId': officerId,
    'officerName': officerName,
    'mode': mode.name,
    'result': result.name,
    'physicalCondition': physicalCondition,
    'sealCondition': sealCondition,
    'displayCondition': displayCondition,
    'tamperDetected': tamperDetected,
    'tamperNotes': tamperNotes,
    'observations': observations,
    'failureReason': failureReason,
    'inspectionLat': inspectionLat,
    'inspectionLng': inspectionLng,
    'gpsAccuracy': gpsAccuracy,
    'distanceFromRegistered': distanceFromRegistered,
    'withinGeofence': withinGeofence,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'inspectedAt': inspectedAt?.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'measurements': measurements.map((e) => e.toJson()).toList(),
    'photos': photos.map((e) => e.toJson()).toList(),
  };

  InspectionModel copyWith({
    String? id,
    String? applicationId,
    String? officerId,
    String? officerName,
    VerificationMode? mode,
    InspectionResult? result,
    String? physicalCondition,
    String? sealCondition,
    String? displayCondition,
    bool? tamperDetected,
    String? tamperNotes,
    String? observations,
    String? failureReason,
    double? inspectionLat,
    double? inspectionLng,
    double? gpsAccuracy,
    double? distanceFromRegistered,
    bool? withinGeofence,
    DateTime? scheduledDate,
    DateTime? inspectedAt,
    DateTime? submittedAt,
    DateTime? createdAt,
    List<MeasurementModel>? measurements,
    List<PhotoEvidenceModel>? photos,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      officerId: officerId ?? this.officerId,
      officerName: officerName ?? this.officerName,
      mode: mode ?? this.mode,
      result: result ?? this.result,
      physicalCondition: physicalCondition ?? this.physicalCondition,
      sealCondition: sealCondition ?? this.sealCondition,
      displayCondition: displayCondition ?? this.displayCondition,
      tamperDetected: tamperDetected ?? this.tamperDetected,
      tamperNotes: tamperNotes ?? this.tamperNotes,
      observations: observations ?? this.observations,
      failureReason: failureReason ?? this.failureReason,
      inspectionLat: inspectionLat ?? this.inspectionLat,
      inspectionLng: inspectionLng ?? this.inspectionLng,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      distanceFromRegistered: distanceFromRegistered ?? this.distanceFromRegistered,
      withinGeofence: withinGeofence ?? this.withinGeofence,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      measurements: measurements ?? this.measurements,
      photos: photos ?? this.photos,
    );
  }
}
