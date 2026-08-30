import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/application_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/inspection_model.dart';
import '../../widgets/forms/measurement_entry_widget.dart';

class InspectionFormScreen extends StatefulWidget {
  final String applicationId;
  const InspectionFormScreen({super.key, required this.applicationId});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _physicalCondition = 'Good';
  String _sealCondition = 'Intact';
  String _displayCondition = 'Clear';
  bool _tamperDetected = false;
  final _tamperNotesController = TextEditingController();
  final _observationsController = TextEditingController();
  final _failureReasonController = TextEditingController();

  @override
  void dispose() {
    _tamperNotesController.dispose();
    _observationsController.dispose();
    _failureReasonController.dispose();
    super.dispose();
  }

  void _submit(InspectionResult result) async {
    if (result == InspectionResult.fail && _failureReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a failure reason.')));
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InspectionProvider>();
      provider.updateInspectionField(
        physicalCondition: _physicalCondition,
        sealCondition: _sealCondition,
        displayCondition: _displayCondition,
        tamperDetected: _tamperDetected,
        tamperNotes: _tamperNotesController.text,
        observations: _observationsController.text,
      );

      final success = await provider.submitInspection(result, failureReason: _failureReasonController.text);
      if (success && mounted) {
        final targetId = (provider.currentInspection?.id != null && provider.currentInspection!.id.isNotEmpty)
            ? provider.currentInspection!.id
            : (widget.applicationId.isNotEmpty ? widget.applicationId : 'INSP-001');
        context.pushReplacementNamed(AppRoutes.verificationSummary, pathParameters: {'id': targetId});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<ApplicationProvider>().selectedApplication;
    final insp = context.watch<InspectionProvider>().currentInspection;

    if (app == null || insp == null) return const Scaffold(body: Center(child: Text('Data error')));

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Form')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section 1: Identification
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instrument Identification', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Text('ID: ${app.instrumentInfo?.instrumentId}'),
                    Text('Serial: ${app.instrumentInfo?.serialNumber}'),
                    Text('Type: ${app.instrumentInfo?.type.name}'),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(insp.mode.name.toUpperCase()),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Physical Condition
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Physical Condition', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: _physicalCondition,
                      decoration: const InputDecoration(labelText: 'Physical Condition'),
                      items: ['Good', 'Fair', 'Poor', 'Damaged'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _physicalCondition = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _sealCondition,
                      decoration: const InputDecoration(labelText: 'Seal Condition'),
                      items: ['Intact', 'Broken', 'Missing', 'Replaced'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _sealCondition = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _displayCondition,
                      decoration: const InputDecoration(labelText: 'Display Condition'),
                      items: ['Clear', 'Damaged', 'Missing', 'N/A'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _displayCondition = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tamper Detected?', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('NO'),
                            value: false,
                            groupValue: _tamperDetected,
                            onChanged: (v) => setState(() => _tamperDetected = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('YES'),
                            value: true,
                            groupValue: _tamperDetected,
                            onChanged: (v) => setState(() => _tamperDetected = v!),
                          ),
                        ),
                      ],
                    ),
                    if (_tamperDetected)
                      TextFormField(
                        controller: _tamperNotesController,
                        decoration: const InputDecoration(labelText: 'Tamper Notes'),
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Required when tamper detected' : null,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Measurements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Measurement Tests', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    const Text('Measurement fields are instrument-specific. Contact supervisor for template guidance.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    const MeasurementEntryWidget(paramName: 'Zero Error Test'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Measurement'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Photo Evidence
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photo Evidence', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Simulated Camera'),
                                content: const Text('Camera not available in prototype. Photo recorded.'),
                                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload'),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 6: Observations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Observations', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    TextFormField(
                      controller: _observationsController,
                      decoration: const InputDecoration(labelText: 'General observations & notes'),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 7: Result
            const Text('Final Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _failureReasonController,
              decoration: const InputDecoration(labelText: 'Non-Compliance Reason (Required for FAIL)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 20)),
                    onPressed: () => _submit(InspectionResult.pass),
                    child: const Text('PASS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 20)),
                    onPressed: () => _submit(InspectionResult.fail),
                    child: const Text('FAIL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
