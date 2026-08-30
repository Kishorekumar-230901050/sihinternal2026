import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final List<({String type, String title, String subtitle, String? fileName, IconData icon})> _docSlots = [
    (
      type: 'invoice',
      title: 'Purchase Invoice / Bill of Sale',
      subtitle: 'Original purchase receipt or invoice with GST details',
      fileName: 'Invoice_2026_ABC_Traders.pdf',
      icon: Icons.receipt_long,
    ),
    (
      type: 'modelApproval',
      title: 'Model Approval Certificate',
      subtitle: 'Issued by Legal Metrology Department (Directorate)',
      fileName: 'Model_Approval_Cert_IndGov.pdf',
      icon: Icons.verified_user,
    ),
    (
      type: 'instrumentPhoto',
      title: 'Instrument Photo with Serial Plate',
      subtitle: 'Clear front photo showing manufacturer label & serial no.',
      fileName: 'Instrument_Plate_Front.jpg',
      icon: Icons.camera_alt,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize provider with default demo documents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendor = context.read<VendorProvider>();
      for (final slot in _docSlots) {
        if (slot.fileName != null) {
          vendor.addUploadedDocument(slot.fileName!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents & Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vendorAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Step 2 of 5 — Upload Document & Photo',
                  style: TextStyle(color: AppColors.vendorAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload required documents and a geotagged photo of the instrument for LMO verification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _docSlots.length,
                itemBuilder: (context, index) {
                  final slot = _docSlots[index];
                  final isUploaded = slot.fileName != null && vendor.uploadedDocuments.contains(slot.fileName);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isUploaded ? AppColors.secondary.withOpacity(0.4) : AppColors.border,
                        width: isUploaded ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isUploaded
                                      ? AppColors.secondary.withOpacity(0.1)
                                      : AppColors.vendorAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  slot.icon,
                                  color: isUploaded ? AppColors.secondary : AppColors.vendorAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(slot.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(slot.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isUploaded) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slot.fileName!,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      vendor.removeUploadedDocument(slot.fileName!);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Document removed')),
                                      );
                                    },
                                    child: const Text('Change', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              icon: const Icon(Icons.file_upload_outlined, size: 18),
                              label: const Text('Upload File / Capture Photo'),
                              onPressed: () {
                                if (slot.fileName != null) {
                                  vendor.addUploadedDocument(slot.fileName!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${slot.title} uploaded successfully!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vendor.uploadedDocuments.isEmpty
                    ? null
                    : () => context.pushNamed(AppRoutes.vendorFindGatc),
                child: const Text('NEXT — Find Nearby GATC Centre'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
