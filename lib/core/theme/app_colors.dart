import 'package:flutter/material.dart';

/// Paleta de colores para la aplicación Registro de Entradas de Embarques.
/// Basada en el sistema de diseño con soporte para modo claro y oscuro.
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  //  MODO OSCURO
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Neutros (base UI) ──
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111B2E);
  static const darkSurfaceElevated = Color(0xFF16233B);
  static const darkBorder = Color(0xFF22314D);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFFB6C2D1);
  static const darkTextDisabled = Color(0xFF7C8AA5);

  // ── Marca / Acción (primarios) ──
  static const darkPrimary = Color(0xFF2563EB);
  static const darkPrimaryHover = Color(0xFF1D4ED8);
  static const darkFocusRing = Color(0xFF60A5FA);

  // ── Acentos útiles (chips, tags, highlights) ──
  static const darkAccentPurple = Color(0xFF7C3AED);
  static const darkAccentPurpleSoft = Color(0xFF1D1233);

  // ── Estados (operación + calidad) ──
  static const darkSuccess = Color(0xFF16A34A);
  static const darkSuccessSoft = Color(0xFF052E1A);
  static const darkWarning = Color(0xFFF59E0B);
  static const darkWarningSoft = Color(0xFF2A1D05);
  static const darkError = Color(0xFFDC2626);
  static const darkErrorSoft = Color(0xFF2B0A0A);
  static const darkInfo = Color(0xFF06B6D4);
  static const darkInfoSoft = Color(0xFF06252B);

  // ── Controles (inputs, estados UI comunes) ──
  static const darkInputBackground = Color(0xFFFFFFFF);
  static const darkInputBorder = Color(0xFFCBD5E1);
  static const darkInputBorderFocus = Color(0xFF60A5FA);
  static const darkDisabledSurface = Color(0xFFF1F5F9);
  static const darkDisabledBorder = Color(0xFFE2E8F0);

  // ═══════════════════════════════════════════════════════════════════════════
  //  MODO CLARO
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Neutros (base UI) ──
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextDisabled = Color(0xFF94A3B8);
  static const lightIconPlaceholder = Color(0xFF64748B);

  // ── Marca / Acción (primarios) ──
  static const lightPrimary = Color(0xFF2563EB);
  static const lightPrimaryHover = Color(0xFF1D4ED8);
  static const lightPrimarySoft = Color(0xFFDBEAFE);
  static const lightFocusRing = Color(0xFF60A5FA);
  static const lightLink = Color(0xFF1D4ED8);

  // ── Acentos útiles (chips, tags, highlights) ──
  static const lightAccentPurple = Color(0xFF7C3AED);
  static const lightAccentPurpleSoft = Color(0xFFEDE9FE);
  static const lightAccentHighlight = Color(0xFFEFF6FF);

  // ── Estados (operación + calidad) ──
  static const lightSuccess = Color(0xFF16A34A);
  static const lightSuccessSoft = Color(0xFFDCFCE7);
  static const lightWarning = Color(0xFFF59E0B);
  static const lightWarningSoft = Color(0xFFFEF3C7);
  static const lightError = Color(0xFFDC2626);
  static const lightErrorSoft = Color(0xFFFEE2E2);
  static const lightInfo = Color(0xFF06B6D4);
  static const lightInfoSoft = Color(0xFFCFFAFE);

  // ── Controles (inputs, estados UI comunes) ──
  static const lightInputBackground = Color(0xFFFFFFFF);
  static const lightInputBorder = Color(0xFFCBD5E1);
  static const lightInputBorderFocus = Color(0xFF60A5FA);
  static const lightDisabledSurface = Color(0xFFF1F5F9);
  static const lightDisabledBorder = Color(0xFFE2E8F0);
}
