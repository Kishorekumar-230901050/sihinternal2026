import 'dart:typed_data';
import 'i_inspection_repository.dart';
import '../models/inspection_model.dart';
import '../mock/mock_data.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendInspectionRepository implements IInspectionRepository {
  final ApiClient apiClient;

  BackendInspectionRepository({required this.apiClient});

  @override
  Future<InspectionModel> createInspection(InspectionModel inspection) async {
    MockDataStore.inspections.add(inspection);

    // Call backend start inspection
    await apiClient.post(
      ApiConfig.lmoStartInspection(inspection.applicationId),
    );

    return inspection;
  }

  /// Upload on-site geotagged inspection photo to Supabase Storage / backend
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
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'capturedAt': DateTime.now().toIso8601String(),
      },
    );

    if (response.success && response.data != null) {
      return response.data!['photo']?['fileUrl']?.toString();
    }
    return null;
  }

  @override
  Future<InspectionModel?> getInspectionById(String id) async {
    try {
      return MockDataStore.inspections.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<InspectionModel>> getInspectionsForApplication(String applicationId) async {
    return MockDataStore.inspections.where((i) => i.applicationId == applicationId).toList();
  }

  @override
  Future<List<InspectionModel>> getInspectionHistoryForInstrument(String instrumentId) async {
    return MockDataStore.inspections.toList();
  }

  @override
  Future<InspectionModel> updateInspection(InspectionModel inspection) async {
    final idx = MockDataStore.inspections.indexWhere((i) => i.id == inspection.id);
    if (idx >= 0) {
      MockDataStore.inspections[idx] = inspection;
    } else {
      MockDataStore.inspections.add(inspection);
    }
    return inspection;
  }

  @override
  Future<InspectionModel> submitInspection(String inspectionId) async {
    final insp = await getInspectionById(inspectionId);
    if (insp == null) throw Exception('Inspection not found');

    // Call backend result endpoint
    await apiClient.post(
      ApiConfig.lmoInspectionResult(insp.applicationId),
      body: {
        'result': insp.result == InspectionResult.pass ? 'PASSED' : 'FAILED',
        'remarks': insp.observations ?? 'Verified per Legal Metrology specifications',
      },
    );

    return insp;
  }
}
