import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/config/api_config.dart';
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
    final verifyUrl = cert.qrToken != null ? ApiConfig.publicVerifyQr(cert.qrToken!) : null;

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
                    if (verifyUrl != null) ...[
                      QrImageView(
                        data: verifyUrl,
                        version: QrVersions.auto,
                        size: 180,
                        gapless: true,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        verifyUrl,
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                        textAlign: TextAlign.center,
                      ),
                    ] else
                      const Text('QR unavailable — certificate details still syncing.',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint)),
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

            if (cert.pdfUrl != null)
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Certificate PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      SelectableText(cert.pdfUrl!, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Open this link in a browser to view or download the signed PDF.',
                          style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ),
              )
            else
              const Text('Certificate PDF is still being generated.', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
