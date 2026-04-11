import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/onboarding.dart';
import '../../../services/api_service.dart';


class PerfilTab extends StatelessWidget {
  final List<Onboarding> onboardings;

  const PerfilTab({
    super.key,
    required this.onboardings,
  });

  static const _azul  = Color(0xFF1565C0);
  static const _gris  = Color(0xFF6B7280);
  static const _fondo = Color(0xFFF5F7FA);

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Perfil',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar + nombre ───────────────────────────────
          _buildCabecera(auth.userName),
          const SizedBox(height: 24),

          // ── Datos personales ──────────────────────────────
          _buildSeccionTitulo('Datos personales'),
          const SizedBox(height: 10),
          _buildDatosCard(auth),
          const SizedBox(height: 24),

          // ── Historial ─────────────────────────────────────
          _buildSeccionTitulo('Historial de onboardings'),
          const SizedBox(height: 10),
          _buildHistorial(),
          const SizedBox(height: 24),

          // ── Cambiar contraseña ────────────────────────────
          _buildSeccionTitulo('Seguridad'),
          const SizedBox(height: 10),
          _buildCambiarPasswordBtn(context),
          const SizedBox(height: 32),

          // ── Cerrar sesión ─────────────────────────────────
          _buildCerrarSesionBtn(context, auth),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Cabecera con avatar ───────────────────────────────────

  Widget _buildCabecera(String nombre) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _azul,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _iniciales(nombre),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _azul.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Empleado',
                style: TextStyle(
                    fontSize: 12,
                    color: _azul,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Título de sección ─────────────────────────────────────

  Widget _buildSeccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _gris,
          letterSpacing: 0.3),
    );
  }

  // ── Datos personales ──────────────────────────────────────

  Widget _buildDatosCard(AuthProvider auth) {
    final userData = auth.userData;
    final email = userData?['email'] as String? ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildDatoFila(
            icono: Icons.business_outlined,
            etiqueta: 'Empresa',
            valor: auth.userData?['nombre_empresa'] as String? ?? '—',
          ),
          _buildDatoFila(
            icono: Icons.person_outline_rounded,
            etiqueta: 'Nombre',
            valor: auth.userName,
          ),
          const Divider(height: 1, indent: 52),
          _buildDatoFila(
            icono: Icons.email_outlined,
            etiqueta: 'Correo',
            valor: email,
          ),
        ],
      ),
    );
  }

  Widget _buildDatoFila({
    required IconData icono,
    required String etiqueta,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icono, color: _azul, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: const TextStyle(
                      fontSize: 11, color: _gris)),
              const SizedBox(height: 2),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Historial de onboardings ──────────────────────────────

  Widget _buildHistorial() {
    if (onboardings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text('Sin onboardings asignados',
              style: TextStyle(fontSize: 14, color: _gris)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: onboardings.asMap().entries.map((e) {
          final i = e.key;
          final o = e.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, indent: 16, endIndent: 16),
              _buildOnboardingFila(o),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOnboardingFila(Onboarding o) {
    final color = _colorEstado(o.estado);
    final icono = _iconoEstado(o.estado);
    final progreso = o.progreso / 100;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Ícono estado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.displayPlan,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progreso,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${o.progreso.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                    if (o.fechaInicio != null) ...[
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 11, color: _gris)),
                      Text(
                        'Inicio: ${o.fechaInicio!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                            fontSize: 11, color: _gris),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Badge estado
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              o.estado,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cambiar contraseña ────────────────────────────────────

  Widget _buildCambiarPasswordBtn(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _azul.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: _azul, size: 18),
        ),
        title: const Text('Cambiar contraseña',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: const Text('Actualiza tu contraseña de acceso',
            style: TextStyle(fontSize: 12, color: _gris)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: _gris, size: 20),
        onTap: () => _mostrarDialogCambiarPassword(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _mostrarDialogCambiarPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _CambiarPasswordDialog(),
    );
  }

  // ── Cerrar sesión ─────────────────────────────────────────

  Widget _buildCerrarSesionBtn(
      BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await auth.logout();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded,
            color: Color(0xFFDC2626), size: 18),
        label: const Text('Cerrar sesión',
            style: TextStyle(color: Color(0xFFDC2626))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'COMPLETADO':
        return const Color(0xFF10B981);
      case 'EN_PROGRESO':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'COMPLETADO':
        return Icons.check_circle_rounded;
      case 'EN_PROGRESO':
        return Icons.play_circle_rounded;
      default:
        return Icons.pending_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Dialog de cambio de contraseña
// Reutiliza ApiService.cambiarPassword y AuthProvider.marcarPasswordCambiado
// ─────────────────────────────────────────────────────────────

class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog();

  @override
  State<_CambiarPasswordDialog> createState() =>
      _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final _formKey       = GlobalKey<FormState>();
  final _actualCtrl    = TextEditingController();
  final _nuevaCtrl     = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _verActual    = false;
  bool _verNueva     = false;
  bool _verConfirmar = false;
  bool _guardando    = false;
  String? _errorApi;

  static const _azul = Color(0xFF1565C0);

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _errorApi  = null;
    });
    try {
      await ApiService.cambiarPassword(
        passwordActual:    _actualCtrl.text.trim(),
        passwordNueva:     _nuevaCtrl.text.trim(),
        passwordConfirmar: _confirmarCtrl.text.trim(),
      );
      if (mounted) {
        await context.read<AuthProvider>().marcarPasswordCambiado();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorApi  = e.toString().replaceAll('Exception: ', '');
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded,
              color: _azul, size: 22),
          SizedBox(width: 8),
          Text('Cambiar contraseña',
              style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error API
              if (_errorApi != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorApi!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              _buildCampo(
                controller: _actualCtrl,
                label: 'Contraseña actual',
                ver: _verActual,
                onToggle: () =>
                    setState(() => _verActual = !_verActual),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildCampo(
                controller: _nuevaCtrl,
                label: 'Contraseña nueva',
                ver: _verNueva,
                onToggle: () =>
                    setState(() => _verNueva = !_verNueva),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildCampo(
                controller: _confirmarCtrl,
                label: 'Confirmar contraseña nueva',
                ver: _verConfirmar,
                onToggle: () =>
                    setState(() => _verConfirmar = !_verConfirmar),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v != _nuevaCtrl.text) return 'No coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: _azul)),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _azul,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required bool ver,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !ver,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: _azul, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            ver
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF9CA3AF),
            size: 18,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
      validator: validator,
    );
  }
}
