import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/instrument_model.dart';
import '../../../data/models/vendor_application_model.dart';

class ApplyVerificationScreen extends StatefulWidget {
  const ApplyVerificationScreen({super.key});

  @override
  State<ApplyVerificationScreen> createState() => _ApplyVerificationScreenState();
}

class _ApplyVerificationScreenState extends State<ApplyVerificationScreen> {
  bool _isSubmitting = false;

  String _typeLabel(InstrumentType type) {
    return type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
  }

  Future<void> _next(VendorProvider vendor) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await vendor.createApplication(userId);
      if (mounted) context.pushNamed(AppRoutes.vendorApplyUploadDocs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vendorAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Step 1 of 5 — Select Instrument & Method',
                  style: TextStyle(color: AppColors.vendorAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 16),

            // ── Verification Type Toggle (Initial vs Reverification) ──
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => vendor.setIsReverification(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !vendor.isReverification ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !vendor.isReverification ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        'Initial Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !vendor.isReverification ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => vendor.setIsReverification(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: vendor.isReverification ? AppColors.saffron : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: vendor.isReverification ? AppColors.saffron : AppColors.border),
                      ),
                      child: Text(
                        'Re-verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: vendor.isReverification ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Reverification Method Choice (Bible Page 1 Note: "For reverification; choose digital / manual method") ──
            if (vendor.isReverification) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.saffron.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.saffron.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, size: 16, color: AppColors.saffron),
                        SizedBox(width: 6),
                        Text(
                          'Choose Reverification Method',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.saffron),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<VerificationMethod>(
                            title: const Text('Digital Method (Ethernet IoT)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Direct tamper logs & zero-contact', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            value: VerificationMethod.digitalEthernet,
                            groupValue: vendor.verificationMethod,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => vendor.setVerificationMethod(v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<VerificationMethod>(
                            title: const Text('Manual Method (GATC / Offline)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Physical inspection by LMO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            value: VerificationMethod.manualOffline,
                            groupValue: vendor.verificationMethod,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => vendor.setVerificationMethod(v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text('Select Registered Instrument:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Expanded(
              child: vendor.instruments.isEmpty
                  ? const Center(child: Text('No instruments registered. Please register an instrument first.'))
                  : ListView.builder(
                      itemCount: vendor.instruments.length,
                      itemBuilder: (context, index) {
                        final inst = vendor.instruments[index];
                        final isSelected = vendor.selectedInstrument?.instrumentId == inst.instrumentId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? AppColors.vendorAccent : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => vendor.selectInstrument(inst),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: inst.instrumentId,
                                    groupValue: vendor.selectedInstrument?.instrumentId,
                                    onChanged: (_) => vendor.selectInstrument(inst),
                                    activeColor: AppColors.vendorAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(_typeLabel(inst.type),
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                inst.effectiveUniqueId,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${inst.manufacturer} ${inst.model} • ${inst.capacity}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        Text('S/N: ${inst.serialNumber}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                onPressed: (vendor.selectedInstrument == null || _isSubmitting) ? null : () => _next(vendor),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('NEXT — Upload Document & Photo'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
