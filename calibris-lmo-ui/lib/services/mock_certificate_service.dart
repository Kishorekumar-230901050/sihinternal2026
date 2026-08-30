import 'i_certificate_service.dart';
import '../data/models/certificate_model.dart';
import '../data/repositories/i_certificate_repository.dart';

class MockCertificateService implements ICertificateService {
  final ICertificateRepository _repository;

  MockCertificateService(this._repository);

  @override
  Future<String> submitForCertification({
    required String applicationId,
    required String instrumentId,
    required String inspectionId,
    required String applicantId,
    required String officerId,
    required DateTime verificationDate,
  }) async {
    final cert = await _repository.requestCertificate(
      applicationId: applicationId,
      instrumentId: instrumentId,
      inspectionId: inspectionId,
      applicantId: applicantId,
      officerId: officerId,
    );
    return cert.id;
  }

  @override
  Future<CertificateModel?> getCertificate(String certId) {
    return _repository.getCertificateById(certId);
  }

  @override
  Future<bool> verifyCertificate(String certId) async {
    final cert = await _repository.verifyCertificate(certId);
    return cert != null && cert.status == CertificateStatus.active;
  }
}
