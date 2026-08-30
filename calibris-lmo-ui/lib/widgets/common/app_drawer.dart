import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(user?.name ?? 'Guest'),
            accountEmail: Text('${user?.employeeId ?? ""} | ${user?.district ?? ""}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              if (GoRouterState.of(context).matchedLocation != '/dashboard') {
                context.goNamed(AppRoutes.dashboard);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Applications'),
            onTap: () {
              Navigator.pop(context);
              if (GoRouterState.of(context).matchedLocation != '/applications') {
                context.pushNamed(AppRoutes.applicationList);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              if (GoRouterState.of(context).matchedLocation != '/notifications') {
                context.pushNamed(AppRoutes.notifications);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              if (GoRouterState.of(context).matchedLocation != '/profile') {
                context.pushNamed(AppRoutes.profile);
              }
            },
          ),
          const Divider(),
          const Spacer(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              context.read<AuthProvider>().logout();
              context.goNamed(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
