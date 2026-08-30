import '../models/certificate_model.dart';

abstract class ICertificateRepository {
  Future<CertificateModel> requestCertificate({
    required String applicationId,
    required String instrumentId,
    required String inspectionId,
    required String applicantId,
    required String officerId,
  });
  Future<CertificateModel?> getCertificateById(String certId);
  Future<CertificateModel?> verifyCertificate(String certId);
}
