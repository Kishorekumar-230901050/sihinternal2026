import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/application_model.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/application_card.dart';
import '../../widgets/common/demo_role_banner.dart';

class LmoDashboardScreen extends StatefulWidget {
  const LmoDashboardScreen({super.key});

  @override
  State<LmoDashboardScreen> createState() => _LmoDashboardScreenState();
}

class _LmoDashboardScreenState extends State<LmoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ApplicationProvider>().loadApplications(user.id);
        context.read<NotificationProvider>().loadNotifications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final appProvider = context.watch<ApplicationProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    if (user == null) return const Scaffold();

    final allApps = appProvider.applications;
    final newAppsCount = allApps.where((a) => a.status == ApplicationStatus.submitted).length;
    final pendingReviewCount = allApps.where((a) => a.status == ApplicationStatus.underReview).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LMO Dashboard'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => context.pushNamed(AppRoutes.notifications),
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProvider.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: GestureDetector(
              onTap: () => context.pushNamed(AppRoutes.profile),
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          appProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<ApplicationProvider>().loadApplications(user.id);
                    await context.read<NotificationProvider>().loadNotifications(user.id);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user.name}', 
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Officer ID: ${user.employeeId} | District: ${user.district}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'New Applications',
                              count: newAppsCount.toString(),
                              icon: Icons.description,
                              color: Colors.blue,
                              onTap: () => context.pushNamed(AppRoutes.applicationList),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Pending Review',
                              count: pendingReviewCount.toString(),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              onTap: () => context.pushNamed(AppRoutes.applicationList),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Inspections Today',
                              count: '2',
                              icon: Icons.verified,
                              color: Colors.green,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Expiring Soon',
                              count: '5',
                              icon: Icons.warning,
                              color: Colors.red,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Recent Applications',
                        actionLabel: 'View All',
                        onAction: () => context.pushNamed(AppRoutes.applicationList),
                      ),
                      const SizedBox(height: 8),
                      if (allApps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No applications found.', textAlign: TextAlign.center),
                        )
                      else
                        ...allApps.take(5).map((app) => ApplicationCard(
                          application: app,
                          onTap: () => context.pushNamed(AppRoutes.applicationDetails, pathParameters: {'id': app.id}),
                        )),
                      
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Recent Notifications',
                        actionLabel: 'View All',
                        onAction: () => context.pushNamed(AppRoutes.notifications),
                      ),
                      const SizedBox(height: 8),
                      if (notifProvider.notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No notifications.', textAlign: TextAlign.center),
                        )
                      else
                        ...notifProvider.notifications.take(3).map((notif) => Card(
                          child: ListTile(
                            leading: Icon(Icons.info, color: notif.isRead ? Colors.grey : AppColors.primary),
                            title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(notif.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          const DemoRoleBanner(),
        ],
      ),
    );
  }
}
