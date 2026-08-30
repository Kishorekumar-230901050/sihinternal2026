import 'i_notification_repository.dart';
import '../models/notification_model.dart';
import '../mock/mock_data.dart';

class MockNotificationRepository implements INotificationRepository {
  @override
  Future<List<NotificationModel>> getNotificationsForOfficer(String officerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataStore.notifications.where((n) => n.officerId == officerId).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = MockDataStore.notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      MockDataStore.notifications[index] = MockDataStore.notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String officerId) async {
    for (int i = 0; i < MockDataStore.notifications.length; i++) {
      if (MockDataStore.notifications[i].officerId == officerId) {
        MockDataStore.notifications[i] = MockDataStore.notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  int getUnreadCount(String officerId) {
    return MockDataStore.notifications.where((n) => n.officerId == officerId && !n.isRead).length;
  }
}
