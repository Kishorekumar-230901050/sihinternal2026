import 'package:flutter/material.dart';
import '../../data/models/device_model.dart';
import '../../core/utils/status_helpers.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/app_colors.dart';

class DeviceStatusCard extends StatelessWidget {
  final DeviceModel device;
  final String? machineType;

  const DeviceStatusCard({
    super.key,
    required this.device,
    this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.isOnline;
    final color = isOnline 
        ? StatusHelpers.getDeviceHealthColor(device.health)
        : Colors.grey.shade600;
    final isSafe = device.safeMode || device.backendStatus == 'safe_mode';
    final isTampered = device.tamperDetected || isSafe;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isTampered 
              ? AppColors.error 
              : (isOnline ? Colors.green.shade300 : Colors.grey.shade300),
          width: isTampered ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.router, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'LUCKFOX IOT HARDWARE STATUS',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isOnline ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'ETHERNET ONLINE' : 'DISCONNECTED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Key-Value Grid of Machine Properties
            _buildInfoRow('Device ID / UID:', 'DEV-${device.deviceId ?? device.instrumentId}'),
            const SizedBox(height: 8),
            _buildInfoRow('Ethernet Port:', isOnline ? 'RJ45 Connected (100 Mbps)' : 'Unplugged (Queuing offline logs)'),
            const SizedBox(height: 8),
            _buildInfoRow('Machine Type:', machineType ?? device.deviceType ?? 'Electronic Weighing Scale'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Heartbeat Interval:',
              '10–15 seconds (${DateFormatter.formatDateTime(device.lastSeen ?? device.lastHeartbeat)})',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Machine Health:',
              isOnline ? device.health.name.toUpperCase() : 'OFFLINE',
              valueColor: color,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Enclosure Tamper:',
              isTampered ? 'CRITICAL: ENCLOSURE TAMPER DETECTED' : 'NORMAL / SECURE',
              valueColor: isTampered ? AppColors.error : Colors.green.shade700,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Safe Mode State:',
              isSafe ? 'LOCKED IN SAFE MODE (Actuated)' : 'UNLOCKED / OPERATIONAL',
              valueColor: isSafe ? AppColors.error : AppColors.secondary,
            ),
            const SizedBox(height: 12),

            // Bible Page 3: Live JSON Payload Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Luckfox ➔ Supabase JSON Payload (Bible Page 3):',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isTampered ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isTampered ? 'tamper: true' : 'tamper: false',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '{\n  "id": "${device.deviceId ?? device.instrumentId}",\n  "tamper": ${isTampered ? "true" : "false"},\n  "safe_mode": ${isSafe ? "true" : "false"},\n  "polling_interval": "15s"\n}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF38BDF8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? (isHighlighted ? AppColors.primary : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
