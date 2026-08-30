import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../data/models/application_model.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/info_row.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().selectApplication(widget.applicationId);
    });
  }

  void _showRejectDialog(BuildContext context, ApplicationProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await provider.rejectApplication(widget.applicationId, controller.text);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context, ApplicationProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Correction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Notes for correction'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await provider.requestCorrection(widget.applicationId, controller.text);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final app = provider.selectedApplication;

    if (provider.isLoading || app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.applicationList);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(app.id),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.applicationList);
              }
            },
          ),
        ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  StatusBadge(status: app.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Applicant Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Applicant Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const Divider(),
                  InfoRow(label: 'Business Name', value: app.applicantInfo?.businessName ?? 'N/A'),
                  InfoRow(label: 'Contact Name', value: app.applicantInfo?.contactName ?? 'N/A'),
                  InfoRow(label: 'Phone', value: app.applicantInfo?.contactPhone ?? 'N/A'),
                  InfoRow(label: 'Address', value: '${app.applicantInfo?.address}, ${app.applicantInfo?.city}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instrument Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Instrument Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const Divider(),
                  InfoRow(label: 'Type', value: app.instrumentInfo?.type.name ?? 'N/A'),
                  InfoRow(label: 'Manufacturer', value: app.instrumentInfo?.manufacturer ?? 'N/A'),
                  InfoRow(label: 'Model / Serial', value: '${app.instrumentInfo?.model} / ${app.instrumentInfo?.serialNumber}'),
                  InfoRow(label: 'Capacity', value: app.instrumentInfo?.capacity ?? 'N/A'),
                  if (app.instrumentInfo?.isDigitalCompatible == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.wifi, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Digital Compatible', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Documents Action
          ListTile(
            tileColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: const Text('View Documents'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.pushNamed(AppRoutes.documentReview, pathParameters: {'id': app.id});
            },
          ),
          const SizedBox(height: 24),

          // Actions based on status
          if (app.status == ApplicationStatus.submitted || app.status == ApplicationStatus.underReview) ...[
            ElevatedButton(
              onPressed: () => provider.approveForVerification(app.id),
              child: const Text('Approve for Verification'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _showCorrectionDialog(context, provider),
              child: const Text('Request Correction'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showRejectDialog(context, provider),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Reject Application'),
            ),
          ] else if (app.status == ApplicationStatus.approvedForVerification) ...[
            ElevatedButton(
              onPressed: () => context.pushNamed(AppRoutes.verificationMode, pathParameters: {'id': app.id}),
              child: const Text('Proceed to Verification'),
            ),
          ]
        ],
      ),
    ),
    );
  }
}
