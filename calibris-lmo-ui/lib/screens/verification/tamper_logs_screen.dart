import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/device_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/tamper_event_model.dart';

class TamperLogsScreen extends StatefulWidget {
  final String applicationId;
  const TamperLogsScreen({super.key, required this.applicationId});

  @override
  State<TamperLogsScreen> createState() => _TamperLogsScreenState();
}

class _TamperLogsScreenState extends State<TamperLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<ApplicationProvider>().selectedApplication;
      if (app?.instrumentId != null) {
        context.read<DeviceProvider>().fetchTamperLogs(app!.instrumentId);
      }
    });
  }

  Color _getSeverityColor(TamperSeverity severity) {
    switch (severity) {
      case TamperSeverity.low: return Colors.blue;
      case TamperSeverity.medium: return AppColors.warning;
      case TamperSeverity.high: return AppColors.error;
      case TamperSeverity.critical: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devProvider = context.watch<DeviceProvider>();
    final logs = devProvider.tamperLogs;
    final isWsConnected = devProvider.isWsConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamper Events Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final app = context.read<ApplicationProvider>().selectedApplication;
              if (app?.instrumentId != null) {
                context.read<DeviceProvider>().fetchTamperLogs(app!.instrumentId);
              }
            },
          ),
        ],
      ),
      body: devProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isWsConnected ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isWsConnected ? 'LIVE SYNC' : 'OFFLINE SYNC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isWsConnected ? Colors.green[800] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text('Total Events: ${logs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (logs.isNotEmpty)
                        Text(
                          'Last: ${DateFormatter.formatDateTime(logs.first.timestamp)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text('No tamper events recorded'))
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final event = logs[index];
                            final hasCryptoHash = event.currHash != null && event.currHash!.isNotEmpty;
                            final hasLocation = event.city != null || event.state != null;
                            final hasDrift = event.drift != null;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: _getSeverityColor(event.severity),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.rawTamperType ?? event.eventType.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormatter.formatDateTime(event.timestamp),
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getSeverityColor(event.severity),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event.severity.name.toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event.details != null && event.details!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        event.details!,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ] else if (event.notes != null && event.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        event.notes!,
                                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    if (hasLocation || hasDrift || event.settlingTime != null) ...[
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        children: [
                                          if (hasLocation)
                                            Text(
                                              '📍 ${event.city ?? ""}${event.city != null && event.state != null ? ", " : ""}${event.state ?? ""}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          if (hasDrift)
                                            Text(
                                              '⚖️ Drift: ${event.drift} kg',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          if (event.settlingTime != null)
                                            Text(
                                              '⏱️ Settling: ${event.settlingTime}s',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ],
                                    if (hasCryptoHash) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Hash: ${event.currHash!.length > 16 ? "${event.currHash!.substring(0, 16)}..." : event.currHash}',
                                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: const Text(
                    'Tamper event log is for monitoring only. Results do not automatically determine verification outcome.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}
