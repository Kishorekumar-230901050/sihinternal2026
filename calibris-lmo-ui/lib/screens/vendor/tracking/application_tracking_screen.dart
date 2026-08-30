import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/vendor_application_model.dart';
import '../../../widgets/common/status_stepper.dart';
import '../../../widgets/common/info_row.dart';

class ApplicationTrackingScreen extends StatelessWidget {
  final String applicationId;
  const ApplicationTrackingScreen({super.key, required this.applicationId});

  static const _bibleSteps = [
    '1. Application & Documents Submitted',
    '2. LMO Document Verification',
    '3. Online Fee Payment',
    '4. GATC Slot & Method Assigned',
    '5. LMO Officer Inspection',
    '6. Inspection Completed (PASS / FAIL)',
    '7. Department Approval',
    '8. Digitally Signed Certificate + QR',
  ];

  int _currentStep(VendorApplicationStatus status) {
    switch (status) {
      case VendorApplicationStatus.draft:
      case VendorApplicationStatus.submitted:
        return 0;
      case VendorApplicationStatus.documentReview:
      case VendorApplicationStatus.reuploadRequested:
        return 1;
      case VendorApplicationStatus.paymentPending:
        return 2;
      case VendorApplicationStatus.paymentComplete:
      case VendorApplicationStatus.scheduled:
        return 3;
      case VendorApplicationStatus.lmoAssigned:
        return 4;
      case VendorApplicationStatus.inspectionInProgress:
        return 4;
      case VendorApplicationStatus.passed:
        return 5;
      case VendorApplicationStatus.departmentApproved:
        return 6;
      case VendorApplicationStatus.certificateIssued:
        return 8; // complete
      case VendorApplicationStatus.rejected:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final app = vendor.applications.where((a) => a.id == applicationId).firstOrNull ?? vendor.currentApplication;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Application')),
        body: const Center(child: Text('Application not found.')),
      );
    }

    final step = _currentStep(app.status);
    final isRejected = app.status == VendorApplicationStatus.rejected;
    final isReupload = app.status == VendorApplicationStatus.reuploadRequested;
    final isComplete = app.status == VendorApplicationStatus.certificateIssued;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${app.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: () {
              final userId = context.read<AuthProvider>().currentUser?.id;
              if (userId != null) context.read<VendorProvider>().loadAll(userId);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRejected || isReupload
                  ? AppColors.error.withOpacity(0.08)
                  : isComplete
                      ? AppColors.secondary.withOpacity(0.08)
                      : AppColors.vendorAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRejected || isReupload
                    ? AppColors.error.withOpacity(0.3)
                    : isComplete
                        ? AppColors.secondary.withOpacity(0.3)
                        : AppColors.vendorAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isRejected
                      ? Icons.cancel
                      : isReupload
                          ? Icons.warning_amber_rounded
                          : isComplete
                              ? Icons.verified
                              : Icons.track_changes,
                  color: isRejected || isReupload
                      ? AppColors.error
                      : isComplete
                          ? AppColors.secondary
                          : AppColors.vendorAccent,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isRejected || isReupload
                              ? AppColors.error
                              : isComplete
                                  ? AppColors.secondary
                                  : AppColors.vendorAccent,
                        ),
                      ),
                      Text('Updated: ${DateFormatter.formatDateTime(app.updatedAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Re-upload Requested Notice (Bible Page 2 Item 3: "If not correct -> reject / reupload") ──
          if (isReupload) ...[
            Card(
              color: AppColors.error.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('LMO Officer Action Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app.reuploadReason ?? 'One or more uploaded documents were rejected by the reviewing officer.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload, size: 18),
                      label: const Text('RE-UPLOAD DOCUMENTS NOW'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        context.pushNamed(AppRoutes.vendorApplyUploadDocs);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Application Summary Card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const Divider(),
                  InfoRow(label: 'Application ID', value: app.id),
                  InfoRow(label: 'Type', value: app.isReverification ? 'Re-verification' : 'Initial Verification'),
                  InfoRow(
                    label: 'Method',
                    value: app.verificationMethod == VerificationMethod.digitalEthernet
                        ? 'Digital (Ethernet IoT)'
                        : 'Manual (GATC / Field)',
                  ),
                  if (app.instrumentInfo != null) ...[
                    InfoRow(label: 'Instrument UID', value: app.instrumentInfo!.effectiveUniqueId),
                    InfoRow(label: 'Serial Number', value: app.instrumentInfo!.serialNumber),
                  ],
                  if (app.gatcName != null) InfoRow(label: 'Assigned GATC', value: app.gatcName!),
                  if (app.slotDate != null) InfoRow(label: 'Appointment', value: '${DateFormatter.formatDate(app.slotDate!)} • ${app.slotTime ?? ""}'),
                  if (app.assignedLmoName != null) InfoRow(label: 'Assigned LMO', value: app.assignedLmoName!),
                  if (app.feeInPaise != null) InfoRow(label: 'Fee Amount', value: '₹${(app.feeInPaise! / 100).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Bible Lifecycle Timeline ──
          if (!isRejected) ...[
            const Text('Official Verification Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 16),
            StatusStepper(steps: _bibleSteps, currentStep: step),
          ],

          // ── Rejection Notice ──
          if (isRejected && app.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.error.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rejection Notice & Reasons', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                    const SizedBox(height: 8),
                    Text(app.rejectionReason!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.pushNamed(AppRoutes.vendorApplyVerification),
                      child: const Text('Apply for Re-verification'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Signed Certificate Download (Bible Page 1 Item 9 & 10) ──
          if (isComplete && app.certificateId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('Department Approval Granted', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Digitally signed verification certificate with QR code is ready in your wallet.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.card_membership),
                      label: const Text('VIEW SIGNED CERTIFICATE + QR'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      onPressed: () => context.pushNamed(
                        AppRoutes.vendorCertificateDetails,
                        pathParameters: {'id': app.certificateId!},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
