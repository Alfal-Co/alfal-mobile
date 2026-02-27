import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// ERPNext/Frappe API client
class ErpNextClient {
  late final Dio _dio;
  String? _authToken;

  ErpNextClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.erpnextUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'token $_authToken';
          }
          // Don't set Content-Type for FormData
          if (options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setToken(String token) {
    _authToken = token;
  }

  void clearAuth() {
    _authToken = null;
  }

  /// Test connection to server
  Future<bool> ping() async {
    try {
      final response = await _dio.get('/api/method/ping');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Login with API token - verify it works
  Future<String> loginWithToken(String apiKey, String apiSecret) async {
    _authToken = '$apiKey:$apiSecret';
    try {
      final response =
          await _dio.get('/api/method/frappe.auth.get_logged_user');
      final data = response.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      throw Exception('استجابة غير متوقعة من السيرفر');
    } catch (e) {
      _authToken = null;
      rethrow;
    }
  }

  /// Login with username and password
  Future<String> login(String username, String password) async {
    // First login to get session
    await _dio.post(
      '/api/method/login',
      data: {'usr': username, 'pwd': password},
    );
    // Then get logged user
    final response =
        await _dio.get('/api/method/frappe.auth.get_logged_user');
    return response.data['message'] as String;
  }

  /// Get user full name
  Future<String?> getUserFullName(String email) async {
    try {
      final response = await _dio.get('/api/resource/User/$email');
      final data = response.data['data'];
      return data['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get a list of documents
  Future<List<dynamic>> getList(
    String doctype, {
    List<String>? fields,
    dynamic filters,
    String? orderBy,
    int? limitPageLength,
    int? limitStart,
  }) async {
    final params = <String, dynamic>{};
    // Frappe expects fields and filters as JSON strings
    if (fields != null) params['fields'] = jsonEncode(fields);
    if (filters != null) params['filters'] = jsonEncode(filters);
    if (orderBy != null) params['order_by'] = orderBy;
    if (limitPageLength != null) {
      params['limit_page_length'] = limitPageLength;
    }
    if (limitStart != null) params['limit_start'] = limitStart;

    final response = await _dio.get(
      '/api/resource/$doctype',
      queryParameters: params,
    );
    return response.data['data'] as List<dynamic>;
  }

  /// Get a single document
  Future<Map<String, dynamic>> getDoc(String doctype, String name) async {
    final response = await _dio.get('/api/resource/$doctype/$name');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Create a new document
  Future<Map<String, dynamic>> createDoc(
    String doctype,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/resource/$doctype', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Update an existing document
  Future<Map<String, dynamic>> updateDoc(
    String doctype,
    String name,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _dio.put('/api/resource/$doctype/$name', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Upload a file and attach to a document
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? doctype,
    String? docname,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (doctype != null) 'doctype': doctype,
      if (docname != null) 'docname': docname,
      'is_private': 1,
    });
    final response = await _dio.post(
      '/api/method/upload_file',
      data: formData,
    );
    return response.data['message'] as Map<String, dynamic>;
  }

  /// Call a whitelisted API method
  Future<dynamic> call(String method, {Map<String, dynamic>? data}) async {
    final response = await _dio.post('/api/method/$method', data: data);
    return response.data['message'];
  }

  /// Get document count
  Future<int> getCount(String doctype, {dynamic filters}) async {
    final result = await call(
      'frappe.client.get_count',
      data: {
        'doctype': doctype,
        if (filters != null) 'filters': filters,
      },
    );
    if (result is int) return result;
    return int.tryParse(result.toString()) ?? 0;
  }
}
