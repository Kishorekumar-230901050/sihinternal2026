import 'instrument_model.dart';

/// Verification method chosen for reverification / initial verification
enum VerificationMethod {
  digitalEthernet,
  manualOffline,
}

/// Document review status by LMO officer
enum DocumentReviewStatus {
  pending,
  approved,
  reuploadRequested,
}

/// Vendor-side application status matching the bible lifecycle.
enum VendorApplicationStatus {
  draft,
  submitted,
  documentReview,
  reuploadRequested,
  paymentPending,
  paymentComplete,
  scheduled,
  lmoAssigned,
  inspectionInProgress,
  passed,
  rejected,
  departmentApproved,
  certificateIssued,
}

/// Represents a verification application from the vendor's perspective.
class VendorApplicationModel {
  final String id;
  final String vendorId;
  final String instrumentId;
  final bool isReverification;
  final VerificationMethod verificationMethod;
  final String? gatcId;
  final String? gatcName;
  final VendorApplicationStatus status;
  final DocumentReviewStatus documentStatus;
  final String? reuploadReason;
  final List<String> uploadedDocuments; // e.g. ["Invoice_2026.pdf", "Model_Approval.pdf", "Instrument_Photo.jpg"]
  final String? assignedLmoName;
  final DateTime? slotDate;
  final String? slotTime;        // "Morning (9:00 AM – 12:00 PM)" or "Afternoon (1:00 PM – 4:00 PM)"
  final String? paymentId;
  final int? feeInPaise;
  final String? rejectionReason;
  final String? certificateId;
  final double? geotagLat;
  final double? geotagLng;
  final DateTime? geotagTimestamp;
  final String? geotagPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InstrumentInfo? instrumentInfo;

  const VendorApplicationModel({
    required this.id,
    required this.vendorId,
    required this.instrumentId,
    this.isReverification = false,
    this.verificationMethod = VerificationMethod.digitalEthernet,
    this.gatcId,
    this.gatcName,
    required this.status,
    this.documentStatus = DocumentReviewStatus.pending,
    this.reuploadReason,
    this.uploadedDocuments = const [],
    this.assignedLmoName,
    this.slotDate,
    this.slotTime,
    this.paymentId,
    this.feeInPaise,
    this.rejectionReason,
    this.certificateId,
    this.geotagLat,
    this.geotagLng,
    this.geotagTimestamp,
    this.geotagPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.instrumentInfo,
  });

  String get statusLabel {
    switch (status) {
      case VendorApplicationStatus.draft:
        return 'Draft';
      case VendorApplicationStatus.submitted:
        return 'Application Submitted';
      case VendorApplicationStatus.documentReview:
        return 'Document Review In Progress';
      case VendorApplicationStatus.reuploadRequested:
        return 'Documents Re-upload Requested';
      case VendorApplicationStatus.paymentPending:
        return 'Fee Payment Pending';
      case VendorApplicationStatus.paymentComplete:
        return 'Payment Complete';
      case VendorApplicationStatus.scheduled:
        return 'GATC Slot Confirmed';
      case VendorApplicationStatus.lmoAssigned:
        return 'LMO Officer Assigned';
      case VendorApplicationStatus.inspectionInProgress:
        return 'Inspection In Progress';
      case VendorApplicationStatus.passed:
        return 'Inspection Passed';
      case VendorApplicationStatus.rejected:
        return 'Inspection Rejected';
      case VendorApplicationStatus.departmentApproved:
        return 'Department Approved';
      case VendorApplicationStatus.certificateIssued:
        return 'Signed Certificate Issued';
    }
  }

  VendorApplicationModel copyWith({
    String? id,
    String? vendorId,
    String? instrumentId,
    VendorApplicationStatus? status,
    DocumentReviewStatus? documentStatus,
    String? reuploadReason,
    List<String>? uploadedDocuments,
    bool? isReverification,
    VerificationMethod? verificationMethod,
    String? gatcId,
    String? gatcName,
    DateTime? slotDate,
    String? slotTime,
    String? paymentId,
    int? feeInPaise,
    String? assignedLmoName,
    String? rejectionReason,
    String? certificateId,
    double? geotagLat,
    double? geotagLng,
    DateTime? geotagTimestamp,
    String? geotagPhotoUrl,
    DateTime? updatedAt,
    InstrumentInfo? instrumentInfo,
  }) {
    return VendorApplicationModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      instrumentId: instrumentId ?? this.instrumentId,
      isReverification: isReverification ?? this.isReverification,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      gatcId: gatcId ?? this.gatcId,
      gatcName: gatcName ?? this.gatcName,
      status: status ?? this.status,
      documentStatus: documentStatus ?? this.documentStatus,
      reuploadReason: reuploadReason ?? this.reuploadReason,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      assignedLmoName: assignedLmoName ?? this.assignedLmoName,
      slotDate: slotDate ?? this.slotDate,
      slotTime: slotTime ?? this.slotTime,
      paymentId: paymentId ?? this.paymentId,
      feeInPaise: feeInPaise ?? this.feeInPaise,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      certificateId: certificateId ?? this.certificateId,
      geotagLat: geotagLat ?? this.geotagLat,
      geotagLng: geotagLng ?? this.geotagLng,
      geotagTimestamp: geotagTimestamp ?? this.geotagTimestamp,
      geotagPhotoUrl: geotagPhotoUrl ?? this.geotagPhotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      instrumentInfo: instrumentInfo ?? this.instrumentInfo,
    );
  }
}
