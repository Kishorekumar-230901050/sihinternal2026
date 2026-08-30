import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/i_notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationRepository _repository;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider(this._repository);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String officerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotificationsForOfficer(officerId);
      // Sort by date descending
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String officerId) async {
    await _repository.markAllAsRead(officerId);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
