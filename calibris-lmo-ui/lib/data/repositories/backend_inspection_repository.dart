import 'dart:typed_data';
import 'i_inspection_repository.dart';
import '../models/inspection_model.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendInspectionRepository implements IInspectionRepository {
  final ApiClient apiClient;
  final List<InspectionModel> _cache = [];

  BackendInspectionRepository({required this.apiClient});

  @override
  Future<InspectionModel> createInspection(InspectionModel inspection) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.lmoStartInspection(inspection.applicationId),
      body: {
        'gpsLatitude': inspection.inspectionLat ?? 0.0,
        'gpsLongitude': inspection.inspectionLng ?? 0.0,
      },
    );
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to start inspection');
    }

    final backendId = response.data?['id']?.toString();
    final created = inspection.copyWith(id: backendId ?? inspection.applicationId);
    final idx = _cache.indexWhere((i) => i.applicationId == created.applicationId);
    if (idx >= 0) {
      _cache[idx] = created;
    } else {
      _cache.add(created);
    }
    return created;
  }

  /// Backend only records GPS at inspection-start time; re-calling start
  /// (an upsert) is how a more accurate on-site reading gets persisted.
  @override
  Future<void> updateInspectionLocation(String applicationId, double lat, double lng) async {
    await apiClient.post(
      ApiConfig.lmoStartInspection(applicationId),
      body: {'gpsLatitude': lat, 'gpsLongitude': lng},
    );
  }

  Future<String?> uploadInspectionPhoto({
    required String applicationId,
    required Uint8List photoBytes,
    required double latitude,
    required double longitude,
  }) async {
    final response = await apiClient.uploadMultipart<Map<String, dynamic>>(
      ApiConfig.lmoInspectionPhotos(applicationId),
      fieldName: 'file',
      filename: 'inspection_geotag_${DateTime.now().millisecondsSinceEpoch}.jpg',
      fileBytes: photoBytes,
      additionalFields: {
        'gpsLatitude': latitude.toString(),
        'gpsLongitude': longitude.toString(),
      },
    );

    if (response.success && response.data != null) {
      return response.data!['url']?.toString();
    }
    return null;
  }

  @override
  Future<InspectionModel?> getInspectionById(String id) async {
    try {
      return _cache.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<InspectionModel>> getInspectionsForApplication(String applicationId) async {
    return _cache.where((i) => i.applicationId == applicationId).toList();
  }

  /// The backend does not expose an instrument-level inspection history
  /// endpoint for the LMO role (inspection results live only on the
  /// applications they belong to), so this returns whatever has been seen
  /// locally this session rather than fabricating history.
  @override
  Future<List<InspectionModel>> getInspectionHistoryForInstrument(String instrumentId) async {
    return List.from(_cache);
  }

  @override
  Future<InspectionModel> updateInspection(InspectionModel inspection) async {
    final idx = _cache.indexWhere((i) => i.applicationId == inspection.applicationId);
    if (idx >= 0) {
      _cache[idx] = inspection;
    } else {
      _cache.add(inspection);
    }
    return inspection;
  }

  @override
  Future<InspectionModel> submitInspection(String inspectionId) async {
    InspectionModel? insp;
    try {
      insp = _cache.firstWhere((i) => i.id == inspectionId);
    } catch (_) {
      insp = null;
    }
    if (insp == null) throw Exception('Inspection not found');

    final measurement = insp.measurements.isNotEmpty ? insp.measurements.first : null;
    final remarks = insp.observations ?? insp.failureReason;

    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.lmoInspectionResult(insp.applicationId),
      body: {
        'status': insp.result == InspectionResult.pass ? 'PASSED' : 'FAILED',
        if (remarks != null) 'remarks': remarks,
        if (measurement != null) 'observedValue': measurement.actual,
        if (measurement != null) 'standardValue': measurement.expected,
        if (measurement != null) 'permissibleError': measurement.tolerance,
      },
    );

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to submit inspection result');
    }

    final updated = insp.copyWith(submittedAt: DateTime.now());
    final idx = _cache.indexWhere((i) => i.id == inspectionId);
    if (idx >= 0) _cache[idx] = updated;
    return updated;
  }
}
