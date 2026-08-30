import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Official Ministry header banner with Ashoka emblem styling.
class GovHeader extends StatelessWidget {
  final String? subtitle;

  const GovHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Ashoka emblem placeholder using icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.account_balance, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'भारत सरकार | Government of India',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ministry of Consumer Affairs,\nFood & Public Distribution',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.saffron,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CALIBRIS — Legal Metrology Verification Platform',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
