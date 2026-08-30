import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/common/demo_role_banner.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<VendorProvider>().loadAll(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final vendor = context.watch<VendorProvider>();
    final alerts = vendor.expiryAlerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.pushNamed(AppRoutes.vendorProfile),
          ),
        ],
      ),
      body: Stack(
        children: [
          vendor.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    if (user != null) await vendor.loadAll(user.id);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Welcome card ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user?.name ?? 'Vendor'}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (user?.businessName != null)
                              Text(
                                user!.businessName!,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${user?.district ?? 'Mumbai'}, ${user?.state ?? 'Maharashtra'} • GST: ${user?.gstNumber ?? '27AAAAA0000A1Z5'}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Automatic Expiry Alerts (Bible Page 1 Item 11: "Automatic Alert: 30, 7, 2, 1 Days before due date") ──
                      if (alerts.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.notification_important, color: AppColors.saffron, size: 20),
                            const SizedBox(width: 6),
                            Text('Re-verification Expiry Alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.saffron)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...alerts.map((alert) {
                          final isCritical = alert.daysLeft <= 2;
                          final color = isCritical ? AppColors.error : alert.daysLeft <= 7 ? AppColors.saffron : AppColors.warning;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: color.withOpacity(0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.alarm, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${alert.alertLevel} — ${alert.cert.certificateNumber}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                                        ),
                                        Text(
                                          'Valid Until: ${DateFormatter.formatDate(alert.cert.validUntil)} (${alert.daysLeft} days left)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bible Page 1 Item 12: "Reverification"
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      vendor.startReverificationForCertificate(alert.cert);
                                      context.pushNamed(AppRoutes.vendorApplyVerification);
                                    },
                                    child: const Text('RE-VERIFY'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // ── Stats cards ──
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.precision_manufacturing,
                            label: 'Instruments',
                            value: '${vendor.instruments.length}',
                            color: AppColors.vendorAccent,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.assignment,
                            label: 'Active Apps',
                            value: '${vendor.activeApplicationsCount}',
                            color: AppColors.saffron,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.verified,
                            label: 'Valid Certs',
                            value: '${vendor.validCertificatesCount}',
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.warning_amber,
                            label: 'Expiring Soon',
                            value: '${vendor.expiringCertificatesCount}',
                            color: AppColors.warning,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Quick Actions ──
                      Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle,
                            label: 'Register\nInstrument',
                            color: AppColors.vendorAccent,
                            onTap: () => context.pushNamed(AppRoutes.vendorRegisterInstrument),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.assignment_add,
                            label: 'Apply for\nVerification',
                            color: AppColors.secondary,
                            onTap: () {
                              vendor.resetWizard();
                              context.pushNamed(AppRoutes.vendorApplyVerification);
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.folder_open,
                            label: 'My\nApplications',
                            color: AppColors.saffron,
                            onTap: () => context.pushNamed(AppRoutes.vendorMyApplications),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.card_membership,
                            label: 'Certificate\nWallet',
                            color: AppColors.primary,
                            onTap: () => context.pushNamed(AppRoutes.vendorCertificateWallet),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── My Instruments ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('My Instruments', style: Theme.of(context).textTheme.headlineSmall),
                          TextButton(
                            onPressed: () => context.pushNamed(AppRoutes.vendorMyInstruments),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...vendor.instruments.take(3).map((inst) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.vendorAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.precision_manufacturing, color: AppColors.vendorAccent, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    inst.type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(inst.effectiveUniqueId, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              subtitle: Text('${inst.manufacturer} ${inst.model}\nS/N: ${inst.serialNumber}',
                                  style: const TextStyle(fontSize: 12)),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.pushNamed(
                                AppRoutes.vendorInstrumentDetails,
                                pathParameters: {'id': inst.instrumentId},
                              ),
                            ),
                          )),

                      const SizedBox(height: 16),

                      // ── Recent Applications ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Applications', style: Theme.of(context).textTheme.headlineSmall),
                          TextButton(
                            onPressed: () => context.pushNamed(AppRoutes.vendorMyApplications),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...vendor.applications.take(3).map((app) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _statusIcon(app.status.name),
                              title: Text(app.id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${app.statusLabel} • ${DateFormatter.formatDate(app.updatedAt)}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                vendor.setCurrentApplication(app);
                                context.pushNamed(
                                  AppRoutes.vendorApplicationTracking,
                                  pathParameters: {'id': app.id},
                                );
                              },
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

  Widget _statusIcon(String status) {
    Color color;
    IconData icon;
    if (status.contains('certificate') || status.contains('passed') || status.contains('departmentApproved')) {
      color = AppColors.secondary;
      icon = Icons.check_circle;
    } else if (status.contains('rejected') || status.contains('reupload')) {
      color = AppColors.error;
      icon = Icons.cancel;
    } else if (status.contains('inspection') || status.contains('scheduled')) {
      color = AppColors.vendorAccent;
      icon = Icons.schedule;
    } else {
      color = AppColors.warning;
      icon = Icons.hourglass_bottom;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
