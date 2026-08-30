import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<(UserModel, String)> login(String employeeId, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  bool get isLoggedIn;
  String? get token;
}
