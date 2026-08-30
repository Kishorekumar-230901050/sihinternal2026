import 'dart:math';
import 'i_certificate_repository.dart';
import '../models/certificate_model.dart';
import '../mock/mock_data.dart';
import '../../core/constants/app_constants.dart';

class MockCertificateRepository implements ICertificateRepository {
  @override
  Future<CertificateModel> requestCertificate({
    required String applicationId,
    required String instrumentId,
    required String inspectionId,
    required String applicantId,
    required String officerId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final number = 'CERT-2026-${Random().nextInt(99999).toString().padLeft(5, '0')}';
    
    final cert = CertificateModel(
      id: number,
      certificateNumber: number,
      applicationId: applicationId,
      instrumentId: instrumentId,
      inspectionId: inspectionId,
      applicantId: applicantId,
      officerId: officerId,
      issuedAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: AppConstants.certificateValidityMonths * 30)),
      reverificationDue: DateTime.now().add(const Duration(days: (AppConstants.certificateValidityMonths - AppConstants.reverificationLeadMonths) * 30)),
      status: CertificateStatus.active,
    );
    
    MockDataStore.certificates.add(cert);
    return cert;
  }

  @override
  Future<CertificateModel?> getCertificateById(String certId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return MockDataStore.certificates.firstWhere((c) => c.id == certId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CertificateModel?> verifyCertificate(String certId) async {
    return getCertificateById(certId);
  }
}
