import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading         = false;
  String? _error;
  Map<String, dynamic>? _userData;
  bool _isAuthenticated   = false;

  bool get isLoading       => _isLoading;
  String? get error        => _error;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin         => _userData?['roles']?.contains('ADMIN_EMPRESA') ?? false;
  String get userName      => _userData?['nombre'] ?? '';
  int get userId           => _userData?['id_user'] ?? 0;
  int get empresaId        => _userData?['empresa_id'] ?? 0;

  /// Lista de roles del usuario autenticado
  List<String> get userRoles =>
      (_userData?['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString())
          .toList();

  /// Verifica si hay sesión activa al iniciar la app
  Future<bool> checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _userData = jsonDecode(userJson);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      final data = await ApiService.getMe();
      _userData = data;
      _isAuthenticated = true;
      await prefs.setString('user_data', jsonEncode(data));
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Login — retorna null si fue exitoso, o el mensaje de error si falló
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
      return _error; // String = error
    }
  }

  /// Logout
  Future<void> logout() async {
    await ApiService.clearToken();
    _userData        = null;
    _isAuthenticated = false;
    _error           = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}