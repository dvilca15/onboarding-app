import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  // ── Token ──────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    required int empresaId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'empresa_id': empresaId,
      }),
    );
    return _handleResponse(response);
  }

  // ── Empresa ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> crearEmpresa({
    required String nombre,
    required String email,
    String? industria,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/empresas/'),
      headers: headers,
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        if (industria != null) 'industria': industria,
      }),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> listarEmpresas() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/empresas/'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as List<dynamic>;
  }

  // ── Usuarios ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> listarUsuarios() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as List<dynamic>;
  }

  // ── Planes ─────────────────────────────────────────────────

  static Future<List<dynamic>> listarPlanes() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/planes/'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> obtenerPlan(int idPlan) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/planes/$idPlan'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> crearPlan({
    required String nombre,
    String? descripcion,
    bool esPlantilla = false,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/planes/'),
      headers: headers,
      body: jsonEncode({
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'es_plantilla': esPlantilla,
      }),
    );
    return _handleResponse(response);
  }

  // ── Steps ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> crearStep({
    required int idPlan,
    required String titulo,
    String? descripcion,
    int orden = 1,
    int? duracionDias,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/planes/$idPlan/steps/'),
      headers: headers,
      body: jsonEncode({
        'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        'orden': orden,
        if (duracionDias != null) 'duracion_dias': duracionDias,
      }),
    );
    return _handleResponse(response);
  }

  // ── Tasks ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> crearTask({
    required int idStep,
    required String titulo,
    String tipo = 'CONFIRMACION',
    bool obligatorio = true,
    int orden = 1,
    String? descripcion,      // ← nuevo
    String? urlContenido,     // ← nuevo
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/steps/$idStep/tasks/'),
      headers: headers,
      body: jsonEncode({
        'titulo': titulo,
        'tipo': tipo,
        'obligatorio': obligatorio,
        'orden': orden,
        if (descripcion != null) 'descripcion': descripcion,
        if (urlContenido != null) 'url_contenido': urlContenido,
      }),
    );
    return _handleResponse(response);
  }

  // ── Onboarding ─────────────────────────────────────────────

  static Future<List<dynamic>> listarOnboardings() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/onboarding/'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> asignarPlan({
    required int idUser,
    required int idPlan,
    String? fechaInicio,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/asignar'),
      headers: headers,
      body: jsonEncode({
        'id_user': idUser,
        'id_plan': idPlan,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verProgreso(int idOnboarding) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/onboarding/$idOnboarding/progreso'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> completarTask({
    required int idOnboarding,
    required int idTask,
    String estado = 'COMPLETADO',
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/$idOnboarding/tasks/$idTask/completar'),
      headers: headers,
      body: jsonEncode({'estado': estado}),
    );
    return _handleResponse(response);
  }

  // ── Usuarios — editar / eliminar ──────────────────────────

  static Future<Map<String, dynamic>> editarUsuario({
    required int idUser,
    String? nombre,
    String? email,
    String? password,
  }) async {
    final headers = await getHeaders();
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    final response = await http.put(
      Uri.parse('$baseUrl/users/$idUser'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<void> eliminarUsuario(int idUser) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$idUser'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Error al eliminar');
    }
  }

  // ── Planes — editar / eliminar ─────────────────────────────

  static Future<Map<String, dynamic>> editarPlan({
    required int idPlan,
    String? nombre,
    String? descripcion,
    bool? esPlantilla,
  }) async {
    final headers = await getHeaders();
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;
    if (esPlantilla != null) body['es_plantilla'] = esPlantilla;
    final response = await http.put(
      Uri.parse('$baseUrl/planes/$idPlan'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<void> eliminarPlan(int idPlan) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/planes/$idPlan'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Error al eliminar');
    }
  }

  // ── Steps — eliminar ───────────────────────────────────────

  static Future<void> eliminarStep({
    required int idPlan,
    required int idStep,
  }) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/planes/$idPlan/steps/$idStep'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Error al eliminar');
    }
  }

  // ── Tasks — eliminar ───────────────────────────────────────

  static Future<void> eliminarTask({
    required int idStep,
    required int idTask,
  }) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/steps/$idStep/tasks/$idTask'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Error al eliminar');
    }
  }

  // ── Empleados por Plan ─────────────────────────────────────

  static Future<List<dynamic>> listarEmpleadosPlan(int idPlan) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/planes/$idPlan/empleados'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as List<dynamic>;
  }

  // ── Onboarding — eliminar ──────────────────────────────────

  static Future<void> eliminarOnboarding(int idOnboarding) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/onboarding/$idOnboarding'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Error al eliminar');
    }
  }

  // ── Handler ────────────────────────────────────────────────

  static dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final detail = body['detail'] ?? 'Error desconocido';
    throw Exception(detail);
  }

