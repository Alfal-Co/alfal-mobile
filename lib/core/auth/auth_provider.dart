import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/erpnext_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? username;
  final String? fullName;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.username,
    this.fullName,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? username,
    String? fullName,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ErpNextClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('username');
    final fullName = prefs.getString('full_name');

    if (token != null && username != null) {
      _client.setToken(token);
      state = state.copyWith(
        isAuthenticated: true,
        username: username,
        fullName: fullName,
      );
    }
  }

  Future<void> loginWithToken(String apiKey, String apiSecret) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _client.loginWithToken(apiKey, apiSecret);
      final fullName = await _client.getUserFullName(user);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', '$apiKey:$apiSecret');
      await prefs.setString('username', user);
      if (fullName != null) await prefs.setString('full_name', fullName);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        username: user,
        fullName: fullName ?? user,
      );
    } catch (e) {
      _client.clearAuth();
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _client.login(username, password);
      final fullName = await _client.getUserFullName(user);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user);
      if (fullName != null) await prefs.setString('full_name', fullName);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        username: user,
        fullName: fullName ?? user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> logout() async {
    _client.clearAuth();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('full_name');
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      // Connection errors (CORS, network, timeout)
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        if (e.message?.contains('XMLHttpRequest') == true) {
          return 'خطأ اتصال بالسيرفر (CORS) - تأكد من الإعدادات';
        }
        return 'لا يمكن الاتصال بالسيرفر';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'انتهت مهلة الاتصال';
      }

      final status = e.response?.statusCode;
      if (status == 401) return 'بيانات الدخول غير صحيحة';
      if (status == 403) return 'ليس لديك صلاحية الدخول';
      if (status == 404) return 'السيرفر غير موجود';
      if (status != null && status >= 500) return 'خطأ في السيرفر';

      // Try to get Frappe error message
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data is String && data.length < 100) {
        return data;
      }

      return 'فشل الاتصال ($status)';
    }

    final msg = e.toString();
    if (msg.length > 80) return 'خطأ في الاتصال بالسيرفر';
    return msg;
  }
}

/// Providers
final erpnextClientProvider = Provider<ErpNextClient>((ref) {
  return ErpNextClient();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(erpnextClientProvider);
  return AuthNotifier(client);
});
