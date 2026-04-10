import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema claro de la aplicación basado en la paleta de diseño.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // ── Esquema de colores ──
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.lightPrimarySoft,
    onPrimaryContainer: AppColors.lightPrimary,
    secondary: AppColors.lightAccentPurple,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.lightAccentPurpleSoft,
    onSecondaryContainer: AppColors.lightAccentPurple,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightSurfaceSecondary,
    error: AppColors.lightError,
    onError: Colors.white,
    errorContainer: AppColors.lightErrorSoft,
    onErrorContainer: AppColors.lightError,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightBorder,
  ),

  // ── Scaffold ──
  scaffoldBackgroundColor: AppColors.lightBackground,

  // ── AppBar ──
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    foregroundColor: AppColors.lightTextPrimary,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
  ),

  // ── Cards ──
  cardTheme: CardThemeData(
    color: AppColors.lightSurface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.lightBorder, width: 1),
    ),
  ),

  // ── Elevated Button ──
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),

  // ── Outlined Button ──
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      side: const BorderSide(color: AppColors.lightPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),

  // ── Text Button ──
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.lightLink,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),

  // ── Input / TextField ──
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightInputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.lightInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.lightInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: AppColors.lightInputBorderFocus, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.lightError),
    ),
    labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
    hintStyle: const TextStyle(color: AppColors.lightTextDisabled),
  ),

  // ── Floating Action Button ──
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: Colors.white,
    elevation: 2,
  ),

  // ── Bottom Navigation Bar ──
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.lightPrimary,
    unselectedItemColor: AppColors.lightIconPlaceholder,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),

  // ── Navigation Bar (M3) ──
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    indicatorColor: AppColors.lightPrimarySoft,
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: AppColors.lightPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }
      return const TextStyle(
        color: AppColors.lightIconPlaceholder,
        fontSize: 12,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.lightPrimary, size: 24);
      }
      return const IconThemeData(
          color: AppColors.lightIconPlaceholder, size: 24);
    }),
  ),

  // ── Chip ──
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurfaceSecondary,
    labelStyle: const TextStyle(color: AppColors.lightTextPrimary),
    side: const BorderSide(color: AppColors.lightBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),

  // ── Divider ──
  dividerTheme: const DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 1,
  ),

  // ── Texto ──
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: AppColors.lightTextSecondary,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: AppColors.lightTextDisabled,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: AppColors.lightTextSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: AppColors.lightTextDisabled,
      fontSize: 11,
    ),
  ),
);
