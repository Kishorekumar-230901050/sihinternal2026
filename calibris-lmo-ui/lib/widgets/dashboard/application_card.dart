import 'package:flutter/material.dart';
import '../../data/models/application_model.dart';
import '../../core/utils/date_formatter.dart';
import '../common/status_badge.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    application.id,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  StatusBadge(status: application.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(application.applicantInfo?.businessName ?? 'Unknown Business')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.scale, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(application.instrumentInfo?.type.name ?? 'Unknown Instrument')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatDate(application.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text('Review', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
