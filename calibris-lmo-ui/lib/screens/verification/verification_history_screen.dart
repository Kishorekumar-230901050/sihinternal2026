import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inspection_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/inspection_model.dart';

class VerificationHistoryScreen extends StatefulWidget {
  final String instrumentId;
  const VerificationHistoryScreen({super.key, required this.instrumentId});

  @override
  State<VerificationHistoryScreen> createState() => _VerificationHistoryScreenState();
}

class _VerificationHistoryScreenState extends State<VerificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionProvider>().loadHistory(widget.instrumentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inspProvider = context.watch<InspectionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verification History')),
      body: inspProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : inspProvider.history.isEmpty
              ? const Center(child: Text('No verification history'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: inspProvider.history.length,
                  itemBuilder: (context, index) {
                    final insp = inspProvider.history[index];
                    final isPass = insp.result == InspectionResult.pass;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormatter.formatDate(insp.createdAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPass ? AppColors.secondary : AppColors.error,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(insp.result.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Mode: ${insp.mode.name.toUpperCase()}'),
                            Text('Officer: ${insp.officerName}'),
                            if (insp.failureReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Note: ${insp.failureReason}', style: const TextStyle(color: AppColors.error)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
