import 'dart:convert';
import 'package:flutter/material.dart';

// ── Modelo de pregunta ────────────────────────────────────────

class PreguntaFormulario {
  String tipo; // 'abierta' | 'unica' | 'multiple'
  String pregunta;
  List<String> opciones;

  PreguntaFormulario({
    this.tipo = 'abierta',
    this.pregunta = '',
    List<String>? opciones,
  }) : opciones = opciones ?? [];

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'pregunta': pregunta,
        if (tipo != 'abierta') 'opciones': opciones,
      };

  factory PreguntaFormulario.fromJson(Map<String, dynamic> json) =>
      PreguntaFormulario(
        tipo: json['tipo'] as String? ?? 'abierta',
        pregunta: json['pregunta'] as String? ?? '',
        opciones: List<String>.from(json['opciones'] as List? ?? []),
      );

  /// Parsea el string guardado en descripcion
  static List<PreguntaFormulario> parsearDescripcion(String descripcion) {
    try {
      final lista = jsonDecode(descripcion) as List;
      // Formato nuevo: lista de objetos
      if (lista.isNotEmpty && lista.first is Map) {
        return lista
            .map((e) => PreguntaFormulario.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Formato viejo: lista de strings
      return lista
          .map((e) => PreguntaFormulario(pregunta: e.toString()))
          .toList();
    } catch (_) {
      // Si es texto simple, crear una pregunta abierta
      return [PreguntaFormulario(pregunta: descripcion)];
    }
  }

  static String serializarLista(List<PreguntaFormulario> preguntas) =>
      jsonEncode(preguntas.map((p) => p.toJson()).toList());
}

// ── Widget constructor de formulario ─────────────────────────

class FormularioBuilder extends StatefulWidget {
  final List<PreguntaFormulario> preguntasIniciales;
  final ValueChanged<List<PreguntaFormulario>> onChanged;

  const FormularioBuilder({
    super.key,
    required this.preguntasIniciales,
    required this.onChanged,
  });

  @override
  State<FormularioBuilder> createState() => _FormularioBuilderState();
}

class _FormularioBuilderState extends State<FormularioBuilder> {
  late List<PreguntaFormulario> _preguntas;

  static const _tipos = [
    ('abierta',   'Respuesta abierta',  Icons.short_text_rounded),
    ('unica',     'Opción única',        Icons.radio_button_checked_rounded),
    ('multiple',  'Opción múltiple',     Icons.check_box_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _preguntas = List.from(widget.preguntasIniciales);
    if (_preguntas.isEmpty) _agregarPregunta();
  }

  void _agregarPregunta() {
    setState(() => _preguntas.add(PreguntaFormulario()));
    widget.onChanged(_preguntas);
  }

  void _eliminarPregunta(int index) {
    setState(() => _preguntas.removeAt(index));
    widget.onChanged(_preguntas);
  }

  void _notificar() => widget.onChanged(_preguntas);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: const [
            Icon(Icons.quiz_outlined, size: 14, color: Color(0xFF8B5CF6)),
            SizedBox(width: 6),
            Expanded(child: Text(
              'Agrega preguntas. El empleado deberá responderlas para completar esta tarea.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6)),
            )),
          ]),
        ),
        const SizedBox(height: 12),

        // Lista de preguntas
        ..._preguntas.asMap().entries.map((entry) =>
            _PreguntaCard(
              key: ValueKey(entry.key),
              index: entry.key,
              pregunta: entry.value,
              tipos: _tipos,
              onEliminar: _preguntas.length > 1
                  ? () => _eliminarPregunta(entry.key)
                  : null,
              onChanged: _notificar,
            )),

        // Botón agregar pregunta
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _agregarPregunta,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar pregunta', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card de una pregunta ──────────────────────────────────────

class _PreguntaCard extends StatefulWidget {
  final int index;
  final PreguntaFormulario pregunta;
  final List<(String, String, IconData)> tipos;
  final VoidCallback? onEliminar;
  final VoidCallback onChanged;

  const _PreguntaCard({
    super.key,
    required this.index,
    required this.pregunta,
    required this.tipos,
    required this.onEliminar,
    required this.onChanged,
  });

  @override
  State<_PreguntaCard> createState() => _PreguntaCardState();
}

class _PreguntaCardState extends State<_PreguntaCard> {
  late TextEditingController _preguntaCtrl;

  @override
  void initState() {
    super.initState();
    _preguntaCtrl = TextEditingController(text: widget.pregunta.pregunta);
  }

  @override
  void dispose() {
    _preguntaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Número + tipo + eliminar
        Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text('${widget.index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.pregunta.tipo,
                isDense: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                items: widget.tipos.map((t) => DropdownMenuItem(
                  value: t.$1,
                  child: Row(children: [
                    Icon(t.$3, size: 14, color: const Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    Text(t.$2),
                  ]),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    widget.pregunta.tipo = v!;
                    if (v != 'abierta' && widget.pregunta.opciones.isEmpty) {
                      widget.pregunta.opciones.addAll(['Opción 1', 'Opción 2']);
                    }
                  });
                  widget.onChanged();
                },
              ),
            ),
          ),
          if (widget.onEliminar != null)
            InkWell(
              onTap: widget.onEliminar,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
              ),
            ),
        ]),
        const SizedBox(height: 10),

        // Campo pregunta
        TextFormField(
          controller: _preguntaCtrl,
          decoration: InputDecoration(
            hintText: 'Escribe la pregunta...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (v) {
            widget.pregunta.pregunta = v;
            widget.onChanged();
          },
        ),

        // Opciones (para tipo unica o multiple)
        if (widget.pregunta.tipo != 'abierta') ...[
          const SizedBox(height: 10),
          ...widget.pregunta.opciones.asMap().entries.map((e) =>
              _OpcionRow(
                key: ValueKey('${widget.index}_${e.key}'),
                index: e.key,
                valor: e.value,
                tipo: widget.pregunta.tipo,
                onChanged: (v) {
                  setState(() => widget.pregunta.opciones[e.key] = v);
                  widget.onChanged();
                },
                onEliminar: widget.pregunta.opciones.length > 2
                    ? () {
                        setState(() => widget.pregunta.opciones.removeAt(e.key));
                        widget.onChanged();
                      }
                    : null,
              )),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () {
              setState(() => widget.pregunta.opciones
                  .add('Opción ${widget.pregunta.opciones.length + 1}'));
              widget.onChanged();
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Agregar opción', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Fila de una opción ────────────────────────────────────────

class _OpcionRow extends StatefulWidget {
  final int index;
  final String valor;
  final String tipo;
  final ValueChanged<String> onChanged;
  final VoidCallback? onEliminar;

  const _OpcionRow({
    super.key,
    required this.index,
    required this.valor,
    required this.tipo,
    required this.onChanged,
    this.onEliminar,
  });

  @override
  State<_OpcionRow> createState() => _OpcionRowState();
}

class _OpcionRowState extends State<_OpcionRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valor);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(
          widget.tipo == 'unica'
              ? Icons.radio_button_unchecked_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 16,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Opción ${widget.index + 1}',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.onEliminar != null)
          InkWell(
            onTap: widget.onEliminar,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
            ),
          ),
      ]),
    );
  }
}