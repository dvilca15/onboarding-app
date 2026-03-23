import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/plan.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';

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

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar asignación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF374151), height: 1.5),
            children: [
              const TextSpan(text: '¿Asignar el plan '),
              TextSpan(
                text: plan.nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
              ),
              const TextSpan(text: ' a '),
              TextSpan(
                text: empleado.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '?\n\nEsta acción no se puede deshacer.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sí, asignar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
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
    return AlertDialog(
      title: const Text('Asignar plan a empleado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empleado',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _usuarioSeleccionado,
              decoration: inputDec('Selecciona un empleado', Icons.person_outline),
              items: widget.usuarios
                  .map((u) => DropdownMenuItem<int>(
                        value: u.idUser,
                        child: Text('${u.nombre} — ${u.email}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _usuarioSeleccionado = v),
            ),
            const SizedBox(height: 16),
            const Text('Plan de onboarding',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _planSeleccionado,
              decoration:
                  inputDec('Selecciona un plan', Icons.assignment_outlined),
              items: widget.planes
                  .map((p) => DropdownMenuItem<int>(
                        value: p.idPlan,
                        child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _planSeleccionado = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirmarYAsignar,
          style: primaryBtnStyle(),
          child: _loading ? btnSpinner() : const Text('Asignar plan'),
        ),
      ],
    );
  }
}