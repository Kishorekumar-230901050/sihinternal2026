import 'package:flutter/material.dart';
import '../data/models/application_model.dart';
import '../data/repositories/i_application_repository.dart';
import '../services/audit_service.dart';
import '../data/models/audit_log_model.dart';

class ApplicationProvider extends ChangeNotifier {
  final IApplicationRepository _repository;
  final AuditService _auditService = AuditService();

  List<ApplicationModel> _applications = [];
  ApplicationModel? _selectedApplication;
  bool _isLoading = false;
  String? _errorMessage;

  ApplicationProvider(this._repository);

  List<ApplicationModel> get applications => _applications;
  ApplicationModel? get selectedApplication => _selectedApplication;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadApplications(String officerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _applications = await _repository.getApplicationsForOfficer(officerId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectApplication(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedApplication = await _repository.getApplicationById(id);
      if (_selectedApplication != null) {
        _auditService.log(
          _selectedApplication!.assignedOfficerId,
          AuditAction.viewApplication,
          entityId: id,
          entityType: 'Application',
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveForVerification(String id) async {
    try {
      final updated = await _repository.approveForVerification(id);
      _updateLocalList(updated);
      _selectedApplication = updated;
      _auditService.log(updated.assignedOfficerId, AuditAction.approveApplication, entityId: id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectApplication(String id, String reason) async {
    try {
      final updated = await _repository.rejectApplication(id, reason);
      _updateLocalList(updated);
      _selectedApplication = updated;
      _auditService.log(updated.assignedOfficerId, AuditAction.rejectApplication, entityId: id, details: reason);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestCorrection(String id, String notes) async {
    try {
      final updated = await _repository.requestCorrection(id, notes);
      _updateLocalList(updated);
      _selectedApplication = updated;
      _auditService.log(updated.assignedOfficerId, AuditAction.requestCorrection, entityId: id, details: notes);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateLocalList(ApplicationModel app) {
    final index = _applications.indexWhere((a) => a.id == app.id);
    if (index != -1) {
      _applications[index] = app;
    }
  }
}
