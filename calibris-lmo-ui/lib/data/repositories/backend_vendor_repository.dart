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
        final parsed = list.map<InstrumentInfo>((item) {
          final m = item as Map<String, dynamic>;
          final typeObj = m['instrumentType'] as Map<String, dynamic>?;
          return InstrumentInfo(
            instrumentId: m['id']?.toString() ?? 'INST-001',
            uniqueId: m['uniqueId']?.toString() ?? m['serialNumber']?.toString(),
            serialNumber: m['serialNumber']?.toString() ?? 'SN-001',
            model: m['model']?.toString() ?? 'Model Standard',
            manufacturer: m['manufacturer']?.toString() ?? 'Vendor',
            capacity: m['capacity']?.toString() ?? '150 kg',
            accuracyClass: m['accuracyClass']?.toString() ?? 'Class III',
            type: (typeObj?['code'] == 'WB')
                ? InstrumentType.platformWeighbridge
                : (typeObj?['code'] == 'FDS')
                    ? InstrumentType.petrolPumpDispenser
                    : InstrumentType.electronicWeighingScale,
            registeredLocationLat: 19.0183,
            registeredLocationLng: 72.8478,
            registeredAddress: m['location']?.toString() ?? 'Mumbai, Maharashtra',
            isDigitalCompatible: true,
          );
        }).toList();
        if (parsed.isNotEmpty) {
          // Merge with local instruments (avoiding duplicate serials)
          for (final inst in parsed) {
            final idx = _instruments.indexWhere((i) => i.serialNumber == inst.serialNumber);
            if (idx >= 0) {
              _instruments[idx] = inst;
            } else {
              _instruments.insert(0, inst);
            }
          }
          return List.from(_instruments);
        }
      } catch (_) {}
    }

    return List.from(_instruments);
  }

  @override
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    _instruments.insert(0, instrument);

    // Call backend API
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorInstruments,
      body: {
        'serialNumber': instrument.serialNumber,
        'model': instrument.model,
        'modelNumber': instrument.model,
        'manufacturer': instrument.manufacturer,
        'capacity': instrument.capacity,
        'accuracyClass': instrument.accuracyClass,
        'uniqueId': instrument.effectiveUniqueId,
        'address': instrument.registeredAddress,
      },
    );

    if (response.success && response.data != null) {
      final serverId = response.data!['id']?.toString();
      if (serverId != null) {
        final idx = _instruments.indexWhere((i) => i.serialNumber == instrument.serialNumber);
        if (idx >= 0) {
          _instruments[idx] = instrument.copyWith(instrumentId: serverId);
        }
      }
    }
  }

  /// Upload document to Supabase Storage / local backend storage via multipart
  @override
  Future<String?> uploadDocument({
    required String applicationId,
    required String fileName,
    required List<int> fileBytes,
    String documentType = 'OTHER',
  }) async {
    final bytes = fileBytes is Uint8List ? fileBytes : Uint8List.fromList(fileBytes);
    final response = await apiClient.uploadMultipart<Map<String, dynamic>>(
      ApiConfig.vendorApplicationDocuments(applicationId),
      fieldName: 'file',
      filename: fileName,
      fileBytes: bytes,
      additionalFields: {
        'type': documentType,
        'documentType': documentType,
      },
    );

    if (response.success && response.data != null) {
      final doc = response.data!['document'] as Map<String, dynamic>?;
      return doc?['fileUrl']?.toString() ?? response.data!['url']?.toString();
    }
    return 'uploaded://$fileName';
  }

  @override
  Future<List<GatcModel>> getGatcs() async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorGatcs);
    if (response.success && response.data != null) {
      try {
        final List list = response.data is List ? response.data : (response.data['gatcs'] ?? []);
        final parsed = list.map<GatcModel>((item) {
          final m = item as Map<String, dynamic>;
          return GatcModel(
            id: m['id']?.toString() ?? 'GATC-001',
            name: m['name']?.toString() ?? 'Govt Approved Test Centre',
            addressLine: m['addressLine']?.toString() ?? 'Mount Road, Chennai',
            district: m['district']?.toString() ?? 'Chennai',
            state: m['state']?.toString() ?? 'Tamil Nadu',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 19.0183,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 72.8478,
            contactPhone: m['contactPhone']?.toString() ?? '+919000000001',
            distanceKm: 2.5,
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
      try {
        final List list = response.data is List ? response.data : (response.data['applications'] ?? []);
        if (list.isNotEmpty) {
          for (final item in list) {
            final m = item as Map<String, dynamic>;
            final serverId = m['id']?.toString();
            if (serverId != null && !_applications.any((a) => a.id == serverId)) {
              _applications.insert(
                0,
                VendorApplicationModel(
                  id: serverId,
                  vendorId: vendorId,
                  instrumentId: m['instrumentId']?.toString() ?? 'VINST-001',
                  status: _mapStatus(m['status']?.toString()),
                  documentStatus: DocumentReviewStatus.approved,
                  uploadedDocuments: ['Invoice.pdf', 'Model_Approval.pdf'],
                  feeInPaise: 50000,
                  createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }
    return _applications.where((a) => a.vendorId == vendorId).toList();
  }

  VendorApplicationStatus _mapStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUBMITTED':
      case 'DOCUMENTS_PENDING':
        return VendorApplicationStatus.submitted;
      case 'DOCUMENTS_VERIFIED':
        return VendorApplicationStatus.documentReview;
      case 'PAYMENT_PENDING':
        return VendorApplicationStatus.paymentPending;
      case 'PAYMENT_COMPLETE':
        return VendorApplicationStatus.paymentComplete;
      case 'LMO_ASSIGNED':
        return VendorApplicationStatus.lmoAssigned;
      case 'INSPECTION_IN_PROGRESS':
        return VendorApplicationStatus.inspectionInProgress;
      case 'PASSED':
        return VendorApplicationStatus.passed;
      case 'CERTIFICATE_ISSUED':
        return VendorApplicationStatus.certificateIssued;
      default:
        return VendorApplicationStatus.submitted;
    }
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
    _applications.insert(0, app);

    // Call backend
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorApplications,
      body: {
        'instrumentId': app.instrumentId,
        'verificationMethod': app.verificationMethod.name,
        'isReverification': app.isReverification,
        'gatcId': app.gatcId,
      },
    );

    if (response.success && response.data != null) {
      final serverId = response.data!['id']?.toString();
      if (serverId != null) {
        final updatedApp = app.copyWith(id: serverId);
        final idx = _applications.indexWhere((a) => a.id == app.id);
        if (idx >= 0) _applications[idx] = updatedApp;
        return updatedApp;
      }
    }
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
