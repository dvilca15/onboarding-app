import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color del sistema de diseño.
/// Estilo: SaaS sobrio (grises neutros + acento teal).
class AppColors {
  AppColors._();

  // Superficies
  static const Color bg          = Color(0xFFF7F7F5); // fondo de la app
  static const Color surface     = Color(0xFFFFFFFF); // tarjetas, paneles
  static const Color surfaceAlt  = Color(0xFFFAFAF9); // filas alternas, inputs
  static const Color border      = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFFD6D3D1);

  // Texto
  static const Color text        = Color(0xFF1C1917); // títulos
  static const Color textBody    = Color(0xFF44403C); // cuerpo
  static const Color textMuted   = Color(0xFF78716C); // secundario
  static const Color textSubtle  = Color(0xFFA8A29E); // placeholders, hints

  // Marca (verde azulado / teal)
  static const Color primary     = Color(0xFF0D9488);
  static const Color primaryHover = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primarySoft = Color(0xFFF0FDFA);
  static const Color primaryBorder = Color(0xFF99F6E4);

  // Estados
  static const Color success     = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF15803D);
  static const Color successSoft = Color(0xFFF0FDF4);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color danger      = Color(0xFFDC2626);
  static const Color dangerSoft  = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFCA5A5);
  static const Color info        = Color(0xFF0EA5E9);
  static const Color infoSoft    = Color(0xFFF0F9FF);

  // Sidebar
  static const Color sidebarBg   = Color(0xFFFFFFFF);
  static const Color sidebarActive = Color(0xFFF0FDFA);
}

/// Espaciado y radios consistentes.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}

/// Sombra sutil para tarjetas (en vez de sombras fuertes).
const List<BoxShadow> kShadowSm = [
  BoxShadow(color: Color(0x0F1C1917), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0A1C1917), blurRadius: 3, offset: Offset(0, 1)),
];
const List<BoxShadow> kShadowMd = [
  BoxShadow(color: Color(0x141C1917), blurRadius: 16, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x081C1917), blurRadius: 6, offset: Offset(0, 2)),
];

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkRipple.splashFactory,
    );

    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textBody,
      displayColor: AppColors.text,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    );

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 1, space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.text,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textMuted,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSubtle),
        labelStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textMuted),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _filled),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textBody,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle:
            GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      ),
    );
  }

  static final ButtonStyle _filled = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md)),
    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
  );
}
