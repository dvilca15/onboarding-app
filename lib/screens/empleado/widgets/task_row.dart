import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/onboarding.dart';

// ── Modelo de pregunta ────────────────────────────────────────

class _Pregunta {
  final String tipo;
  final String pregunta;
  final List<String> opciones;

  const _Pregunta({
    required this.tipo,
    required this.pregunta,
    this.opciones = const [],
  });

  factory _Pregunta.fromJson(Map<String, dynamic> json) => _Pregunta(
        tipo:     json['tipo'] as String? ?? 'abierta',
        pregunta: json['pregunta'] as String? ?? '',
        opciones: List<String>.from(json['opciones'] as List? ?? []),
      );

  static List<_Pregunta> parsear(String descripcion) {
    try {
      final lista = jsonDecode(descripcion) as List;
      if (lista.isNotEmpty && lista.first is Map) {
        return lista
            .map((e) => _Pregunta.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Formato viejo: lista de strings
      return lista
          .map((e) => _Pregunta(tipo: 'abierta', pregunta: e.toString()))
          .toList();
    } catch (_) {
      return [_Pregunta(tipo: 'abierta', pregunta: descripcion)];
    }
  }
}

// ── Helpers de URL de video ───────────────────────────────────

String? _convertirEmbedUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  // YouTube: youtube.com/watch?v=ID
  if (uri.host.contains('youtube.com') &&
      uri.queryParameters.containsKey('v')) {
    final id = uri.queryParameters['v'];
    return 'https://www.youtube.com/embed/$id?autoplay=0';
  }
  // YouTube: youtu.be/ID
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return 'https://www.youtube.com/embed/${uri.pathSegments.first}?autoplay=0';
  }
  // Google Drive: drive.google.com/file/d/ID/view
  if (uri.host.contains('drive.google.com') && url.contains('/file/d/')) {
    final match = RegExp(r'/file/d/([^/]+)').firstMatch(url);
    if (match != null) {
      return 'https://drive.google.com/file/d/${match.group(1)}/preview';
    }
  }
  return null;
}

int _iframeCounter = 0;

// ── TaskRow principal ─────────────────────────────────────────

class TaskRow extends StatelessWidget {
  final TaskProgressDetalle task;
  final int idOnboarding;
  final VoidCallback onCompletar;
  final Future<void> Function(int idTask, List<Map<String, String>> respuestas)?
      onEnviarFormulario;

  const TaskRow({
    super.key,
    required this.task,
    required this.idOnboarding,
    required this.onCompletar,
    this.onEnviarFormulario,
  });

  static const _baseUrl = 'http://localhost:8000';

