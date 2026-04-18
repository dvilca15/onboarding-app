import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html;
//import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/onboarding.dart';
import '../../../services/api_service.dart';

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
  if (uri.host.contains('youtube.com') &&
      uri.queryParameters.containsKey('v')) {
    return 'https://www.youtube.com/embed/${uri.queryParameters['v']}?autoplay=0';
  }
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return 'https://www.youtube.com/embed/${uri.pathSegments.first}?autoplay=0';
  }
  if (uri.host.contains('drive.google.com') && url.contains('/file/d/')) {
    final match = RegExp(r'/file/d/([^/]+)').firstMatch(url);
    if (match != null) {
      return 'https://drive.google.com/file/d/${match.group(1)}/preview';
    }
  }
  return null;
}

//int _iframeCounter = 0;

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

  void _abrirContenido(BuildContext context, String url) async {
    String fullUrl = url;
    if (fullUrl.startsWith('/static')) fullUrl = '$_baseUrl$fullUrl';
    final uri = Uri.tryParse(fullUrl);
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

  /*void _mostrarVideo(BuildContext context) {
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
                    icon: const Icon(Icons.close_rounded, size: 20)),
              ]),
            ),
            const Divider(height: 1),
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _abrirContenido(context, task.urlContenido!),
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
                    onPressed: () { Navigator.pop(ctx); onCompletar(); },
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
  }*/

  void _mostrarVideo(BuildContext context) {
  if (task.urlContenido == null || task.urlContenido!.isEmpty) {
    onCompletar();
    return;
  }
  _abrirContenido(context, task.urlContenido!);
  Future.delayed(const Duration(seconds: 2), onCompletar);
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

  // ── entrega_v2: modal de entrega del empleado ─────────────

  void _mostrarEntrega(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _EntregaDialog(
        task: task,
        idOnboarding: idOnboarding,
        onEntregado: () {
          Navigator.pop(ctx);
          onCompletar();
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
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.titulo,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: task.completada
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1A1A2E),
                    decoration: task.completada
                        ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 3),
              Row(children: [
                _TipoBadge(tipo: task.tipo,
                    requiereEntrega: task.requiereEntrega),
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

        // ── Botones secundarios bajo el título ────────────

        // DOCUMENTO sin entrega: ver PDF
        if (task.tipo == 'DOCUMENTO' &&
            !task.requiereEntrega &&
            task.urlContenido != null &&
            task.urlContenido!.isNotEmpty)
          _botonSecundario(
            icono: Icons.picture_as_pdf_outlined,
            label: 'Ver documento',
            color: const Color(0xFF3B82F6),
            onTap: () => _abrirContenido(context, task.urlContenido!),
            visible: !task.completada,
          ),

        // DOCUMENTO con entrega: ver PDF del admin + subir entrega
        if (task.tipo == 'DOCUMENTO' && task.requiereEntrega) ...[
          if (task.urlContenido != null && task.urlContenido!.isNotEmpty)
            _botonSecundario(
              icono: Icons.picture_as_pdf_outlined,
              label: 'Ver documento a firmar',
              color: const Color(0xFF3B82F6),
              onTap: () => _abrirContenido(context, task.urlContenido!),
              visible: true,
            ),
          if (!task.completada)
            _botonSecundario(
              icono: Icons.upload_file_rounded,
              label: task.urlEntrega != null
                  ? 'Reemplazar entrega' : 'Subir documento firmado',
              color: const Color(0xFF10B981),
              onTap: () => _mostrarEntrega(context),
              visible: true,
            ),
          // Ver la entrega que ya subió
          if (task.urlEntrega != null && task.urlEntrega!.isNotEmpty)
            _botonSecundario(
              icono: Icons.attach_file_rounded,
              label: 'Ver mi entrega',
              color: const Color(0xFF10B981),
              onTap: () => _abrirContenido(context, task.urlEntrega!),
              visible: true,
            ),
        ],

        // Sin contenido
        if (!task.completada &&
            task.tipo == 'DOCUMENTO' &&
            !task.requiereEntrega &&
            (task.urlContenido == null || task.urlContenido!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Text('El administrador aún no ha cargado el documento.',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ),

        if (!task.completada &&
            task.tipo == 'VIDEO' &&
            (task.urlContenido == null || task.urlContenido!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Text('El administrador aún no ha cargado el video.',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ),
      ]),
    );
  }

  Widget _botonSecundario({
    required IconData icono,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 34, top: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
      ),
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
        // Con entrega: el botón principal es "Confirmar" solo después de subir
        if (task.requiereEntrega) {
          return TextButton(
            onPressed: task.urlEntrega != null ? onCompletar : null,
            style: TextButton.styleFrom(
              foregroundColor: task.urlEntrega != null
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Confirmar entrega',
                style: TextStyle(fontSize: 12)),
          );
        }
        return TextButton(
          onPressed: () {
            if (task.urlContenido != null) {
              _abrirContenido(context, task.urlContenido!);
            }
            Future.delayed(const Duration(seconds: 2), onCompletar);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Confirmar lectura',
              style: TextStyle(fontSize: 12)),
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
      case 'DOCUMENTO':
        if (task.requiereEntrega) {
          _mostrarEntrega(context);
        } else if (task.urlContenido != null) {
          _abrirContenido(context, task.urlContenido!);
          Future.delayed(const Duration(seconds: 2), onCompletar);
        } else {
          onCompletar();
        }
        break;
      default:
        onCompletar();
    }
  }
}

// ── Dialog de entrega del empleado ────────────────────────────

class _EntregaDialog extends StatefulWidget {
  final TaskProgressDetalle task;
  final int idOnboarding;
  final VoidCallback onEntregado;

  const _EntregaDialog({
    required this.task,
    required this.idOnboarding,
    required this.onEntregado,
  });

  @override
  State<_EntregaDialog> createState() => _EntregaDialogState();
}

class _EntregaDialogState extends State<_EntregaDialog> {
  bool _subiendo = false;
  String? _error;
  String? _nombreArchivo;

  static const _verde = Color(0xFF10B981);

  Future<void> _seleccionarYSubir() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() { _subiendo = true; _error = null; });
    try {
      await ApiService.subirEntregaEmpleado(
        idOnboarding: widget.idOnboarding,
        idTask: widget.task.idTask,
        bytes: file.bytes!,
        nombreArchivo: file.name,
      );
      setState(() { _nombreArchivo = file.name; _subiendo = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _subiendo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.upload_file_rounded, color: _verde, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.task.titulo,
            style: const TextStyle(fontSize: 16))),
      ]),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Instrucción
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Descarga el documento, fírmalo y súbelo aquí.',
                style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
              )),
            ]),
          ),
          const SizedBox(height: 14),

          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFDC2626)))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Archivo subido
          if (_nombreArchivo != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: _verde),
                const SizedBox(width: 8),
                Expanded(child: Text(_nombreArchivo!,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF065F46)))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Botón subir
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _subiendo ? null : _seleccionarYSubir,
              icon: _subiendo
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _verde))
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                _nombreArchivo != null
                    ? 'Reemplazar archivo'
                    : 'Seleccionar archivo firmado',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _verde,
                side: const BorderSide(color: _verde),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('PDF, PNG o JPG',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _nombreArchivo == null ? null : widget.onEntregado,
          style: ElevatedButton.styleFrom(
            backgroundColor: _verde,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmar entrega'),
        ),
      ],
    );
  }
}

