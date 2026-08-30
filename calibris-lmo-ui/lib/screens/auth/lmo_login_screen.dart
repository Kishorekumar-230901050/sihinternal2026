import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';

class LmoLoginScreen extends StatefulWidget {
  const LmoLoginScreen({super.key});

  @override
  State<LmoLoginScreen> createState() => _LmoLoginScreenState();
}

class _LmoLoginScreenState extends State<LmoLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController(text: 'officer001');
  final _passwordController = TextEditingController(text: 'Lmo@1234');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _employeeIdController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        context.goNamed(AppRoutes.dashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Legal Metrology Officer Portal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Online Verification System',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _employeeIdController,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: Validators.employeeId,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white),
                                  )
                                : const Text('LOGIN'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Demo: officer001 / Lmo@1234',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'SIH 2026 | Ministry of Consumer Affairs',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
