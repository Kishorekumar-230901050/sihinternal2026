import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/instrument_model.dart';

class RegisterInstrumentScreen extends StatefulWidget {
  const RegisterInstrumentScreen({super.key});

  @override
  State<RegisterInstrumentScreen> createState() => _RegisterInstrumentScreenState();
}

class _RegisterInstrumentScreenState extends State<RegisterInstrumentScreen> {
  InstrumentType _selectedType = InstrumentType.electronicWeighingScale;
  final _manufacturerController = TextEditingController(text: 'Essae Teraoka');
  final _modelController = TextEditingController(text: 'DS-252 Pro');
  final _serialController = TextEditingController(text: 'ET-2026-099');
  final _capacityController = TextEditingController(text: '30 kg (e=5g)');
  final _addressController = TextEditingController(text: 'Shop 14, Dadar West, Mumbai');
  bool _isDigital = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _typeLabel(InstrumentType type) {
    return type.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final randomCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final uniqueId = 'CLM-IND-2026-$randomCode';

    final instrument = InstrumentInfo(
      instrumentId: 'VINST-${DateTime.now().millisecondsSinceEpoch}',
      uniqueId: uniqueId,
      type: _selectedType,
      manufacturer: _manufacturerController.text.isEmpty ? 'Unknown' : _manufacturerController.text,
      model: _modelController.text.isEmpty ? 'N/A' : _modelController.text,
      serialNumber: _serialController.text.isEmpty ? 'SN-$randomCode' : _serialController.text,
      capacity: _capacityController.text.isEmpty ? 'N/A' : _capacityController.text,
      accuracyClass: 'Class III',
      registeredLocationLat: 19.0183,
      registeredLocationLng: 72.8478,
      registeredAddress: _addressController.text.isEmpty ? 'Mumbai, Maharashtra' : _addressController.text,
      isDigitalCompatible: _isDigital,
    );

    try {
      await context.read<VendorProvider>().registerInstrument(instrument);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Show Government Unique ID Success Dialog (Page 1 Item 2)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppColors.secondary, size: 28),
              SizedBox(width: 8),
              Text('Instrument Registered!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Official Government Unique ID generated successfully:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  uniqueId,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 8),
              Text('Serial No: ${instrument.serialNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 12),
              const Text(
                'A QR-verifiable certificate will be issued once an LMO officer passes this instrument\'s verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('DONE'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Instrument')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registering will generate a National Government Unique Identifier (UID) and QR badge.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Type selector
            Text('Instrument Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<InstrumentType>(
              value: _selectedType,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category)),
              items: InstrumentType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(_typeLabel(t), style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(labelText: 'Manufacturer Name', prefixIcon: Icon(Icons.factory)),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model Number / Name', prefixIcon: Icon(Icons.info_outline)),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _serialController,
              decoration: const InputDecoration(labelText: 'Machine Serial Number', prefixIcon: Icon(Icons.qr_code)),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Max Capacity & Verification Interval (e)', prefixIcon: Icon(Icons.straighten)),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Installation Site Address', prefixIcon: Icon(Icons.location_on)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Digital / IoT Ethernet Compatible'),
              subtitle: const Text('Supports Calibris digital tamper log monitoring'),
              value: _isDigital,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _isDigital = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('REGISTER & GENERATE UNIQUE ID'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
