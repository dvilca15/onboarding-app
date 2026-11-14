import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../widgets/ui_helpers.dart';
import '../../../theme/app_dialog.dart';

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
    return AppDialog(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Nuevo empleado',
      subtitle: 'Crea su cuenta. Podrá entrar con este correo y contraseña.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            modalField('Nombre completo', _nombreCtrl, Icons.person_outline,
                (v) => v!.isEmpty ? 'Requerido' : null,
                hint: 'Ana Pérez'),
            const SizedBox(height: 16),
            modalField('Correo electrónico', _emailCtrl, Icons.email_outlined,
                (v) {
              if (v!.isEmpty) return 'Requerido';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            }, hint: 'ana@empresa.com'),
            const SizedBox(height: 16),
            modalField('Contraseña inicial', _passCtrl, Icons.lock_outline,
                (v) {
              if (v!.isEmpty) return 'Requerido';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
                obscure: true,
                help: 'Mínimo 6 caracteres. Se le pedirá cambiarla al '
                    'primer ingreso.'),
          ],
        ),
      ),
      actions: [
        DialogCancelButton(
            onPressed: _loading ? null : () => Navigator.pop(context)),
        DialogPrimaryButton(
          label: 'Crear empleado',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
