import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/instrument_model.dart';

class MyInstrumentsScreen extends StatelessWidget {
  const MyInstrumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final instruments = context.watch<VendorProvider>().instruments;

    return Scaffold(
      appBar: AppBar(title: const Text('My Instruments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.vendorRegisterInstrument),
        icon: const Icon(Icons.add),
        label: const Text('Register New'),
        backgroundColor: AppColors.vendorAccent,
        foregroundColor: Colors.white,
      ),
      body: instruments.isEmpty
          ? const Center(child: Text('No instruments registered yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: instruments.length,
              itemBuilder: (context, index) {
                final inst = instruments[index];
                return _InstrumentCard(
                  instrument: inst,
                  onTap: () => context.pushNamed(
                    AppRoutes.vendorInstrumentDetails,
                    pathParameters: {'id': inst.instrumentId},
                  ),
                );
              },
            ),
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  final InstrumentInfo instrument;
  final VoidCallback onTap;

  const _InstrumentCard({required this.instrument, required this.onTap});

  String _typeLabel(InstrumentType type) {
    return type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.vendorAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.precision_manufacturing, color: AppColors.vendorAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_typeLabel(instrument.type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${instrument.manufacturer} ${instrument.model}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('S/N: ${instrument.serialNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: instrument.isDigitalCompatible ? AppColors.secondary.withOpacity(0.1) : AppColors.textHint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      instrument.isDigitalCompatible ? 'IoT Ready' : 'Manual',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: instrument.isDigitalCompatible ? AppColors.secondary : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(instrument.capacity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
