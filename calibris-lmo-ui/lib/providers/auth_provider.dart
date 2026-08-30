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

  AuthProvider(this._authRepository);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String employeeId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(employeeId, password);
      _currentUser = result.user;
      _auditService.log(_currentUser!.id, AuditAction.login);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
