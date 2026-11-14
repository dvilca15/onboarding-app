/// Tipos de tarea que puede proponer la IA.
const kTiposTarea = ['DOCUMENTO', 'VIDEO', 'FORMULARIO', 'CONFIRMACION'];

class TareaSugerida {
  final String titulo;
  final String tipo; // DOCUMENTO | VIDEO | FORMULARIO | CONFIRMACION
  final bool obligatorio;
  final bool requiereEntrega; // solo DOCUMENTO: el empleado sube un archivo
  final String? documento;    // documento de Conocimiento que se adjuntará solo
  final List<dynamic> preguntas; // solo FORMULARIO (se reenvía tal cual)

  const TareaSugerida({
    required this.titulo,
    this.tipo = 'CONFIRMACION',
    this.obligatorio = true,
    this.requiereEntrega = false,
    this.documento,
    this.preguntas = const [],
  });

  factory TareaSugerida.fromJson(dynamic json) {
    // Compatibilidad: antes la IA devolvía solo el texto de la tarea.
    if (json is String) return TareaSugerida(titulo: json);
    final m = json as Map<String, dynamic>;
    final tipo = (m['tipo'] as String? ?? 'CONFIRMACION').toUpperCase();
    return TareaSugerida(
      titulo: m['titulo'] as String? ?? '',
      tipo: kTiposTarea.contains(tipo) ? tipo : 'CONFIRMACION',
      obligatorio: m['obligatorio'] as bool? ?? true,
      requiereEntrega: m['requiere_entrega'] as bool? ?? false,
      documento: m['documento'] as String?,
      preguntas: m['preguntas'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson(int orden) => {
        'titulo': titulo,
        'tipo': tipo,
        'obligatorio': obligatorio,
        'orden': orden,
        if (tipo == 'DOCUMENTO') 'requiere_entrega': requiereEntrega,
        if (tipo == 'DOCUMENTO' && documento != null) 'documento': documento,
        if (tipo == 'FORMULARIO' && preguntas.isNotEmpty)
          'preguntas': preguntas,
      };
}

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
        nombre: json['nombre'] as String,
        duracionDias: json['duracion_dias'] as int? ?? 1,
        tareas: (json['tareas'] as List<dynamic>? ?? [])
            .map(TareaSugerida.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'duracion_dias': duracionDias,
        'tareas': tareas
            .asMap()
            .entries
            .map((e) => e.value.toJson(e.key + 1))
            .toList(),
      };
}

class PlanSugerido {
  final String titulo;
  final int duracionDias;
  final String? mensajeBienvenida;
  final List<EtapaSugerida> etapas;

  const PlanSugerido({
    required this.titulo,
    required this.duracionDias,
    this.mensajeBienvenida,
    required this.etapas,
  });

  factory PlanSugerido.fromJson(Map<String, dynamic> json) => PlanSugerido(
        titulo: json['titulo'] as String,
        duracionDias: json['duracion_dias'] as int? ?? 1,
        mensajeBienvenida: json['mensaje_bienvenida'] as String?,
        etapas: (json['etapas'] as List<dynamic>? ?? [])
            .map((e) => EtapaSugerida.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'duracion_dias': duracionDias,
        if (mensajeBienvenida != null && mensajeBienvenida!.trim().isNotEmpty)
          'mensaje_bienvenida': mensajeBienvenida,
        'etapas': etapas.asMap().entries.map((e) => {
              ...e.value.toJson(),
              'orden': e.key + 1,
            }).toList(),
      };
}

// Mensaje en el chat
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

/// Fuente citada por el asistente en una respuesta (RAG).
class FuenteChat {
  final int numero;
  final String documento;
  final String extracto;

  const FuenteChat({
    required this.numero,
    required this.documento,
    required this.extracto,
  });

  factory FuenteChat.fromJson(Map<String, dynamic> json) => FuenteChat(
        numero: json['numero'] as int? ?? 0,
        documento: json['documento'] as String? ?? '',
        extracto: json['extracto'] as String? ?? '',
      );
}
