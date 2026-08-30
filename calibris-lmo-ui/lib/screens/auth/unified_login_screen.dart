import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/gov_header.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _idController = TextEditingController(text: 'officer001');
  final _passwordController = TextEditingController(text: 'demo');
  bool _obscurePassword = true;

  // Registration controllers (Page 1 Item 1: Login / Register)
  final _regNameController = TextEditingController(text: 'Suresh Kumar');
  final _regBusinessController = TextEditingController(text: 'Kumar Retail Scale Co.');
  final _regPhoneController = TextEditingController(text: '9820011223');
  final _regGstController = TextEditingController(text: '27AABCK1234F1Z5');
  final _regDistrictController = TextEditingController(text: 'Mumbai');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _idController.text = 'officer001';
      } else if (_tabController.index == 1) {
        _idController.text = 'vendor001';
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regBusinessController.dispose();
    _regPhoneController.dispose();
    _regGstController.dispose();
    _regDistrictController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String employeeId) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(employeeId, _passwordController.text);

    if (success && mounted) {
      final user = auth.currentUser;
      if (user != null && user.isVendor) {
        context.goNamed(AppRoutes.vendorDashboard);
      } else {
        context.goNamed(AppRoutes.dashboard);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor registered successfully! Logging you into the Vendor Portal...'),
        backgroundColor: AppColors.secondary,
      ),
    );
    await _handleLogin('vendor001');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Government Header ──
            const GovHeader(subtitle: 'SIH 2026 — Legal Metrology Verification System'),

            const SizedBox(height: 20),

            // ── Role Tabs (LMO, Vendor, Register) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 16),
                          SizedBox(width: 4),
                          Text('LMO Officer'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store, size: 16),
                          SizedBox(width: 4),
                          Text('Vendor Login'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 16),
                          SizedBox(width: 4),
                          Text('Register'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Forms Area ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _tabController.index == 2
                      // ── Registration Form (Page 1 Item 1) ──
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Vendor / Applicant Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            const Text('Register your business for weights & measures verification.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _regNameController,
                              decoration: const InputDecoration(labelText: 'Applicant Full Name', prefixIcon: Icon(Icons.person)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regBusinessController,
                              decoration: const InputDecoration(labelText: 'Business / Establishment Name', prefixIcon: Icon(Icons.storefront)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regPhoneController,
                              decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_android)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regGstController,
                              decoration: const InputDecoration(labelText: 'GSTIN / Trade License No.', prefixIcon: Icon(Icons.receipt)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regDistrictController,
                              decoration: const InputDecoration(labelText: 'District & State', prefixIcon: Icon(Icons.location_on)),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                                onPressed: isLoading ? null : _handleRegister,
                                child: const Text('COMPLETE REGISTRATION'),
                              ),
                            ),
                          ],
                        )
                      // ── Login Form (LMO or Vendor) ──
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _tabController.index == 0 ? 'LMO Officer Portal' : 'Vendor Portal Login',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tabController.index == 0
                                  ? 'Enter your Department Employee ID'
                                  : 'Enter your registered Mobile or Email ID',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _idController,
                              decoration: InputDecoration(
                                labelText: _tabController.index == 0 ? 'Employee ID' : 'Mobile / Email ID',
                                prefixIcon: Icon(_tabController.index == 0 ? Icons.badge : Icons.phone_android),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => _handleLogin(_idController.text.trim()),
                                child: isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('SIGN IN TO PORTAL'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Demo Login Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.demoGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science, size: 14, color: AppColors.demoGold),
                            SizedBox(width: 4),
                            Text(
                              'DEMO MODE — 1-Click Role Access',
                              style: TextStyle(color: AppColors.demoGold, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DemoLoginButton(
                    icon: Icons.gavel,
                    color: AppColors.lmoAccent,
                    title: 'Officer Rajesh Kumar (LMO)',
                    subtitle: 'Legal Metrology Officer — Mumbai',
                    isLoading: isLoading,
                    onTap: () => _handleLogin('officer001'),
                  ),
                  const SizedBox(height: 8),
                  _DemoLoginButton(
                    icon: Icons.store,
                    color: AppColors.vendorAccent,
                    title: 'Arjun Mehta (Vendor)',
                    subtitle: 'ABC Traders — Mumbai',
                    isLoading: isLoading,
                    onTap: () => _handleLogin('vendor001'),
                  ),
                  const SizedBox(height: 8),
                  _DemoLoginButton(
                    icon: Icons.store,
                    color: const Color(0xFF7C3AED),
                    title: 'Neha Joshi (Vendor)',
                    subtitle: 'XYZ Weighing Solutions — Pune',
                    isLoading: isLoading,
                    onTap: () => _handleLogin('vendor002'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'SIH 2026 | Legal Metrology Directorate • Government of India',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DemoLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _DemoLoginButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            color: color.withOpacity(0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 13, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
