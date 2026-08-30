import '../models/application_model.dart';

abstract class IApplicationRepository {
  Future<List<ApplicationModel>> getApplicationsForOfficer(String officerId);
  Future<ApplicationModel?> getApplicationById(String id);
  Future<ApplicationModel> updateApplicationStatus(String id, ApplicationStatus status, {String? reason});
  Future<ApplicationModel> approveForVerification(String id);
  Future<ApplicationModel> rejectApplication(String id, String reason);
  Future<ApplicationModel> requestCorrection(String id, String notes);
}
