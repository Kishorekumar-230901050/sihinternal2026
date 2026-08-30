import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/vendor_application_model.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final apps = vendor.applications;

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: apps.isEmpty
          ? const Center(child: Text('No applications yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _ApplicationCard(
                  app: app,
                  onTap: () {
                    vendor.setCurrentApplication(app);
                    context.pushNamed(
                      AppRoutes.vendorApplicationTracking,
                      pathParameters: {'id': app.id},
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final VendorApplicationModel app;
  final VoidCallback onTap;

  const _ApplicationCard({required this.app, required this.onTap});

  Color _statusColor(VendorApplicationStatus status) {
    switch (status) {
      case VendorApplicationStatus.certificateIssued:
      case VendorApplicationStatus.passed:
        return AppColors.secondary;
      case VendorApplicationStatus.rejected:
        return AppColors.error;
      case VendorApplicationStatus.inspectionInProgress:
      case VendorApplicationStatus.scheduled:
      case VendorApplicationStatus.lmoAssigned:
        return AppColors.vendorAccent;
      case VendorApplicationStatus.paymentPending:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(app.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(app.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(app.statusLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (app.instrumentInfo != null)
                Text(
                  '${app.instrumentInfo!.type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim()} — ${app.instrumentInfo!.serialNumber}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (app.gatcName != null) ...[
                    const Icon(Icons.location_city, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(app.gatcName!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.access_time, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDate(app.updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
