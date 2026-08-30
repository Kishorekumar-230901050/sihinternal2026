import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/certificate_model.dart';

class CertificateWalletScreen extends StatelessWidget {
  const CertificateWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final certs = context.watch<VendorProvider>().certificates;

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Wallet')),
      body: certs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_membership, size: 64, color: AppColors.textHint.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No certificates yet.', style: TextStyle(color: AppColors.textSecondary)),
                  const Text('Complete a verification to receive your first certificate.', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: certs.length,
              itemBuilder: (context, index) {
                final cert = certs[index];
                return _CertificateCard(
                  cert: cert,
                  onTap: () => context.pushNamed(
                    AppRoutes.vendorCertificateDetails,
                    pathParameters: {'id': cert.id},
                  ),
                );
              },
            ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel cert;
  final VoidCallback onTap;

  const _CertificateCard({required this.cert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = cert.status == CertificateStatus.active;
    final isExpired = cert.status == CertificateStatus.expired;
    final daysLeft = cert.validUntil.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isActive ? AppColors.secondary : isExpired ? AppColors.error : AppColors.warning,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cert.certificateNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.secondary.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : isExpired ? 'EXPIRED' : cert.status.name.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? AppColors.secondary : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Issued: ${DateFormatter.formatDate(cert.issuedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Valid Until: ${DateFormatter.formatDate(cert.validUntil)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (isActive && daysLeft <= 60) ...[
                const SizedBox(height: 6),
                Text('⚠ Expiring in $daysLeft days — Re-verification due', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
