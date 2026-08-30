import '../data/models/certificate_model.dart';

abstract class ICertificateService {
  Future<String> submitForCertification({
    required String applicationId,
    required String instrumentId,
    required String inspectionId,
    required String applicantId,
    required String officerId,
    required DateTime verificationDate,
  });
  Future<CertificateModel?> getCertificate(String certId);
  Future<bool> verifyCertificate(String certId);
}
