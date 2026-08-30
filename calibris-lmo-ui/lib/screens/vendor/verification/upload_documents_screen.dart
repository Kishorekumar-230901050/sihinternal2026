import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/vendor_provider.dart';
import '../../../data/repositories/i_vendor_repository.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class _UploadedFileInfo {
  final String slotType;
  final String title;
  final String subtitle;
  final IconData icon;
  String? fileName;
  int? fileSizeBytes;
  String? uploadedUrl;
  bool isUploading;

  _UploadedFileInfo({
    required this.slotType,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.fileName,
    this.fileSizeBytes,
    this.uploadedUrl,
    this.isUploading = false,
  });
}

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final List<_UploadedFileInfo> _slots = [
    _UploadedFileInfo(
      slotType: 'SUPPORTING_DOCUMENT',
      title: 'Purchase Invoice / Bill of Sale (PDF)',
      subtitle: 'Original purchase receipt or invoice with GST details',
      icon: Icons.receipt_long,
    ),
    _UploadedFileInfo(
      slotType: 'SUPPORTING_DOCUMENT',
      title: 'Model Approval Certificate (PDF)',
      subtitle: 'Issued by Legal Metrology Department (Directorate)',
      icon: Icons.verified_user,
    ),
    _UploadedFileInfo(
      slotType: 'INSTRUMENT_PHOTO',
      title: 'Instrument Photo with Serial Plate',
      subtitle: 'Clear front photo showing manufacturer label & serial no.',
      icon: Icons.camera_alt,
    ),
  ];

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUploadFile(_UploadedFileInfo slot) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final fileBytes = file.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data. Please try again.')),
          );
        }
        return;
      }

      setState(() {
        slot.isUploading = true;
        slot.fileName = file.name;
        slot.fileSizeBytes = file.size;
      });

      final vendorProvider = context.read<VendorProvider>();
      final vendorRepo = context.read<IVendorRepository>();
      final appId = vendorProvider.currentApplication?.id ?? 'VAPP-PENDING';

      // Real upload to backend / Supabase storage
      final uploadedUrl = await vendorRepo.uploadDocument(
        applicationId: appId,
        fileName: file.name,
        fileBytes: fileBytes,
        documentType: slot.slotType,
      );

      if (mounted) {
        setState(() {
          slot.isUploading = false;
          slot.uploadedUrl = uploadedUrl;
        });

        vendorProvider.addUploadedDocument(file.name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${file.name} uploaded successfully!')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => slot.isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Upload failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final anyUploaded = _slots.any((s) => s.fileName != null) || vendor.uploadedDocuments.isNotEmpty;

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
              child: const Text(
                'Step 2 of 5 — Upload Document & Photo',
                style: TextStyle(color: AppColors.vendorAccent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your actual PDF documents or photos. Files are securely uploaded to backend storage.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _slots.length,
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  final isUploaded = slot.fileName != null;

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

                          if (slot.isUploading) ...[
                            const Row(
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Uploading to backend storage...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                              ],
                            ),
                          ] else if (isUploaded) ...[
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot.fileName!,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (slot.fileSizeBytes != null)
                                          Text(
                                            'Size: ${_formatSize(slot.fileSizeBytes!)} • Verified',
                                            style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _pickAndUploadFile(slot),
                                    child: const Text('Change File', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: const Text('Choose PDF / Photo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () => _pickAndUploadFile(slot),
                                ),
                              ],
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
                onPressed: anyUploaded
                    ? () => context.pushNamed(AppRoutes.vendorFindGatc)
                    : null,
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
