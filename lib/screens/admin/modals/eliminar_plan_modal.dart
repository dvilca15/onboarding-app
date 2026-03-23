import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';

class EliminarPlanModal extends StatefulWidget {
  final int idPlan;
  final String nombrePlan;
  final VoidCallback onEliminado;

  const EliminarPlanModal({
    super.key,
    required this.idPlan,
    required this.nombrePlan,
    required this.onEliminado,
  });

  static Future<void> show(
    BuildContext context, {
    required int idPlan,
    required String nombrePlan,
    required VoidCallback onEliminado,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EliminarPlanModal(
        idPlan: idPlan,
        nombrePlan: nombrePlan,
        onEliminado: onEliminado,
      ),
    );
  }

  @override
  State<EliminarPlanModal> createState() => _EliminarPlanModalState();
}

class _EliminarPlanModalState extends State<EliminarPlanModal> {
  List<Map<String, dynamic>> _empleados = [];
  bool _loadingEmpleados = true;
  bool _eliminando = false;
  final Set<int> _desasignando = {};

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => _loadingEmpleados = true);
    try {
      final raw = await ApiService.listarEmpleadosPlan(widget.idPlan);
      setState(() {
        _empleados = raw.cast<Map<String, dynamic>>();
        _loadingEmpleados = false;
      });
    } catch (e) {
      setState(() => _loadingEmpleados = false);
      if (mounted) {
        showSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _desasignarEmpleado(Map<String, dynamic> empleado) async {
    final idOnboarding = empleado['id_employee_onboarding'] as int;
    final idUser = empleado['id_user'] as int;
    setState(() => _desasignando.add(idUser));
    try {
      await ApiService.eliminarOnboarding(idOnboarding);
      setState(() {
        _empleados.removeWhere((e) => e['id_user'] == idUser);
        _desasignando.remove(idUser);
      });
      if (mounted) showSnack(context, 'Empleado desasignado', success: true);
    } catch (e) {
      setState(() => _desasignando.remove(idUser));
      if (mounted) {
        showSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _eliminarPlan() async {
    if (_empleados.isNotEmpty) {
      showSnack(context, 'Debes desasignar todos los empleados primero');
      return;
    }
    setState(() => _eliminando = true);
    try {
      await ApiService.eliminarPlan(widget.idPlan);
      if (mounted) {
        Navigator.pop(context);
        widget.onEliminado();
        showSnack(context, 'Plan eliminado correctamente', success: true);
      }
    } catch (e) {
      setState(() => _eliminando = false);
      if (mounted) {
        showSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneEmpleados = _empleados.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Eliminar "${widget.nombrePlan}"',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingEmpleados
                          ? 'Cargando empleados asignados...'
                          : tieneEmpleados
                              ? 'Este plan tiene ${_empleados.length} empleado(s) asignado(s). Desasígnalos antes de eliminar.'
                              : 'No hay empleados asignados. Puedes eliminar el plan.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

            // Loading
            if (_loadingEmpleados) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ]

            // Lista de empleados
            else if (tieneEmpleados) ...[
              const SizedBox(height: 16),
              const Text(
                'Empleados asignados:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _empleados.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (_, i) {
                    final emp    = _empleados[i];
                    final idUser = emp['id_user'] as int;
                    final nombre = emp['nombre'] as String;
                    final email  = emp['email'] as String;
                    final estado = emp['estado'] as String? ?? 'PENDIENTE';
                    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
                    final desasignando = _desasignando.contains(idUser);

                    final colorEstado = estado == 'COMPLETADO'
                        ? const Color(0xFF10B981)
                        : estado == 'EN_PROGRESO'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF6B7280);

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                        child: Text(inicial,
                            style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      title: Text(nombre, style: const TextStyle(fontSize: 13)),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(email,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF6B7280)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(estado,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: colorEstado,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      trailing: desasignando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: () => _desasignarEmpleado(emp),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Desasignar',
                                  style: TextStyle(fontSize: 12)),
                            ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton.icon(
          onPressed: (_eliminando || tieneEmpleados || _loadingEmpleados)
              ? null
              : _eliminarPlan,
          icon: _eliminando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.delete_outline, size: 18),
          label: const Text('Eliminar plan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tieneEmpleados
                ? const Color(0xFF9CA3AF)
                : const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }
}