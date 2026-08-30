import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/info_row.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.vendorAccent, Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      if (user?.businessName != null)
                        Text(user!.businessName!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(user?.effectiveEmail ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const Divider(),
                  InfoRow(label: 'Business Name', value: user?.businessName ?? '—'),
                  InfoRow(label: 'GST Number', value: user?.gstNumber ?? '—'),
                  InfoRow(label: 'Phone', value: user?.phone ?? '—'),
                  InfoRow(label: 'Address', value: user?.addressLine ?? '—'),
                  InfoRow(label: 'City', value: user?.city ?? '—'),
                  InfoRow(label: 'State', value: user?.state ?? '—'),
                  InfoRow(label: 'Pincode', value: user?.pincode ?? '—'),
                  InfoRow(label: 'District', value: user?.district ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Logout', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.goNamed(AppRoutes.login);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
