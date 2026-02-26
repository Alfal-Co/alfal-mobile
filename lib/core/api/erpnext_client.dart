import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// ERPNext/Frappe API client
/// Handles all HTTP communication with the backend
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
          'Content-Type': 'application/json',
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
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 - redirect to login
          if (error.response?.statusCode == 401) {
            _authToken = null;
            // TODO: Navigate to login
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Set API token (api_key:api_secret)
  void setToken(String token) {
    _authToken = token;
  }

  /// Login with username and password
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '/api/method/login',
      data: {'usr': username, 'pwd': password},
    );
    return response.data;
  }

  /// Get current logged-in user
  Future<String> getLoggedUser() async {
    final response = await _dio.get('/api/method/frappe.auth.get_logged_user');
    return response.data['message'];
  }

  /// Get a list of documents
  Future<List<dynamic>> getList(
    String doctype, {
    List<String>? fields,
    List<List<dynamic>>? filters,
    String? orderBy,
    int? limitPageLength,
    int? limitStart,
  }) async {
    final params = <String, dynamic>{
      if (fields != null) 'fields': fields,
      if (filters != null) 'filters': filters,
      if (orderBy != null) 'order_by': orderBy,
      if (limitPageLength != null) 'limit_page_length': limitPageLength,
      if (limitStart != null) 'limit_start': limitStart,
    };

    final response = await _dio.get(
      '/api/resource/$doctype',
      queryParameters: params,
    );
    return response.data['data'];
  }

  /// Get a single document
  Future<Map<String, dynamic>> getDoc(String doctype, String name) async {
    final response = await _dio.get('/api/resource/$doctype/$name');
    return response.data['data'];
  }

  /// Create a new document
  Future<Map<String, dynamic>> createDoc(
    String doctype,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/resource/$doctype', data: data);
    return response.data['data'];
  }

  /// Update a document
  Future<Map<String, dynamic>> updateDoc(
    String doctype,
    String name,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/resource/$doctype/$name', data: data);
    return response.data['data'];
  }

  /// Call a whitelisted method
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post(
      '/api/method/$method',
      data: data,
    );
    return response.data['message'];
  }

  /// Get document count
  Future<int> getCount(
    String doctype, {
    List<List<dynamic>>? filters,
  }) async {
    final result = await call(
      'frappe.client.get_count',
      data: {
        'doctype': doctype,
        if (filters != null) 'filters': filters,
      },
    );
    return result as int;
  }

  /// Upload a file
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
    });

    final response = await _dio.post(
      '/api/method/upload_file',
      data: formData,
    );
    return response.data['message'];
  }
}
