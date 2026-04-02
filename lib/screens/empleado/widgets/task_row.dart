import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/onboarding.dart';

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
    // Si es ruta relativa del servidor, construir URL completa
    if (url.startsWith('/static')) {
      url = '$_baseUrl$url';
    }

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

  void _mostrarFormulario(BuildContext context) {
    if (task.descripcion == null || task.descripcion!.isEmpty) {
      // Sin preguntas — completar directo
      onCompletar();
      return;
    }

    List<String> preguntas = [];
    try {
      preguntas = List<String>.from(jsonDecode(task.descripcion!));
    } catch (_) {
      preguntas = [task.descripcion!];
    }

    final controllers = preguntas.map((_) => TextEditingController()).toList();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(task.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: preguntas.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key + 1}. ${e.value}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: controllers[e.key],
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Tu respuesta...',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB)),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      set(() => loading = true);
                      final respuestas = preguntas
                          .asMap()
                          .entries
                          .map((e) => {
                                'pregunta': e.value,
                                'respuesta': controllers[e.key].text.trim(),
                              })
                          .toList();
                      Navigator.pop(ctx);
                      if (onEnviarFormulario != null) {
                        await onEnviarFormulario!(task.idTask, respuestas);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar respuestas'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: task.completada ? null : () => _onTapTask(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.completada
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    border: Border.all(
                      color: task.completada
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD1D5DB),
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

              // Título + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titulo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: task.completada
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1A1A2E),
                        decoration: task.completada
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _TipoBadge(tipo: task.tipo),
                        if (task.obligatorio) ...[
                          const SizedBox(width: 6),
                          const Text('Obligatoria',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Botón acción según tipo
              if (!task.completada) _buildBotonAccion(context),
            ],
          ),

          // Botón ver contenido (DOCUMENTO / VIDEO) si tiene URL
          if (!task.completada &&
              (task.tipo == 'DOCUMENTO' || task.tipo == 'VIDEO') &&
              task.urlContenido != null &&
              task.urlContenido!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 6),
              child: OutlinedButton.icon(
                onPressed: () => _abrirContenido(context),
                icon: Icon(
                  task.tipo == 'VIDEO'
                      ? Icons.play_circle_outline_rounded
                      : Icons.picture_as_pdf_outlined,
                  size: 16,
                ),
                label: Text(
                  task.tipo == 'VIDEO' ? 'Ver video' : 'Ver documento',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: task.tipo == 'VIDEO'
                      ? const Color(0xFFF97316)
                      : const Color(0xFF3B82F6),
                  side: BorderSide(
                    color: task.tipo == 'VIDEO'
                        ? const Color(0xFFF97316)
                        : const Color(0xFF3B82F6),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
        ],
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
        return TextButton(
          onPressed: () {
            if (task.urlContenido != null) {
              _abrirContenido(context);
            }
            // Confirmar después de abrir
            Future.delayed(const Duration(seconds: 1), onCompletar);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Confirmar lectura', style: TextStyle(fontSize: 12)),
        );
      case 'VIDEO':
        return TextButton(
          onPressed: () {
            if (task.urlContenido != null) {
              _abrirContenido(context);
            }
            Future.delayed(const Duration(seconds: 1), onCompletar);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF97316),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text('Confirmar vista', style: TextStyle(fontSize: 12)),
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
      default:
        onCompletar();
    }
  }
}

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
      child: Text(
        tipo,
        style: TextStyle(
            fontSize: 10,
            color: c[1] as Color,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}