// ── Video embed ───────────────────────────────────────────────

/*class _VideoEmbed extends StatefulWidget {
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
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 380,
        child: HtmlElementView(viewType: _viewId),
      );
}*/

// ── Formulario dialog ─────────────────────────────────────────

class _FormularioDialog extends StatefulWidget {
  final String titulo;
  final List<_Pregunta> preguntas;
  final Future<void> Function(List<Map<String, String>>) onEnviar;

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
    _textControllers =
        widget.preguntas.map((_) => TextEditingController()).toList();
    _selectedUnica = List.filled(widget.preguntas.length, null);
    _selectedMultiple =
        List.generate(widget.preguntas.length, (_) => <String>{});
  }

  @override
  void dispose() {
    for (final c in _textControllers) c.dispose();
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
        String r;
        if (p.tipo == 'abierta') {
          r = _textControllers[i].text.trim();
        } else if (p.tipo == 'unica') {
          r = _selectedUnica[i] ?? '';
        } else {
          r = _selectedMultiple[i].join(', ');
        }
        return {'pregunta': p.pregunta, 'respuesta': r};
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
            final valido = List.generate(
                    widget.preguntas.length, (i) => _campoValido(i))
                .every((v) => v);
            if (!valido) return;
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
  final bool requiereEntrega;

  const _TipoBadge({required this.tipo, this.requiereEntrega = false});

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
    // Si es DOCUMENTO con entrega, mostrar badge especial
    final label = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? 'DOC + ENTREGA'
        : tipo;
    final bgColor = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? const Color(0xFFF0FDF4)
        : c[0] as Color;
    final txtColor = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? const Color(0xFF10B981)
        : c[1] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: txtColor, fontWeight: FontWeight.w500)),
    );
  }
}
