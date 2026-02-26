import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/erpnext_client.dart';

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final String? username;
  final String? fullName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.username,
    this.fullName,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    String? fullName,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Authentication provider
class AuthNotifier extends StateNotifier<AuthState> {
  final ErpNextClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('username');

    if (token != null && username != null) {
      _client.setToken(token);
      state = state.copyWith(
        isAuthenticated: true,
        username: username,
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.login(username, password);
      final user = await _client.getLoggedUser();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user);

      state = state.copyWith(
        isAuthenticated: true,
        username: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تسجيل الدخول: ${e.toString()}',
      );
    }
  }

  Future<void> loginWithToken(String apiKey, String apiSecret) async {
    final token = '$apiKey:$apiSecret';
    _client.setToken(token);

    try {
      final user = await _client.getLoggedUser();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', user);

      state = state.copyWith(
        isAuthenticated: true,
        username: user,
      );
    } catch (e) {
      _client.setToken('');
      state = state.copyWith(
        error: 'فشل التحقق من المفتاح',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    state = const AuthState();
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
