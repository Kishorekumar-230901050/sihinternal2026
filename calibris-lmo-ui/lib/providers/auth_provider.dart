import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/i_auth_repository.dart';
import '../services/audit_service.dart';
import '../data/models/audit_log_model.dart';

class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepository;
  final AuditService _auditService = AuditService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _restoring = true;

  AuthProvider(this._authRepository) {
    _restoreSession();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isRestoring => _restoring;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> _restoreSession() async {
    _currentUser = await _authRepository.getCurrentUser();
    _restoring = false;
    notifyListeners();
  }

  Future<bool> login(UserRole role, String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(role, identifier, password);
      _currentUser = result.user;
      _auditService.log(_currentUser!.id, AuditAction.login);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerVendor({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? businessName,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.registerVendor(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        businessName: businessName,
        addressLine: addressLine,
        city: city,
        state: state,
        pincode: pincode,
      );
      _currentUser = result.user;
      _auditService.log(_currentUser!.id, AuditAction.login);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      _auditService.log(_currentUser!.id, AuditAction.logout);
    }
    await _authRepository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
