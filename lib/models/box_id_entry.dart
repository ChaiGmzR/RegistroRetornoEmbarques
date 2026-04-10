import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Modelo para representar estados de calidad de un Box ID.
enum MovementType {
  entry,
  exit,
  materialReturn,
  adjustment,
}

extension MovementTypeExtension on MovementType {
  String get label {
    switch (this) {
      case MovementType.entry:
        return 'Entrada';
      case MovementType.exit:
        return 'Salida';
      case MovementType.materialReturn:
        return 'Retorno';
      case MovementType.adjustment:
        return 'Ajuste';
    }
  }

  IconData get icon {
    switch (this) {
      case MovementType.entry:
        return Icons.login_rounded;
      case MovementType.exit:
        return Icons.logout_rounded;
      case MovementType.materialReturn:
        return Icons.assignment_return_rounded;
      case MovementType.adjustment:
        return Icons.sync_alt_rounded;
    }
  }

  Color color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case MovementType.entry:
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case MovementType.exit:
        return isDark ? AppColors.darkInfo : AppColors.lightInfo;
      case MovementType.materialReturn:
        return isDark ? AppColors.darkError : AppColors.lightError;
      case MovementType.adjustment:
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
    }
  }

  Color softColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case MovementType.entry:
        return isDark ? AppColors.darkSuccessSoft : AppColors.lightSuccessSoft;
      case MovementType.exit:
        return isDark ? AppColors.darkInfoSoft : AppColors.lightInfoSoft;
      case MovementType.materialReturn:
        return isDark ? AppColors.darkErrorSoft : AppColors.lightErrorSoft;
      case MovementType.adjustment:
        return isDark ? AppColors.darkWarningSoft : AppColors.lightWarningSoft;
    }
  }
}

/// Modelo de datos de un movimiento registrado desde la app móvil.
class BoxIdEntry {
  final String boxId;
  final MovementType status;
  final DateTime scannedAt;
  final String? partNumber;
  final int? quantity;
  final String? rawCode;
  final String? productName;
  final String? lotNumber;
  final String? detail;
  final String? folio;
  final String? location;
  final String? notes;

  const BoxIdEntry({
    required this.boxId,
    required this.status,
    required this.scannedAt,
    this.partNumber,
    this.quantity,
    this.rawCode,
    this.productName,
    this.lotNumber,
    this.detail,
    this.folio,
    this.location,
    this.notes,
  });
}
