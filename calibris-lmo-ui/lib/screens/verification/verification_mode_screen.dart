import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/instrument_model.dart';

class VerificationModeScreen extends StatelessWidget {
  final String applicationId;
  const VerificationModeScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<ApplicationProvider>().selectedApplication;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign Verification Mode')),
        body: const Center(child: Text('Application not found')),
      );
    }

    final isWeighbridge = app.instrumentInfo?.type == InstrumentType.platformWeighbridge;
    final isDigitalCompatible = app.instrumentInfo?.isDigitalCompatible ?? !isWeighbridge;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Verification Mode & Slot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Application Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Application: ${app.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isWeighbridge ? AppColors.saffron.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isWeighbridge ? 'WEIGHBRIDGE' : 'SMALL DEVICE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isWeighbridge ? AppColors.saffron : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Instrument: ${app.instrumentInfo?.manufacturer ?? ""} ${app.instrumentInfo?.model ?? (app.instrumentInfo?.type.name ?? "Scale")}'),
                  Text('Applicant: ${app.applicantInfo?.contactName ?? ""} (${app.applicantInfo?.businessName ?? ""})'),
                  Text('Location: ${app.applicantInfo?.address ?? ""}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bible Step 4 Directive Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isWeighbridge ? AppColors.saffron.withOpacity(0.08) : AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isWeighbridge ? AppColors.saffron.withOpacity(0.3) : AppColors.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isWeighbridge ? Icons.scale : Icons.devices,
                  color: isWeighbridge ? AppColors.saffron : AppColors.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWeighbridge
                            ? 'Bible Rule: Platform Weighbridge Inspection'
                            : 'Bible Rule: Small Device Digital Inspection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isWeighbridge ? AppColors.saffron : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isWeighbridge
                            ? 'Platform weighbridges require mandatory offline field inspection with standard test load weights at site.'
                            : 'Small devices support online digital verification via Ethernet IoT tamper monitoring.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Option 1: Digital Verification through Ethernet (Bible Page 2 Item 4 & 5(i)) ──
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: !isWeighbridge && isDigitalCompatible ? AppColors.secondary : AppColors.border,
                width: !isWeighbridge && isDigitalCompatible ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_ethernet, color: AppColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Digital Verification (Online / Ethernet)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Luckfox Firmware IoT • Zero-Contact Tamper Audit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LMO verifies live Ethernet connection, enclosure tamper status, and calibration stream without physical travel.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('ASSIGN & START DIGITAL VERIFICATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      onPressed: () async {
                        final officerId = context.read<AuthProvider>().currentUser?.id ?? '';
                        await context.read<InspectionProvider>().startInspection(applicationId, officerId, VerificationMode.digital);
                        if (context.mounted) {
                          context.pushNamed(AppRoutes.digitalVerification, pathParameters: {'id': applicationId});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Option 2: Offline / Field Verification (Bible Page 2 Item 4 & 5(ii)) ──
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isWeighbridge ? AppColors.primary : AppColors.border,
                width: isWeighbridge ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_location_alt, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offline Field Verification (On-Site)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Physical Visit • Geotagged Photo Inspection', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Officer visits applicant premises, runs standard weight test suite, and uploads mandatory geotagged photo proof.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('ASSIGN & START FIELD INSPECTION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () async {
                        final officerId = context.read<AuthProvider>().currentUser?.id ?? '';
                        await context.read<InspectionProvider>().startInspection(applicationId, officerId, VerificationMode.field);
                        if (context.mounted) {
                          context.pushNamed(AppRoutes.fieldVerification, pathParameters: {'id': applicationId});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
