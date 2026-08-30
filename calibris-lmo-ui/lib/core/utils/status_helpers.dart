import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/models/application_model.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/device_model.dart';

class StatusHelpers {
  static Color getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted: return Colors.blue;
      case ApplicationStatus.underReview: return Colors.orange;
      case ApplicationStatus.approvedForVerification: return Colors.indigo;
      case ApplicationStatus.verificationScheduled: return Colors.cyan;
      case ApplicationStatus.inspectionInProgress: return Colors.amber;
      case ApplicationStatus.verificationSubmitted: return Colors.purple;
      case ApplicationStatus.approved: return AppColors.secondary;
      case ApplicationStatus.rejected: return AppColors.error;
      case ApplicationStatus.certificatePending: return Colors.teal;
      case ApplicationStatus.certificateIssued: return AppColors.secondary;
    }
  }

  static String getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted: return 'Submitted';
      case ApplicationStatus.underReview: return 'Under Review';
      case ApplicationStatus.approvedForVerification: return 'Approved For Verification';
      case ApplicationStatus.verificationScheduled: return 'Verification Scheduled';
      case ApplicationStatus.inspectionInProgress: return 'Inspection In Progress';
      case ApplicationStatus.verificationSubmitted: return 'Verification Submitted';
      case ApplicationStatus.approved: return 'Approved';
      case ApplicationStatus.rejected: return 'Rejected';
      case ApplicationStatus.certificatePending: return 'Certificate Pending';
      case ApplicationStatus.certificateIssued: return 'Certificate Issued';
    }
  }

  static IconData getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved:
      case ApplicationStatus.certificateIssued:
        return Icons.check_circle;
      case ApplicationStatus.rejected: return Icons.cancel;
      default: return Icons.access_time;
    }
  }

  static Color getResultColor(InspectionResult result) {
    switch (result) {
      case InspectionResult.pass: return AppColors.secondary;
      case InspectionResult.fail: return AppColors.error;
      case InspectionResult.pending: return AppColors.warning;
    }
  }

  static Color getDeviceHealthColor(DeviceHealth health) {
    switch (health) {
      case DeviceHealth.normal: return AppColors.secondary;
      case DeviceHealth.warning: return AppColors.warning;
      case DeviceHealth.critical: return AppColors.error;
      case DeviceHealth.offline: return Colors.grey;
    }
  }

  static IconData getDeviceHealthIcon(DeviceHealth health) {
    switch (health) {
      case DeviceHealth.normal: return Icons.check_circle;
      case DeviceHealth.warning: return Icons.warning;
      case DeviceHealth.critical: return Icons.error;
      case DeviceHealth.offline: return Icons.offline_bolt;
    }
  }
}
