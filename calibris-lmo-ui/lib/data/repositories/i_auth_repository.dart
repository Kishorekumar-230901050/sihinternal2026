import '../models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String token;

  const AuthResult({required this.user, required this.token});
}

abstract class IAuthRepository {
  Future<AuthResult> login(UserRole role, String identifier, String password);
  Future<AuthResult> registerVendor({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? businessName,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  bool get isLoggedIn;
  String? get token;
}
