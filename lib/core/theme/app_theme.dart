import 'package:flutter/material.dart';

abstract final class NoriaColors {
  static const ink = Color(0xFF0B0B0B);
  static const paper = Color(0xFFF2F1EC);
  static const signal = Color(0xFFC6F432);
  static const warn = Color(0xFFFFB020);
  static const danger = Color(0xFFFF4D3D);
}

abstract final class NoriaTheme {
  static const mono = 'monospace';
  static const borderWidth = 1.5;

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? NoriaColors.ink : NoriaColors.paper;
    final fg = isDark ? NoriaColors.paper : NoriaColors.ink;
    final muted = fg.withValues(alpha: 0.55);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: fg,
      onPrimary: bg,
      secondary: NoriaColors.signal,
      onSecondary: NoriaColors.ink,
      error: NoriaColors.danger,
      onError: NoriaColors.ink,
      surface: bg,
      onSurface: fg,
      onSurfaceVariant: muted,
      outline: fg,
      outlineVariant: fg.withValues(alpha: 0.18),
    );

    const square = BorderRadius.zero;
    final hardBorder = BorderSide(color: fg, width: borderWidth);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: hardBorder),
      ),
      dividerTheme: DividerThemeData(color: fg, thickness: borderWidth, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: square, borderSide: hardBorder),
        enabledBorder: OutlineInputBorder(borderRadius: square, borderSide: hardBorder),
        focusedBorder: OutlineInputBorder(
          borderRadius: square,
          borderSide: BorderSide(color: fg, width: borderWidth * 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: fg,
          foregroundColor: bg,
          shape: const RoundedRectangleBorder(borderRadius: square),
          textStyle: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: hardBorder,
          shape: const RoundedRectangleBorder(borderRadius: square),
          textStyle: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        shape: Border(top: hardBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: square, side: hardBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: fg,
        contentTextStyle: TextStyle(color: bg, fontFamily: mono),
        shape: const RoundedRectangleBorder(borderRadius: square),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: fg,
        linearTrackColor: fg.withValues(alpha: 0.12),
      ),
    );
  }
}
