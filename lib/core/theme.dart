import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class AppColors {
  // Brand: deep green with a warm gold accent. Hues below are semantic or
  // used sparingly (they are blended toward the brand in IconBadge).
  static const primary = Color(0xFF0B6B58);
  static const primaryDark = Color(0xFF053F34);
  static const mint = Color(0xFFE7F2EE);
  static const leaf = Color(0xFF2F9E6E); // success
  static const amber = Color(0xFFD99A2B); // warning / premium
  static const coral = Color(0xFFD4524A); // danger
  static const sky = Color(0xFF3A78C9); // info
  static const violet = Color(0xFF5D5FC7);
  static const rose = Color(0xFFC2507F);
  static const gold = Color(0xFFC9962B);
  static const ink = Color(0xFF11201C);
  static const muted = Color(0xFF66766F);
  static const cream = Color(0xFFF4F6F5);
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;
  Color get muted => isDark ? const Color(0xFF9DB0A8) : AppColors.muted;
  Color get card => cs.surface;
  Color get line => isDark ? const Color(0xFF24322D) : const Color(0xFFE6EAE8);
  Color get ink => cs.onSurface;
  Color get brand => isDark ? AppColors.leaf : AppColors.primary;
  Color get brandSoft =>
      isDark ? const Color(0xFF173129) : AppColors.mint;
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
      surface: dark ? const Color(0xFF121D19) : Colors.white,
      onSurface: dark ? const Color(0xFFE6EFEA) : AppColors.ink,
      error: AppColors.coral,
    );
    final base = ThemeData(brightness: b, useMaterial3: true);
    final text = base.textTheme
        .apply(
          fontFamily: 'Cairo',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
          titleSmall: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.35),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: const TextStyle(fontSize: 12.5, height: 1.45),
          labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
          color: dark ? const Color(0xFF2A3A34) : const Color(0xFFDCE5DF)),
    );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: dark ? const Color(0xFF0B1210) : AppColors.cream,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleSpacing: 20,
        titleTextStyle: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? const Color(0xFF1E3B32) : AppColors.mint,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : (dark ? const Color(0xFF8FA39B) : AppColors.muted))),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelSmall!
            .copyWith(
                fontSize: 11,
                fontWeight: s.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: s.contains(WidgetState.selected)
                    ? scheme.primary
                    : (dark ? const Color(0xFF8FA39B) : AppColors.muted))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
          color: dark ? const Color(0xFF24322D) : const Color(0xFFE6EAE8),
          space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 3,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: dark ? const Color(0xFF24322D) : const Color(0xFFE6EAE8),
      ),
    );
  }
}
