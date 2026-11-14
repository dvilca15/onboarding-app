import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';
import '../../../theme/app_dialog.dart';

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

    return AppDialog(
      maxWidth: 520,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.danger,
      iconBg: AppColors.dangerSoft,
      title: 'Eliminar plan',
      subtitle: widget.nombrePlan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingEmpleados)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tieneEmpleados) ...[
            InlineBanner(
              _empleados.length == 1
                  ? 'Este plan tiene 1 empleado asignado. Desasígnalo antes de eliminarlo.'
                  : 'Este plan tiene ${_empleados.length} empleados asignados. Desasígnalos antes de eliminarlo.',
              tone: BannerTone.warning,
            ),
            const SizedBox(height: 16),
            const Text('EMPLEADOS ASIGNADOS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: AppColors.textSubtle)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _empleados.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final emp = _empleados[i];
                  final idUser = emp['id_user'] as int;
                  final nombre = emp['nombre'] as String;
                  final email = emp['email'] as String;
                  final estado = emp['estado'] as String? ?? 'PENDIENTE';
                  final desasignando = _desasignando.contains(idUser);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(children: [
                      InitialAvatar(nombre, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text)),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge.estado(estado),
                            ]),
                            const SizedBox(height: 2),
                            Text(email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      desasignando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : OutlinedButton(
                              onPressed: () => _desasignarEmpleado(emp),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(
                                    color: AppColors.dangerBorder),
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                              ),
                              child: const Text('Desasignar',
                                  style: TextStyle(fontSize: 12.5)),
                            ),
                    ]),
                  );
                },
              ),
            ),
          ] else
            const Text(
              'No hay empleados asignados a este plan. Al eliminarlo se '
              'borrarán también sus etapas y tareas. Esta acción no se '
              'puede deshacer.',
              style: TextStyle(
                  fontSize: 14, height: 1.55, color: AppColors.textMuted),
            ),
        ],
      ),
      actions: [
        DialogCancelButton(
            onPressed: _eliminando ? null : () => Navigator.pop(context)),
        DialogPrimaryButton(
          label: 'Eliminar plan',
          destructive: true,
          icon: Icons.delete_outline_rounded,
          loading: _eliminando,
          onPressed: (tieneEmpleados || _loadingEmpleados)
              ? null
              : _eliminarPlan,
        ),
      ],
    );
  }
}
