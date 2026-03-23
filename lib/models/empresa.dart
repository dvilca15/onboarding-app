class Empresa {
  final int idEmpresa;
  final String nombre;
  final String? industria;
  final String email;
  final DateTime fechaCreacion;

  const Empresa({
    required this.idEmpresa,
    required this.nombre,
    this.industria,
    required this.email,
    required this.fechaCreacion,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        idEmpresa: json['id_empresa'] as int,
        nombre: json['nombre'] as String,
        industria: json['industria'] as String?,
        email: json['email'] as String,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id_empresa': idEmpresa,
        'nombre': nombre,
        'industria': industria,
        'email': email,
        'fecha_creacion': fechaCreacion.toIso8601String(),
      };
}