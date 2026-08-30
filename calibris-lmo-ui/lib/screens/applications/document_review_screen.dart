import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class DocumentReviewScreen extends StatefulWidget {
  final String applicationId;
  const DocumentReviewScreen({super.key, required this.applicationId});

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  final _reuploadReasonController = TextEditingController(
    text: 'Model Approval Certificate is blurred and serial plate photo is unclear. Please re-upload high-resolution scans.',
  );

  @override
  void dispose() {
    _reuploadReasonController.dispose();
    super.dispose();
  }

  void _showReuploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: AppColors.error),
            SizedBox(width: 8),
            Text('Request Re-upload'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify reasons for document rejection so the applicant can re-upload correct files:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reuploadReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection / Re-upload Remarks',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Re-upload request sent to applicant.'),
                  backgroundColor: AppColors.error,
                ),
              );
              context.pop();
            },
            child: const Text('SUBMIT REJECTION'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<ApplicationProvider>().selectedApplication;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Review')),
        body: const Center(child: Text('Application not found')),
      );
    }

    final docs = app.documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Uploaded Documents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guidance banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.rule, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bible Step 3: Verify all documents uploaded by the applicant. If correct, approve to proceed with slot assignment. If not correct, reject / request re-upload.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Uploaded Verification Documents (${docs.length}):', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('No documents uploaded.'))
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final isPdf = doc.fileName.endsWith('.pdf');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isPdf ? AppColors.error.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPdf ? Icons.picture_as_pdf : Icons.image,
                                    color: isPdf ? AppColors.error : AppColors.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('Document Type: ${doc.type.name}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye, color: AppColors.primary),
                                  tooltip: 'Preview Document',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(doc.fileName),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified, size: 48, color: AppColors.primary),
                                            const SizedBox(height: 12),
                                            Text('Document Preview: ${doc.type.name} for ${app.instrumentInfo?.type.name ?? "Scale"}'),
                                            const SizedBox(height: 8),
                                            const Text('Document status: Legible & Signed', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── LMO Action Buttons (Bible Page 2 Item 3) ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                    label: const Text('REJECT / RE-UPLOAD', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showReuploadDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('APPROVE DOCS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All documents verified & approved!'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                      context.pushNamed(
                        AppRoutes.verificationMode,
                        pathParameters: {'id': app.id},
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
