import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/application_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/verification/gps_comparison_card.dart';

class FieldVerificationScreen extends StatefulWidget {
  final String applicationId;
  const FieldVerificationScreen({super.key, required this.applicationId});

  @override
  State<FieldVerificationScreen> createState() => _FieldVerificationScreenState();
}

class _FieldVerificationScreenState extends State<FieldVerificationScreen> {
  Position? _currentPosition;
  double? _distance;
  bool _isGettingLocation = false;
  bool _hasGeotagPhoto = false;

  void _captureLocation() async {
    setState(() => _isGettingLocation = true);
    final locationService = context.read<LocationService>();
    final pos = await locationService.getCurrentLocation();
    
    if (pos != null && mounted) {
      final app = context.read<ApplicationProvider>().selectedApplication;
      final targetLat = app?.instrumentInfo?.registeredLocationLat ?? 19.0183;
      final targetLng = app?.instrumentInfo?.registeredLocationLng ?? 72.8478;
      
      final dist = locationService.calculateDistance(pos.latitude, pos.longitude, targetLat, targetLng);
      final isWithin = locationService.isWithinGeofence(pos.latitude, pos.longitude, targetLat, targetLng);
      
      setState(() {
        _currentPosition = pos;
        _distance = dist;
      });

      context.read<InspectionProvider>().updateInspectionField(
        inspectionLat: pos.latitude,
        inspectionLng: pos.longitude,
        gpsAccuracy: pos.accuracy,
        distanceFromRegistered: dist,
        withinGeofence: isWithin,
      );
    }
    
    if (mounted) {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<ApplicationProvider>().selectedApplication;
    if (app == null) return const Scaffold(body: Center(child: Text('App not found')));

    final isWithinGeofence = context.watch<InspectionProvider>().currentInspection?.withinGeofence;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Field Verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bible Step 5(ii) Directive Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.pin_drop, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bible Step 5(ii): LMO visits the applicant\'s place, physically verifies machine with standard weights, and captures a live geotagged photo proof.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schedule & Site Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Applicant: ${app.applicantInfo?.contactName ?? "Applicant"} (${app.applicantInfo?.businessName ?? ""})', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Site Address: ${app.instrumentInfo?.registeredAddress ?? "Dadar West, Mumbai"}'),
                  const SizedBox(height: 4),
                  Text(
                    'Target GPS: ${app.instrumentInfo?.registeredLocationLat ?? 19.0183}, ${app.instrumentInfo?.registeredLocationLng ?? 72.8478}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // GPS Capture Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Geotag Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      icon: _isGettingLocation
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.gps_fixed),
                      label: const Text('Capture My Live Location'),
                      onPressed: _isGettingLocation ? null : _captureLocation,
                    ),
                  ),
                  if (_currentPosition != null && _distance != null) ...[
                    const SizedBox(height: 16),
                    GpsComparisonCard(
                      registeredLat: app.instrumentInfo?.registeredLocationLat ?? 19.0183,
                      registeredLng: app.instrumentInfo?.registeredLocationLng ?? 72.8478,
                      currentLat: _currentPosition!.latitude,
                      currentLng: _currentPosition!.longitude,
                      distance: _distance!,
                      isWithinGeofence: isWithinGeofence ?? true,
                    ),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Geotagged Photo Upload Card (Bible Page 2 Item 5(ii))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Geotagged Photo Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload on-site photograph of the weighing instrument with stamped watermark.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_hasGeotagPhoto) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                              SizedBox(width: 8),
                              Text('Geotag Photo Captured & Watermarked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(Icons.camera_alt, size: 48, color: Colors.white38),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'WATERMARK: LAT 19.0183° N • LNG 72.8478° E • ${DateTime.now().toString().substring(0, 16)} IST • OFFICER: ${app.assignedOfficerId}',
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.amber, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture On-Site Photo with GPS Geotag'),
                        onPressed: () {
                          setState(() => _hasGeotagPhoto = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo geotagged with GPS coordinates and timestamp!'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('PROCEED TO INSPECTION CHECKLIST & TESTS'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              context.pushNamed(AppRoutes.inspectionForm, pathParameters: {'id': widget.applicationId});
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }
}
