import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_dialog.dart';

class NuevoStepModal extends StatefulWidget {
  final int idPlan;
  final String nombrePlan;
  final VoidCallback? onCreated;

  const NuevoStepModal({
    super.key,
    required this.idPlan,
    required this.nombrePlan,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required int idPlan,
    required String nombrePlan,
    VoidCallback? onCreated,
  }) {
    return showDialog(
      context: context,
      builder: (_) => NuevoStepModal(
        idPlan: idPlan,
        nombrePlan: nombrePlan,
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<NuevoStepModal> createState() => _NuevoStepModalState();
}

class _NuevoStepModalState extends State<NuevoStepModal> {
  final _formKey    = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _ordenCtrl  = TextEditingController(text: '1');
  final _diasCtrl   = TextEditingController();
  bool _loading     = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _ordenCtrl.dispose();
    _diasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.crearStep(
        idPlan:       widget.idPlan,
        titulo:       _tituloCtrl.text.trim(),
        descripcion:  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        orden:        int.parse(_ordenCtrl.text),
        duracionDias: _diasCtrl.text.trim().isEmpty ? null : int.parse(_diasCtrl.text),
      );
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Etapa creada correctamente', success: true);
        widget.onCreated?.call();
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
      icon: Icons.view_agenda_outlined,
      title: 'Nueva etapa',
      subtitle: widget.nombrePlan,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            modalField('Título de la etapa', _tituloCtrl,
                Icons.view_agenda_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null,
                hint: 'Inducción y cultura'),
            const SizedBox(height: 16),
            modalField('Descripción (opcional)', _descCtrl,
                Icons.notes_outlined, (_) => null,
                maxLines: 2, hint: 'Qué logrará el empleado en esta etapa'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: modalField('Orden', _ordenCtrl,
                      Icons.format_list_numbered, (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (int.tryParse(v) == null) return 'Número';
                    return null;
                  },
                      keyboardType: TextInputType.number,
                      help: 'Posición en el plan'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: modalField('Duración (días)', _diasCtrl,
                      Icons.calendar_today_outlined, (v) {
                    if (v!.isNotEmpty && int.tryParse(v) == null) {
                      return 'Número';
                    }
                    return null;
                  },
                      keyboardType: TextInputType.number,
                      help: 'Opcional'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        DialogCancelButton(
            onPressed: _loading ? null : () => Navigator.pop(context)),
        DialogPrimaryButton(
          label: 'Crear etapa',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
