import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_dialog.dart';

class NuevoPlanModal extends StatefulWidget {
  final VoidCallback onCreated;
  const NuevoPlanModal({super.key, required this.onCreated});

  static Future<void> show(BuildContext context, VoidCallback onCreated) {
    return showDialog(
      context: context,
      builder: (_) => NuevoPlanModal(onCreated: onCreated),
    );
  }

  @override
  State<NuevoPlanModal> createState() => _NuevoPlanModalState();
}

class _NuevoPlanModalState extends State<NuevoPlanModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _esPlantilla = false;
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.crearPlan(
        nombre: _nombreCtrl.text.trim(),
        descripcion:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        esPlantilla: _esPlantilla,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        showSnack(context, 'Plan creado correctamente', success: true);
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
      icon: Icons.route_rounded,
      title: 'Nuevo plan de onboarding',
      subtitle: 'Luego podrás agregarle etapas y tareas.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            modalField('Nombre del plan', _nombreCtrl,
                Icons.assignment_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null,
                hint: 'Onboarding de ventas'),
            const SizedBox(height: 16),
            modalField('Descripción (opcional)', _descCtrl,
                Icons.notes_outlined, (_) => null,
                maxLines: 3, hint: 'Para qué puesto o área es este plan'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marcar como plantilla',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text)),
                        SizedBox(height: 2),
                        Text('Sirve de base para crear otros planes.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _esPlantilla,
                    onChanged: (v) => setState(() => _esPlantilla = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        DialogCancelButton(
            onPressed: _loading ? null : () => Navigator.pop(context)),
        DialogPrimaryButton(
          label: 'Crear plan',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
