enum NotificationType {
  newApplication,
  correctionSubmitted,
  verificationScheduled,
  tamperAlert,
  attentionRequired,
  general
}

class NotificationModel {
  final String id;
  final String officerId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? relatedApplicationId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.officerId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.relatedApplicationId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      officerId: json['officerId'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      isRead: json['isRead'],
      relatedApplicationId: json['relatedApplicationId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'officerId': officerId,
    'title': title,
    'body': body,
    'type': type.name,
    'isRead': isRead,
    'relatedApplicationId': relatedApplicationId,
    'createdAt': createdAt.toIso8601String(),
  };

  NotificationModel copyWith({
    String? id,
    String? officerId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    String? relatedApplicationId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      officerId: officerId ?? this.officerId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedApplicationId: relatedApplicationId ?? this.relatedApplicationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
