import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/onboarding.dart';
import '../../../services/api_service.dart';

class OnboardingsTab extends StatelessWidget {
  final List<Onboarding> onboardings;
  final VoidCallback onRefresh;

  const OnboardingsTab({
    super.key,
    required this.onboardings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (onboardings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes_rounded,
                size: 48, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('No hay onboardings asignados',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: onboardings
            .map((o) => _OnboardingCard(
                  onboarding: o,
                  onVerDetalle: () => _mostrarDetalle(context, o),
                  onDesasignar: () => _confirmarDesasignar(context, o),
                ))
            .toList(),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, Onboarding o) {
    showDialog(
      context: context,
      builder: (ctx) => _DetalleDialog(onboarding: o),
    );
  }

  void _confirmarDesasignar(BuildContext context, Onboarding o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Row(children: [
          Icon(Icons.remove_circle_outline_rounded,
              color: Color(0xFFDC2626), size: 20),
          SizedBox(width: 8),
          Text('Desasignar onboarding',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626))),
        ]),
        content: Text(
          '¿Desasignar el plan "${o.displayPlan}" de ${o.displayEmpleado}?\n\n'
          'Se eliminará todo su progreso. Esta acción es irreversible.',
          style: const TextStyle(fontSize: 13,
              color: Color(0xFF374151), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.eliminarOnboarding(o.idEmployeeOnboarding);
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onboarding desasignado'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, desasignar'),
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final Onboarding onboarding;
  final VoidCallback onVerDetalle;
  final VoidCallback onDesasignar;

  const _OnboardingCard({
    required this.onboarding,
    required this.onVerDetalle,
    required this.onDesasignar,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(onboarding.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_iniciales(onboarding.displayEmpleado),
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0)))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(onboarding.displayEmpleado,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                Text(onboarding.displayPlan,
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF6B7280))),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(onboarding.estado,
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: onboarding.progreso / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            )),
            const SizedBox(width: 10),
            Text('${onboarding.progreso.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: color)),
          ]),
          if (onboarding.fechaInicio != null) ...[
            const SizedBox(height: 4),
            Text('Inicio: ${onboarding.fechaInicio!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: onDesasignar,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 14),
              label: const Text('Desasignar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onVerDetalle,
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Ver detalle', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'COMPLETADO': return const Color(0xFF10B981);
      case 'EN_PROGRESO': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6B7280);
    }
  }

  String _iniciales(String nombre) {
    final p = nombre.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}

// ── Dialog de detalle ─────────────────────────────────────────

class _DetalleDialog extends StatefulWidget {
  final Onboarding onboarding;
  const _DetalleDialog({required this.onboarding});

  @override
  State<_DetalleDialog> createState() => _DetalleDialogState();
}

class _DetalleDialogState extends State<_DetalleDialog> {
  OnboardingDetalle? _detalle;
  bool _loading = true;
  String? _error;

