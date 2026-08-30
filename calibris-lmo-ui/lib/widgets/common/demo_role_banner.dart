import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/user_model.dart';

/// Floating banner for 1-tap role switching during demonstrations.
class DemoRoleBanner extends StatelessWidget {
  const DemoRoleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Positioned(
        bottom: 0,
        right: 0,
        child: SizedBox(width: 1, height: 1),
      );
    }

    final isVendor = user.isVendor;
    final roleLabel = isVendor ? 'VENDOR' : 'LMO';
    final roleColor = isVendor ? AppColors.vendorAccent : AppColors.lmoAccent;

    return Positioned(
      bottom: 24,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: roleColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _showSwitchDialog(context, user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DEMO: $roleLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSwitchDialog(BuildContext context, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.demoGold),
                const SizedBox(width: 8),
                Text(
                  'Switch Demo Role',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Currently logged in as: ${currentUser.name} (${currentUser.isVendor ? "Vendor" : "LMO"})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _RoleTile(
              icon: Icons.gavel,
              title: 'Officer Rajesh Kumar',
              subtitle: 'LMO — Mumbai District',
              color: AppColors.lmoAccent,
              isActive: currentUser.employeeId == 'officer001',
              onTap: () => _switchTo(context, 'officer001'),
            ),
            const SizedBox(height: 8),
            _RoleTile(
              icon: Icons.store,
              title: 'Arjun Mehta — ABC Traders',
              subtitle: 'Vendor — Mumbai',
              color: AppColors.vendorAccent,
              isActive: currentUser.employeeId == 'vendor001',
              onTap: () => _switchTo(context, 'vendor001'),
            ),
            const SizedBox(height: 8),
            _RoleTile(
              icon: Icons.store,
              title: 'Neha Joshi — XYZ Weighing',
              subtitle: 'Vendor — Pune',
              color: AppColors.vendorAccent,
              isActive: currentUser.employeeId == 'vendor002',
              onTap: () => _switchTo(context, 'vendor002'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _switchTo(BuildContext context, String employeeId) async {
    Navigator.of(context).pop(); // close bottom sheet
    final auth = context.read<AuthProvider>();
    await auth.logout();
    await auth.login(employeeId, 'demo');
    if (context.mounted) {
      final user = auth.currentUser;
      if (user != null && user.isVendor) {
        context.goNamed(AppRoutes.vendorDashboard);
      } else {
        context.goNamed(AppRoutes.dashboard);
      }
    }
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? color.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : AppColors.border,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
