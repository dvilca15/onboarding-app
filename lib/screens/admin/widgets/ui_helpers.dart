import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_dialog.dart';
import '../../../theme/app_toast.dart';

/// Decoración estándar para campos de formulario
InputDecoration inputDec(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textSubtle, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

/// Estilo estándar para botones primarios
ButtonStyle primaryBtnStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      minimumSize: const Size(0, 42),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      elevation: 0,
    );

/// Campo de formulario estándar: etiqueta arriba y campo limpio debajo.
Widget modalField(
  String label,
  TextEditingController ctrl,
  IconData icon,
  String? Function(String?) validator, {
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  String? hint,
  String? help,
}) =>
    FieldLabel(
      label: label,
      help: help,
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(hintText: hint),
      ),
    );

/// Spinner de carga para botones
Widget btnSpinner() => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );

/// Muestra un aviso (toast) de éxito o error
void showSnack(BuildContext context, String msg, {bool success = false}) {
  if (success) {
    AppToast.success(context, msg);
  } else {
    AppToast.error(context, msg);
  }
}
