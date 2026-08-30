import 'package:flutter/material.dart';
import '../../data/models/application_model.dart';
import '../../core/utils/status_helpers.dart';

class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusHelpers.getStatusColor(status);
    final label = StatusHelpers.getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
