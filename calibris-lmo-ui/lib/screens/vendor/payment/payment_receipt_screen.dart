import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final String applicationId;
  const PaymentReceiptScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 56, color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              const Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Text('Application $applicationId', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _Row(label: 'Transaction ID', value: 'TXN-BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                      _Row(label: 'Application ID', value: applicationId),
                      _Row(label: 'Amount Paid', value: '₹500.00'),
                      _Row(label: 'Payment Mode', value: 'Bharatkosh UPI'),
                      _Row(label: 'Status', value: 'SUCCESS', valueColor: AppColors.secondary),
                      _Row(label: 'Date', value: DateTime.now().toString().substring(0, 16)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.pushNamed(
                    AppRoutes.vendorApplicationTracking,
                    pathParameters: {'id': applicationId},
                  ),
                  child: const Text('TRACK APPLICATION'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.goNamed(AppRoutes.vendorDashboard),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
