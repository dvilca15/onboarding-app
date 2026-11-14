import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Diálogo estándar de la app (patrón de Stripe, Linear y Notion):
/// cabecera con icono + título + subtítulo + cerrar, cuerpo con scroll y
/// pie con los botones alineados a la derecha.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool showClose;
  final VoidCallback? onClose;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBg,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.maxWidth = 480,
    this.showClose = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabecera ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg ?? AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          size: 20, color: iconColor ?? AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: AppColors.text)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(subtitle!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.textSubtle),
                    ),
                ],
              ),
            ),

            // ── Cuerpo ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                child: child,
              ),
            ),

            // ── Pie con botones ──
            if (actions.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Botones de pie ────────────────────────────────────────────

/// Botón secundario del pie (Cancelar, Cerrar...).
class DialogCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const DialogCancelButton({super.key, this.label = 'Cancelar', this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 40),
        ),
        child: Text(label),
      );
}

/// Botón principal del pie, con estado de carga y variante destructiva.
class DialogPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool destructive;
  final IconData? icon;

  const DialogPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.destructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: destructive ? AppColors.danger : AppColors.primary,
        disabledBackgroundColor:
            destructive ? AppColors.dangerBorder : AppColors.border,
        minimumSize: const Size(0, 40),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 6)],
              Text(label),
            ]),
    );
  }
}

// ── Elementos de formulario ───────────────────────────────────

/// Campo con la etiqueta encima (como Stripe o Linear) y ayuda opcional.
class FieldLabel extends StatelessWidget {
  final String label;
  final String? help;
  final Widget child;
  final bool required;

  const FieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.help,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody)),
            if (required)
              const TextSpan(
                  text: ' *',
                  style: TextStyle(fontSize: 13, color: AppColors.danger)),
          ])),
        ),
        child,
        if (help != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(help!,
                style: const TextStyle(
                    fontSize: 12, height: 1.4, color: AppColors.textSubtle)),
          ),
      ],
    );
  }
}

enum BannerTone { info, error, success, warning }

/// Aviso dentro de un diálogo (instrucción, error, éxito...).
class InlineBanner extends StatelessWidget {
  final String text;
  final BannerTone tone;
  final IconData? icon;

  const InlineBanner(this.text,
      {super.key, this.tone = BannerTone.info, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, ic) = switch (tone) {
      BannerTone.info => (
          AppColors.infoSoft,
          const Color(0xFF0369A1),
          const Color(0xFFBAE6FD),
          Icons.info_outline_rounded
        ),
      BannerTone.error => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.dangerBorder,
          Icons.error_outline_rounded
        ),
      BannerTone.success => (
          AppColors.successSoft,
          AppColors.successDark,
          const Color(0xFFBBF7D0),
          Icons.check_circle_outline_rounded
        ),
      BannerTone.warning => (
          AppColors.warningSoft,
          AppColors.warningDark,
          const Color(0xFFFDE68A),
          Icons.warning_amber_rounded
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon ?? ic, size: 16, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, height: 1.45, color: fg)),
        ),
      ]),
    );
  }
}

// ── Zona de subida de archivos ────────────────────────────────

/// Área para elegir un archivo: borde punteado, estados vacío, subiendo y listo.
class FileDropZone extends StatelessWidget {
  final VoidCallback? onTap;
  final bool uploading;
  final String? fileName;
  final String hint; // p. ej. "PDF, PNG o JPG"
  final String emptyLabel;

  const FileDropZone({
    super.key,
    required this.onTap,
    required this.hint,
    this.uploading = false,
    this.fileName,
    this.emptyLabel = 'Haz clic para seleccionar un archivo',
  });

  @override
  Widget build(BuildContext context) {
    final listo = fileName != null && !uploading;
    final color = listo ? AppColors.success : AppColors.borderStrong;

    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: color,
          radius: AppRadius.lg,
          fill: listo ? AppColors.successSoft : AppColors.surfaceAlt,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: listo ? AppColors.successSoft : AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                    color: listo
                        ? const Color(0xFFBBF7D0)
                        : AppColors.primaryBorder),
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Icon(
                      listo
                          ? Icons.check_rounded
                          : Icons.cloud_upload_outlined,
                      size: 22,
                      color: listo ? AppColors.successDark : AppColors.primary,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              uploading
                  ? 'Subiendo archivo…'
                  : listo
                      ? fileName!
                      : emptyLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: listo ? AppColors.successDark : AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              listo ? 'Archivo subido. Haz clic para reemplazarlo.' : hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final Color fill;

  _DashedBorderPainter(
      {required this.color, required this.radius, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill);

    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0, gap = 5.0;
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius;
}

// ── Confirmación ──────────────────────────────────────────────

/// Diálogo de confirmación (por defecto destructivo).
/// Devuelve `true` si el usuario confirma.
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String confirmar = 'Eliminar',
  String cancelar = 'Cancelar',
  bool destructivo = true,
  IconData? icono,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      maxWidth: 440,
      icon: icono ??
          (destructivo
              ? Icons.delete_outline_rounded
              : Icons.help_outline_rounded),
      iconColor: destructivo ? AppColors.danger : AppColors.primary,
      iconBg: destructivo ? AppColors.dangerSoft : AppColors.primarySoft,
      title: titulo,
      showClose: false,
      child: Text(mensaje,
          style: const TextStyle(
              fontSize: 14, height: 1.55, color: AppColors.textMuted)),
      actions: [
        DialogCancelButton(
            label: cancelar, onPressed: () => Navigator.pop(ctx, false)),
        DialogPrimaryButton(
            label: confirmar,
            destructive: destructivo,
            onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return r ?? false;
}

/// Reemplazo directo de [AlertDialog] con el aspecto de [AppDialog]:
/// misma interfaz (title, content, actions), pero con cabecera limpia,
/// ancho máximo y pie de botones con fondo propio.
class AppAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;

  // Se aceptan (y se ignoran) los parámetros visuales de AlertDialog
  // para poder sustituirlo sin tocar las llamadas existentes.
  const AppAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth = 520,
    ShapeBorder? shape,
    Color? backgroundColor,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? titlePadding,
    EdgeInsetsGeometry? actionsPadding,
    EdgeInsets? insetPadding,
    bool scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                child: DefaultTextStyle(
                  style: const TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppColors.text),
                  child: title!,
                ),
              ),
            if (content != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      24, title == null ? 22 : 4, 24, 22),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textMuted),
                    child: content!,
                  ),
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
