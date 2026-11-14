import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html;
//import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/onboarding.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_dialog.dart';
import '../../../theme/app_toast.dart';

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

  static const _baseUrl = ApiService.baseUrl;

  void _abrirContenido(BuildContext context, String url) async {
    String fullUrl = url;
    if (fullUrl.startsWith('/static')) fullUrl = '$_baseUrl$fullUrl';
    final uri = Uri.tryParse(fullUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppToast.fromSnackBar(context, 
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
                      size: 48, color: AppColors.warning),
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
                      backgroundColor: AppColors.warning,
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
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); onCompletar(); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
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
                    ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: task.completada
                      ? AppColors.success : AppColors.borderStrong,
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
                        ? AppColors.textSubtle
                        : AppColors.text,
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
                          color: AppColors.danger,
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
            color: AppColors.info,
            onTap: () => _abrirContenido(context, task.urlContenido!),
            visible: !task.completada,
          ),

        // DOCUMENTO con entrega: ver PDF del admin + subir entrega
        if (task.tipo == 'DOCUMENTO' && task.requiereEntrega) ...[
          if (task.urlContenido != null && task.urlContenido!.isNotEmpty)
            _botonSecundario(
              icono: Icons.picture_as_pdf_outlined,
              label: 'Ver documento a firmar',
              color: AppColors.info,
              onTap: () => _abrirContenido(context, task.urlContenido!),
              visible: true,
            ),
          if (!task.completada)
            _botonSecundario(
              icono: Icons.upload_file_rounded,
              label: task.urlEntrega != null
                  ? 'Reemplazar entrega' : 'Subir documento firmado',
              color: AppColors.success,
              onTap: () => _mostrarEntrega(context),
              visible: true,
            ),
          // Ver la entrega que ya subió
          if (task.urlEntrega != null && task.urlEntrega!.isNotEmpty)
            _botonSecundario(
              icono: Icons.attach_file_rounded,
              label: 'Ver mi entrega',
              color: AppColors.success,
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
                    fontSize: 11, color: AppColors.textSubtle)),
          ),

        if (!task.completada &&
            task.tipo == 'VIDEO' &&
            (task.urlContenido == null || task.urlContenido!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Text('El administrador aún no ha cargado el video.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSubtle)),
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
            foregroundColor: AppColors.primaryLight,
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
                  ? AppColors.success
                  : AppColors.textSubtle,
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
            foregroundColor: AppColors.info,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Confirmar lectura',
              style: TextStyle(fontSize: 12)),
        );
      case 'VIDEO':
        return TextButton(
          onPressed: () => _mostrarVideo(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Ver video', style: TextStyle(fontSize: 12)),
        );
      default:
        return TextButton(
          onPressed: onCompletar,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
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
    return AppDialog(
      icon: Icons.upload_file_rounded,
      title: 'Entrega de documento',
      subtitle: widget.task.titulo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pasos
          const _PasoEntrega(
              numero: 1, texto: 'Descarga el documento de la tarea.'),
          const SizedBox(height: 8),
          const _PasoEntrega(numero: 2, texto: 'Revísalo y fírmalo.'),
          const SizedBox(height: 8),
          const _PasoEntrega(
              numero: 3, texto: 'Sube aquí el archivo firmado.'),
          const SizedBox(height: 18),

          if (_error != null) ...[
            InlineBanner(_error!, tone: BannerTone.error),
            const SizedBox(height: 14),
          ],

          FileDropZone(
            onTap: _seleccionarYSubir,
            uploading: _subiendo,
            fileName: _nombreArchivo,
            hint: 'PDF, PNG o JPG',
            emptyLabel: 'Seleccionar archivo firmado',
          ),
        ],
      ),
      actions: [
        const DialogCancelButton(),
        DialogPrimaryButton(
          label: 'Confirmar entrega',
          icon: Icons.check_rounded,
          onPressed: _nombreArchivo == null || _subiendo
              ? null
              : widget.onEntregado,
        ),
      ],
    );
  }
}