  void _abrirContenido(BuildContext context) async {
    if (task.urlContenido == null || task.urlContenido!.isEmpty) return;
    String url = task.urlContenido!;
    if (url.startsWith('/static')) url = '$_baseUrl$url';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el contenido')),
        );
      }
    }
  }

  void _mostrarVideo(BuildContext context) {
    if (task.urlContenido == null || task.urlContenido!.isEmpty) {
      onCompletar();
      return;
    }
    final embedUrl = _convertirEmbedUrl(task.urlContenido!);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 720,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(children: [
                Expanded(child: Text(task.titulo,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600))),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ]),
            ),
            const Divider(height: 1),

            // Video embebido o botón abrir
            if (embedUrl != null)
              _VideoEmbed(embedUrl: embedUrl)
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 48, color: Color(0xFFF97316)),
                  const SizedBox(height: 12),
                  const Text('Este video no se puede mostrar aquí.',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  const Text('Se abrirá en una nueva pestaña.',
                      style: TextStyle(fontSize: 13,
                          color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _abrirContenido(context),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Abrir video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Color(0xFF6B7280))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onCompletar();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirmar que lo vi'),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context) {
    if (task.descripcion == null || task.descripcion!.isEmpty) {
      onCompletar();
      return;
    }
    final preguntas = _Pregunta.parsear(task.descripcion!);
    if (preguntas.isEmpty) { onCompletar(); return; }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FormularioDialog(
        titulo: task.titulo,
        preguntas: preguntas,
        onEnviar: (respuestas) async {
          Navigator.pop(ctx);
          if (onEnviarFormulario != null) {
            await onEnviarFormulario!(task.idTask, respuestas);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Checkbox
          GestureDetector(
            onTap: task.completada ? null : () => _onTapTask(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: task.completada
                    ? const Color(0xFF10B981) : Colors.transparent,
                border: Border.all(
                  color: task.completada
                      ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.completada
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Título + badges
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.titulo,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: task.completada
                        ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A2E),
                    decoration: task.completada
                        ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 3),
              Row(children: [
                _TipoBadge(tipo: task.tipo),
                if (task.obligatorio) ...[
                  const SizedBox(width: 6),
                  const Text('Obligatoria',
                      style: TextStyle(fontSize: 10,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500)),
                ],
              ]),
            ]),
          ),

          if (!task.completada) _buildBotonAccion(context),
        ]),

        // Botón ver documento
        if (!task.completada &&
            task.tipo == 'DOCUMENTO' &&
            task.urlContenido != null &&
            task.urlContenido!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 6),
            child: OutlinedButton.icon(
              onPressed: () => _abrirContenido(context),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Ver documento', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),

        // Mensaje si no tiene contenido
        if (!task.completada &&
            (task.tipo == 'DOCUMENTO' || task.tipo == 'VIDEO') &&
            (task.urlContenido == null || task.urlContenido!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Text(
              task.tipo == 'VIDEO'
                  ? 'El administrador aún no ha cargado el video.'
                  : 'El administrador aún no ha cargado el documento.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
      ]),
    );
  }

  Widget _buildBotonAccion(BuildContext context) {
    switch (task.tipo) {
      case 'FORMULARIO':
        return TextButton(
          onPressed: () => _mostrarFormulario(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Responder', style: TextStyle(fontSize: 12)),
        );
      case 'DOCUMENTO':
        return TextButton(
          onPressed: () {
            _abrirContenido(context);
            Future.delayed(const Duration(seconds: 2), onCompletar);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Confirmar lectura', style: TextStyle(fontSize: 12)),
        );
      case 'VIDEO':
        return TextButton(
          onPressed: () => _mostrarVideo(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF97316),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Ver video', style: TextStyle(fontSize: 12)),
        );
      default:
        return TextButton(
          onPressed: onCompletar,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Completar', style: TextStyle(fontSize: 12)),
        );
    }
  }

  void _onTapTask(BuildContext context) {
    switch (task.tipo) {
      case 'FORMULARIO':
        _mostrarFormulario(context);
        break;
      case 'VIDEO':
        _mostrarVideo(context);
        break;
      default:
        onCompletar();
    }
  }
}

// ── Widget iframe para video embebido (Flutter Web) ───────────

class _VideoEmbed extends StatefulWidget {
  final String embedUrl;
  const _VideoEmbed({required this.embedUrl});

  @override
  State<_VideoEmbed> createState() => _VideoEmbedState();
}

class _VideoEmbedState extends State<_VideoEmbed> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-iframe-${_iframeCounter++}';
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.embedUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allowFullscreen = true
        ..setAttribute('allow',
            'accelerometer; autoplay; clipboard-write; '
            'encrypted-media; gyroscope; picture-in-picture');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 380,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}

// ── Dialog del formulario ─────────────────────────────────────

class _FormularioDialog extends StatefulWidget {
  final String titulo;
  final List<_Pregunta> preguntas;
  final Future<void> Function(List<Map<String, String>> respuestas) onEnviar;

  const _FormularioDialog({
    required this.titulo,
    required this.preguntas,
    required this.onEnviar,
  });

  @override
  State<_FormularioDialog> createState() => _FormularioDialogState();
}

class _FormularioDialogState extends State<_FormularioDialog> {
  late List<TextEditingController> _textControllers;
  late List<String?> _selectedUnica;
  late List<Set<String>> _selectedMultiple;
  bool _loading = false;
  bool _intentoEnviar = false;

  @override
  void initState() {
    super.initState();
    _textControllers = widget.preguntas
        .map((_) => TextEditingController()).toList();
    _selectedUnica = List.filled(widget.preguntas.length, null);
    _selectedMultiple =
        List.generate(widget.preguntas.length, (_) => <String>{});
  }

  @override
  void dispose() {
    for (final c in _textControllers) { c.dispose(); }
    super.dispose();
  }

  bool _campoValido(int i) {
    final p = widget.preguntas[i];
    if (p.tipo == 'abierta') return _textControllers[i].text.trim().isNotEmpty;
    if (p.tipo == 'unica') return _selectedUnica[i] != null;
    return _selectedMultiple[i].isNotEmpty;
  }

  List<Map<String, String>> _construirRespuestas() =>
      widget.preguntas.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        String respuesta;
        if (p.tipo == 'abierta') {
          respuesta = _textControllers[i].text.trim();
        } else if (p.tipo == 'unica') {
          respuesta = _selectedUnica[i] ?? '';
        } else {
          respuesta = _selectedMultiple[i].join(', ');
        }
        return {'pregunta': p.pregunta, 'respuesta': respuesta};
      }).toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.preguntas.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final invalido = _intentoEnviar && !_campoValido(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: invalido
                      ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: invalido
                        ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text('${i + 1}. ${p.pregunta}',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)))),
                      if (invalido)
                        const Text('Requerido',
                            style: TextStyle(fontSize: 11,
                                color: Color(0xFFDC2626))),
                    ]),
                    const SizedBox(height: 10),

                    // Abierta
                    if (p.tipo == 'abierta')
                      TextField(
                        controller: _textControllers[i],
                        maxLines: 3,
                        onChanged: (_) {
                          if (_intentoEnviar) setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Escribe tu respuesta...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB)),
                          ),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),

                    // Opción única
                    if (p.tipo == 'unica')
                      ...p.opciones.map((op) => RadioListTile<String>(
                        value: op,
                        groupValue: _selectedUnica[i],
                        onChanged: (v) =>
                            setState(() => _selectedUnica[i] = v),
                        title: Text(op,
                            style: const TextStyle(fontSize: 13)),
                        activeColor: const Color(0xFF8B5CF6),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),

                    // Opción múltiple
                    if (p.tipo == 'multiple')
                      ...p.opciones.map((op) => CheckboxListTile(
                        value: _selectedMultiple[i].contains(op),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedMultiple[i].add(op);
                          } else {
                            _selectedMultiple[i].remove(op);
                          }
                        }),
                        title: Text(op,
                            style: const TextStyle(fontSize: 13)),
                        activeColor: const Color(0xFF8B5CF6),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _intentoEnviar = true);
            final todosValidos = List.generate(
                    widget.preguntas.length, (i) => _campoValido(i))
                .every((v) => v);
            if (!todosValidos) return;
            setState(() => _loading = true);
            await widget.onEnviar(_construirRespuestas());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Enviar respuestas'),
        ),
      ],
    );
  }
}

// ── Badge de tipo ─────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  static const _colors = {
    'DOCUMENTO':    [Color(0xFFEFF6FF), Color(0xFF3B82F6)],
    'VIDEO':        [Color(0xFFFFF7ED), Color(0xFFF97316)],
    'FORMULARIO':   [Color(0xFFF5F3FF), Color(0xFF8B5CF6)],
    'CONFIRMACION': [Color(0xFFF0FDF4), Color(0xFF22C55E)],
    'BIENVENIDA':   [Color(0xFFEDE9FE), Color(0xFF7C3AED)],
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[tipo] ??
        [const Color(0xFFF3F4F6), const Color(0xFF6B7280)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c[0] as Color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tipo,
          style: TextStyle(fontSize: 10, color: c[1] as Color,
              fontWeight: FontWeight.w500)),
    );
  }
}