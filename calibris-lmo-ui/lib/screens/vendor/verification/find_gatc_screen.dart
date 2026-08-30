import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class FindGatcScreen extends StatefulWidget {
  const FindGatcScreen({super.key});

  @override
  State<FindGatcScreen> createState() => _FindGatcScreenState();
}

class _FindGatcScreenState extends State<FindGatcScreen> {
  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final gatcs = vendor.gatcs;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Test Centre')),
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
              child: const Text('Step 3 of 5 — Detect Nearby GATC (Live GPS)',
                  style: TextStyle(color: AppColors.vendorAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 12),

            // ── Live Location Detector Bar (Bible Page 1 Item 5: "Detect nearby GATC using live location") ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Location: Dadar, Mumbai (19.0183° N, 72.8478° E)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          vendor.isGpsDetecting ? 'Refreshing GPS coordinates...' : 'Showing test centres closest to your registered address',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: vendor.isGpsDetecting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                        : const Icon(Icons.refresh, color: AppColors.secondary, size: 20),
                    onPressed: () => vendor.detectLiveGpsLocation(),
                    tooltip: 'Detect Nearby GATC',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Select Nearest Government Approved Test Centre (GATC):',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: gatcs.length,
                itemBuilder: (context, index) {
                  final gatc = gatcs[index];
                  final isSelected = vendor.selectedGatc?.id == gatc.id;
                  final mockDistance = (index + 1) * 3.4;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.secondary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => vendor.selectGatc(gatc),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.secondary.withOpacity(0.1) : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.location_city,
                                  color: isSelected ? AppColors.secondary : AppColors.textSecondary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gatc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(gatc.addressLine, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _Chip(icon: Icons.near_me, label: '${mockDistance.toStringAsFixed(1)} km away'),
                                      const SizedBox(width: 8),
                                      _Chip(icon: Icons.people, label: '${gatc.dailyCapacity}/day'),
                                      const SizedBox(width: 8),
                                      if (gatc.contactPhone != null)
                                        _Chip(icon: Icons.phone, label: gatc.contactPhone!),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.secondary),
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
                onPressed: vendor.selectedGatc == null
                    ? null
                    : () => context.pushNamed(AppRoutes.vendorBookSlot),
                child: const Text('NEXT — Book Time Slot'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
