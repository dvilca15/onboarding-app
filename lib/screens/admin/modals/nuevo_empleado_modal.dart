import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';

class NuevoEmpleadoModal extends StatefulWidget {
  final VoidCallback onCreated;
  const NuevoEmpleadoModal({super.key, required this.onCreated});

  static Future<void> show(BuildContext context, VoidCallback onCreated) {
    return showDialog(
      context: context,
      builder: (_) => NuevoEmpleadoModal(onCreated: onCreated),
    );
  }

  @override
  State<NuevoEmpleadoModal> createState() => _NuevoEmpleadoModalState();
}

class _NuevoEmpleadoModalState extends State<NuevoEmpleadoModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await ApiService.register(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        empresaId: auth.empresaId,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        showSnack(context, 'Empleado creado correctamente', success: true);
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
      title: const Text('Nuevo empleado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField('Nombre completo', _nombreCtrl, Icons.person_outline,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Correo electrónico', _emailCtrl, Icons.email_outlined,
                  (v) {
                if (v!.isEmpty) return 'Requerido';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              }),
              const SizedBox(height: 12),
              modalField('Contraseña', _passCtrl, Icons.lock_outline, (v) {
                if (v!.isEmpty) return 'Requerido';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              }, obscure: true),
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
          child: _loading ? btnSpinner() : const Text('Crear empleado'),
        ),
      ],
    );
  }
}