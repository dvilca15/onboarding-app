import 'package:flutter/material.dart';

/// Decoración estándar para campos de formulario
InputDecoration inputDec(String hint, IconData icon) => InputDecoration(
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
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

/// Estilo estándar para botones primarios
ButtonStyle primaryBtnStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    );

/// Campo de formulario estándar
Widget modalField(
  String label,
  TextEditingController ctrl,
  IconData icon,
  String? Function(String?) validator, {
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) =>
    TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: inputDec(label, icon),
      validator: validator,
    );

/// Spinner de carga para botones
Widget btnSpinner() => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );

/// Muestra un snackbar de éxito o error
void showSnack(BuildContext context, String msg, {bool success = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
    ),
  );
}