  static const _baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final raw = await ApiService.verProgreso(
          widget.onboarding.idEmployeeOnboarding);
      setState(() {
        _detalle = OnboardingDetalle.fromJson(raw);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  int get _dias {
    if (widget.onboarding.fechaInicio == null) return 0;
    return DateTime.now()
        .difference(widget.onboarding.fechaInicio!)
        .inDays;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.onboarding;
    final color = _colorEstado(o.estado);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 640,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.displayEmpleado,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(o.displayPlan,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13)),
                ],
              )),
              _stat('$_dias', _dias == 1 ? 'día' : 'días'),
              const SizedBox(width: 16),
              _stat('${o.progreso.toStringAsFixed(0)}%', 'progreso'),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(o.estado,
                    style: TextStyle(color: color, fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          // Contenido
          Flexible(
            child: _loading
                ? const SizedBox(height: 120,
                    child: Center(child: CircularProgressIndicator()))
                : _error != null
                    ? _buildError()
                    : _buildContenido(),
          ),
          // Acciones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String valor, String etiqueta) => Column(children: [
        Text(valor, style: const TextStyle(color: Colors.white,
            fontSize: 20, fontWeight: FontWeight.w700)),
        Text(etiqueta, style: TextStyle(
            color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ]);

  Widget _buildError() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFDC2626), size: 40),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() { _loading = true; _error = null; });
              _cargar();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ]),
      );

  Widget _buildContenido() {
    if (_detalle == null) return const SizedBox.shrink();
    final steps = _detalle!.stepsConProgreso
        .where((s) => s.titulo != '__BIENVENIDA__')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: steps.asMap().entries
            .map((e) => _buildStep(e.value, e.key + 1))
            .toList(),
      ),
    );
  }

  Widget _buildStep(StepConProgreso step, int numero) {
    final color = step.todoCompleto
        ? const Color(0xFF10B981)
        : step.enProgreso
            ? const Color(0xFF1565C0)
            : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(child: Text('$numero',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(step.titulo,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)))),
            Text('${step.completadas}/${step.totalTasks} tareas',
                style: TextStyle(fontSize: 11, color: color,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        ...step.tasks
            .where((t) => t.tipo != 'BIENVENIDA')
            .map((t) => _buildTask(t)),
      ]),
    );
  }

  Widget _buildTask(TaskProgressDetalle task) {
    final completada = task.completada;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Fila principal
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          Icon(
            completada
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: completada
                ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(task.titulo,
              style: TextStyle(fontSize: 12,
                  color: completada
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF1A1A2E),
                  decoration: completada
                      ? TextDecoration.lineThrough : null))),
          const SizedBox(width: 8),
          _tipoBadge(task.tipo, task.requiereEntrega),
          const SizedBox(width: 8),
          if (completada && task.fechaCompletada != null)
            Text(task.fechaCompletada!.toLocal().toString().split(' ')[0],
                style: const TextStyle(fontSize: 10,
                    color: Color(0xFF10B981)))
          else if (!completada)
            const Text('Pendiente',
                style: TextStyle(fontSize: 10,
                    color: Color(0xFF9CA3AF))),
        ]),
      ),

      // ── Respuestas de formulario ──────────────────────────
      if (task.tipo == 'FORMULARIO' && task.respuestas.isNotEmpty)
        _buildRespuestas(task.respuestas),

      // ── Entrega del empleado ──────────────────────────────
      if (task.tipo == 'DOCUMENTO' &&
          task.requiereEntrega)
        _buildEntrega(task),
    ]);
  }

  Widget _buildRespuestas(List<RespuestaFormulario> respuestas) {
    return Container(
      margin: const EdgeInsets.fromLTRB(42, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.quiz_outlined, size: 12, color: Color(0xFF8B5CF6)),
          SizedBox(width: 6),
          Text('Respuestas del empleado',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6))),
        ]),
        const SizedBox(height: 8),
        ...respuestas.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.key + 1}. ${e.value.pregunta}',
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151))),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(e.value.respuesta,
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF1A1A2E))),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _buildEntrega(TaskProgressDetalle task) {
    final tieneEntrega = task.urlEntrega != null && task.urlEntrega!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(42, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tieneEntrega
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneEntrega
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(children: [
        Icon(
          tieneEntrega
              ? Icons.attach_file_rounded
              : Icons.hourglass_empty_rounded,
          size: 14,
          color: tieneEntrega
              ? const Color(0xFF10B981)
              : const Color(0xFFD97706),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
          tieneEntrega
              ? 'El empleado subió su documento firmado'
              : 'Pendiente: el empleado aún no ha subido el documento firmado',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tieneEntrega
                  ? const Color(0xFF065F46)
                  : const Color(0xFF92400E)),
        )),
        if (tieneEntrega)
          TextButton.icon(
            onPressed: () async {
              String url = task.urlEntrega!;
              if (url.startsWith('/static')) url = '$_baseUrl$url';
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 13),
            label: const Text('Ver archivo', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
            ),
          ),
      ]),
    );
  }

  Widget _tipoBadge(String tipo, bool requiereEntrega) {
    final label = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? 'DOC+ENTREGA' : tipo;
    final bg = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? const Color(0xFFF0FDF4) : const Color(0xFFE0F2FE);
    final txt = (tipo == 'DOCUMENTO' && requiereEntrega)
        ? const Color(0xFF10B981) : const Color(0xFF0369A1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(fontSize: 9,
              color: txt, fontWeight: FontWeight.w500)),
    );
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'COMPLETADO': return const Color(0xFF10B981);
      case 'EN_PROGRESO': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6B7280);
    }
  }
}
