import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema oscuro de la aplicación basado en la paleta de diseño.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // ── Esquema de colores ──
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.darkPrimaryHover,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.darkAccentPurple,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.darkAccentPurpleSoft,
    onSecondaryContainer: AppColors.darkTextPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceElevated,
    error: AppColors.darkError,
    onError: Colors.white,
    errorContainer: AppColors.darkErrorSoft,
    onErrorContainer: AppColors.darkError,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorder,
  ),

  // ── Scaffold ──
  scaffoldBackgroundColor: AppColors.darkBackground,

  // ── AppBar ──
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
  ),

  // ── Cards ──
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.darkBorder, width: 1),
    ),
  ),

  // ── Elevated Button ──
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
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
      foregroundColor: AppColors.darkPrimary,
      side: const BorderSide(color: AppColors.darkPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),

  // ── Text Button ──
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.darkFocusRing,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),

  // ── Input / TextField ──
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurfaceElevated,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.darkFocusRing, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.darkError),
    ),
    labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
    hintStyle: const TextStyle(color: AppColors.darkTextDisabled),
  ),

  // ── Floating Action Button ──
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  // ── Bottom Navigation Bar ──
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.darkPrimary,
    unselectedItemColor: AppColors.darkTextDisabled,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),

  // ── Navigation Bar (M3) ──
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    indicatorColor: AppColors.darkPrimary.withValues(alpha: 0.15),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: AppColors.darkPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }
      return const TextStyle(
        color: AppColors.darkTextDisabled,
        fontSize: 12,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.darkPrimary, size: 24);
      }
      return const IconThemeData(color: AppColors.darkTextDisabled, size: 24);
    }),
  ),

  // ── Chip ──
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkSurfaceElevated,
    labelStyle: const TextStyle(color: AppColors.darkTextPrimary),
    side: const BorderSide(color: AppColors.darkBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),

  // ── Divider ──
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
  ),

  // ── Texto ──
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: AppColors.darkTextSecondary,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: AppColors.darkTextDisabled,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: AppColors.darkTextSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: AppColors.darkTextDisabled,
      fontSize: 11,
    ),
  ),
);
