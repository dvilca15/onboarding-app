import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EmpleadoDashboard extends StatefulWidget {
  const EmpleadoDashboard({super.key});

  @override
  State<EmpleadoDashboard> createState() => _EmpleadoDashboardState();
}

class _EmpleadoDashboardState extends State<EmpleadoDashboard> {
  List<dynamic> _onboardings = [];
  Map<String, dynamic>? _progresoActual;
  bool _loading = true;
  int? _onboardingSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final onboardings = await ApiService.listarOnboardings();
      setState(() {
        _onboardings = onboardings;
        _loading = false;
      });
      if (onboardings.isNotEmpty) {
        await _cargarProgreso(onboardings[0]['id_employee_onboarding']);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarProgreso(int idOnboarding) async {
    setState(() {
      _onboardingSeleccionado = idOnboarding;
      _loading = true;
    });
    try {
      final progreso = await ApiService.verProgreso(idOnboarding);
      setState(() {
        _progresoActual = progreso;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _completarTask(int idTask) async {
    if (_onboardingSeleccionado == null) return;
    try {
      await ApiService.completarTask(
        idOnboarding: _onboardingSeleccionado!,
        idTask: idTask,
      );
      await _cargarProgreso(_onboardingSeleccionado!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tarea completada!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
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
                  style: const TextStyle(fontSize: 14)),
            ),
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
          : _onboardings.isEmpty
              ? _buildSinOnboarding()
              : _buildConOnboarding(),
    );
  }

  Widget _buildSinOnboarding() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const Text('Contacta a tu administrador para\nque te asigne un plan de onboarding.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildConOnboarding() {
    final progreso = _progresoActual;
    final progresoNum = double.tryParse(progreso?['progreso']?.toString() ?? '0') ?? 0.0;
    final estado = progreso?['estado'] as String? ?? 'PENDIENTE';
    final taskProgresses = progreso?['task_progresses'] as List<dynamic>? ?? [];

    final colorEstado = estado == 'COMPLETADO'
        ? const Color(0xFF10B981)
        : estado == 'EN_PROGRESO'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de progreso general
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progreso?['nombre_plan'] ?? 'Mi Plan',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorEstado.withOpacity(0.4)),
                      ),
                      child: Text(estado,
                          style: TextStyle(
                              color: colorEstado,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progreso?['nombre_empleado'] ?? '',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progreso general',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    Text('${progresoNum.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tasks
          const Text('Mis tareas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),

          if (taskProgresses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No hay tareas asignadas aún.',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...taskProgresses.map((tp) {
              final task = tp['task'] as Map<String, dynamic>?;
              final taskEstado = tp['estado'] as String? ?? 'PENDIENTE';
              final completada = taskEstado == 'COMPLETADO';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completada
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox
                    InkWell(
                      onTap: completada
                          ? null
                          : () => _completarTask(tp['id_task']),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: completada
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          border: Border.all(
                            color: completada
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: completada
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task?['titulo'] ?? 'Tarea',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: completada
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF1A1A2E),
                              decoration: completada
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _tipoBadge(task?['tipo'] ?? ''),
                              if (task?['obligatorio'] == true) ...[
                                const SizedBox(width: 6),
                                const Text('Obligatoria',
                                    style: TextStyle(
                                        fontSize: 11, color: Color(0xFFDC2626))),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!completada)
                      TextButton(
                        onPressed: () => _completarTask(tp['id_task']),
                        child: const Text('Completar',
                            style: TextStyle(
                                color: Color(0xFF1565C0), fontSize: 13)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _tipoBadge(String tipo) {
    final colors = {
      'DOCUMENTO': [const Color(0xFFEFF6FF), const Color(0xFF3B82F6)],
      'VIDEO': [const Color(0xFFFFF7ED), const Color(0xFFF97316)],
      'FORMULARIO': [const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)],
      'CONFIRMACION': [const Color(0xFFF0FDF4), const Color(0xFF22C55E)],
    };
    final c = colors[tipo] ?? [const Color(0xFFF3F4F6), const Color(0xFF6B7280)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tipo,
          style: TextStyle(fontSize: 10, color: c[1], fontWeight: FontWeight.w500)),
    );
  }
}