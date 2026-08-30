import '../models/instrument_model.dart';
import '../models/gatc_model.dart';
import '../models/vendor_application_model.dart';
import '../models/payment_model.dart';
import '../models/certificate_model.dart';

/// Vendor data access interface.
abstract class IVendorRepository {
  Future<List<InstrumentInfo>> getInstruments(String vendorId);
  Future<void> registerInstrument(InstrumentInfo instrument);
  Future<List<GatcModel>> getGatcs();
  Future<List<VendorApplicationModel>> getApplications(String vendorId);
  Future<VendorApplicationModel?> getApplication(String applicationId);
  Future<VendorApplicationModel> createApplication(VendorApplicationModel app);
  Future<VendorApplicationModel> updateApplication(VendorApplicationModel app);
  Future<List<PaymentModel>> getPayments(String vendorId);
  Future<List<CertificateModel>> getCertificates(String vendorId);
  Future<CertificateModel?> getCertificate(String certId);
}
