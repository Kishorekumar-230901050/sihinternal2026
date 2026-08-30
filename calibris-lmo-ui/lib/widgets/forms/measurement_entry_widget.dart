import 'package:flutter/material.dart';

class MeasurementEntryWidget extends StatefulWidget {
  final String paramName;
  const MeasurementEntryWidget({super.key, required this.paramName});

  @override
  State<MeasurementEntryWidget> createState() => _MeasurementEntryWidgetState();
}

class _MeasurementEntryWidgetState extends State<MeasurementEntryWidget> {
  final _expectedController = TextEditingController(text: '0.0');
  final _actualController = TextEditingController();
  final _toleranceController = TextEditingController(text: '0.5');

  bool? _isWithinTolerance;

  void _calculate() {
    final expected = double.tryParse(_expectedController.text);
    final actual = double.tryParse(_actualController.text);
    final tolerance = double.tryParse(_toleranceController.text);

    if (expected != null && actual != null && tolerance != null) {
      final diff = (expected - actual).abs();
      setState(() {
        _isWithinTolerance = diff <= tolerance;
      });
    } else {
      setState(() {
        _isWithinTolerance = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: widget.paramName,
                  decoration: const InputDecoration(labelText: 'Parameter', isDense: true),
                ),
              ),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expectedController,
                  decoration: const InputDecoration(labelText: 'Expected', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _actualController,
                  decoration: const InputDecoration(labelText: 'Actual', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _toleranceController,
                  decoration: const InputDecoration(labelText: 'Tolerance (±)', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isWithinTolerance != null)
            Row(
              children: [
                Icon(_isWithinTolerance! ? Icons.check_circle : Icons.error, 
                  color: _isWithinTolerance! ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  _isWithinTolerance! ? 'Within Tolerance' : 'Out of Tolerance',
                  style: TextStyle(color: _isWithinTolerance! ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                )
              ],
            )
        ],
      ),
    );
  }
}
