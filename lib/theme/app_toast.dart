import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';

enum ToastType { success, error, warning, info }

/// Avisos (toasts) compactos, al estilo de Linear, Vercel o Sonner:
/// una tarjeta pequeña con icono, centrada abajo, que se cierra sola.
///
/// Se dibuja sobre el Overlay raíz, así se ve por encima de los diálogos.
class AppToast {
  AppToast._();

  /// Se asigna al GoRouter (navigatorKey) para poder mostrar avisos incluso
  /// cuando el `context` ya no es válido (por ejemplo tras un `await`).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _actual;

  static void success(BuildContext c, String m) =>
      show(c, m, type: ToastType.success);
  static void error(BuildContext c, String m) =>
      show(c, m, type: ToastType.error);
  static void warning(BuildContext c, String m) =>
      show(c, m, type: ToastType.warning);
  static void info(BuildContext c, String m) =>
      show(c, m, type: ToastType.info);

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final overlay = navigatorKey.currentState?.overlay ??
        _overlayDe(context);
    if (overlay == null) return;

    _cerrarActual();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        message: message,
        type: type,
        duration: duration ??
            (type == ToastType.error
                ? const Duration(seconds: 6)
                : const Duration(seconds: 3, milliseconds: 500)),
        onFinished: () {
          if (_actual == entry) _actual = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _actual = entry;
    overlay.insert(entry);
  }

  /// Compatibilidad: convierte un `SnackBar` existente en un toast.
  /// El tipo se deduce del color de fondo (rojo = error, verde = éxito...).
  static void fromSnackBar(BuildContext context, SnackBar snack) {
    final content = snack.content;
    final texto = content is Text
        ? (content.data ?? content.textSpan?.toPlainText() ?? '')
        : '';
    if (texto.isEmpty) return;
    show(context, texto, type: _tipoDeColor(snack.backgroundColor));
  }

  static ToastType _tipoDeColor(Color? c) {
    if (c == null) return ToastType.info;
    final r = (c.r * 255).round(), g = (c.g * 255).round(), b = (c.b * 255).round();
    if (r > g + 40 && r > b + 40) {
      // rojo/naranja: distinguimos ámbar (aviso) de rojo (error)
      return g > 100 ? ToastType.warning : ToastType.error;
    }
    if (g > r + 20 && g >= b) return ToastType.success;
    return ToastType.info;
  }

  static OverlayState? _overlayDe(BuildContext context) {
    try {
      return Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return null;
    }
  }

  static void _cerrarActual() {
    final e = _actual;
    _actual = null;
    if (e != null && e.mounted) e.remove();
  }
}

class _ToastHost extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onFinished;

  const _ToastHost({
    required this.message,
    required this.type,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  Timer? _timer;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _timer = Timer(widget.duration, _cerrar);
  }

  Future<void> _cerrar() async {
    if (_cerrando) return;
    _cerrando = true;
    _timer?.cancel();
    if (mounted) await _ctrl.reverse();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  ({IconData icono, Color color, Color fondo}) get _estilo {
    switch (widget.type) {
      case ToastType.success:
        return (
          icono: Icons.check_rounded,
          color: AppColors.successDark,
          fondo: AppColors.successSoft
        );
      case ToastType.error:
        return (
          icono: Icons.error_outline_rounded,
          color: AppColors.danger,
          fondo: AppColors.dangerSoft
        );
      case ToastType.warning:
        return (
          icono: Icons.warning_amber_rounded,
          color: AppColors.warningDark,
          fondo: AppColors.warningSoft
        );
      case ToastType.info:
        return (
          icono: Icons.info_outline_rounded,
          color: AppColors.primaryHover,
          fondo: AppColors.primarySoft
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _estilo;
    final ancho = MediaQuery.of(context).size.width;
    final movil = ancho < 700;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // en móvil se deja espacio para la barra de navegación inferior
              padding: EdgeInsets.fromLTRB(16, 0, 16, movil ? 84 : 28),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: kShadowMd,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: e.fondo,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(e.icono, size: 17, color: e.color),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.message,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: _cerrar,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.close_rounded,
                                    size: 16, color: AppColors.textSubtle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
