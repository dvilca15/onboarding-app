import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/onboarding.dart';

// ─────────────────────────────────────────────────────────────
// InicioTab — Paso 4
//
// Muestra un resumen ejecutivo del onboarding activo:
//   - Tarjeta de bienvenida con % en grande
//   - Hasta 4 tareas más urgentes (primeras pendientes)
//   - Días transcurridos desde el inicio
//
// Lee directamente de [detalle] y [onboardings] que vienen
// del EmpleadoShell — sin llamadas extra a la API.
// ─────────────────────────────────────────────────────────────

class InicioTab extends StatelessWidget {
  final OnboardingDetalle? detalle;
  final List<Onboarding> onboardings;

  const InicioTab({
    super.key,
    required this.detalle,
    required this.onboardings,
  });

  static const _azul    = Color(0xFF1565C0);
  static const _verde   = Color(0xFF10B981);
  static const _gris    = Color(0xFF6B7280);
  static const _fondo   = Color(0xFFF5F7FA);

  // ── Helpers ───────────────────────────────────────────────

  /// Devuelve hasta [max] tareas pendientes ordenadas por etapa y orden.
  List<_TareaUrgente> _tareasUrgentes(
      OnboardingDetalle detalle, int max) {
    final resultado = <_TareaUrgente>[];
    for (final step in detalle.stepsConProgreso) {
      if (step.titulo == '__BIENVENIDA__') continue;
      for (final task in step.tasks) {
        if (!task.completada) {
          resultado.add(_TareaUrgente(task: task, step: step));
          if (resultado.length >= max) return resultado;
        }
      }
    }
    return resultado;
  }

