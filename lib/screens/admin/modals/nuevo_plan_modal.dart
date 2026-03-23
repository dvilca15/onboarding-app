import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';

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
    return AlertDialog(
      title: const Text('Nuevo plan de onboarding',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField(
                  'Nombre del plan', _nombreCtrl, Icons.assignment_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Descripción (opcional)', _descCtrl,
                  Icons.notes_outlined, (_) => null,
                  maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _esPlantilla,
                    onChanged: (v) => setState(() => _esPlantilla = v),
                    activeColor: const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  const Text('Marcar como plantilla',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: primaryBtnStyle(),
          child: _loading ? btnSpinner() : const Text('Crear plan'),
        ),
      ],
    );
  }
}