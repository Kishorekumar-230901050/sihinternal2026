import 'package:flutter/material.dart';
import '../data/models/inspection_model.dart';
import '../data/models/measurement_model.dart';
import '../data/models/photo_evidence_model.dart';
import '../data/repositories/i_inspection_repository.dart';

class InspectionProvider extends ChangeNotifier {
  final IInspectionRepository _repository;

  InspectionModel? _currentInspection;
  List<InspectionModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  InspectionProvider(this._repository);

  InspectionModel? get currentInspection => _currentInspection;
  List<InspectionModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> startInspection(String applicationId, String officerId, VerificationMode mode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newInspection = InspectionModel(
        id: '',
        applicationId: applicationId,
        officerId: officerId,
        officerName: 'LMO Officer', // In real app, fetch from auth
        mode: mode,
        result: InspectionResult.pending,
        createdAt: DateTime.now(),
      );
      _currentInspection = await _repository.createInspection(newInspection);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateInspectionField({
    String? physicalCondition,
    String? sealCondition,
    String? displayCondition,
    bool? tamperDetected,
    String? tamperNotes,
    String? observations,
    double? inspectionLat,
    double? inspectionLng,
    double? gpsAccuracy,
    double? distanceFromRegistered,
    bool? withinGeofence,
  }) {
    if (_currentInspection == null) return;

    _currentInspection = _currentInspection!.copyWith(
      physicalCondition: physicalCondition ?? _currentInspection!.physicalCondition,
      sealCondition: sealCondition ?? _currentInspection!.sealCondition,
      displayCondition: displayCondition ?? _currentInspection!.displayCondition,
      tamperDetected: tamperDetected ?? _currentInspection!.tamperDetected,
      tamperNotes: tamperNotes ?? _currentInspection!.tamperNotes,
      observations: observations ?? _currentInspection!.observations,
      inspectionLat: inspectionLat ?? _currentInspection!.inspectionLat,
      inspectionLng: inspectionLng ?? _currentInspection!.inspectionLng,
      gpsAccuracy: gpsAccuracy ?? _currentInspection!.gpsAccuracy,
      distanceFromRegistered: distanceFromRegistered ?? _currentInspection!.distanceFromRegistered,
      withinGeofence: withinGeofence ?? _currentInspection!.withinGeofence,
    );
    notifyListeners();
  }

  /// Pushes a refined GPS reading to the backend. Returns false (and sets
  /// errorMessage) on failure rather than throwing, since this is a
  /// best-effort refinement of a location already recorded at inspection
  /// start — a failure here shouldn't block the rest of the inspection.
  Future<bool> syncLocation(double lat, double lng) async {
    if (_currentInspection == null) return false;
    try {
      await _repository.updateInspectionLocation(_currentInspection!.applicationId, lat, lng);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void addMeasurement(MeasurementModel m) {
    if (_currentInspection == null) return;

    final updatedMeasurements = List<MeasurementModel>.from(_currentInspection!.measurements)..add(m);
    _currentInspection = _currentInspection!.copyWith(measurements: updatedMeasurements);
    notifyListeners();
  }

  void addPhoto(PhotoEvidenceModel p) {
    if (_currentInspection == null) return;

    final updatedPhotos = List<PhotoEvidenceModel>.from(_currentInspection!.photos)..add(p);
    _currentInspection = _currentInspection!.copyWith(photos: updatedPhotos);
    notifyListeners();
  }

  Future<bool> submitInspection(InspectionResult result, {String? failureReason}) async {
    if (_currentInspection == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentInspection = _currentInspection!.copyWith(
        result: result,
        failureReason: failureReason,
        inspectedAt: DateTime.now(),
      );
      await _repository.updateInspection(_currentInspection!);
      _currentInspection = await _repository.submitInspection(_currentInspection!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String instrumentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _repository.getInspectionHistoryForInstrument(instrumentId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
