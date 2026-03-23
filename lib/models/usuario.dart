class Usuario {
  final int idUser;
  final String nombre;
  final String email;
  final int empresaId;
  final DateTime fechaCreacion;
  final List<String> roles;

  const Usuario({
    required this.idUser,
    required this.nombre,
    required this.email,
    required this.empresaId,
    required this.fechaCreacion,
    required this.roles,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        idUser: json['id_user'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        empresaId: json['empresa_id'] as int,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((r) => r.toString())
            .toList(),
      );

  bool get esAdmin => roles.contains('ADMIN_EMPRESA');
  String get inicial => nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
}