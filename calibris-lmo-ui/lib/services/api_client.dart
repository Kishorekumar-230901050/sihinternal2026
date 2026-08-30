import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

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

class ApiClient {
  final String baseUrl;
  final TokenStorageService tokenStorage;
  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 10);

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
  });

  Future<Map<String, String>> _buildHeaders({bool isJson = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String url, {
    T Function(dynamic json)? transform,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _client.get(Uri.parse(url), headers: headers).timeout(_timeout);
      return _processResponse<T>(response, transform);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? transform,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse<T>(response, transform);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String url, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? transform,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse<T>(response, transform);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String url, {
    T Function(dynamic json)? transform,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _client.delete(Uri.parse(url), headers: headers).timeout(_timeout);
      return _processResponse<T>(response, transform);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  /// Upload multipart file (e.g. document PDF or geotagged inspection image)
  Future<ApiResponse<T>> uploadMultipart<T>(
    String url, {
    required String fieldName,
    required String filename,
    required Uint8List fileBytes,
    Map<String, String>? additionalFields,
    T Function(dynamic json)? transform,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      final token = await tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse<T>(response, transform);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Upload failed: ${e.toString()}',
      );
    }
  }

  ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(dynamic json)? transform,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse<T>(success: true, statusCode: response.statusCode);
      }
      try {
        final decoded = jsonDecode(response.body);
        final data = transform != null ? transform(decoded) : decoded as T;
        return ApiResponse<T>(success: true, data: data, statusCode: response.statusCode);
      } catch (e) {
        return ApiResponse<T>(success: true, statusCode: response.statusCode);
      }
    } else {
      String errorMsg = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          if (decoded.containsKey('error')) {
            final err = decoded['error'];
            if (err is Map && err.containsKey('fieldErrors')) {
              errorMsg = (err['fieldErrors'] as Map).values.join(', ');
            } else {
              errorMsg = err.toString();
            }
          } else if (decoded.containsKey('message')) {
            errorMsg = decoded['message'].toString();
          }
        }
      } catch (_) {}
      return ApiResponse<T>(
        success: false,
        errorMessage: errorMsg,
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
