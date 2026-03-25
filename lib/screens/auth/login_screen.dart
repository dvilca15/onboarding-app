import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: const Color(0xFFDC2626),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No tienes permisos de administrador'),
          backgroundColor: Color(0xFFDC2626),
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
    final colorRol = _rolSeleccionado == 'ADMIN_EMPRESA'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Ícono animado por rol ───────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorRol,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorRol.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _rolActual['icon'] as IconData,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // ── Título ──────────────────────────────────────
              const Text(
                'Sistema de Onboarding',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Ingresa como ${_rolActual['label']}',
                  key: ValueKey(_rolSeleccionado),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorRol,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Card del formulario ─────────────────────────
              Container(
                width: 400,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Selector de rol (toggle) ────────────
                      const Text(
                        'Ingresar como',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: colorRol.withOpacity(0.4), width: 1.5),
                          color: colorRol.withOpacity(0.04),
                        ),
                        child: Row(
                          children: _roles.map((rol) {
                            final isSelected =
                                _rolSeleccionado == rol['value'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _rolSeleccionado = rol['value'] as String),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorRol
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        rol['icon'] as IconData,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        rol['label'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Email ───────────────────────────────
                      const Text(
                        'Correo electrónico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDec(
                          'correo@empresa.com',
                          Icons.email_outlined,
                          colorRol,
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Contraseña ──────────────────────────
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: _inputDec(
                          '••••••••',
                          Icons.lock_outline,
                          colorRol,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),

                      const SizedBox(height: 24),

                      // ── Botón login ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorRol,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Ingresar como ${_rolActual['label']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Sistema de Onboarding para Mipymes',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon, Color color) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}