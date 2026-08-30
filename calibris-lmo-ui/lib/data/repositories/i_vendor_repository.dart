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

  /// Books a real GATC appointment slot for [applicationId]; the returned
  /// application reflects the backend's authoritative post-booking status.
  Future<VendorApplicationModel> bookAppointment({
    required String applicationId,
    required String gatcId,
    required DateTime slotDate,
    required DateTime slotStart,
    required DateTime slotEnd,
  });

  /// Remaining slot capacity for a GATC + instrument type on a given day.
  Future<int> getSlotAvailability({
    required String gatcId,
    required String instrumentTypeId,
    required DateTime slotDate,
  });

  /// Runs the full mock-gateway payment cycle (order → checkout → verify)
  /// against the backend and returns the resulting payment record.
  Future<PaymentModel> payForApplication(String applicationId, int amountInPaise);

  Future<List<PaymentModel>> getPayments(String vendorId);
  Future<List<CertificateModel>> getCertificates(String vendorId);
  Future<CertificateModel?> getCertificate(String certId);
  Future<String?> uploadDocument({
    required String applicationId,
    required String fileName,
    required List<int> fileBytes,
    String documentType = 'OTHER',
  });
}
