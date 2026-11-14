import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_toast.dart';
import '../../../theme/app_widgets.dart';

/// Base de conocimiento de la empresa: documentos que usa el asistente de IA
/// del empleado para responder con información real (y citar la fuente).
class ConocimientoTab extends StatefulWidget {
  const ConocimientoTab({super.key});

  @override
  State<ConocimientoTab> createState() => _ConocimientoTabState();
}

class _ConocimientoTabState extends State<ConocimientoTab> {
  List<Map<String, dynamic>> _docs = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final raw = await ApiService.listarDocumentosConocimiento();
      if (!mounted) return;
      setState(() {
        _docs = raw;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _subir() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SubirDocumentoDialog(),
    );
    if (ok == true) {
      _cargar();
    }
  }

  Future<void> _eliminar(Map<String, dynamic> doc) async {
    final ok = await confirmarAccion(
      context,
      titulo: 'Eliminar documento',
      mensaje:
          '«${doc['nombre']}» dejará de usarse en las respuestas del asistente. '
          'Esta acción no se puede deshacer.',
    );
    if (!ok) return;
    try {
      await ApiService.eliminarDocumentoConocimiento(
          doc['id_documento'] as int);
      if (!mounted) return;
      AppToast.success(context, 'Documento eliminado');
      _cargar();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(ancho >= 700 ? 28 : 16),
      child: ContentWidth(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explicación
            AppCard(
              color: AppColors.primarySoft,
              borderColor: AppColors.primaryBorder,
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enséñale a la IA sobre tu empresa',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text)),
                        SizedBox(height: 4),
                        Text(
                          'Sube tu reglamento, políticas o manuales. El asistente '
                          'de tus empleados responderá usando solo estos documentos '
                          'y citará la fuente. Si algo no está en ellos, dirá que no '
                          'lo sabe en vez de inventarlo. Al crear un plan con la IA, '
                          'las tareas de leer un documento se adjuntan solas.',
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textBody),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(children: [
              const Expanded(
                child: Text('Documentos',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              ElevatedButton.icon(
                onPressed: _subir,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Subir documento'),
              ),
            ]),
            const SizedBox(height: 14),

            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              AppCard(
                  child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'No se pudieron cargar los documentos',
                message: _error,
                action: OutlinedButton(
                    onPressed: _cargar, child: const Text('Reintentar')),
              ))
            else if (_docs.isEmpty)
              const AppCard(
                  child: EmptyState(
                icon: Icons.description_outlined,
                title: 'Aún no hay documentos',
                message: 'Sube tu primer documento (PDF, TXT o MD) para que '
                    'el asistente pueda responder preguntas sobre tu empresa.',
              ))
            else
              ..._docs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DocumentoCard(
                      doc: d,
                      onEliminar: () => _eliminar(d),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _DocumentoCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final VoidCallback onEliminar;

  const _DocumentoCard({required this.doc, required this.onEliminar});

  String _fecha(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tipo = (doc['tipo'] as String? ?? '').toUpperCase();
    final esPdf = tipo == 'PDF';
    final caracteres = doc['num_caracteres'] as int? ?? 0;
    final paginas = (caracteres / 1800).ceil().clamp(1, 9999);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: esPdf ? AppColors.dangerSoft : AppColors.infoSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            esPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.description_outlined,
            size: 22,
            color: esPdf ? AppColors.danger : const Color(0xFF0369A1),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc['nombre'] as String? ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 3),
              Text(
                '${doc['nombre_archivo']} · ${tipo.toLowerCase()} · '
                '≈ $paginas pág. · ${doc['num_fragmentos']} fragmentos · '
                '${_fecha(doc['fecha_creacion'] as String?)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (doc['tiene_archivo'] == true)
          const Tooltip(
            message:
                'Se adjuntará solo a las tareas del plan que lo mencionen',
            child: StatusBadge('Adjuntable', tone: BadgeTone.success),
          )
        else
          const Tooltip(
            message:
                'Se subió antes de poder guardar el archivo. Vuelve a subirlo para adjuntarlo solo a las tareas.',
            child: StatusBadge('Sin archivo original', tone: BadgeTone.warning),
          ),
        IconButton(
          tooltip: 'Eliminar',
          onPressed: onEliminar,
          icon: const Icon(Icons.delete_outline_rounded,
              size: 20, color: AppColors.textSubtle),
        ),
      ]),
    );
  }
}

// ── Diálogo de subida ─────────────────────────────────────────

class _SubirDocumentoDialog extends StatefulWidget {
  const _SubirDocumentoDialog();

  @override
  State<_SubirDocumentoDialog> createState() => _SubirDocumentoDialogState();
}

class _SubirDocumentoDialogState extends State<_SubirDocumentoDialog> {
  final _nombreCtrl = TextEditingController();
  PlatformFile? _archivo;
  bool _subiendo = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegir() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt', 'md'],
      withData: true,
    );
    if (r == null || r.files.single.bytes == null) return;
    final f = r.files.single;
    setState(() {
      _archivo = f;
      _error = null;
      if (_nombreCtrl.text.trim().isEmpty) {
        _nombreCtrl.text = f.name.contains('.')
            ? f.name.substring(0, f.name.lastIndexOf('.'))
            : f.name;
      }
    });
  }

  Future<void> _subir() async {
    final f = _archivo;
    if (f == null) return;
    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      await ApiService.subirDocumentoConocimiento(
        bytes: f.bytes!,
        nombreArchivo: f.name,
        nombre: _nombreCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      AppToast.success(context, 'Documento subido e indexado');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _tamano(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.auto_stories_rounded,
      title: 'Subir documento',
      subtitle: 'El asistente lo usará para responder preguntas.',
      showClose: !_subiendo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            InlineBanner(_error!, tone: BannerTone.error),
            const SizedBox(height: 14),
          ],
          FileDropZone(
            onTap: _subiendo ? null : _elegir,
            fileName: _archivo == null
                ? null
                : '${_archivo!.name} (${_tamano(_archivo!.size)})',
            hint: 'PDF, TXT o MD · hasta 10 MB',
            emptyLabel: 'Seleccionar documento',
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Nombre del documento',
            help: 'Así se citará como fuente en las respuestas.',
            child: TextField(
              controller: _nombreCtrl,
              enabled: !_subiendo,
              decoration:
                  const InputDecoration(hintText: 'Reglamento Interno'),
            ),
          ),
          if (_subiendo) ...[
            const SizedBox(height: 16),
            const InlineBanner(
              'Procesando el documento… puede tardar unos segundos.',
              tone: BannerTone.info,
            ),
          ],
        ],
      ),
      actions: [
        DialogCancelButton(
            onPressed: _subiendo ? null : () => Navigator.pop(context, false)),
        DialogPrimaryButton(
          label: 'Subir y procesar',
          icon: Icons.cloud_upload_outlined,
          loading: _subiendo,
          onPressed: _archivo == null ? null : _subir,
        ),
      ],
    );
  }
}
