import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading       = false;
  String? _error;
  Map<String, dynamic>? _userData;
  bool _isAuthenticated = false;

  bool get isLoading        => _isLoading;
  String? get error         => _error;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated  => _isAuthenticated;
  bool get isAdmin          => _userData?['roles']?.contains('ADMIN_EMPRESA') ?? false;
  String get userName       => _userData?['nombre'] ?? '';
  int get userId            => _userData?['id_user'] ?? 0;
  int get empresaId         => _userData?['empresa_id'] ?? 0;

  // ── Paso 2: indica si el empleado ya cambió su contraseña inicial ──
  bool get passwordChanged  => _userData?['password_changed'] ?? true;

  List<String> get userRoles =>
      (_userData?['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString())
          .toList();

  // ── Verificación de sesión al iniciar la app ──────────────

Future<bool> checkAuth() async {
  final token = await ApiService.getToken();
  if (token == null) return false;

  try {
    final data = await ApiService.getMe();
    _userData = data;
    _isAuthenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(data));
    notifyListeners();
    return true;
  } catch (_) {
    await logout();
    return false;
  }
}

  // ── Login ─────────────────────────────────────────────────

  /// Retorna null si fue exitoso, o el mensaje de error si falló.
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loginData = await ApiService.login(email, password);
      await ApiService.saveToken(loginData['access_token']);

      final userData = await ApiService.getMe();
      _userData = userData;
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));

      _isLoading = false;
      notifyListeners();
      return null; // null = éxito
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Paso 2: actualiza password_changed en memoria y SharedPreferences ──

  /// Llamado desde CambiarPasswordScreen tras un cambio exitoso.
  /// Actualiza el estado local sin necesidad de hacer logout/login.
  Future<void> marcarPasswordCambiado() async {
    if (_userData == null) return;
    _userData!['password_changed'] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_userData));
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.clearToken();
    _userData       = null;
    _isAuthenticated = false;
    _error          = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