  int _diasTranscurridos(DateTime? fechaInicio) {
    if (fechaInicio == null) return 0;
    return DateTime.now().difference(fechaInicio).inDays;
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inicio',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(userName,
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: detalle == null
          ? _buildSinDatos()
          : _buildConDatos(context, detalle!, userName),
    );
  }

  // ── Sin datos aún ─────────────────────────────────────────

  Widget _buildSinDatos() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando tu información...',
                  style: TextStyle(fontSize: 14, color: _gris)),
            ],
          ),
        ),
      );

  // ── Vista principal ───────────────────────────────────────

  Widget _buildConDatos(
      BuildContext context, OnboardingDetalle detalle, String userName) {
    final urgentes = _tareasUrgentes(detalle, 4);
    final dias = _diasTranscurridos(detalle.fechaInicio);
    final steps = detalle.stepsConProgreso
        .where((s) => s.titulo != '__BIENVENIDA__')
        .toList();
    final totalTasks =
        steps.fold(0, (s, e) => s + e.totalTasks);
    final completadas =
        steps.fold(0, (s, e) => s + e.completadas);
    final pendientes = totalTasks - completadas;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tarjeta de bienvenida ─────────────────────────
          _buildBienvenidaCard(detalle, userName, dias,
              completadas, totalTasks),
          const SizedBox(height: 20),

          // ── Stats rápidos ─────────────────────────────────
          _buildStatsRow(detalle, dias, pendientes, completadas),
          const SizedBox(height: 24),

          // ── Tareas urgentes ───────────────────────────────
          if (urgentes.isNotEmpty) ...[
            _buildSeccionHeader(
              icono: Icons.flag_rounded,
              titulo: 'Por hacer ahora',
              subtitulo: 'Tus próximas ${urgentes.length} tareas',
              color: _azul,
            ),
            const SizedBox(height: 12),
            ...urgentes.map((u) => _buildTareaCard(u)),
            const SizedBox(height: 24),
          ],

          // ── Todo al día ───────────────────────────────────
          if (urgentes.isEmpty && totalTasks > 0)
            _buildTodoAlDia(),

          // ── Etapas del plan ───────────────────────────────
          _buildSeccionHeader(
            icono: Icons.layers_rounded,
            titulo: 'Tu plan',
            subtitulo:
                '${steps.length} etapa${steps.length != 1 ? "s" : ""}',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
                (e) => _buildEtapaResumen(e.value, e.key + 1),
              ),
        ],
      ),
    );
  }

  // ── Tarjeta de bienvenida con % en grande ─────────────────

  Widget _buildBienvenidaCard(
    OnboardingDetalle detalle,
    String userName,
    int dias,
    int completadas,
    int totalTasks,
  ) {
    final progreso = detalle.progreso;
    final completado = detalle.estado == 'COMPLETADO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + saludo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _iniciales(userName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completado
                          ? '¡Lo lograste, $userName!'
                          : '¡Hola, $userName!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      detalle.nombrePlan,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // % en grande
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progreso.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  completado
                      ? 'completado'
                      : 'de progreso',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '$completadas de $totalTasks tareas completadas',
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Stats rápidos en fila ─────────────────────────────────

  Widget _buildStatsRow(
    OnboardingDetalle detalle,
    int dias,
    int pendientes,
    int completadas,
  ) {
    return Row(
      children: [
        _buildStatChip(
          icono: Icons.calendar_today_rounded,
          valor: '$dias',
          etiqueta: dias == 1 ? 'día' : 'días',
          color: _azul,
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          icono: Icons.hourglass_empty_rounded,
          valor: '$pendientes',
          etiqueta: 'pendientes',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          icono: Icons.check_circle_rounded,
          valor: '$completadas',
          etiqueta: 'completadas',
          color: _verde,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icono,
    required String valor,
    required String etiqueta,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text(
              etiqueta,
              style: const TextStyle(
                  fontSize: 10, color: _gris),
            ),
          ],
        ),
      ),
    );
  }

  // ── Encabezado de sección ─────────────────────────────────

  Widget _buildSeccionHeader({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            Text(subtitulo,
                style:
                    const TextStyle(fontSize: 11, color: _gris)),
          ],
        ),
      ],
    );
  }

  // ── Tarjeta de tarea urgente ──────────────────────────────

  Widget _buildTareaCard(_TareaUrgente urgente) {
    final colores = _coloresTipo(urgente.task.tipo);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Ícono del tipo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colores.fondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(colores.icono, color: colores.texto, size: 18),
          ),
          const SizedBox(width: 12),
          // Título y etapa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgente.task.titulo,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  urgente.step.titulo,
                  style: const TextStyle(
                      fontSize: 11, color: _gris),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge tipo
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colores.fondo,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              urgente.task.tipo,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: colores.texto),
            ),
          ),
        ],
      ),
    );
  }

  // ── Todo al día ───────────────────────────────────────────

  Widget _buildTodoAlDia() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _verde.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _verde.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _verde.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _verde, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Todo al día!',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _verde),
                ),
                SizedBox(height: 2),
                Text(
                  'No tienes tareas pendientes. Revisa "Mi Plan" para ver tu historial.',
                  style: TextStyle(fontSize: 12, color: _gris),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Resumen de etapa ──────────────────────────────────────

  Widget _buildEtapaResumen(StepConProgreso step, int numero) {
    final porcentaje = step.porcentaje;
    final color = step.todoCompleto
        ? _verde
        : step.enProgreso
            ? _azul
            : _gris;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Número de etapa
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$numero',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Título + barra
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.titulo,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: porcentaje / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // % texto
          Text(
            '$porcentaje%',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }

  // ── Helper colores por tipo de tarea ─────────────────────

  _ColorTipo _coloresTipo(String tipo) {
    switch (tipo) {
      case 'DOCUMENTO':
        return _ColorTipo(
          icono: Icons.picture_as_pdf_rounded,
          fondo: const Color(0xFFEFF6FF),
          texto: const Color(0xFF3B82F6),
        );
      case 'VIDEO':
        return _ColorTipo(
          icono: Icons.play_circle_rounded,
          fondo: const Color(0xFFFFF7ED),
          texto: const Color(0xFFF97316),
        );
      case 'FORMULARIO':
        return _ColorTipo(
          icono: Icons.list_alt_rounded,
          fondo: const Color(0xFFF5F3FF),
          texto: const Color(0xFF8B5CF6),
        );
      default:
        return _ColorTipo(
          icono: Icons.check_box_outline_blank_rounded,
          fondo: const Color(0xFFF0FDF4),
          texto: const Color(0xFF22C55E),
        );
    }
  }
}

// ── Modelos auxiliares privados ───────────────────────────────

class _TareaUrgente {
  final TaskProgressDetalle task;
  final StepConProgreso step;
  const _TareaUrgente({required this.task, required this.step});
}

class _ColorTipo {
  final IconData icono;
  final Color fondo;
  final Color texto;
  const _ColorTipo(
      {required this.icono, required this.fondo, required this.texto});
}
