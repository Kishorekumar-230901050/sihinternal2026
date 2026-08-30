import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final officerId = context.read<AuthProvider>().currentUser?.id ?? '';

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.dashboard);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark All Read',
              onPressed: () {
                notifProvider.markAllAsRead(officerId);
              },
            )
          ],
        ),
        body: notifProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifProvider.notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : RefreshIndicator(
                    onRefresh: () async {
                      await notifProvider.loadNotifications(officerId);
                    },
                    child: ListView.builder(
                      itemCount: notifProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifProvider.notifications[index];
                        return Material(
                          color: notif.isRead ? Colors.transparent : AppColors.surface,
                          child: ListTile(
                            leading: Icon(
                              notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: notif.isRead ? Colors.grey : AppColors.primary,
                            ),
                            title: Text(
                              notif.title,
                              style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notif.body),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatDateTime(notif.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!notif.isRead) {
                                notifProvider.markAsRead(notif.id);
                              }
                              if (notif.relatedApplicationId != null) {
                                context.pushNamed(AppRoutes.applicationDetails, pathParameters: {'id': notif.relatedApplicationId!});
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