class _PasoEntrega extends StatelessWidget {
  final int numero;
  final String texto;
  const _PasoEntrega({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.primarySoft, shape: BoxShape.circle),
        child: Text('$numero',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryHover)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(texto,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textBody)),
      ),
    ]);
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

  int get _respondidas =>
      List.generate(widget.preguntas.length, (i) => _campoValido(i))
          .where((v) => v)
          .length;

  Future<void> _enviar() async {
    setState(() => _intentoEnviar = true);
    final valido =
        List.generate(widget.preguntas.length, (i) => _campoValido(i))
            .every((v) => v);
    if (!valido) return;
    setState(() => _loading = true);
    await widget.onEnviar(_construirRespuestas());
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.preguntas.length;
    final faltan = _intentoEnviar ? total - _respondidas : 0;

    return AppDialog(
      maxWidth: 560,
      icon: Icons.list_alt_rounded,
      title: widget.titulo,
      subtitle: '$_respondidas de $total respondidas',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : _respondidas / total,
              minHeight: 5,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          if (faltan > 0) ...[
            InlineBanner(
              faltan == 1
                  ? 'Te falta responder 1 pregunta.'
                  : 'Te faltan responder $faltan preguntas.',
              tone: BannerTone.error,
            ),
            const SizedBox(height: 14),
          ],
          ...widget.preguntas.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final invalido = _intentoEnviar && !_campoValido(i);
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: invalido
                      ? AppColors.dangerBorder
                      : AppColors.border,
                  width: invalido ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _campoValido(i)
                              ? AppColors.primary
                              : AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: _campoValido(i)
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryHover)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(p.pregunta,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text)),
                        ),
                      ),
                    ],
                  ),
                  if (p.tipo == 'multiple')
                    const Padding(
                      padding: EdgeInsets.only(left: 34, top: 2),
                      child: Text('Puedes elegir varias opciones',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSubtle)),
                    ),
                  const SizedBox(height: 12),
                  if (p.tipo == 'abierta')
                    TextField(
                      controller: _textControllers[i],
                      minLines: 2,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta…',
                      ),
                    ),
                  if (p.tipo == 'unica')
                    ...p.opciones.map((op) => _OpcionFicha(
                          label: op,
                          seleccionada: _selectedUnica[i] == op,
                          multiple: false,
                          onTap: () =>
                              setState(() => _selectedUnica[i] = op),
                        )),
                  if (p.tipo == 'multiple')
                    ...p.opciones.map((op) => _OpcionFicha(
                          label: op,
                          seleccionada: _selectedMultiple[i].contains(op),
                          multiple: true,
                          onTap: () => setState(() {
                            if (!_selectedMultiple[i].add(op)) {
                              _selectedMultiple[i].remove(op);
                            }
                          }),
                        )),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        const DialogCancelButton(),
        DialogPrimaryButton(
          label: 'Enviar respuestas',
          icon: Icons.send_rounded,
          loading: _loading,
          onPressed: _enviar,
        ),
      ],
    );
  }
}

/// Opción seleccionable (radio o casilla) con aspecto de ficha.
class _OpcionFicha extends StatelessWidget {
  final String label;
  final bool seleccionada;
  final bool multiple;
  final VoidCallback onTap;

  const _OpcionFicha({
    required this.label,
    required this.seleccionada,
    required this.multiple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: seleccionada ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: seleccionada
                  ? AppColors.primary
                  : AppColors.borderStrong,
              width: seleccionada ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: seleccionada ? AppColors.primary : Colors.transparent,
                shape: multiple ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: multiple ? BorderRadius.circular(5) : null,
                border: Border.all(
                  color: seleccionada
                      ? AppColors.primary
                      : AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: seleccionada
                  ? Icon(multiple ? Icons.check_rounded : Icons.circle,
                      size: multiple ? 14 : 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          seleccionada ? FontWeight.w600 : FontWeight.w500,
                      color: seleccionada
                          ? AppColors.primaryHover
                          : AppColors.textBody)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Badge de tipo ─────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  final String tipo;
  final bool requiereEntrega;

  const _TipoBadge({required this.tipo, this.requiereEntrega = false});

  static const _colors = {
    'DOCUMENTO':    [AppColors.infoSoft, AppColors.info],
    'VIDEO':        [AppColors.warningSoft, AppColors.warning],
    'FORMULARIO':   [AppColors.primarySoft, AppColors.primaryLight],
    'CONFIRMACION': [AppColors.successSoft, AppColors.success],
    'BIENVENIDA':   [AppColors.primarySoft, AppColors.primary],
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[tipo] ??
        [AppColors.bg, AppColors.textMuted];
    // Si es DOCUMENTO con entrega, mostrar badge especial
    final label = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? 'DOC + ENTREGA'
        : tipo;
    final bgColor = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? AppColors.successSoft
        : c[0] as Color;
    final txtColor = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? AppColors.success
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
