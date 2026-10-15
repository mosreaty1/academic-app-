import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0E7C66);
  static const primaryDark = Color(0xFF07503F);
  static const mint = Color(0xFFE2F3EC);
  static const leaf = Color(0xFF53B87F);
  static const amber = Color(0xFFF4A340);
  static const coral = Color(0xFFE96A5B);
  static const sky = Color(0xFF3B8EDB);
  static const violet = Color(0xFF7C5CC4);
  static const rose = Color(0xFFD65C8F);
  static const ink = Color(0xFF14231E);
  static const muted = Color(0xFF6A7A73);
  static const cream = Color(0xFFF4F7F2);
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;
  Color get muted => isDark ? const Color(0xFF9DB0A8) : AppColors.muted;
  Color get card => cs.surface;
  Color get line => isDark ? const Color(0xFF263530) : const Color(0xFFE5ECE7);
  Color get ink => cs.onSurface;
  Color get brand => isDark ? AppColors.leaf : AppColors.primary;
  Color get brandSoft =>
      isDark ? const Color(0xFF1D3A30) : AppColors.mint;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: b,
    ).copyWith(
      primary: dark ? AppColors.leaf : AppColors.primary,
      onPrimary: dark ? const Color(0xFF06241B) : Colors.white,
      surface: dark ? const Color(0xFF16211D) : Colors.white,
      onSurface: dark ? const Color(0xFFE6EFEA) : AppColors.ink,
      error: AppColors.coral,
    );
    final base = ThemeData(brightness: b, useMaterial3: true);
    final text = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
          color: dark ? const Color(0xFF2A3A34) : const Color(0xFFDCE5DF)),
    );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: dark ? const Color(0xFF0E1512) : AppColors.cream,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1B2823) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor:
            dark ? const Color(0xFF244438) : AppColors.mint,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelSmall!
            .copyWith(
                fontWeight: s.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
          color: dark ? const Color(0xFF263530) : const Color(0xFFE5ECE7),
          space: 1),
    );
  }
}
