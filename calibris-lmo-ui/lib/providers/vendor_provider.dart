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

  // ── Wizard state (multi-step apply flow) ──────────────────────
  InstrumentInfo? _selectedInstrument;
  bool _isReverification = false;
  VerificationMethod _verificationMethod = VerificationMethod.digitalEthernet;
  List<String> _uploadedDocuments = [];
  GatcModel? _selectedGatc;
  DateTime? _selectedSlotDate;
  String? _selectedSlotTime; // "Morning" or "Afternoon"
  bool _isGpsDetecting = false;
  double _currentLat = 19.0183;
  double _currentLng = 72.8478;
  VendorApplicationModel? _currentApplication;

  // ── Getters ────────────────────────────────────────────────────
  List<InstrumentInfo> get instruments => _instruments;
  List<GatcModel> get gatcs => _gatcs;
  List<VendorApplicationModel> get applications => _applications;
  List<CertificateModel> get certificates => _certificates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  InstrumentInfo? get selectedInstrument => _selectedInstrument;
  bool get isReverification => _isReverification;
  VerificationMethod get verificationMethod => _verificationMethod;
  List<String> get uploadedDocuments => _uploadedDocuments;
  GatcModel? get selectedGatc => _selectedGatc;
  DateTime? get selectedSlotDate => _selectedSlotDate;
  String? get selectedSlotTime => _selectedSlotTime;
  bool get isGpsDetecting => _isGpsDetecting;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
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
      final results = await Future.wait([
        _repo.getInstruments(vendorId),
        _repo.getGatcs(),
        _repo.getApplications(vendorId),
        _repo.getCertificates(vendorId),
      ]);
      _instruments = results[0] as List<InstrumentInfo>;
      _gatcs = results[1] as List<GatcModel>;
      _applications = results[2] as List<VendorApplicationModel>;
      _certificates = results[3] as List<CertificateModel>;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Instrument registration ────────────────────────────────────
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    await _repo.registerInstrument(instrument);
    _instruments.add(instrument);
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
    _currentLat = 19.0183;
    _currentLng = 72.8478;
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

  Future<VendorApplicationModel> createApplication(String vendorId) async {
    final app = VendorApplicationModel(
      id: 'VAPP-${DateTime.now().millisecondsSinceEpoch}',
      vendorId: vendorId,
      instrumentId: _selectedInstrument?.instrumentId ?? 'VINST-001',
      isReverification: _isReverification,
      verificationMethod: _verificationMethod,
      status: VendorApplicationStatus.paymentPending,
      documentStatus: DocumentReviewStatus.pending,
      uploadedDocuments: List.from(_uploadedDocuments.isEmpty
          ? ['Invoice_${DateTime.now().year}.pdf', 'Model_Approval.pdf', 'Device_Plate_Photo.jpg']
          : _uploadedDocuments),
      gatcId: _selectedGatc?.id,
      gatcName: _selectedGatc?.name,
      slotDate: _selectedSlotDate,
      slotTime: _selectedSlotTime,
      feeInPaise: _selectedInstrument?.isWeighbridge == true ? 150000 : 50000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      instrumentInfo: _selectedInstrument,
    );

    final created = await _repo.createApplication(app);
    _applications.add(created);
    _currentApplication = created;
    notifyListeners();
    return created;
  }

  // ── Payment simulation ─────────────────────────────────────────
  Future<PaymentModel> simulatePayment(String applicationId, int amountInPaise) async {
    await Future.delayed(const Duration(seconds: 1));
    final payment = PaymentModel(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      applicationId: applicationId,
      amountInPaise: amountInPaise,
      status: PaymentStatus.success,
      provider: 'BHARATKOSH_UPI',
      orderRef: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      transactionRef: 'TXN-BK-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    final idx = _applications.indexWhere((a) => a.id == applicationId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: VendorApplicationStatus.paymentComplete,
        paymentId: payment.id,
        updatedAt: DateTime.now(),
      );
      _currentApplication = _applications[idx];
      await _repo.updateApplication(_applications[idx]);
    }

    notifyListeners();
    return payment;
  }

  // ── Demo: advance application status matching bible stages ──────
  Future<void> advanceStatus(String applicationId) async {
    final idx = _applications.indexWhere((a) => a.id == applicationId);
    if (idx < 0) return;

    final app = _applications[idx];
    VendorApplicationStatus? next;
    DocumentReviewStatus docStatus = app.documentStatus;

    switch (app.status) {
      case VendorApplicationStatus.draft:
        next = VendorApplicationStatus.submitted;
        break;
      case VendorApplicationStatus.submitted:
        next = VendorApplicationStatus.documentReview;
        break;
      case VendorApplicationStatus.documentReview:
        next = VendorApplicationStatus.paymentPending;
        docStatus = DocumentReviewStatus.approved;
        break;
      case VendorApplicationStatus.reuploadRequested:
        next = VendorApplicationStatus.documentReview;
        docStatus = DocumentReviewStatus.pending;
        break;
      case VendorApplicationStatus.paymentPending:
        next = VendorApplicationStatus.paymentComplete;
        break;
      case VendorApplicationStatus.paymentComplete:
        next = VendorApplicationStatus.scheduled;
        break;
      case VendorApplicationStatus.scheduled:
        next = VendorApplicationStatus.lmoAssigned;
        break;
      case VendorApplicationStatus.lmoAssigned:
        next = VendorApplicationStatus.inspectionInProgress;
        break;
      case VendorApplicationStatus.inspectionInProgress:
        next = VendorApplicationStatus.passed;
        break;
      case VendorApplicationStatus.passed:
        next = VendorApplicationStatus.departmentApproved;
        break;
      case VendorApplicationStatus.departmentApproved:
        next = VendorApplicationStatus.certificateIssued;
        break;
      default:
        return;
    }

    _applications[idx] = app.copyWith(
      status: next,
      documentStatus: docStatus,
      assignedLmoName: next == VendorApplicationStatus.lmoAssigned ? 'Officer Rajesh Kumar' : app.assignedLmoName,
      certificateId: next == VendorApplicationStatus.certificateIssued ? 'CERT-2026-00001' : app.certificateId,
      updatedAt: DateTime.now(),
    );
    _currentApplication = _applications[idx];
    await _repo.updateApplication(_applications[idx]);
    notifyListeners();
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
