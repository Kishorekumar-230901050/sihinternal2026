import '../models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String token;

  const AuthResult({required this.user, required this.token});
}

abstract class IAuthRepository {
  Future<AuthResult> login(String employeeId, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  bool get isLoggedIn;
  String? get token;
}
