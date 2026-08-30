import 'i_application_repository.dart';
import '../models/application_model.dart';
import '../models/instrument_model.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendApplicationRepository implements IApplicationRepository {
  final ApiClient apiClient;
  final List<ApplicationModel> _cache = [];

  BackendApplicationRepository({required this.apiClient});

  ApplicationStatus _mapStatus(String status) {
    switch (status) {
      case 'SUBMITTED':
      case 'DOCUMENTS_PENDING':
      case 'DOCUMENTS_VERIFIED':
      case 'SLOT_BOOKED':
      case 'PAYMENT_PENDING':
      case 'PAYMENT_COMPLETE':
        return ApplicationStatus.submitted;
      case 'LMO_ASSIGNED':
        return ApplicationStatus.approvedForVerification;
      case 'INSPECTION_IN_PROGRESS':
        return ApplicationStatus.inspectionInProgress;
      case 'INSPECTION_COMPLETE':
        return ApplicationStatus.verificationSubmitted;
      case 'PASSED':
        return ApplicationStatus.approved;
      case 'FAILED':
      case 'REJECTED':
      case 'CANCELLED':
        return ApplicationStatus.rejected;
      case 'CERTIFICATE_ISSUED':
        return ApplicationStatus.certificateIssued;
      default:
        return ApplicationStatus.submitted;
    }
  }

  ApplicationModel _mapApplication(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return ApplicationModel(
      id: json['id'].toString(),
      applicantId: json['vendorId']?.toString() ?? vendor?['id']?.toString() ?? '',
      instrumentId: json['instrumentId']?.toString() ?? '',
      assignedOfficerId: json['assignedLmoId']?.toString() ?? '',
      status: _mapStatus(json['status'].toString()),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      applicantInfo: vendor != null
          ? ApplicantInfo(
              businessName: vendor['businessName']?.toString() ?? '',
              contactName: vendor['fullName']?.toString() ?? '',
              contactPhone: vendor['phone']?.toString() ?? '',
              contactEmail: vendor['email']?.toString() ?? '',
              address: vendor['addressLine']?.toString() ?? '',
              city: vendor['city']?.toString() ?? '',
              state: vendor['state']?.toString() ?? '',
              pincode: vendor['pincode']?.toString() ?? '',
              gstNumber: '',
              registrationNumber: '',
            )
          : null,
      instrumentInfo: json['instrument'] != null
          ? InstrumentInfo.fromBackendJson(json['instrument'] as Map<String, dynamic>)
          : null,
      documents: const [],
    );
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForOfficer(String officerId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.lmoQueue);
    if (response.success && response.data is List) {
      _cache
        ..clear()
        ..addAll((response.data as List).map((e) => _mapApplication(e as Map<String, dynamic>)));
      return List.from(_cache);
    }
    throw Exception(response.errorMessage ?? 'Failed to load assigned applications');
  }

  @override
  Future<ApplicationModel?> getApplicationById(String id) async {
    final response = await apiClient.get<dynamic>(ApiConfig.lmoApplication(id));
    if (response.success && response.data is Map) {
      final app = _mapApplication(response.data as Map<String, dynamic>);
      final idx = _cache.indexWhere((a) => a.id == app.id);
      if (idx >= 0) {
        _cache[idx] = app;
      } else {
        _cache.add(app);
      }
      return app;
    }
    try {
      return _cache.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // The backend does not expose a separate LMO "document review" step —
  // an LMO's role is limited to inspection (see /lmo/* routes). These
  // remain local-only state changes for the pre-inspection review screens
  // until/unless that workflow is added server-side.
  @override
  Future<ApplicationModel> updateApplicationStatus(
    String id,
    ApplicationStatus status, {
    String? reason,
  }) async {
    final index = _cache.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Application not found');

    final updated = _cache[index].copyWith(
      status: status,
      rejectionReason: status == ApplicationStatus.rejected ? reason : null,
      updatedAt: DateTime.now(),
    );
    _cache[index] = updated;
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
    final index = _cache.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Application not found');

    final updated = _cache[index].copyWith(
      status: ApplicationStatus.submitted,
      correctionNotes: notes,
      updatedAt: DateTime.now(),
    );
    _cache[index] = updated;
    return updated;
  }
}