// ── Bienvenida ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> obtenerBienvenida({
    required int idPlan,
    required int idOnboarding,
  }) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/planes/$idPlan/bienvenida/$idOnboarding'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<void> actualizarBienvenida({
    required int idPlan,
    required String? mensaje,
  }) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/planes/$idPlan/bienvenida'),
      headers: headers,
      body: jsonEncode({'mensaje_bienvenida': mensaje}),
    );
    _handleResponse(response);
  }

  // Agregar en lib/services/api_service.dart dentro de la clase ApiService:

static Future<Map<String, dynamic>> chatAdminMensaje({
  required String mensaje,
  required List<Map<String, String>> historial,
}) async {
  final headers = await getHeaders();
  final response = await http.post(
    Uri.parse('$baseUrl/chat/admin/mensaje'),
    headers: headers,
    body: jsonEncode({
      'mensaje': mensaje,
      'historial': historial,
    }),
  );
  return _handleResponse(response);
}

static Future<Map<String, dynamic>> chatAdminCrearPlan({
  required Map<String, dynamic> sugerencia,
}) async {
  final headers = await getHeaders();
  final response = await http.post(
    Uri.parse('$baseUrl/chat/admin/crear-plan'),
    headers: headers,
    body: jsonEncode({'sugerencia': sugerencia}),
  );
  return _handleResponse(response);
}

// ── Steps — editar ─────────────────────────────────────────
static Future<Map<String, dynamic>> editarStep({
  required int idPlan,
  required int idStep,
  String? titulo,
  String? descripcion,
  int? orden,
  int? duracionDias,
}) async {
  final headers = await getHeaders();
  final body = <String, dynamic>{};
  if (titulo != null) body['titulo'] = titulo;
  if (descripcion != null) body['descripcion'] = descripcion;
  if (orden != null) body['orden'] = orden;
  if (duracionDias != null) body['duracion_dias'] = duracionDias;
  final response = await http.put(
    Uri.parse('$baseUrl/planes/$idPlan/steps/$idStep'),
    headers: headers,
    body: jsonEncode(body),
  );
  return _handleResponse(response);
}

// ── Tasks — editar ──────────────────────────────────────────
static Future<Map<String, dynamic>> editarTask({
  required int idStep,
  required int idTask,
  String? titulo,
  String? tipo,
  bool? obligatorio,
  int? orden,
  String? descripcion,
  String? urlContenido,
}) async {
  final headers = await getHeaders();
  final body = <String, dynamic>{};
  if (titulo != null) body['titulo'] = titulo;
  if (tipo != null) body['tipo'] = tipo;
  if (obligatorio != null) body['obligatorio'] = obligatorio;
  if (orden != null) body['orden'] = orden;
  // Siempre enviar aunque sea null para limpiar el campo
  body['descripcion'] = descripcion;
  body['url_contenido'] = urlContenido;
  final response = await http.put(
    Uri.parse('$baseUrl/steps/$idStep/tasks/$idTask'),
    headers: headers,
    body: jsonEncode(body),
  );
  return _handleResponse(response);
}

static Future<void> enviarRespuestasFormulario({
  required int idOnboarding,
  required int idTask,
  required int idStep,
  required List<Map<String, String>> respuestas,
}) async {
  final headers = await getHeaders();
  final response = await http.post(
    Uri.parse('$baseUrl/steps/$idStep/tasks/$idTask/respuestas?id_onboarding=$idOnboarding'),
    headers: headers,
    body: jsonEncode({'respuestas': respuestas}),
  );
  _handleResponse(response);
}

static Future<Map<String, dynamic>> subirArchivoTaskWeb({
  required int idStep,
  required int idTask,
  required List<int> bytes,
  required String nombreArchivo,
}) async {
  final token = await getToken();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/steps/$idStep/tasks/$idTask/upload'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(http.MultipartFile.fromBytes(
    'archivo',
    bytes,
    filename: nombreArchivo,
  ));
  final response = await request.send();
  final body = await response.stream.bytesToString();
  if (response.statusCode != 200) {
    final data = jsonDecode(body);
    throw Exception(data['detail'] ?? 'Error al subir archivo');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

static Future<String> chatEmpleadoMensaje({
  required String mensaje,
  required List<Map<String, String>> historial,
  required int idOnboarding,
}) async {
  final headers = await getHeaders();
  final response = await http.post(
    Uri.parse('$baseUrl/chat/empleado/mensaje'),
    headers: headers,
    body: jsonEncode({
      'mensaje': mensaje,
      'historial': historial,
      'id_onboarding': idOnboarding,
    }),
  );
  final data = _handleResponse(response);
  return data['texto'] as String;
}
}