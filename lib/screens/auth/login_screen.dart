import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _obscure    = true;
  String _rolSeleccionado = 'EMPLEADO'; // Por defecto empleado

  static const _roles = [
    {'value': 'EMPLEADO',      'label': 'Empleado',      'icon': Icons.person_rounded},
    {'value': 'ADMIN_EMPRESA', 'label': 'Administrador', 'icon': Icons.admin_panel_settings_rounded},
  ];

  Map<String, dynamic> get _rolActual =>
      _roles.firstWhere((r) => r['value'] == _rolSeleccionado);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final error = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (error != null) {
      setState(() => _loading = false);
      AppToast.fromSnackBar(context, SnackBar(
        content: Text(error),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Verificar que el rol seleccionado coincide con los roles reales del usuario
    final rolesUsuario = auth.userRoles;
    if (_rolSeleccionado == 'ADMIN_EMPRESA' && !rolesUsuario.contains('ADMIN_EMPRESA')) {
      await auth.logout();
      setState(() => _loading = false);
      if (mounted) {
        AppToast.fromSnackBar(context, const SnackBar(
          content: Text('No tienes permisos de administrador'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    // Redirigir según el rol seleccionado
    if (_rolSeleccionado == 'ADMIN_EMPRESA') {
      context.go('/admin/dashboard');
    } else {
      context.go('/empleado/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return Row(children: [
          if (wide) const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(showLogo: !wide),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildForm({required bool showLogo}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo) ...[
            const _LogoMark(),
            const SizedBox(height: 32),
          ],
          const Text('Bienvenido de nuevo',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          const Text('Ingresa tus credenciales para continuar.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 28),

          // ── Selector de rol (segmented) ───────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: _roles.map((rol) {
                final selected = _rolSeleccionado == rol['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _rolSeleccionado = rol['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: selected ? kShadowSm : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(rol['icon'] as IconData,
                              size: 16,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(rol['label'] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.text
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          const _FieldLabel('Correo electrónico'),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'nombre@empresa.com',
              prefixIcon: Icon(Icons.mail_outline_rounded,
                  size: 20, color: AppColors.textSubtle),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          const _FieldLabel('Contraseña'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 20, color: AppColors.textSubtle),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSubtle,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Ingresar como ${_rolActual['label']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody)),
      );
}

class _LogoMark extends StatelessWidget {
  final bool onDark;
  const _LogoMark({this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onDark ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.rocket_launch_rounded,
            size: 20, color: onDark ? AppColors.primary : Colors.white),
      ),
      const SizedBox(width: 10),
      Text('Onboarding',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: onDark ? Colors.white : AppColors.text)),
    ]);
  }
}

/// Panel izquierdo de marca (solo en pantallas anchas).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E4A), AppColors.primaryHover, AppColors.primary],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LogoMark(onDark: true),
          const Spacer(),
          const Text('Incorpora a tu equipo\nsin fricción.',
              style: TextStyle(
                  fontSize: 40,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Text(
              'Planes de inducción, seguimiento del progreso y un asistente '
              'con IA para que cada nuevo empleado arranque con claridad.',
              style: TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.78))),
          const SizedBox(height: 36),
          const _Feature(Icons.checklist_rounded, 'Planes por etapas y tareas'),
          const SizedBox(height: 14),
          const _Feature(Icons.insights_rounded, 'Progreso en tiempo real'),
          const SizedBox(height: 14),
          const _Feature(Icons.auto_awesome_rounded, 'Asistente con IA integrado'),
          const Spacer(),
          Text('Sistema de Onboarding para Mipymes',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
      ]);
}
