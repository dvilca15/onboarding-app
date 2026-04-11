import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../models/onboarding.dart';

import '../widgets/step_card.dart';
import '../widgets/onboarding_selector.dart';
import '../widgets/bienvenida_modal.dart';
import '../widgets/felicitacion_modal.dart';

// ─────────────────────────────────────────────────────────────
// Filtro de vista disponible en Mi Plan
// ─────────────────────────────────────────────────────────────
enum _FiltroPlan { pendientes, completados }

class MiPlanTab extends StatefulWidget {
  final List<Onboarding> onboardings;
  final void Function(OnboardingDetalle? detalle, int? idOnboarding)
      onDetalleChanged;

  const MiPlanTab({
    super.key,
    required this.onboardings,
    required this.onDetalleChanged,
  });

  @override
  State<MiPlanTab> createState() => _MiPlanTabState();
}

class _MiPlanTabState extends State<MiPlanTab> {
  OnboardingDetalle? _detalle;
  bool _loadingDetalle = false;
  String? _loadError;
  int? _onboardingSeleccionado;
  final Set<int> _stepsExpandidos = {};
  bool _bienvenidaMostrada = false;

  // ── Paso 3: filtro activo ─────────────────────────────────
  _FiltroPlan _filtro = _FiltroPlan.pendientes;

  @override
  void initState() {
    super.initState();
    _initCargaInicial();
  }

  @override
  void didUpdateWidget(MiPlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final llegaConDatos = widget.onboardings.isNotEmpty;
    final aunNoCargado = _onboardingSeleccionado == null && !_loadingDetalle;
    if (llegaConDatos && aunNoCargado) {
      _initCargaInicial();
    }
  }

  // ── Carga ─────────────────────────────────────────────────

