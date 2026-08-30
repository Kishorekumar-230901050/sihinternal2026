import 'i_notification_repository.dart';
import '../models/notification_model.dart';
import '../mock/mock_data.dart';
import '../../services/api_client.dart';

class BackendNotificationRepository implements INotificationRepository {
  final ApiClient apiClient;

  BackendNotificationRepository({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotificationsForOfficer(String officerId) async {
    return MockDataStore.notifications.where((n) => n.userId == officerId).toList();
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
      if (MockDataStore.notifications[i].userId == officerId) {
        MockDataStore.notifications[i] = MockDataStore.notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  int getUnreadCount(String officerId) {
    return MockDataStore.notifications.where((n) => n.userId == officerId && !n.isRead).length;
  }
}
