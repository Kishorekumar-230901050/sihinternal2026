import '../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotificationsForOfficer(String officerId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String officerId);
  int getUnreadCount(String officerId);
}
