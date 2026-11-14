import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/plan.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_dialog.dart';

class AsignarPlanModal extends StatefulWidget {
  final List<Usuario> usuarios;
  final List<Plan> planes;
  final VoidCallback onAsignado;

  const AsignarPlanModal({
    super.key,
    required this.usuarios,
    required this.planes,
    required this.onAsignado,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Usuario> usuarios,
    required List<Plan> planes,
    required VoidCallback onAsignado,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AsignarPlanModal(
        usuarios: usuarios,
        planes: planes,
        onAsignado: onAsignado,
      ),
    );
  }

  @override
  State<AsignarPlanModal> createState() => _AsignarPlanModalState();
}

class _AsignarPlanModalState extends State<AsignarPlanModal> {
  int? _usuarioSeleccionado;
  int? _planSeleccionado;
  bool _loading = false;

  Future<void> _confirmarYAsignar() async {
    if (_usuarioSeleccionado == null || _planSeleccionado == null) {
      showSnack(context, 'Selecciona empleado y plan');
      return;
    }

    final empleado = widget.usuarios.firstWhere(
      (u) => u.idUser == _usuarioSeleccionado,
    );
    final plan = widget.planes.firstWhere(
      (p) => p.idPlan == _planSeleccionado,
    );

    final confirmar = await confirmarAccion(
      context,
      titulo: 'Confirmar asignación',
      mensaje:
          'Se asignará el plan «${plan.nombre}» a ${empleado.nombre}. '
          'El empleado lo verá de inmediato en su cuenta.',
      confirmar: 'Asignar plan',
      destructivo: false,
      icono: Icons.assignment_turned_in_outlined,
    );

    if (!confirmar || !mounted) return;
    setState(() => _loading = true);

    try {
      await ApiService.asignarPlan(
        idUser: _usuarioSeleccionado!,
        idPlan: _planSeleccionado!,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAsignado();
        showSnack(context, 'Plan asignado correctamente', success: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.assignment_ind_outlined,
      title: 'Asignar plan a empleado',
      subtitle: 'Elige a quién y qué plan de onboarding recibirá.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label: 'Empleado',
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _usuarioSeleccionado,
              hint: const Text('Selecciona un empleado'),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textSubtle),
              items: widget.usuarios
                  .map((u) => DropdownMenuItem<int>(
                        value: u.idUser,
                        child: Text('${u.nombre} — ${u.email}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _usuarioSeleccionado = v),
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            label: 'Plan de onboarding',
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _planSeleccionado,
              hint: const Text('Selecciona un plan'),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textSubtle),
              items: widget.planes
                  .map((p) => DropdownMenuItem<int>(
                        value: p.idPlan,
                        child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _planSeleccionado = v),
            ),
          ),
        ],
      ),
      actions: [
        DialogCancelButton(
            onPressed: _loading ? null : () => Navigator.pop(context)),
        DialogPrimaryButton(
          label: 'Asignar plan',
          loading: _loading,
          onPressed: _confirmarYAsignar,
        ),
      ],
    );
  }
}
