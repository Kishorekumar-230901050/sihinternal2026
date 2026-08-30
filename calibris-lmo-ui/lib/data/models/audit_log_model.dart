enum AuditAction {
  login,
  logout,
  viewApplication,
  viewDocument,
  approveApplication,
  rejectApplication,
  requestCorrection,
  scheduleVerification,
  submitInspection,
  changeResult,
  requestCertificate,
  viewTamperLog,
  viewDeviceStatus,
  remoteUnlock,
  remoteLock
}

class AuditLogModel {
  final String id;
  final String userId;
  final AuditAction action;
  final String? entityId;
  final String? entityType;
  final DateTime timestamp;
  final String? details;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    this.entityId,
    this.entityType,
    required this.timestamp,
    this.details,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      userId: json['userId'],
      action: AuditAction.values.firstWhere((e) => e.name == json['action']),
      entityId: json['entityId'],
      entityType: json['entityType'],
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action.name,
    'entityId': entityId,
    'entityType': entityType,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };
}
