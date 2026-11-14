import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';
import '../../../theme/app_dialog.dart';

class NuevoTaskModal extends StatefulWidget {
  final int idStep;
  final VoidCallback? onCreated;

  const NuevoTaskModal({
    super.key,
    required this.idStep,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required int idStep,
    VoidCallback? onCreated,
  }) {
    return showDialog(
      context: context,
      builder: (_) => NuevoTaskModal(idStep: idStep, onCreated: onCreated),
    );
  }

  @override
  State<NuevoTaskModal> createState() => _NuevoTaskModalState();
}

class _NuevoTaskModalState extends State<NuevoTaskModal> {
  final _formKey    = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _ordenCtrl  = TextEditingController(text: '1');
  bool _loading     = false;
  bool _obligatorio = true;
  String _tipo      = 'CONFIRMACION';

  static const _tipos = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _ordenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.crearTask(
        idStep:      widget.idStep,
        titulo:      _tituloCtrl.text.trim(),
        tipo:        _tipo,
        obligatorio: _obligatorio,
        orden:       int.parse(_ordenCtrl.text),
      );
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Tarea creada correctamente', success: true);
        widget.onCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  static const _descripcionTipo = {
    'DOCUMENTO': 'El empleado lee o firma un archivo.',
    'VIDEO': 'El empleado ve un video.',
    'FORMULARIO': 'El empleado responde preguntas.',
    'CONFIRMACION': 'El empleado confirma que lo hizo.',
  };

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.task_alt_rounded,
      title: 'Nueva tarea',
      subtitle: 'Define qué debe hacer el empleado.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            modalField('Título de la tarea', _tituloCtrl, Icons.task_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null,
                hint: 'Leer el reglamento interno'),
            const SizedBox(height: 16),
            FieldLabel(
              label: 'Tipo de tarea',
              help: _descripcionTipo[_tipo],
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _tipo,
                icon: const Icon(Icons.expand_more_rounded,
                    color: AppColors.textSubtle),
                items: _tipos.map((t) {
                  final i = TipoTareaInfo.de(t);
                  return DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(i.icono, size: 18, color: i.color),
                      const SizedBox(width: 10),
                      Text(i.etiqueta),
                    ]),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
            ),
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
                  }, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FieldLabel(
                    label: 'Obligatoria',
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(_obligatorio ? 'Sí' : 'No',
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.text)),
                        ),
                        Switch(
                          value: _obligatorio,
                          onChanged: (v) => setState(() => _obligatorio = v),
                          activeColor: AppColors.primary,
                        ),
                      ]),
                    ),
                  ),
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
          label: 'Crear tarea',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
