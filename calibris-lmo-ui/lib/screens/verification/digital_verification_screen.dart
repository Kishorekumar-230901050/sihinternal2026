import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/verification/device_status_card.dart';

class DigitalVerificationScreen extends StatefulWidget {
  final String applicationId;
  const DigitalVerificationScreen({super.key, required this.applicationId});

  @override
  State<DigitalVerificationScreen> createState() => _DigitalVerificationScreenState();
}

class _DigitalVerificationScreenState extends State<DigitalVerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<ApplicationProvider>().selectedApplication;
      if (app != null) {
        final instrumentId = app.instrumentInfo?.instrumentId.isNotEmpty == true 
            ? app.instrumentInfo!.instrumentId 
            : app.instrumentId;
        if (instrumentId.isNotEmpty) {
          context.read<DeviceProvider>().startLiveDeviceMonitoring(instrumentId);
        }
      }
    });
  }

  @override
  void dispose() {
    // Stop live machine connection when leaving verification screen
    context.read<DeviceProvider>().stopLiveDeviceMonitoring();
    super.dispose();
  }

  void _showSafeModeLockDialog(BuildContext context, String deviceId) {
    final reasonController = TextEditingController(text: 'Physical seal broken / critical tamper detected during field inspection.');
    final user = context.read<AuthProvider>().currentUser;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.error),
            SizedBox(width: 8),
            Text('Lock Machine / Safe Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activating SAFE MODE on Weighing Machine #$deviceId will immediately disable measurements and alert central legal metrology servers.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Authorized Officer: ${user?.name ?? "Officer"} (${user?.employeeId ?? "USR-001"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Safe Mode Lock',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for official audit logs',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<DeviceProvider>().lockDeviceSafeMode(
                deviceId: deviceId,
                officerEmail: user?.effectiveEmail ?? 'officer@calibris.gov.in',
                officerId: user?.employeeId ?? user?.id ?? 'USR-001',
                reason: reasonController.text,
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Machine placed in SAFE MODE. Actuation command dispatched to Luckfox.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  final err = context.read<DeviceProvider>().errorMessage ?? 'Failed to lock machine';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Confirm Lock'),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, String deviceId) {
    final reasonController = TextEditingController(text: 'Inspection completed and verified. Safe mode reset.');
    final user = context.read<AuthProvider>().currentUser;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Remote Device Unlock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispatch remote unlock command to Luckfox Device #$deviceId through backend server.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Authorized Officer: ${user?.name ?? "Officer"} (${user?.employeeId ?? "USR-001"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Unlock',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for audit logs',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: The Luckfox device will poll the backend, execute the unlock locally, and confirm back within 30-60 seconds.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<DeviceProvider>().unlockDevice(
                deviceId: deviceId,
                officerEmail: user?.effectiveEmail ?? 'officer@calibris.gov.in',
                officerId: user?.employeeId ?? user?.id ?? 'USR-001',
                reason: reasonController.text,
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Unlock command created. Luckfox machine will unlock within 30-60s.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = context.read<DeviceProvider>().errorMessage ?? 'Failed to send unlock command';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $err'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devProvider = context.watch<DeviceProvider>();
    final app = context.watch<ApplicationProvider>().selectedApplication;
    final device = devProvider.device;
    final isSafeMode = device != null && (device.safeMode || device.backendStatus == 'safe_mode');
    final isTampered = device != null && (device.tamperDetected || isSafeMode);
    final instrumentInfo = app?.instrumentInfo;
    final isWeighingMachine = instrumentInfo != null ? instrumentInfo.isWeighingMachine : true;
    final isFuelPump = instrumentInfo != null ? instrumentInfo.isFuelPump : false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification — ${app?.id ?? "Application"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (app != null) {
                final instrumentId = app.instrumentInfo?.instrumentId.isNotEmpty == true 
                    ? app.instrumentInfo!.instrumentId 
                    : app.instrumentId;
                if (instrumentId.isNotEmpty) {
                  context.read<DeviceProvider>().fetchDeviceStatus(instrumentId);
                }
              }
            },
          ),
        ],
      ),
      body: devProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : device == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        const Text(
                          'Machine Offline — Live verification unavailable.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          devProvider.errorMessage ?? 'Could not establish connection to Luckfox device.',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (app != null) {
                              final instrumentId = app.instrumentInfo?.instrumentId.isNotEmpty == true 
                                  ? app.instrumentInfo!.instrumentId 
                                  : app.instrumentId;
                              if (instrumentId.isNotEmpty) {
                                context.read<DeviceProvider>().fetchDeviceStatus(instrumentId);
                              }
                            }
                          },
                          child: const Text('Retry Connection'),
                        )
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Official MACHINE STATUS Section
                    DeviceStatusCard(
                      device: device,
                      machineType: instrumentInfo != null
                          ? '${instrumentInfo.manufacturer} ${instrumentInfo.model}'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tamper Forensics & Control Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isTampered ? AppColors.error : Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isTampered ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                                  color: isTampered ? AppColors.error : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTampered ? 'TAMPER & INTEGRITY ALERT' : 'TAMPER INTEGRITY STATUS',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isTampered ? AppColors.error : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isTampered 
                                  ? 'Condition: Unauthorized tampering / enclosure access detected on this instrument.'
                                  : 'Condition: Hardware seals, enclosure sensors, and calibration memory are intact.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isTampered ? AppColors.error : Colors.black87,
                                fontWeight: isTampered ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (device.tamperType != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Last Logged Event: ${device.tamperType}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Controls Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.history, size: 18),
                                  label: const Text('View Tamper Logs'),
                                  onPressed: () => context.pushNamed(
                                    AppRoutes.tamperLogs,
                                    pathParameters: {'id': widget.applicationId},
                                  ),
                                ),

                                // WEIGHING MACHINE CONTROLS (Actuation allowed)
                                if (isWeighingMachine) ...[
                                  if (isSafeMode)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: devProvider.isActionInProgress
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.lock_open, size: 18),
                                      label: Text(devProvider.isActionInProgress ? 'Unlocking...' : 'Remote Unlock Machine'),
                                      onPressed: devProvider.isActionInProgress
                                          ? null
                                          : () => _showUnlockDialog(context, device.deviceId?.toString() ?? device.instrumentId),
                                    )
                                  else if (isTampered)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: devProvider.isActionInProgress
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.shield, size: 18),
                                      label: Text(devProvider.isActionInProgress ? 'Locking...' : 'LOCK MACHINE / SAFE MODE'),
                                      onPressed: devProvider.isActionInProgress
                                          ? null
                                          : () => _showSafeModeLockDialog(context, device.deviceId?.toString() ?? device.instrumentId),
                                    ),
                                ],

                                // FUEL PUMP NOTICE (Read-only, no remote lock allowed)
                                if (isFuelPump) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blueGrey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.blueGrey.shade700, size: 18),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Fuel pump verification is read-only. Remote actuation/locking is not permitted on fuel dispensing systems.',
                                            style: TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Device health check is an automated verification aid. You must complete the official inspection form to record legal measurements and stamp decisions.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        context.pushNamed(AppRoutes.inspectionForm, pathParameters: {'id': widget.applicationId});
                      },
                      child: const Text('Proceed to Inspection Form', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
    );
  }
}
