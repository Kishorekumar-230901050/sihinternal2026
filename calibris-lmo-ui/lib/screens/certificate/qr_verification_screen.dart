import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/i_certificate_service.dart';
import '../../data/models/certificate_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';

class QrVerificationScreen extends StatelessWidget {
  final String certId;
  const QrVerificationScreen({super.key, required this.certId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Certificate Verification'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.dashboard);
              }
            },
          ),
        ),
      body: FutureBuilder<CertificateModel?>(
        future: context.read<ICertificateService>().getCertificate(certId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cert = snapshot.data;
          if (cert == null) {
            return const Center(child: Text('Certificate not found'));
          }

          final isValid = cert.status == CertificateStatus.active && !DateFormatter.isExpired(cert.validUntil);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: isValid ? AppColors.secondary : AppColors.error,
                child: Text(
                  isValid ? 'VALID CERTIFICATE' : 'EXPIRED / INVALID',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: QrImageView(
                  data: '${AppConstants.baseUrl}/verify/${cert.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Scan to verify certificate authenticity', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('Certificate ID', cert.certificateNumber),
                      _buildRow('Instrument ID', cert.instrumentId),
                      _buildRow('Status', cert.status.name.toUpperCase()),
                      _buildRow('Issue Date', DateFormatter.formatDate(cert.issuedAt)),
                      _buildRow('Valid Until', DateFormatter.formatDate(cert.validUntil)),
                      _buildRow('Re-Verification Due', DateFormatter.formatDate(cert.reverificationDue)),
                      _buildRow('Issued By', cert.officerId),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate sharing will be available in production')));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generation will be available in production')));
                      },
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
