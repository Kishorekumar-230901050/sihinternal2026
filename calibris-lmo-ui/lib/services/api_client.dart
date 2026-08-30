/// Future API client using Dio.
/// Replace mock repositories with API repositories that use this client
/// when the Node.js backend is ready.
class ApiClient {
  // Stub implementation
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<dynamic> get(String path) async {
    // throw UnimplementedError();
  }

  Future<dynamic> post(String path, dynamic data) async {
    // throw UnimplementedError();
  }
}
