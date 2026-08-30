import 'package:flutter/material.dart';
import '../data/repositories/i_vendor_repository.dart';
import '../data/models/instrument_model.dart';
import '../data/models/gatc_model.dart';
import '../data/models/vendor_application_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/certificate_model.dart';

class VendorProvider extends ChangeNotifier {
  final IVendorRepository _repo;

  VendorProvider(this._repo);

  // ── State ──────────────────────────────────────────────────────
  List<InstrumentInfo> _instruments = [];
  List<GatcModel> _gatcs = [];
  List<VendorApplicationModel> _applications = [];
  List<CertificateModel> _certificates = [];
  bool _isLoading = false;
  String? _errorMessage;
  PaymentModel? _lastPayment;

  // ── Wizard state (multi-step apply flow) ──────────────────────
  InstrumentInfo? _selectedInstrument;
  bool _isReverification = false;
  VerificationMethod _verificationMethod = VerificationMethod.digitalEthernet;
  List<String> _uploadedDocuments = [];
  GatcModel? _selectedGatc;
  DateTime? _selectedSlotDate;
  String? _selectedSlotTime; // "Morning" or "Afternoon"
  bool _isGpsDetecting = false;
  VendorApplicationModel? _currentApplication;

  // ── Getters ────────────────────────────────────────────────────
  List<InstrumentInfo> get instruments => _instruments;
  List<GatcModel> get gatcs => _gatcs;
  List<VendorApplicationModel> get applications => _applications;
  List<CertificateModel> get certificates => _certificates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaymentModel? get lastPayment => _lastPayment;

  InstrumentInfo? get selectedInstrument => _selectedInstrument;
  bool get isReverification => _isReverification;
  VerificationMethod get verificationMethod => _verificationMethod;
  List<String> get uploadedDocuments => _uploadedDocuments;
  GatcModel? get selectedGatc => _selectedGatc;
  DateTime? get selectedSlotDate => _selectedSlotDate;
  String? get selectedSlotTime => _selectedSlotTime;
  bool get isGpsDetecting => _isGpsDetecting;
  VendorApplicationModel? get currentApplication => _currentApplication;

  // ── Automated Due Date Alerts (30, 7, 2, 1 days) ──────────────
  List<({CertificateModel cert, int daysLeft, String alertLevel})> get expiryAlerts {
    final alerts = <({CertificateModel cert, int daysLeft, String alertLevel})>[];
    final now = DateTime.now();

    for (final cert in _certificates.where((c) => c.status == CertificateStatus.active)) {
      final days = cert.validUntil.difference(now).inDays;
      if (days <= 30) {
        String level = '30-Day Reminder';
        if (days <= 1) {
          level = 'CRITICAL: 1 Day Left!';
        } else if (days <= 2) {
          level = 'URGENT: 2 Days Left!';
        } else if (days <= 7) {
          level = 'High: 7 Days Left';
        }
        alerts.add((cert: cert, daysLeft: days, alertLevel: level));
      }
    }
    alerts.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return alerts;
  }

  // ── Convenience getters ────────────────────────────────────────
  int get activeApplicationsCount =>
      _applications.where((a) =>
          a.status != VendorApplicationStatus.certificateIssued &&
          a.status != VendorApplicationStatus.rejected &&
          a.status != VendorApplicationStatus.draft).length;

  int get validCertificatesCount =>
      _certificates.where((c) => c.status == CertificateStatus.active).length;

  int get expiringCertificatesCount => expiryAlerts.length;

