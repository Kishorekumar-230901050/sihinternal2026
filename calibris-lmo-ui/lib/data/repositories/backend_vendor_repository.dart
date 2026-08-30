import 'dart:typed_data';
import 'i_vendor_repository.dart';
import '../models/instrument_model.dart';
import '../models/gatc_model.dart';
import '../models/vendor_application_model.dart';
import '../models/payment_model.dart';
import '../models/certificate_model.dart';
import '../../services/api_client.dart';
import '../../core/config/api_config.dart';

class BackendVendorRepository implements IVendorRepository {
  final ApiClient apiClient;

  final List<VendorApplicationModel> _appCache = [];
  final List<CertificateModel> _certCache = [];

  BackendVendorRepository({required this.apiClient});

  @override
  Future<List<InstrumentInfo>> getInstruments(String vendorId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorInstruments);
    if (response.success && response.data is List) {
      return (response.data as List)
          .map((e) => InstrumentInfo.fromBackendJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(response.errorMessage ?? 'Failed to load instruments');
  }

  @override
  Future<void> registerInstrument(InstrumentInfo instrument) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorInstruments,
      body: {
        'serialNumber': instrument.serialNumber,
        'model': instrument.model,
        'manufacturer': instrument.manufacturer,
        'capacity': instrument.capacity,
      },
    );
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to register instrument');
    }
  }

  @override
  Future<List<GatcModel>> getGatcs() async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorGatcs);
    if (response.success && response.data is List) {
      return (response.data as List).map<GatcModel>((item) {
        final m = item as Map<String, dynamic>;
        final location = m['location'] as Map<String, dynamic>?;
        final types = (m['instrumentTypes'] as List?)
                ?.map((t) => (t as Map<String, dynamic>)['instrumentTypeId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList() ??
            const <String>[];
        return GatcModel(
          id: m['id'].toString(),
          name: m['name']?.toString() ?? 'Test Centre',
          addressLine: m['addressLine']?.toString() ?? '',
          district: location?['district']?.toString() ?? '',
          state: location?['state']?.toString() ?? '',
          latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
          contactPhone: m['contactPhone']?.toString(),
          dailyCapacity: 20,
          supportedInstrumentTypes: types,
          distanceKm: (m['distanceKm'] as num?)?.toDouble(),
        );
      }).toList();
    }
    throw Exception(response.errorMessage ?? 'Failed to load test centres');
  }

  VendorApplicationStatus _mapStatus(String status) {
    switch (status) {
      case 'SUBMITTED':
        return VendorApplicationStatus.submitted;
      case 'DOCUMENTS_PENDING':
        return VendorApplicationStatus.documentReview;
      case 'DOCUMENTS_VERIFIED':
        return VendorApplicationStatus.documentReview;
      case 'SLOT_BOOKED':
        return VendorApplicationStatus.scheduled;
      case 'PAYMENT_PENDING':
        return VendorApplicationStatus.paymentPending;
      case 'PAYMENT_COMPLETE':
        return VendorApplicationStatus.paymentComplete;
      case 'LMO_ASSIGNED':
        return VendorApplicationStatus.lmoAssigned;
      case 'INSPECTION_IN_PROGRESS':
        return VendorApplicationStatus.inspectionInProgress;
      case 'INSPECTION_COMPLETE':
        return VendorApplicationStatus.inspectionInProgress;
      case 'PASSED':
        return VendorApplicationStatus.passed;
      case 'FAILED':
        return VendorApplicationStatus.rejected;
      case 'REJECTED':
        return VendorApplicationStatus.rejected;
      case 'CANCELLED':
        return VendorApplicationStatus.rejected;
      case 'CERTIFICATE_ISSUED':
        return VendorApplicationStatus.certificateIssued;
      default:
        return VendorApplicationStatus.submitted;
    }
  }

  VendorApplicationModel _mapApplication(Map<String, dynamic> m, String vendorId) {
    final instrument = m['instrument'] as Map<String, dynamic>?;
    final instrumentType = instrument?['instrumentType'] as Map<String, dynamic>?;
    final gatc = m['gatc'] as Map<String, dynamic>?;
    final assignedLmo = m['assignedLmo'] as Map<String, dynamic>?;
    final certificate = m['certificate'] as Map<String, dynamic>?;
    final appointment = m['appointment'] as Map<String, dynamic>?;

    return VendorApplicationModel(
      id: m['id'].toString(),
      vendorId: vendorId,
      instrumentId: instrument?['id']?.toString() ?? m['instrumentId']?.toString() ?? '',
      status: _mapStatus(m['status'].toString()),
      gatcId: gatc?['id']?.toString(),
      gatcName: gatc?['name']?.toString(),
      assignedLmoName: assignedLmo?['fullName']?.toString(),
      slotDate: appointment?['slotDate'] != null ? DateTime.tryParse(appointment!['slotDate'].toString()) : null,
      feeInPaise: (instrumentType?['feeInPaise'] as num?)?.toInt(),
      certificateId: certificate?['id']?.toString(),
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      instrumentInfo: instrument != null ? InstrumentInfo.fromBackendJson(instrument) : null,
    );
  }

  @override
  Future<List<VendorApplicationModel>> getApplications(String vendorId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorApplications);
    if (response.success && response.data is List) {
      _appCache
        ..clear()
        ..addAll((response.data as List).map((e) => _mapApplication(e as Map<String, dynamic>, vendorId)));
      return List.from(_appCache);
    }
    throw Exception(response.errorMessage ?? 'Failed to load applications');
  }

  @override
  Future<VendorApplicationModel?> getApplication(String applicationId) async {
    final response = await apiClient.get<dynamic>(ApiConfig.vendorApplication(applicationId));
    if (response.success && response.data is Map) {
      final m = response.data as Map<String, dynamic>;
      final app = _mapApplication(m, m['vendorId']?.toString() ?? '');
      final idx = _appCache.indexWhere((a) => a.id == app.id);
      if (idx >= 0) {
        _appCache[idx] = app;
      } else {
        _appCache.add(app);
      }
      return app;
    }
    return null;
  }

  @override
  Future<VendorApplicationModel> createApplication(VendorApplicationModel app) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorApplications,
      body: {
        'instrumentId': app.instrumentId,
        if (app.gatcId != null) 'gatcId': app.gatcId,
      },
    );
    if (!response.success || response.data == null) {
      throw Exception(response.errorMessage ?? 'Failed to submit application');
    }
    final created = _mapApplication(response.data!, app.vendorId);
    _appCache.add(created);
    return created;
  }

  @override
  Future<VendorApplicationModel> bookAppointment({
    required String applicationId,
    required String gatcId,
    required DateTime slotDate,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorAppointments,
      body: {
        'applicationId': applicationId,
        'gatcId': gatcId,
        'slotDate': slotDate.toIso8601String(),
        'slotStart': slotStart.toIso8601String(),
        'slotEnd': slotEnd.toIso8601String(),
      },
    );
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to book appointment slot');
    }
    final updated = await getApplication(applicationId);
    if (updated == null) throw Exception('Application not found after booking');
    return updated;
  }

  @override
  Future<int> getSlotAvailability({
    required String gatcId,
    required String instrumentTypeId,
    required DateTime slotDate,
  }) async {
    final dateStr = slotDate.toIso8601String().split('T').first;
    final url = Uri.parse(ApiConfig.vendorGatcAvailability).replace(queryParameters: {
      'gatcId': gatcId,
      'instrumentTypeId': instrumentTypeId,
      'slotDate': dateStr,
    }).toString();
    final response = await apiClient.get<Map<String, dynamic>>(url);
    if (response.success && response.data != null) {
      return (response.data!['remaining'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  @override
  Future<PaymentModel> payForApplication(String applicationId, int amountInPaise) async {
    final orderResponse = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorPaymentOrders,
      body: {'applicationId': applicationId},
    );
    if (!orderResponse.success || orderResponse.data == null) {
      throw Exception(orderResponse.errorMessage ?? 'Failed to create payment order');
    }
    final orderRef = orderResponse.data!['orderRef'].toString();

    final checkoutResponse = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorPaymentSimulateCheckout,
      body: {'orderRef': orderRef},
    );
    if (!checkoutResponse.success || checkoutResponse.data == null) {
      throw Exception(checkoutResponse.errorMessage ?? 'Payment checkout failed');
    }
    final transactionRef = checkoutResponse.data!['transactionRef'].toString();
    final signature = checkoutResponse.data!['signature'].toString();

    final verifyResponse = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.vendorPaymentVerify,
      body: {'orderRef': orderRef, 'transactionRef': transactionRef, 'signature': signature},
    );
    final verified = verifyResponse.success && verifyResponse.data?['verified'] == true;
    if (!verified) {
      throw Exception(verifyResponse.errorMessage ?? 'Payment verification failed');
    }

    return PaymentModel(
      id: orderRef,
      applicationId: applicationId,
      amountInPaise: amountInPaise,
      status: PaymentStatus.success,
      provider: 'MOCK_RAZORPAY',
      orderRef: orderRef,
      transactionRef: transactionRef,
      createdAt: DateTime.now(),
    );
  }

  /// Upload document to backend storage via multipart
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
      additionalFields: {'type': documentType},
    );

    if (response.success && response.data != null) {
      final doc = response.data!['document'] as Map<String, dynamic>?;
      return doc?['fileUrl']?.toString() ?? response.data!['url']?.toString();
    }
    throw Exception(response.errorMessage ?? 'Upload failed');
  }

  @override
  Future<List<PaymentModel>> getPayments(String vendorId) async {
    // No standalone "my payments" listing endpoint exists server-side;
    // payments are read per-application via the receipt endpoint instead.
    return const [];
  }

  @override
  Future<List<CertificateModel>> getCertificates(String vendorId) async {
    final issuedApps = _appCache.where((a) => a.certificateId != null);
    _certCache.clear();
    for (final app in issuedApps) {
      final cert = await getCertificateForApplication(app.id, app.instrumentId, vendorId);
      if (cert != null) _certCache.add(cert);
    }
    return List.from(_certCache);
  }

  Future<CertificateModel?> getCertificateForApplication(
    String applicationId,
    String instrumentId,
    String vendorId,
  ) async {
    final response = await apiClient.get<Map<String, dynamic>>(ApiConfig.vendorCertificate(applicationId));
    if (response.success && response.data != null) {
      return CertificateModel.fromBackendJson(response.data!, instrumentId: instrumentId, applicantId: vendorId);
    }
    return null;
  }

  @override
  Future<CertificateModel?> getCertificate(String certId) async {
    try {
      return _certCache.firstWhere((c) => c.id == certId);
    } catch (_) {
      return null;
    }
  }
}
