import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
// CambiarPasswordScreen
//
// Se muestra obligatoriamente cuando el empleado entra por
// primera vez y password_changed = false.
// El empleado no puede navegar a ningún otro lado hasta
// completar este paso.
// ─────────────────────────────────────────────────────────────

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _actualController   = TextEditingController();
  final _nuevaController    = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _verActual    = false;
  bool _verNueva     = false;
  bool _verConfirmar = false;
  bool _guardando    = false;
  String? _errorApi;

  static const _azul = Color(0xFF1565C0);

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // ── Envío ─────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorApi  = null;
    });

    try {
      await ApiService.cambiarPassword(
        passwordActual:    _actualController.text.trim(),
        passwordNueva:     _nuevaController.text.trim(),
        passwordConfirmar: _confirmarController.text.trim(),
      );

      // Actualizar estado local del provider
      if (mounted) {
        await context.read<AuthProvider>().marcarPasswordCambiado();
        // Redirigir al dashboard del empleado
        context.go('/empleado/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorApi = e.toString().replaceAll('Exception: ', '');
        _guardando = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().userName;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(userName),
                const SizedBox(height: 32),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _azul.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: _azul, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Bienvenido, $userName!',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Por seguridad, debes cambiar tu contraseña\nantes de continuar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error API
              if (_errorApi != null) ...[
                _buildErrorBanner(_errorApi!),
                const SizedBox(height: 16),
              ],

              // Contraseña actual
              _buildPasswordField(
                controller: _actualController,
                label: 'Contraseña actual',
                verTexto: _verActual,
                onToggleVer: () =>
                    setState(() => _verActual = !_verActual),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
              ),
              const SizedBox(height: 16),

              // Contraseña nueva
              _buildPasswordField(
                controller: _nuevaController,
                label: 'Contraseña nueva',
                verTexto: _verNueva,
                onToggleVer: () =>
                    setState(() => _verNueva = !_verNueva),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la contraseña nueva';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar contraseña nueva
              _buildPasswordField(
                controller: _confirmarController,
                label: 'Confirmar contraseña nueva',
                verTexto: _verConfirmar,
                onToggleVer: () =>
                    setState(() => _verConfirmar = !_verConfirmar),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la contraseña nueva';
                  if (v != _nuevaController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool verTexto,
    required VoidCallback onToggleVer,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !verTexto,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
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
          borderSide: const BorderSide(color: _azul, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            verTexto ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
          onPressed: onToggleVer,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildErrorBanner(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                  color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
