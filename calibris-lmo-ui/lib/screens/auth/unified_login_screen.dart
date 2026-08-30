import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common/gov_header.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Registration fields
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regBusinessController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regDistrictController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regBusinessController.dispose();
    _regPhoneController.dispose();
    _regDistrictController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final role = _tabController.index == 0 ? UserRole.lmo : UserRole.vendor;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(role, _idController.text.trim(), _passwordController.text);

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
    if (!_registerFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.registerVendor(
      fullName: _regNameController.text.trim(),
      email: _regEmailController.text.trim(),
      phone: _regPhoneController.text.trim(),
      password: _regPasswordController.text,
      businessName: _regBusinessController.text.trim().isEmpty ? null : _regBusinessController.text.trim(),
      city: _regDistrictController.text.trim().isEmpty ? null : _regDistrictController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully.'), backgroundColor: AppColors.secondary),
      );
      context.goNamed(AppRoutes.vendorDashboard);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                        children: [Icon(Icons.gavel, size: 16), SizedBox(width: 4), Text('LMO Officer')],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.store, size: 16), SizedBox(width: 4), Text('Vendor Login')],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.person_add, size: 16), SizedBox(width: 4), Text('Register')],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _tabController.index == 2
                      ? Form(
                          key: _registerFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Vendor / Applicant Registration',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            const Text('Register your business for weights & measures verification.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _regNameController,
                              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                              validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                                  ? 'Enter a valid email address'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                helperText: 'Minimum 8 characters',
                              ),
                              validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: Icon(Icons.phone_android),
                                helperText: 'Minimum 8 digits',
                              ),
                              validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid mobile number' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regBusinessController,
                              decoration: const InputDecoration(labelText: 'Business / Establishment Name (optional)', prefixIcon: Icon(Icons.storefront)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regDistrictController,
                              decoration: const InputDecoration(labelText: 'City (optional)', prefixIcon: Icon(Icons.location_on)),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                                onPressed: isLoading ? null : _handleRegister,
                                child: isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('COMPLETE REGISTRATION'),
                              ),
                            ),
                          ],
                          ),
                        )
                      : Form(
                          key: _loginFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _tabController.index == 0 ? 'LMO Officer Portal' : 'Vendor Portal Login',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enter your registered email and password',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _idController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.badge)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
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
                              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
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
