import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nueva tarea',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField(
                'Título de la tarea',
                _tituloCtrl,
                Icons.task_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: inputDec('Tipo de tarea', Icons.category_outlined),
                items: _tipos
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: modalField(
                      'Orden',
                      _ordenCtrl,
                      Icons.format_list_numbered,
                      (v) {
                        if (v!.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Número';
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Switch(
                        value: _obligatorio,
                        onChanged: (v) => setState(() => _obligatorio = v),
                        activeColor: const Color(0xFF1565C0),
                      ),
                      const Text('Obligatoria', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: primaryBtnStyle(),
          child: _loading ? btnSpinner() : const Text('Crear tarea'),
        ),
      ],
    );
  }
}