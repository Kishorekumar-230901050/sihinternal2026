import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/common/info_row.dart';

class CertificateDetailsScreen extends StatelessWidget {
  final String certificateId;
  const CertificateDetailsScreen({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context) {
    final certs = context.watch<VendorProvider>().certificates;
    final cert = certs.where((c) => c.id == certificateId).firstOrNull;

    if (cert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificate')),
        body: const Center(child: Text('Certificate not found.')),
      );
    }

    final isActive = cert.status.name == 'active';

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Certificate card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [AppColors.secondary, const Color(0xFF047857)]
                      : [AppColors.error, const Color(0xFF991B1B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('VERIFICATION CERTIFICATE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(cert.certificateNumber, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'VALID' : cert.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── QR Code ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Scan to Verify', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: 'https://verify.calibris.gov.in/c/${cert.id}',
                      version: QrVersions.auto,
                      size: 180,
                      gapless: true,
                      embeddedImage: null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'https://verify.calibris.gov.in/c/${cert.id}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Details ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Certificate Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const Divider(),
                    InfoRow(label: 'Certificate No.', value: cert.certificateNumber),
                    InfoRow(label: 'Application', value: cert.applicationId),
                    InfoRow(label: 'Instrument', value: cert.instrumentId),
                    InfoRow(label: 'Issued On', value: DateFormatter.formatDate(cert.issuedAt)),
                    InfoRow(label: 'Valid Until', value: DateFormatter.formatDate(cert.validUntil)),
                    InfoRow(label: 'Re-verification Due', value: DateFormatter.formatDate(cert.reverificationDue)),
                    InfoRow(label: 'Status', value: cert.status.name.toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD CERTIFICATE PDF'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF download simulated (demo mode)')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
