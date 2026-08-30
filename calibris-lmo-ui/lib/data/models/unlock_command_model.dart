class UnlockCommandModel {
  final int id;
  final String deviceId;
  final String officerId;
  final String? officerName;
  final String? officerEmail;
  final String? officerRole;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime? executedAt;

  const UnlockCommandModel({
    required this.id,
    required this.deviceId,
    required this.officerId,
    this.officerName,
    this.officerEmail,
    this.officerRole,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.executedAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isExecuted => status.toLowerCase() == 'executed';
  bool get isExpired => status.toLowerCase() == 'expired' || status.toLowerCase() == 'expired_by_tamper';

  factory UnlockCommandModel.fromJson(Map<String, dynamic> json) {
    return UnlockCommandModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      deviceId: json['device_id']?.toString() ?? '',
      officerId: json['officer_id']?.toString() ?? '',
      officerName: json['officer_name']?.toString(),
      officerEmail: json['officer_email']?.toString(),
      officerRole: json['officer_role']?.toString(),
      reason: json['reason']?.toString() ?? 'Remote unlock via dashboard',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      executedAt: json['executed_at'] != null 
          ? DateTime.tryParse(json['executed_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'officer_id': officerId,
    'officer_name': officerName,
    'officer_email': officerEmail,
    'officer_role': officerRole,
    'reason': reason,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'executed_at': executedAt?.toIso8601String(),
  };
}
