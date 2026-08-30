import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final String applicationId;
  const PaymentGatewayScreen({super.key, required this.applicationId});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  String _selectedMethod = 'UPI';
  bool _isProcessing = false;

  Future<void> _pay() async {
    setState(() => _isProcessing = true);

    final vendor = context.read<VendorProvider>();
    try {
      await vendor.payForCurrentApplication();
      if (mounted) {
        context.pushReplacementNamed(
          AppRoutes.vendorPaymentReceipt,
          pathParameters: {'id': widget.applicationId},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final app = vendor.currentApplication;
    final amount = (app?.feeInPaise ?? 50000) / 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Amount Payable', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Application: ${widget.applicationId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Select Payment Method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            ...const [
              _PaymentOption(id: 'UPI', icon: Icons.account_balance_wallet, title: 'UPI / Google Pay / PhonePe'),
              _PaymentOption(id: 'NetBanking', icon: Icons.account_balance, title: 'Net Banking'),
              _PaymentOption(id: 'Card', icon: Icons.credit_card, title: 'Debit / Credit Card'),
            ].map((m) {
              final isSelected = _selectedMethod == m.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppColors.vendorAccent : AppColors.border, width: isSelected ? 2 : 1),
                ),
                child: ListTile(
                  leading: Icon(m.icon, color: isSelected ? AppColors.vendorAccent : AppColors.textSecondary),
                  title: Text(m.title),
                  trailing: Radio<String>(
                    value: m.id,
                    groupValue: _selectedMethod,
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                    activeColor: AppColors.vendorAccent,
                  ),
                  onTap: () => setState(() => _selectedMethod = m.id),
                ),
              );
            }),

            const Spacer(),

            const Text(
              'This uses the department\'s sandbox payment gateway.\nNo real money is charged.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                onPressed: _isProcessing ? null : _pay,
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text('PAY ₹${amount.toStringAsFixed(2)}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption {
  final String id;
  final IconData icon;
  final String title;

  const _PaymentOption({
    required this.id,
    required this.icon,
    required this.title,
  });
}

