import 'i_vendor_repository.dart';
import '../models/instrument_model.dart';
import '../models/gatc_model.dart';
import '../models/vendor_application_model.dart';
import '../models/payment_model.dart';
import '../models/certificate_model.dart';
import '../mock/mock_data.dart';

class MockVendorRepository implements IVendorRepository {
  // Mutable copies for demo state changes
  final List<InstrumentInfo> _instruments = List.from(MockDataStore.vendorInstruments);
  final List<VendorApplicationModel> _applications = List.from(MockDataStore.vendorApplications);
  final List<PaymentModel> _payments = List.from(MockDataStore.payments);

  @override
  Future<List<InstrumentInfo>> getInstruments(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In demo mode, return all vendor instruments regardless of vendorId
    return List.from(_instruments);
  }

  @override
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _instruments.add(instrument);
  }

  @override
  Future<List<GatcModel>> getGatcs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(MockDataStore.gatcs);
  }

  @override
  Future<List<VendorApplicationModel>> getApplications(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _applications.where((a) => a.vendorId == vendorId).toList();
  }

  @override
  Future<VendorApplicationModel?> getApplication(String applicationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _applications.firstWhere((a) => a.id == applicationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VendorApplicationModel> createApplication(VendorApplicationModel app) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _applications.add(app);
    return app;
  }

  @override
  Future<VendorApplicationModel> updateApplication(VendorApplicationModel app) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _applications.indexWhere((a) => a.id == app.id);
    if (idx >= 0) {
      _applications[idx] = app;
    }
    return app;
  }

  @override
  Future<List<PaymentModel>> getPayments(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Return payments for applications belonging to this vendor
    final vendorAppIds = _applications.where((a) => a.vendorId == vendorId).map((a) => a.id).toSet();
    return _payments.where((p) => vendorAppIds.contains(p.applicationId)).toList();
  }

  @override
  Future<List<CertificateModel>> getCertificates(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return certificates linked to vendor's completed applications
    final vendorAppIds = _applications
        .where((a) => a.vendorId == vendorId && a.certificateId != null)
        .map((a) => a.certificateId!)
        .toSet();
    return MockDataStore.certificates.where((c) => vendorAppIds.contains(c.id)).toList();
  }

  @override
  Future<CertificateModel?> getCertificate(String certId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return MockDataStore.certificates.firstWhere((c) => c.id == certId);
    } catch (_) {
      return null;
    }
  }
}