  Future<void> _initCargaInicial() async {
    if (widget.onboardings.isEmpty) return;
    await _cargarDetalle(widget.onboardings.first.idEmployeeOnboarding);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkBienvenida());
    }
  }

  Future<void> _cargarDetalle(int idOnboarding) async {
    setState(() {
      _onboardingSeleccionado = idOnboarding;
      _loadingDetalle = true;
      _loadError = null;
      _stepsExpandidos.clear();
    });
    try {
      final raw = await ApiService.verProgreso(idOnboarding);
      final detalle = OnboardingDetalle.fromJson(raw);

      for (final step in detalle.stepsConProgreso) {
        if (step.titulo == '__BIENVENIDA__') continue;
        if (step.tasks.any((t) => !t.completada)) {
          _stepsExpandidos.add(step.idStep);
          break;
        }
      }

      setState(() {
        _detalle = detalle;
        _loadingDetalle = false;
      });

      widget.onDetalleChanged(detalle, idOnboarding);

      if (detalle.progreso >= 100 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FelicitacionModal.show(
            context: context,
            nombreEmpleado: context.read<AuthProvider>().userName,
            nombrePlan: detalle.nombrePlan,
          );
        });
      }
    } catch (e) {
      setState(() {
        _loadingDetalle = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
      widget.onDetalleChanged(null, null);
    }
  }

  Future<void> _checkBienvenida() async {
    if (_bienvenidaMostrada || widget.onboardings.isEmpty) return;

    final onboardingActivo = widget.onboardings.firstWhere(
      (o) => o.estado != 'COMPLETADO',
      orElse: () => widget.onboardings.first,
    );

    try {
      final data = await ApiService.obtenerBienvenida(
        idPlan: onboardingActivo.idPlan,
        idOnboarding: onboardingActivo.idEmployeeOnboarding,
      );

      final tieneBienvenida = data['tiene_bienvenida'] as bool;
      final yaLeida = data['ya_leida'] as bool;
      if (!tieneBienvenida || yaLeida) return;

      final mensaje = data['mensaje'] as String;
      final idTask = data['id_task'] as int;

      if (!mounted) return;
      setState(() => _bienvenidaMostrada = true);

      await BienvenidaModal.show(
        context: context,
        nombreEmpleado: context.read<AuthProvider>().userName,
        nombrePlan: onboardingActivo.nombrePlan,
        mensaje: mensaje,
        onLeido: () async {
          try {
            await ApiService.completarTask(
              idOnboarding: onboardingActivo.idEmployeeOnboarding,
              idTask: idTask,
            );
            await _cargarDetalle(onboardingActivo.idEmployeeOnboarding);
          } catch (_) {}
        },
      );
    } catch (_) {}
  }

  // ── Acciones de tareas ────────────────────────────────────

  Future<void> _completarTask(int idTask) async {
    if (_onboardingSeleccionado == null) return;
    try {
      await ApiService.completarTask(
        idOnboarding: _onboardingSeleccionado!,
        idTask: idTask,
      );
      await _cargarDetalle(_onboardingSeleccionado!);
      _mostrarSnackbar('¡Tarea completada!', esError: false);
    } catch (e) {
      _mostrarSnackbar(
          e.toString().replaceAll('Exception: ', ''), esError: true);
    }
  }

  Future<void> _enviarFormulario(
    int idTask,
    List<Map<String, String>> respuestas,
  ) async {
    if (_onboardingSeleccionado == null || _detalle == null) return;
    try {
      await ApiService.enviarRespuestasFormulario(
        idOnboarding: _onboardingSeleccionado!,
        idTask: idTask,
        idStep: _detalle!.stepsConProgreso
            .firstWhere((s) => s.tasks.any((t) => t.idTask == idTask))
            .idStep,
        respuestas: respuestas,
      );
      await _cargarDetalle(_onboardingSeleccionado!);
      _mostrarSnackbar('Respuestas enviadas', esError: false);
    } catch (e) {
      _mostrarSnackbar(
          e.toString().replaceAll('Exception: ', ''), esError: true);
    }
  }

  void _mostrarSnackbar(String mensaje, {required bool esError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final userName = context.watch<AuthProvider>().userName;
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Mi Plan',
          style: TextStyle(fontWeight: FontWeight.w600)),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
              child: Text(userName, style: const TextStyle(fontSize: 14))),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar',
          onPressed: () {
            _bienvenidaMostrada = false;
            _initCargaInicial();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.onboardings.isEmpty && !_loadingDetalle) {
      return _buildSinOnboarding();
    }
    if (_loadError != null && _detalle == null) {
      return _buildError();
    }
    return _buildConOnboarding();
  }

  // ── Estados vacíos ────────────────────────────────────────

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFFDC2626), size: 48),
              const SizedBox(height: 16),
              const Text('No se pudo cargar tu información',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(_loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initCargaInicial,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSinOnboarding() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.assignment_late_rounded,
                    color: Color(0xFF1565C0), size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Sin onboarding asignado',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              const Text(
                'Contacta a tu administrador para\nque te asigne un plan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );

  // ── Vista principal ───────────────────────────────────────

  Widget _buildConOnboarding() {
    // Filtrar step oculto de bienvenida
    final todosLosSteps = (_detalle?.stepsConProgreso ?? [])
        .where((s) => s.titulo != '__BIENVENIDA__')
        .toList();

    // Paso 3: aplicar filtro — pendientes u completados
    final stepsFiltrados = _filtro == _FiltroPlan.pendientes
        ? todosLosSteps
            .where((s) => s.tasks.any((t) => !t.completada))
            .toList()
        : todosLosSteps
            .where((s) => s.tasks.any((t) => t.completada))
            .toList();

    // Contadores para las etiquetas del toggle
    final totalPendientes = todosLosSteps.fold(
        0, (sum, s) => sum + s.tasks.where((t) => !t.completada).length);
    final totalCompletadas = todosLosSteps.fold(
        0, (sum, s) => sum + s.tasks.where((t) => t.completada).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de onboarding
          if (widget.onboardings.length > 1) ...[
            OnboardingSelector(
              onboardings: widget.onboardings,
              seleccionado: _onboardingSeleccionado,
              onChanged: (id) {
                if (id != null && id != _onboardingSeleccionado) {
                  _bienvenidaMostrada = false;
                  _cargarDetalle(id);
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // Card de progreso
          _buildProgresoCard(),
          const SizedBox(height: 20),

          // ── Paso 3: toggle de filtro ──────────────────────
          _buildFiltroToggle(totalPendientes, totalCompletadas),
          const SizedBox(height: 16),

          // Banner error inline
          if (_loadError != null && _detalle != null) _buildErrorBanner(),

          // Encabezado etapas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filtro == _FiltroPlan.pendientes
                    ? 'Tareas pendientes'
                    : 'Tareas completadas',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
              ),
              if (_loadingDetalle)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),

          // Lista de etapas filtradas
          if (_loadingDetalle && todosLosSteps.isEmpty)
            const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()),
            )
          else if (stepsFiltrados.isEmpty)
            _buildEmptyFiltro()
          else
            ...stepsFiltrados.asMap().entries.map(
                  (e) => StepCard(
                    step: e.value,
                    numero: todosLosSteps.indexOf(e.value) + 1,
                    idOnboarding: _onboardingSeleccionado!,
                    expandido: _filtro == _FiltroPlan.pendientes
                        ? _stepsExpandidos.contains(e.value.idStep)
                        : true, // completados siempre expandidos
                    onToggle: () => setState(() {
                      _stepsExpandidos.contains(e.value.idStep)
                          ? _stepsExpandidos.remove(e.value.idStep)
                          : _stepsExpandidos.add(e.value.idStep);
                    }),
                    onCompletarTask: _completarTask,
                    onEnviarFormulario: _enviarFormulario,
                  ),
                ),
        ],
      ),
    );
  }

  // ── Paso 3: toggle pendientes / completados ───────────────

  Widget _buildFiltroToggle(int pendientes, int completadas) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildFiltroBtn(
            label: 'Pendientes',
            count: pendientes,
            activo: _filtro == _FiltroPlan.pendientes,
            color: const Color(0xFF1565C0),
            onTap: () => setState(() => _filtro = _FiltroPlan.pendientes),
          ),
          _buildFiltroBtn(
            label: 'Completados',
            count: completadas,
            activo: _filtro == _FiltroPlan.completados,
            color: const Color(0xFF10B981),
            onTap: () => setState(() => _filtro = _FiltroPlan.completados),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroBtn({
    required String label,
    required int count,
    required bool activo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      activo ? FontWeight.w600 : FontWeight.w400,
                  color: activo ? color : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? color.withOpacity(0.12)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: activo ? color : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFiltro() {
    final esPendientes = _filtro == _FiltroPlan.pendientes;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              esPendientes
                  ? Icons.check_circle_outline_rounded
                  : Icons.hourglass_empty_rounded,
              size: 48,
              color: esPendientes
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              esPendientes
                  ? '¡Todo al día! No tienes tareas pendientes.'
                  : 'Aún no has completado ninguna tarea.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────

  Widget _buildProgresoCard() {
    final progreso = _detalle?.progreso ?? 0.0;
    final estado = _detalle?.estado ?? 'PENDIENTE';
    final steps = (_detalle?.stepsConProgreso ?? [])
        .where((s) => s.titulo != '__BIENVENIDA__')
        .toList();
    final totalTasks = steps.fold(0, (s, e) => s + e.totalTasks);
    final completadas = steps.fold(0, (s, e) => s + e.completadas);
    final colorEstado = _colorEstado(estado);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _detalle?.nombrePlan ?? 'Mi Plan',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: colorEstado.withOpacity(0.4)),
                ),
                child: Text(estado,
                    style: TextStyle(
                        color: colorEstado,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_detalle?.fechaInicio != null) ...[
            const SizedBox(height: 4),
            Text(
              'Inicio: ${_detalle!.fechaInicio!.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progreso general',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13)),
              Text('${progreso.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          if (totalTasks > 0) ...[
            const SizedBox(height: 8),
            Text('$completadas de $totalTasks tareas completadas',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_loadError!,
                style: const TextStyle(
                    color: Color(0xFFDC2626), fontSize: 13)),
          ),
          TextButton(
            onPressed: () => _cargarDetalle(_onboardingSeleccionado!),
            child: const Text('Reintentar',
                style: TextStyle(
                    color: Color(0xFFDC2626), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'COMPLETADO':
        return const Color(0xFF10B981);
      case 'EN_PROGRESO':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
