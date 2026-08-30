import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/vendor_application_model.dart';
import '../../../widgets/common/info_row.dart';

class ApplicationSummaryScreen extends StatelessWidget {
  const ApplicationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final inst = vendor.selectedInstrument;
    final gatc = vendor.selectedGatc;
    final fee = inst?.isWeighbridge == true ? 150000 : 50000; // paise

    return Scaffold(
      appBar: AppBar(title: const Text('Application Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Step 5 of 5 — Review Application & Proceed to Pay',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Instrument & Application Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          const Divider(),
                          InfoRow(label: 'Application Type', value: vendor.isReverification ? 'Re-verification' : 'Initial Verification'),
                          InfoRow(
                            label: 'Verification Method',
                            value: vendor.verificationMethod == VerificationMethod.digitalEthernet
                                ? 'Digital Method (Ethernet IoT)'
                                : 'Manual Method (GATC / Offline)',
                          ),
                          if (inst != null) ...[
                            InfoRow(label: 'Unique ID', value: inst.effectiveUniqueId),
                            InfoRow(label: 'Category', value: inst.type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim()),
                            InfoRow(label: 'Manufacturer', value: '${inst.manufacturer} ${inst.model}'),
                            InfoRow(label: 'Serial No.', value: inst.serialNumber),
                            InfoRow(label: 'Capacity', value: inst.capacity),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Uploaded Verification Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          const Divider(),
                          if (vendor.uploadedDocuments.isEmpty)
                            const Text('Default demo verification documents attached.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          else
                            ...vendor.uploadedDocuments.map((doc) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.secondary),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(doc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Test Centre & Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          const Divider(),
                          if (gatc != null) ...[
                            InfoRow(label: 'Assigned GATC', value: gatc.name),
                            InfoRow(label: 'Address', value: gatc.addressLine),
                          ],
                          if (vendor.selectedSlotDate != null)
                            InfoRow(label: 'Date', value: DateFormatter.formatDate(vendor.selectedSlotDate!)),
                          if (vendor.selectedSlotTime != null)
                            InfoRow(label: 'Slot Time', value: vendor.selectedSlotTime!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: AppColors.saffron.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.saffron.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statutory Verification Fee (BharatKosh)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.saffron)),
                          const Divider(),
                          InfoRow(label: 'Government Verification Fee', value: '₹${(fee / 100).toStringAsFixed(2)}'),
                          InfoRow(label: 'GST (18%)', value: '₹${(fee * 0.18 / 100).toStringAsFixed(2)}'),
                          const Divider(),
                          InfoRow(label: 'Total Payable Amount', value: '₹${(fee * 1.18 / 100).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                onPressed: () async {
                  final user = context.read<AuthProvider>().currentUser;
                  if (user == null) return;
                  final app = await vendor.createApplication(user.id);
                  if (context.mounted) {
                    context.pushNamed(
                      AppRoutes.vendorPaymentGateway,
                      pathParameters: {'id': app.id},
                    );
                  }
                },
                child: const Text('SUBMIT & PROCEED TO ONLINE FEE PAYMENT'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
