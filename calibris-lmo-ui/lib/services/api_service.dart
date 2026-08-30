import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });
}

class ApiService {
  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 8);

  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<ApiResponse<T>> get<T>(String url, {T Function(dynamic json)? transform}) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: _defaultHeaders).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = transform != null ? transform(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('error')) {
            errorMsg = decoded['error'].toString();
          } else if (decoded is Map && decoded.containsKey('message')) {
            errorMsg = decoded['message'].toString();
          }
        } catch (_) {}
        return ApiResponse(success: false, errorMessage: errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(String url, {Map<String, dynamic>? body, T Function(dynamic json)? transform}) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: _defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = transform != null ? transform(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('error')) {
            errorMsg = decoded['error'].toString();
          } else if (decoded is Map && decoded.containsKey('message')) {
            errorMsg = decoded['message'].toString();
          }
        } catch (_) {}
        return ApiResponse(success: false, errorMessage: errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}
