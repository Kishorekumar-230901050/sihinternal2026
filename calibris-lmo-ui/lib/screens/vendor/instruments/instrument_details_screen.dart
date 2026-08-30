import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/info_row.dart';

class InstrumentDetailsScreen extends StatelessWidget {
  final String instrumentId;
  const InstrumentDetailsScreen({super.key, required this.instrumentId});

  @override
  Widget build(BuildContext context) {
    final instruments = context.watch<VendorProvider>().instruments;
    final inst = instruments.where((i) => i.instrumentId == instrumentId).firstOrNull;

    if (inst == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Instrument Details')),
        body: const Center(child: Text('Instrument not found.')),
      );
    }

    final typeLabel = inst.type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Instrument Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.vendorAccent, Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.precision_manufacturing, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(typeLabel, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${inst.manufacturer} ${inst.model}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: inst.isDigitalCompatible ? AppColors.secondary : Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inst.isDigitalCompatible ? '● IoT READY' : '● MANUAL ONLY',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Details ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const Divider(),
                  InfoRow(label: 'Instrument ID', value: inst.instrumentId),
                  InfoRow(label: 'Serial Number', value: inst.serialNumber),
                  InfoRow(label: 'Capacity', value: inst.capacity),
                  InfoRow(label: 'Accuracy Class', value: inst.accuracyClass),
                  InfoRow(label: 'Location', value: inst.registeredAddress),
                  if (inst.lastCertificateId != null)
                    InfoRow(label: 'Last Certificate', value: inst.lastCertificateId!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
