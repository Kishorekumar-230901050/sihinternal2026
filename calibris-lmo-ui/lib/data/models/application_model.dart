import 'document_model.dart';
import 'instrument_model.dart';

enum ApplicationStatus {
  submitted,
  underReview,
  approvedForVerification,
  verificationScheduled,
  inspectionInProgress,
  verificationSubmitted,
  approved,
  rejected,
  certificatePending,
  certificateIssued
}

class ApplicantInfo {
  final String businessName;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String gstNumber;
  final String registrationNumber;

  const ApplicantInfo({
    required this.businessName,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.gstNumber,
    required this.registrationNumber,
  });

  factory ApplicantInfo.fromJson(Map<String, dynamic> json) {
    return ApplicantInfo(
      businessName: json['businessName'],
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      contactEmail: json['contactEmail'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      gstNumber: json['gstNumber'],
      registrationNumber: json['registrationNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'gstNumber': gstNumber,
    'registrationNumber': registrationNumber,
  };
}

class ApplicationModel {
  final String id;
  final String applicantId;
  final String instrumentId;
  final String assignedOfficerId;
  final ApplicationStatus status;
  final String? rejectionReason;
  final String? correctionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApplicantInfo? applicantInfo;
  final InstrumentInfo? instrumentInfo;
  final List<DocumentModel> documents;

  const ApplicationModel({
    required this.id,
    required this.applicantId,
    required this.instrumentId,
    required this.assignedOfficerId,
    required this.status,
    this.rejectionReason,
    this.correctionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.applicantInfo,
    this.instrumentInfo,
    required this.documents,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'],
      applicantId: json['applicantId'],
      instrumentId: json['instrumentId'],
      assignedOfficerId: json['assignedOfficerId'],
      status: ApplicationStatus.values.firstWhere((e) => e.name == json['status']),
      rejectionReason: json['rejectionReason'],
      correctionNotes: json['correctionNotes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      applicantInfo: json['applicantInfo'] != null ? ApplicantInfo.fromJson(json['applicantInfo']) : null,
      instrumentInfo: json['instrumentInfo'] != null ? InstrumentInfo.fromJson(json['instrumentInfo']) : null,
      documents: (json['documents'] as List?)?.map((e) => DocumentModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'applicantId': applicantId,
    'instrumentId': instrumentId,
    'assignedOfficerId': assignedOfficerId,
    'status': status.name,
    'rejectionReason': rejectionReason,
    'correctionNotes': correctionNotes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'applicantInfo': applicantInfo?.toJson(),
    'instrumentInfo': instrumentInfo?.toJson(),
    'documents': documents.map((e) => e.toJson()).toList(),
  };

  ApplicationModel copyWith({
    String? id,
    String? applicantId,
    String? instrumentId,
    String? assignedOfficerId,
    ApplicationStatus? status,
    String? rejectionReason,
    String? correctionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ApplicantInfo? applicantInfo,
    InstrumentInfo? instrumentInfo,
    List<DocumentModel>? documents,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      instrumentId: instrumentId ?? this.instrumentId,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      correctionNotes: correctionNotes ?? this.correctionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      applicantInfo: applicantInfo ?? this.applicantInfo,
      instrumentInfo: instrumentInfo ?? this.instrumentInfo,
      documents: documents ?? this.documents,
    );
  }
}
