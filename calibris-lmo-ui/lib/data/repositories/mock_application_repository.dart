import 'i_application_repository.dart';
import '../models/application_model.dart';
import '../mock/mock_data.dart';

class MockApplicationRepository implements IApplicationRepository {
  @override
  Future<List<ApplicationModel>> getApplicationsForOfficer(String officerId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockDataStore.applications.where((a) => a.assignedOfficerId == officerId).toList();
  }

  @override
  Future<ApplicationModel?> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return MockDataStore.applications.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ApplicationModel> updateApplicationStatus(String id, ApplicationStatus status, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 300));
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
