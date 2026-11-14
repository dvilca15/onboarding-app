import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Tarjeta estándar: fondo blanco, borde fino y sombra muy sutil.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: borderColor ?? AppColors.border),
          boxShadow: kShadowSm,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum BadgeTone { neutral, primary, success, warning, danger, info }

/// Insignia de estado (pill) con punto de color.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final bool dot;

  const StatusBadge(this.label,
      {super.key, this.tone = BadgeTone.neutral, this.dot = true});

  /// Atajo a partir de un estado de onboarding/tarea.
  factory StatusBadge.estado(String estado, {Key? key}) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADO':
        return StatusBadge('Completado', key: key, tone: BadgeTone.success);
      case 'EN_PROGRESO':
        return StatusBadge('En progreso', key: key, tone: BadgeTone.warning);
      case 'OMITIDO':
        return StatusBadge('Omitido', key: key, tone: BadgeTone.neutral);
      default:
        return StatusBadge('Pendiente', key: key, tone: BadgeTone.neutral);
    }
  }

  (Color bg, Color fg) get _colors {
    switch (tone) {
      case BadgeTone.primary:
        return (AppColors.primarySoft, AppColors.primaryHover);
      case BadgeTone.success:
        return (AppColors.successSoft, AppColors.successDark);
      case BadgeTone.warning:
        return (AppColors.warningSoft, AppColors.warningDark);
      case BadgeTone.danger:
        return (AppColors.dangerSoft, AppColors.danger);
      case BadgeTone.info:
        return (AppColors.infoSoft, const Color(0xFF0369A1));
      case BadgeTone.neutral:
        return (const Color(0xFFF5F5F4), AppColors.textBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

/// Avatar circular con la inicial; el color depende del texto (estable).
class InitialAvatar extends StatelessWidget {
  final String text;
  final double size;

  const InitialAvatar(this.text, {super.key, this.size = 36});

  static const _palette = [
    (Color(0xFFF0FDFA), Color(0xFF0F766E)),
    (Color(0xFFF0FDF4), Color(0xFF15803D)),
    (Color(0xFFFFFBEB), Color(0xFFB45309)),
    (Color(0xFFFDF2FA), Color(0xFFC11574)),
    (Color(0xFFF0F9FF), Color(0xFF0369A1)),
    (Color(0xFFF5F3FF), Color(0xFF6D28D9)),
  ];

  @override
  Widget build(BuildContext context) {
    final inicial = text.trim().isEmpty ? '?' : text.trim()[0].toUpperCase();
    final (bg, fg) = _palette[inicial.codeUnitAt(0) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(inicial,
          style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }
}

/// Barra de progreso fina y redondeada.
class AppProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const AppProgressBar(
      {super.key, required this.value, this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
      ),
    );
  }
}

/// Estado vacío con icono, título y texto de ayuda.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMuted, height: 1.5)),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ]),
      ),
    );
  }
}

/// Barra superior de página: blanca, con borde inferior y título en negrita.
class PageBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top, 16, 0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.text)),
              if (subtitle != null)
                Text(subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        ...actions,
      ]),
    );
  }
}

/// Centra el contenido con un ancho máximo (lectura cómoda en pantallas grandes).
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = 920});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Apariencia de cada tipo de tarea (icono, etiqueta y colores).
class TipoTareaInfo {
  final IconData icono;
  final String etiqueta;
  final Color fondo;
  final Color color;
  const TipoTareaInfo(this.icono, this.etiqueta, this.fondo, this.color);

  static TipoTareaInfo de(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'DOCUMENTO':
        return const TipoTareaInfo(Icons.description_outlined, 'Documento',
            AppColors.infoSoft, Color(0xFF0369A1));
      case 'VIDEO':
        return const TipoTareaInfo(Icons.play_circle_outline_rounded, 'Video',
            AppColors.warningSoft, AppColors.warningDark);
      case 'FORMULARIO':
        return const TipoTareaInfo(Icons.list_alt_rounded, 'Formulario',
            Color(0xFFF5F3FF), Color(0xFF6D28D9));
      default:
        return const TipoTareaInfo(Icons.check_circle_outline_rounded,
            'Confirmación', AppColors.successSoft, AppColors.successDark);
    }
  }
}

/// Etiqueta pequeña con el tipo de tarea.
class TipoTareaChip extends StatelessWidget {
  final String tipo;
  final bool conIcono;

  const TipoTareaChip(this.tipo, {super.key, this.conIcono = true});

  @override
  Widget build(BuildContext context) {
    final t = TipoTareaInfo.de(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (conIcono) ...[
          Icon(t.icono, size: 12, color: t.color),
          const SizedBox(width: 4),
        ],
        Text(t.etiqueta,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: t.color)),
      ]),
    );
  }
}
