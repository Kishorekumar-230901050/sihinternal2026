import 'dart:convert';
import 'i_auth_repository.dart';
import '../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/token_storage_service.dart';
import '../../core/config/api_config.dart';

class BackendAuthRepository implements IAuthRepository {
  final ApiClient apiClient;
  final TokenStorageService tokenStorage;
  UserModel? _currentUser;
  String? _token;

  BackendAuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  @override
  Future<AuthResult> login(UserRole role, String identifier, String password) async {
    final endpoint = role == UserRole.lmo ? ApiConfig.authLmoLogin : ApiConfig.authVendorLogin;

    final response = await apiClient.post<Map<String, dynamic>>(
      endpoint,
      body: {'email': identifier.trim(), 'password': password},
    );

    if (!response.success || response.data == null) {
      throw Exception(response.errorMessage ?? 'Login failed');
    }

    final token = response.data!['token'] as String;
    final UserModel user;
    if (role == UserRole.lmo) {
      final lmoData = response.data!['lmo'] as Map<String, dynamic>;
      user = UserModel(
        id: lmoData['id'].toString(),
        employeeId: lmoData['employeeCode']?.toString() ?? lmoData['id'].toString(),
        name: lmoData['fullName']?.toString() ?? 'LMO Officer',
        district: '',
        email: lmoData['email']?.toString(),
        role: UserRole.lmo,
      );
    } else {
      final userData = response.data!['user'] as Map<String, dynamic>;
      user = UserModel(
        id: userData['id'].toString(),
        employeeId: userData['id'].toString(),
        name: userData['fullName']?.toString() ?? 'Vendor',
        district: userData['city']?.toString() ?? '',
        email: userData['email']?.toString(),
        phone: userData['phone']?.toString(),
        businessName: userData['businessName']?.toString(),
        addressLine: userData['addressLine']?.toString(),
        city: userData['city']?.toString(),
        state: userData['state']?.toString(),
        pincode: userData['pincode']?.toString(),
        role: UserRole.vendor,
      );
    }

    await _persistSession(token: token, user: user);
    return AuthResult(user: user, token: token);
  }

  @override
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
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConfig.authVendorRegister,
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'businessName': businessName,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(response.errorMessage ?? 'Registration failed');
    }

    final token = response.data!['token'] as String;
    final userData = response.data!['user'] as Map<String, dynamic>;
    final user = UserModel(
      id: userData['id'].toString(),
      employeeId: userData['id'].toString(),
      name: userData['fullName']?.toString() ?? fullName,
      district: userData['city']?.toString() ?? city ?? '',
      email: userData['email']?.toString() ?? email,
      phone: userData['phone']?.toString() ?? phone,
      businessName: userData['businessName']?.toString() ?? businessName,
      addressLine: userData['addressLine']?.toString() ?? addressLine,
      city: userData['city']?.toString() ?? city,
      state: userData['state']?.toString() ?? state,
      pincode: userData['pincode']?.toString() ?? pincode,
      role: UserRole.vendor,
    );

    await _persistSession(token: token, user: user);
    return AuthResult(user: user, token: token);
  }

  Future<void> _persistSession({required String token, required UserModel user}) async {
    _currentUser = user;
    _token = token;
    await tokenStorage.saveSession(
      token: token,
      role: user.role.name,
      userJson: jsonEncode(user.toJson()),
    );
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    await tokenStorage.clearSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final token = await tokenStorage.getToken();
    final userJson = await tokenStorage.getUserJson();
    if (token != null && userJson != null) {
      _token = token;
      _currentUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return _currentUser;
  }

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  String? get token => _token;
}
