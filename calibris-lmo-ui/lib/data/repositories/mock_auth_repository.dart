import 'i_auth_repository.dart';
import '../models/user_model.dart';
import '../mock/mock_data.dart';

class MockAuthRepository implements IAuthRepository {
  UserModel? _currentUser;
  String? _token;

  @override
  Future<AuthResult> login(String employeeId, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // No validation per requirements — accept any password in demo mode
    try {
      final user = MockDataStore.users.firstWhere((u) => u.employeeId == employeeId);
      _currentUser = user;
      _token = 'mock-token-${user.role.name}-12345';
      return AuthResult(user: user, token: _token!);
    } catch (e) {
      throw Exception('User not found');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _token = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  String? get token => _token;
}
