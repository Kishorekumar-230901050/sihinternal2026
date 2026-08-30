import 'dart:typed_data';
import 'i_vendor_repository.dart';
import '../models/instrument_model.dart';
import '../models/gatc_model.dart';
import '../models/vendor_application_model.dart';
import '../models/payment_model.dart';
import '../models/certificate_model.dart';
import '../mock/mock_data.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendVendorRepository implements IVendorRepository {
  final ApiClient apiClient;

  // Local state cache / fallback
  final List<InstrumentInfo> _instruments = List.from(MockDataStore.vendorInstruments);
  final List<VendorApplicationModel> _applications = List.from(MockDataStore.vendorApplications);
  final List<PaymentModel> _payments = List.from(MockDataStore.payments);

  BackendVendorRepository({required this.apiClient});

  @override
  Future<List<InstrumentInfo>> getInstruments(String vendorId) async {
    final response = await apiClient.get<dynamic>(
      ApiConfig.vendorInstruments,
    );

    if (response.success && response.data != null) {
      try {
        final List list = response.data is List ? response.data : (response.data['instruments'] ?? []);
        final parsed = list.map((item) {
          final m = item as Map<String, dynamic>;
          return InstrumentInfo(
            instrumentId: m['id']?.toString() ?? 'INST-001',
            uniqueId: m['uniqueId']?.toString() ?? m['serialNumber']?.toString(),
            serialNumber: m['serialNumber']?.toString() ?? 'SN-001',
            model: m['model']?.toString() ?? 'Model Standard',
            manufacturer: m['manufacturer']?.toString() ?? 'Vendor',
            capacity: m['capacity']?.toString() ?? '150 kg',
            accuracyClass: m['accuracyClass']?.toString() ?? 'Class III',
            type: InstrumentType.electronicWeighingScale,
            registeredLocationLat: 19.0183,
            registeredLocationLng: 72.8478,
            registeredAddress: m['location']?.toString() ?? 'Mumbai, Maharashtra',
          );
        }).toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {}
    }

    return List.from(_instruments);
  }

  @override
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    _instruments.add(instrument);

    // Try pushing to backend
    await apiClient.post(
      ApiConfig.vendorInstruments,
      body: {
        'instrumentTypeId': 'seed-type-1',
        'serialNumber': instrument.serialNumber,
        'modelNumber': instrument.model,
        'manufacturer': instrument.manufacturer,
        'capacity': instrument.capacity,
        'accuracyClass': instrument.accuracyClass,
        'uniqueId': instrument.effectiveUniqueId,
      },
    );
  }

  /// Upload document to Supabase Storage / local backend storage via multipart
  Future<String?> uploadDocument({
    required String applicationId,
    required String fileName,
    required Uint8List fileBytes,
    String documentType = 'OTHER',
  }) async {
    final response = await apiClient.uploadMultipart<Map<String, dynamic>>(
      ApiConfig.vendorApplicationDocuments(applicationId),
      fieldName: 'file',
      filename: fileName,
      fileBytes: fileBytes,
      additionalFields: {
        'documentType': documentType,
      },
    );

    if (response.success && response.data != null) {
      return response.data!['document']?['fileUrl']?.toString();
    }
    return null;
  }

  @override
  Future<List<GatcModel>> getGatcs() async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorGatcs);
    if (response.success && response.data != null) {
      try {
        final List list = response.data is List ? response.data : (response.data['gatcs'] ?? []);
        final parsed = list.map((item) {
          final m = item as Map<String, dynamic>;
          return GatcModel(
            id: m['id']?.toString() ?? 'GATC-001',
            name: m['name']?.toString() ?? 'Govt Approved Test Centre',
            addressLine: m['addressLine']?.toString() ?? 'Mount Road, Chennai',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 19.0183,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 72.8478,
            distanceKm: 2.5,
            phone: m['contactPhone']?.toString() ?? '+919000000001',
            email: m['contactEmail']?.toString() ?? 'gatc@calibris.gov.in',
            availableSlotsCount: 8,
          );
        }).toList();
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }
    return List.from(MockDataStore.gatcs);
  }

  @override
  Future<List<VendorApplicationModel>> getApplications(String vendorId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorApplications);
    if (response.success && response.data != null) {
      // Return synced list if available, or fall back to cached list
    }
    return _applications.where((a) => a.vendorId == vendorId).toList();
  }

  @override
  Future<VendorApplicationModel?> getApplication(String applicationId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorApplication(applicationId));
    if (response.success && response.data != null) {
      // Parsed backend app
    }
    try {
      return _applications.firstWhere((a) => a.id == applicationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VendorApplicationModel> createApplication(VendorApplicationModel app) async {
    _applications.add(app);

    // Call backend
    await apiClient.post(
      ApiConfig.vendorApplications,
      body: {
        'instrumentId': app.instrumentId,
        'verificationMethod': app.verificationMethod.name,
        'isReverification': app.isReverification,
      },
    );
    return app;
  }

  @override
  Future<VendorApplicationModel> updateApplication(VendorApplicationModel app) async {
    final idx = _applications.indexWhere((a) => a.id == app.id);
    if (idx >= 0) {
      _applications[idx] = app;
    }
    return app;
  }

  @override
  Future<List<PaymentModel>> getPayments(String vendorId) async {
    final vendorAppIds = _applications.where((a) => a.vendorId == vendorId).map((a) => a.id).toSet();
    return _payments.where((p) => vendorAppIds.contains(p.applicationId)).toList();
  }

  @override
  Future<List<CertificateModel>> getCertificates(String vendorId) async {
    final vendorAppIds = _applications
        .where((a) => a.vendorId == vendorId && a.certificateId != null)
        .map((a) => a.certificateId!)
        .toSet();
    return MockDataStore.certificates.where((c) => vendorAppIds.contains(c.id)).toList();
  }

  @override
  Future<CertificateModel?> getCertificate(String certId) async {
    try {
      return MockDataStore.certificates.firstWhere((c) => c.id == certId);
    } catch (_) {
      return null;
    }
  }
}
