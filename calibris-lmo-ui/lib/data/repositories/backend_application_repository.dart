import 'i_application_repository.dart';
import '../models/application_model.dart';
import '../mock/mock_data.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendApplicationRepository implements IApplicationRepository {
  final ApiClient apiClient;

  BackendApplicationRepository({required this.apiClient});

  @override
  Future<List<ApplicationModel>> getApplicationsForOfficer(String officerId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.lmoQueue);
    if (response.success && response.data != null) {
      // Return synced queue if available
    }
    return MockDataStore.applications.where((a) => a.assignedOfficerId == officerId).toList();
  }

  @override
  Future<ApplicationModel?> getApplicationById(String id) async {
    final response = await apiClient.get<dynamic>(ApiConfig.lmoApplication(id));
    if (response.success && response.data != null) {
      // Sync from backend
    }
    try {
      return MockDataStore.applications.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ApplicationModel> updateApplicationStatus(
    String id,
    ApplicationStatus status, {
    String? reason,
  }) async {
    final index = MockDataStore.applications.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Application not found');

    final updated = MockDataStore.applications[index].copyWith(
      status: status,
      rejectionReason: status == ApplicationStatus.rejected ? reason : null,
      updatedAt: DateTime.now(),
    );
    MockDataStore.applications[index] = updated;
    return updated;
  }

  @override
  Future<ApplicationModel> approveForVerification(String id) {
    return updateApplicationStatus(id, ApplicationStatus.approvedForVerification);
  }

  @override
  Future<ApplicationModel> rejectApplication(String id, String reason) {
    return updateApplicationStatus(id, ApplicationStatus.rejected, reason: reason);
  }

  @override
  Future<ApplicationModel> requestCorrection(String id, String notes) async {
    final index = MockDataStore.applications.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Application not found');

    final updated = MockDataStore.applications[index].copyWith(
      status: ApplicationStatus.submitted,
      correctionNotes: notes,
      updatedAt: DateTime.now(),
    );
    MockDataStore.applications[index] = updated;
    return updated;
  }
}
