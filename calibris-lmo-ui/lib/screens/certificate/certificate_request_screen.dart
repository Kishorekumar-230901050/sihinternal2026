import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../services/i_certificate_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';

class CertificateRequestScreen extends StatefulWidget {
  const CertificateRequestScreen({super.key});

  @override
  State<CertificateRequestScreen> createState() => _CertificateRequestScreenState();
}

class _CertificateRequestScreenState extends State<CertificateRequestScreen> {
  bool _isSubmitting = false;

  void _submit() async {
    setState(() => _isSubmitting = true);
    
    final app = context.read<ApplicationProvider>().selectedApplication;
    final insp = context.read<InspectionProvider>().currentInspection;
    final certService = context.read<ICertificateService>();

    if (app == null || insp == null) return;

    try {
      final certId = await certService.submitForCertification(
        applicationId: app.id,
        instrumentId: app.instrumentId,
        inspectionId: insp.id,
        applicantId: app.applicantId,
        officerId: insp.officerId,
        verificationDate: DateTime.now(),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: Text('Certificate generation requested successfully.\nID: $certId'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pushReplacementNamed(AppRoutes.qrVerification, pathParameters: {'certId': certId});
                },
                child: const Text('View QR Certificate'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<ApplicationProvider>().selectedApplication;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_turned_in, size: 64, color: AppColors.secondary),
                    const SizedBox(height: 16),
                    const Text('Ready for Certification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Application ID: ${app?.id}'),
                    Text('Instrument ID: ${app?.instrumentId}'),
                    const SizedBox(height: 24),
                    const Text('Proposed Validity: 12 months from today', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This will submit the verification result to the Certificate Authority module for official certificate generation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('SUBMIT FOR CERTIFICATE GENERATION'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting ? null : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(AppRoutes.dashboard);
                }
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