  // ── Data loading ───────────────────────────────────────────────
  Future<void> loadAll(String vendorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _instruments = await _repo.getInstruments(vendorId);
      _gatcs = await _repo.getGatcs();
      _applications = await _repo.getApplications(vendorId);
      _certificates = await _repo.getCertificates(vendorId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Instrument registration ────────────────────────────────────
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    await _repo.registerInstrument(instrument);
    // vendorId is unused by the backend-scoped implementation (the JWT
    // determines the caller); passed empty since only that impl is wired.
    _instruments = await _repo.getInstruments('');
    notifyListeners();
  }

  // ── Application wizard methods ─────────────────────────────────
  void selectInstrument(InstrumentInfo instrument) {
    _selectedInstrument = instrument;
    notifyListeners();
  }

  void setIsReverification(bool value) {
    _isReverification = value;
    notifyListeners();
  }

  void setVerificationMethod(VerificationMethod method) {
    _verificationMethod = method;
    notifyListeners();
  }

  void addUploadedDocument(String docName) {
    if (!_uploadedDocuments.contains(docName)) {
      _uploadedDocuments.add(docName);
      notifyListeners();
    }
  }

  void removeUploadedDocument(String docName) {
    _uploadedDocuments.remove(docName);
    notifyListeners();
  }

  Future<void> detectLiveGpsLocation() async {
    _isGpsDetecting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 900));
    _isGpsDetecting = false;
    notifyListeners();
  }

  void selectGatc(GatcModel gatc) {
    _selectedGatc = gatc;
    notifyListeners();
  }

  void selectSlot(DateTime date, String time) {
    _selectedSlotDate = date;
    _selectedSlotTime = time;
    notifyListeners();
  }

  // 1-Click Reverification helper from alert card
  void startReverificationForCertificate(CertificateModel cert) {
    resetWizard();
    _isReverification = true;
    _selectedInstrument = _instruments.where((i) => i.instrumentId == cert.instrumentId).firstOrNull ??
        _instruments.firstOrNull;
    _verificationMethod = (_selectedInstrument?.isDigitalCompatible ?? true)
        ? VerificationMethod.digitalEthernet
        : VerificationMethod.manualOffline;
    notifyListeners();
  }

  /// Creates the real backend application for the currently selected
  /// instrument. Called as soon as the instrument step is confirmed so
  /// that subsequent steps (document upload, slot booking) operate on a
  /// real application id instead of a client-invented placeholder.
  Future<VendorApplicationModel> createApplication(String vendorId) async {
    final draft = VendorApplicationModel(
      id: '',
      vendorId: vendorId,
      instrumentId: _selectedInstrument?.instrumentId ?? '',
      isReverification: _isReverification,
      verificationMethod: _verificationMethod,
      status: VendorApplicationStatus.draft,
      instrumentInfo: _selectedInstrument,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final created = await _repo.createApplication(draft);
    _applications = [created, ..._applications.where((a) => a.id != created.id)];
    _currentApplication = created;
    notifyListeners();
    return created;
  }

  /// Books the wizard-selected GATC + date/time slot against the backend
  /// for [currentApplication], then refreshes it with the authoritative
  /// post-booking status.
  Future<VendorApplicationModel> bookSelectedSlot() async {
    final app = _currentApplication;
    final gatc = _selectedGatc;
    final date = _selectedSlotDate;
    final timeLabel = _selectedSlotTime;
    if (app == null || gatc == null || date == null || timeLabel == null) {
      throw Exception('Select a test centre, date and time slot first');
    }

    final isAfternoon = timeLabel.toLowerCase().startsWith('after');
    final slotStart = DateTime(date.year, date.month, date.day, isAfternoon ? 13 : 9);
    final slotEnd = DateTime(date.year, date.month, date.day, isAfternoon ? 16 : 12);

    final updated = await _repo.bookAppointment(
      applicationId: app.id,
      gatcId: gatc.id,
      slotDate: DateTime(date.year, date.month, date.day),
      slotStart: slotStart,
      slotEnd: slotEnd,
    );

    final idx = _applications.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      _applications[idx] = updated;
    } else {
      _applications.add(updated);
    }
    _currentApplication = updated;
    notifyListeners();
    return updated;
  }

  /// Runs the backend's mock payment gateway cycle for [currentApplication].
  Future<PaymentModel> payForCurrentApplication() async {
    final app = _currentApplication;
    if (app == null) throw Exception('No active application to pay for');

    final payment = await _repo.payForApplication(app.id, app.feeInPaise ?? 50000);
    _lastPayment = payment;

    final updated = await _repo.getApplication(app.id);
    if (updated != null) {
      final idx = _applications.indexWhere((a) => a.id == updated.id);
      if (idx >= 0) _applications[idx] = updated;
      _currentApplication = updated;
    }
    notifyListeners();
    return payment;
  }

  // ── Wizard reset ───────────────────────────────────────────────
  void resetWizard() {
    _selectedInstrument = null;
    _isReverification = false;
    _verificationMethod = VerificationMethod.digitalEthernet;
    _uploadedDocuments = [];
    _selectedGatc = null;
    _selectedSlotDate = null;
    _selectedSlotTime = null;
    _currentApplication = null;
    notifyListeners();
  }

  void setCurrentApplication(VendorApplicationModel app) {
    _currentApplication = app;
    notifyListeners();
  }
}
