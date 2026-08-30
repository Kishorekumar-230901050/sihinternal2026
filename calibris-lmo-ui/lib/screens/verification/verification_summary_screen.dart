import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inspection_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/inspection_model.dart';
import '../../widgets/common/info_row.dart';

class VerificationSummaryScreen extends StatelessWidget {
  final String inspectionId;
  const VerificationSummaryScreen({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    final insp = context.watch<InspectionProvider>().currentInspection;
    
    if (insp == null || insp.id != inspectionId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification Summary')),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    final isPass = insp.result == InspectionResult.pass;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(AppRoutes.dashboard);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inspection Result & Approval'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed(AppRoutes.dashboard),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner (Bible Page 1 Item 9 & Page 2 Item 6/7)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPass ? AppColors.secondary : AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isPass ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'FINAL VERDICT: ${isPass ? "PASS" : "FAIL"}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPass
                        ? 'Bible Rule: PASS ➔ Department Approval ➔ Signed Certificate + QR'
                        : 'Bible Rule: FAIL ➔ Official Rejection Notice ➔ Re-verification Required',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inspection Audit Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const Divider(),
                    InfoRow(label: 'Application ID', value: insp.applicationId),
                    InfoRow(label: 'Inspecting Officer', value: insp.officerName),
                    InfoRow(label: 'Verification Mode', value: insp.mode == VerificationMode.digital ? 'Digital (Ethernet IoT)' : 'Field (On-Site Geotag)'),
                    InfoRow(label: 'Audit Timestamp', value: insp.inspectedAt != null ? DateFormatter.formatDateTime(insp.inspectedAt!) : 'N/A'),
                    if (insp.withinGeofence != null)
                      InfoRow(label: 'GPS Geofence', value: insp.withinGeofence! ? 'Verified (Within range)' : 'Out of range'),
                    InfoRow(label: 'Tamper Audit', value: insp.tamperDetected ? 'CRITICAL TAMPER DETECTED' : 'CLEAR / INTACT'),
                    if (insp.observations != null && insp.observations!.isNotEmpty)
                      InfoRow(label: 'Observations', value: insp.observations!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (!isPass && insp.failureReason != null)
              Card(
                color: AppColors.error.withOpacity(0.08),
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
                          Icon(Icons.warning, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Rejection Details & Remedial Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(insp.failureReason!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text(
                        'The applicant has been notified and given remedial instructions to service the instrument and apply for re-verification.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: 24),
            
            if (isPass) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  context.pushNamed(AppRoutes.certificateRequest);
                },
                label: const Text('DEPARTMENT APPROVAL ➔ GENERATE SIGNED CERTIFICATE + QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.goNamed(AppRoutes.dashboard),
                child: const Text('Return to LMO Dashboard'),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rejection notice officially recorded and dispatched.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  context.goNamed(AppRoutes.dashboard);
                },
                label: const Text('CONFIRM REJECTION & NOTIFY APPLICANT'),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
