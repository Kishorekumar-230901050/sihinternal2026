import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/audit_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold();

    final auditLogs = AuditService().getLogs(userId: user.id).take(5).toList();

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
          title: const Text('My Profile'),
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
        ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(user.name.substring(0, 1), style: const TextStyle(fontSize: 40, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user.employeeId, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const Divider(),
                  ListTile(title: const Text('Name'), subtitle: Text(user.name)),
                  ListTile(title: const Text('Employee ID'), subtitle: Text(user.employeeId)),
                  ListTile(title: const Text('District'), subtitle: Text(user.district)),
                  ListTile(title: const Text('Role'), subtitle: Text(user.role.name.toUpperCase())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const Divider(),
                  if (auditLogs.isEmpty)
                    const Text('No recent activity')
                  else
                    ...auditLogs.map((log) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(log.action.name),
                      subtitle: Text(DateFormatter.formatDateTime(log.timestamp)),
                      trailing: log.entityId != null ? Text(log.entityId!, style: const TextStyle(fontSize: 10)) : null,
                    )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Change Password'),
                  content: const Text('Password change will be available in production version'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                ),
              );
            },
            child: const Text('Change Password'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.goNamed(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    ),
    );
  }
}
