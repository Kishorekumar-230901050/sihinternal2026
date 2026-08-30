enum CertificateStatus { active, expired, revoked, pending }

class CertificateModel {
  final String id;
  final String certificateNumber;
  final String applicationId;
  final String instrumentId;
  final String inspectionId;
  final String applicantId;
  final String officerId;
  final DateTime issuedAt;
  final DateTime validUntil;
  final DateTime reverificationDue;
  final CertificateStatus status;
  final String? qrToken;
  final String? pdfUrl;

  const CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.applicationId,
    required this.instrumentId,
    required this.inspectionId,
    required this.applicantId,
    required this.officerId,
    required this.issuedAt,
    required this.validUntil,
    required this.reverificationDue,
    required this.status,
    this.qrToken,
    this.pdfUrl,
  });

  /// Maps the `Certificate` JSON returned by
  /// `GET /api/vendor/applications/:applicationId/certificate`.
  factory CertificateModel.fromBackendJson(
    Map<String, dynamic> json, {
    required String instrumentId,
    required String applicantId,
  }) {
    final validUntil = DateTime.parse(json['validUntil'] as String);
    return CertificateModel(
      id: json['id'].toString(),
      certificateNumber: json['certificateNo']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      instrumentId: instrumentId,
      inspectionId: '',
      applicantId: applicantId,
      officerId: '',
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      validUntil: validUntil,
      reverificationDue: validUntil,
      status: validUntil.isAfter(DateTime.now()) ? CertificateStatus.active : CertificateStatus.expired,
      qrToken: json['qrToken']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
    );
  }

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'],
      certificateNumber: json['certificateNumber'],
      applicationId: json['applicationId'],
      instrumentId: json['instrumentId'],
      inspectionId: json['inspectionId'],
      applicantId: json['applicantId'],
      officerId: json['officerId'],
      issuedAt: DateTime.parse(json['issuedAt']),
      validUntil: DateTime.parse(json['validUntil']),
      reverificationDue: DateTime.parse(json['reverificationDue']),
      status: CertificateStatus.values.firstWhere((e) => e.name == json['status']),
      qrToken: json['qrToken'],
      pdfUrl: json['pdfUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'certificateNumber': certificateNumber,
    'applicationId': applicationId,
    'instrumentId': instrumentId,
    'inspectionId': inspectionId,
    'applicantId': applicantId,
    'officerId': officerId,
    'issuedAt': issuedAt.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
    'reverificationDue': reverificationDue.toIso8601String(),
    'status': status.name,
    'qrToken': qrToken,
    'pdfUrl': pdfUrl,
  };
}
