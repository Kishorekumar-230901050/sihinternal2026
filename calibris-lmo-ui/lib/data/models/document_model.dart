enum DocumentType {
  previousCertificate,
  purchaseDocument,
  registrationDocument,
  ownershipProof,
  other
}

class DocumentModel {
  final String id;
  final String applicationId;
  final DocumentType type;
  final String fileName;
  final String url;
  final DateTime uploadedAt;
  final bool isVerified;

  const DocumentModel({
    required this.id,
    required this.applicationId,
    required this.type,
    required this.fileName,
    required this.url,
    required this.uploadedAt,
    this.isVerified = false,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      applicationId: json['applicationId'],
      type: DocumentType.values.firstWhere((e) => e.name == json['type']),
      fileName: json['fileName'],
      url: json['url'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'applicationId': applicationId,
    'type': type.name,
    'fileName': fileName,
    'url': url,
    'uploadedAt': uploadedAt.toIso8601String(),
    'isVerified': isVerified,
  };
}
