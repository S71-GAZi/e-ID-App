import 'package:flutter/material.dart';

/// Brand colors. Default accent is a deep indigo; card themes (Phase 1
/// templates) layer accent choices on top of this base palette.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF3D5AFE); // indigo accent
  static const Color primaryDark = Color(0xFF1E2A78);
  static const Color surfaceTint = Color(0xFFF6F7FB);
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  /// Accent choices offered in the card editor.
  static const List<Color> cardAccents = <Color>[
    Color(0xFF3D5AFE), // indigo
    Color(0xFF00897B), // teal
    Color(0xFF6D4C41), // brown
    Color(0xFF8E24AA), // purple
    Color(0xFFE53935), // red
    Color(0xFF43A047), // green
    Color(0xFFFB8C00), // orange
    Color(0xFF455A64), // blue-grey
  ];
}

/// Central theme factory — light and dark, Material 3, card-like surfaces
/// with rounded corners and subtle elevation.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.surfaceTint
          : null,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52), // large tap targets (a11y)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12, // >=48dp effective touch height
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
