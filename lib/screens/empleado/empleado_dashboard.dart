import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/onboarding.dart';

import 'widgets/step_card.dart';
import 'widgets/onboarding_selector.dart';
import 'widgets/bienvenida_modal.dart';

class EmpleadoDashboard extends StatefulWidget {
  const EmpleadoDashboard({super.key});

  @override
  State<EmpleadoDashboard> createState() => _EmpleadoDashboardState();
}

class _EmpleadoDashboardState extends State<EmpleadoDashboard> {
  List<Onboarding> _onboardings = [];
  OnboardingDetalle? _detalle;
  bool _loading = true;
  bool _loadingDetalle = false;
  String? _loadError;
  int? _onboardingSeleccionado;
  final Set<int> _stepsExpandidos = {};
  bool _bienvenidaMostrada = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final raw = await ApiService.listarOnboardings();
      final idUsuario = context.read<AuthProvider>().userId;
      final lista = raw
          .map((e) => Onboarding.fromJson(e))
          .where((o) => o.idUser == idUsuario)
          .toList();
      setState(() { _onboardings = lista; _loading = false; });
      if (lista.isNotEmpty) {
        await _cargarDetalle(lista.first.idEmployeeOnboarding);
        // Verificar bienvenida después de cargar datos
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkBienvenida());
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _checkBienvenida() async {
    if (_bienvenidaMostrada || _onboardings.isEmpty) return;

    final onboardingActivo = _onboardings.firstWhere(
      (o) => o.estado != 'COMPLETADO',
      orElse: () => _onboardings.first,
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
    } catch (_) {
      // Si falla, no bloqueamos al empleado
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
        // Saltar el step oculto de bienvenida
        if (step.titulo == '__BIENVENIDA__') continue;
        if (step.tasks.any((t) => !t.completada)) {
          _stepsExpandidos.add(step.idStep);
          break;
        }
      }
      setState(() { _detalle = detalle; _loadingDetalle = false; });
    } catch (e) {
      setState(() {
        _loadingDetalle = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _completarTask(int idTask) async {
    if (_onboardingSeleccionado == null) return;
    try {
      await ApiService.completarTask(
        idOnboarding: _onboardingSeleccionado!,
        idTask: idTask,
      );
      await _cargarDetalle(_onboardingSeleccionado!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Tarea completada!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi Onboarding',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
                child: Text(auth.userName,
                    style: const TextStyle(fontSize: 14))),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadError != null && _onboardings.isEmpty) return _buildError();
    if (_onboardings.isEmpty) return _buildSinOnboarding();
    return _buildConOnboarding();
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFDC2626), size: 48),
        const SizedBox(height: 16),
        const Text('No se pudo cargar tu información',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(_loadError!, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildSinOnboarding() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.assignment_late_rounded,
              color: Color(0xFF1565C0), size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Sin onboarding asignado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        const Text('Contacta a tu administrador para\nque te asigne un plan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ]),
    ),
  );

  Widget _buildConOnboarding() {
    final progresoNum      = _detalle?.progreso ?? 0.0;
    final estado           = _detalle?.estado ?? 'PENDIENTE';
    // Filtrar el step oculto de bienvenida de la vista
    final steps            = (_detalle?.stepsConProgreso ?? [])
        .where((s) => s.titulo != '__BIENVENIDA__')
        .toList();
    final totalTasks       = steps.fold(0, (s, e) => s + e.totalTasks);
    final completadasTotal = steps.fold(0, (s, e) => s + e.completadas);
    final colorEstado      = estado == 'COMPLETADO'
        ? const Color(0xFF10B981)
        : estado == 'EN_PROGRESO'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        if (_onboardings.length > 1) ...[
          OnboardingSelector(
            onboardings: _onboardings,
            seleccionado: _onboardingSeleccionado,
            onChanged: (id) {
              if (id != null && id != _onboardingSeleccionado) {
                _bienvenidaMostrada = false; // reset para el nuevo onboarding
                _cargarDetalle(id);
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Card de progreso
        Container(
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text(
                  _detalle?.nombrePlan ?? 'Mi Plan',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorEstado.withOpacity(0.4)),
                ),
                child: Text(estado,
                    style: TextStyle(
                        color: colorEstado, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            if (_detalle?.fechaInicio != null) ...[
              const SizedBox(height: 4),
              Text(
                'Inicio: ${_detalle!.fechaInicio!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progreso general',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              Text('${progresoNum.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresoNum / 100,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            if (totalTasks > 0) ...[
              const SizedBox(height: 8),
              Text('$completadasTotal de $totalTasks tareas completadas',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 12)),
            ],
          ]),
        ),

        const SizedBox(height: 24),

        // Banner error inline
        if (_loadError != null && _onboardings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_loadError!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
              TextButton(
                onPressed: () => _cargarDetalle(_onboardingSeleccionado!),
                child: const Text('Reintentar',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
              ),
            ]),
          ),

        // Encabezado etapas
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Etapas del plan',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          if (_loadingDetalle)
            const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        const SizedBox(height: 12),

        // Steps (sin el step __BIENVENIDA__)
        if (_loadingDetalle && steps.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))
        else if (steps.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _loadError != null
                    ? 'No se pudieron cargar las etapas.'
                    : 'Este plan no tiene etapas aún.',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          )
        else
          ...steps.asMap().entries.map((e) => StepCard(
            step: e.value,
            numero: e.key + 1,
            expandido: _stepsExpandidos.contains(e.value.idStep),
            onToggle: () => setState(() {
              _stepsExpandidos.contains(e.value.idStep)
                  ? _stepsExpandidos.remove(e.value.idStep)
                  : _stepsExpandidos.add(e.value.idStep);
            }),
            onCompletarTask: _completarTask,
          )),
      ]),
    );
  }
}