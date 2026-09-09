import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildSafeRideTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F6BFF),
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: GoogleFonts.inter().fontFamily,
  );
  final expressiveTextTheme = GoogleFonts.interTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    visualDensity: VisualDensity.standard,
    textTheme: expressiveTextTheme.copyWith(
      displayLarge: expressiveTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.12),
      displayMedium: expressiveTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.16),
      displaySmall: expressiveTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.22),
      headlineLarge: expressiveTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25),
      headlineMedium: expressiveTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.29),
      headlineSmall: expressiveTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.33),
      titleLarge: expressiveTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.27),
      titleMedium: expressiveTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.5),
      titleSmall: expressiveTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43),
      bodyLarge: expressiveTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5),
      bodyMedium: expressiveTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43),
      bodySmall: expressiveTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33),
      labelLarge: expressiveTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43),
      labelMedium: expressiveTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.33),
      labelSmall: expressiveTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.45),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: expressiveTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    cardTheme: CardThemeData(
      elevation: 1,
      color: colorScheme.surfaceContainerHighest,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      labelTextStyle: WidgetStatePropertyAll(
        expressiveTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: expressiveTextTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
      thumbColor: colorScheme.primary,
      trackHeight: 6,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withOpacity(0.2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 24,
    ),
  );
}
