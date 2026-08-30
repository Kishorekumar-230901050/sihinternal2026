import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GpsComparisonCard extends StatelessWidget {
  final double registeredLat;
  final double registeredLng;
  final double currentLat;
  final double currentLng;
  final double distance;
  final bool isWithinGeofence;

  const GpsComparisonCard({
    super.key,
    required this.registeredLat,
    required this.registeredLng,
    required this.currentLat,
    required this.currentLng,
    required this.distance,
    required this.isWithinGeofence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Distance:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${distance.toStringAsFixed(2)} m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isWithinGeofence ? Icons.check_circle : Icons.cancel,
                color: isWithinGeofence ? AppColors.secondary : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                isWithinGeofence ? 'WITHIN GEOFENCE' : 'OUT OF RANGE',
                style: TextStyle(
                  color: isWithinGeofence ? AppColors.secondary : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
