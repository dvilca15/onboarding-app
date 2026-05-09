// ── TareaSugerida ─────────────────────────────────────────────
class TareaSugerida {
  final String titulo;
  final String tipo;

  const TareaSugerida({
    required this.titulo,
    required this.tipo,
  });
}

// ── EtapaSugerida ─────────────────────────────────────────────
class EtapaSugerida {
  final String nombre;
  final int duracionDias;
  final List<TareaSugerida> tareas;

  const EtapaSugerida({
    required this.nombre,
    required this.duracionDias,
    required this.tareas,
  });

  factory EtapaSugerida.fromJson(Map<String, dynamic> json) => EtapaSugerida(
        nombre:       json['nombre'] as String,
        duracionDias: json['duracion_dias'] as int? ?? 1,
        tareas: (json['tareas'] as List<dynamic>? ?? [])
            .map((t) {
              if (t is String) {
                return TareaSugerida(titulo: t, tipo: 'CONFIRMACION');
              }
              final m = t as Map<String, dynamic>;
              return TareaSugerida(
                titulo: m['titulo'] as String,
                tipo:   m['tipo']   as String? ?? 'CONFIRMACION',
              );
            })
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'nombre':        nombre,
        'duracion_dias': duracionDias,
        'tareas': tareas.asMap().entries.map((e) => {
          'titulo':      e.value.titulo,
          'tipo':        e.value.tipo,
          'obligatorio': true,
          'orden':       e.key + 1,
        }).toList(),
      };
}

// ── PlanSugerido ──────────────────────────────────────────────
class PlanSugerido {
  final String titulo;
  final int duracionDias;
  final List<EtapaSugerida> etapas;

  const PlanSugerido({
    required this.titulo,
    required this.duracionDias,
    required this.etapas,
  });

  factory PlanSugerido.fromJson(Map<String, dynamic> json) => PlanSugerido(
        titulo:       json['titulo'] as String,
        duracionDias: json['duracion_dias'] as int? ?? 1,
        etapas: (json['etapas'] as List<dynamic>? ?? [])
            .map((e) => EtapaSugerida.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'titulo':        titulo,
        'duracion_dias': duracionDias,
        'etapas': etapas.asMap().entries.map((e) => {
          ...e.value.toJson(),
          'orden': e.key + 1,
        }).toList(),
      };
}

// ── ChatMensaje ───────────────────────────────────────────────
class ChatMensaje {
  final String rol;
  final String texto;
  final PlanSugerido? plan;

  const ChatMensaje({
    required this.rol,
    required this.texto,
    this.plan,
  });
}