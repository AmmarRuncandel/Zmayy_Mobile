import 'package:flutter/material.dart';

import 'zmayy_colors.dart';

/// Material 3 theme aligned with the web CSS variables in `app/globals.css`.
ThemeData buildZmayyDarkTheme() {
  const scheme = ColorScheme.dark(
    surface: ZmayyColors.surface,
    primary: ZmayyColors.gold,
    onPrimary: ZmayyColors.base,
    secondary: ZmayyColors.goldDim,
    onSecondary: ZmayyColors.base,
    error: ZmayyColors.danger,
    onError: Colors.white,
    onSurface: ZmayyColors.primaryText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ZmayyColors.base,
    canvasColor: ZmayyColors.base,
    dividerColor: ZmayyColors.border,
    dialogTheme: DialogThemeData(
      backgroundColor: ZmayyColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ZmayyColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: ZmayyColors.overlay,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ZmayyColors.surface,
      contentTextStyle: const TextStyle(color: ZmayyColors.primaryText),
      actionTextColor: ZmayyColors.gold,
      behavior: SnackBarBehavior.floating,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ZmayyColors.base,
      foregroundColor: ZmayyColors.primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0DFFFFFF), // matches `rgba(255,255,255,0.05)` usage
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ZmayyColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ZmayyColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ZmayyColors.gold, width: 1.2),
      ),
      hintStyle: const TextStyle(color: ZmayyColors.muted),
      labelStyle: const TextStyle(color: ZmayyColors.muted),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ZmayyColors.gold,
      selectionColor: Color(0x66FCD535),
      selectionHandleColor: ZmayyColors.gold,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ZmayyColors.gold;
        }
        return ZmayyColors.border;
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ZmayyColors.primaryText, fontSize: 16),
      bodyMedium: TextStyle(color: ZmayyColors.primaryText, fontSize: 14),
      bodySmall: TextStyle(color: ZmayyColors.muted, fontSize: 12),
      titleLarge: TextStyle(
        color: ZmayyColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: ZmayyColors.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(
        color: ZmayyColors.gold,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
