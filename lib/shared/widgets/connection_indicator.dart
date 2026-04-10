import 'package:flutter/material.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

/// Indicador de calidad de conexión.
/// 
/// Muestra un badge discreto cuando la conexión es lenta o está offline.
/// No molesta al usuario cuando la conexión es buena.
class ConnectionIndicator extends StatefulWidget {
  final bool compact;
  
  const ConnectionIndicator({super.key, this.compact = true});

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  ConnectionQuality _quality = ConnectivityService.quality;

  @override
  void initState() {
    super.initState();
    ConnectivityService.onQualityChanged.listen((quality) {
      if (mounted) setState(() => _quality = quality);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Solo mostrar si hay problema
    if (!_quality.showIndicator) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = _quality == ConnectionQuality.offline
        ? (isDark ? AppColors.darkError : AppColors.lightError)
        : (isDark ? AppColors.darkWarning : AppColors.lightWarning);

    final bgColor = _quality == ConnectionQuality.offline
        ? (isDark ? AppColors.darkErrorSoft : AppColors.lightErrorSoft)
        : (isDark ? AppColors.darkWarningSoft : AppColors.lightWarningSoft);

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _quality == ConnectionQuality.offline
                  ? Icons.wifi_off_rounded
                  : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              _quality.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Versión expandida (banner)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          Icon(
            _quality == ConnectionQuality.offline
                ? Icons.wifi_off_rounded
                : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _quality == ConnectionQuality.offline
                  ? 'Sin conexión. Los datos se sincronizarán cuando vuelvas a conectarte.'
                  : 'Conexión lenta. Algunas operaciones pueden tardar más.',
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner de sincronización pendiente.
class PendingSyncBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onRetry;

  const PendingSyncBanner({
    super.key,
    required this.pendingCount,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkInfo : AppColors.lightInfo;
    final bgColor = isDark ? AppColors.darkInfoSoft : AppColors.lightInfoSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$pendingCount registro${pendingCount > 1 ? 's' : ''} pendiente${pendingCount > 1 ? 's' : ''} de sincronizar',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: Text('Reintentar', style: TextStyle(color: color)),
            ),
        ],
      ),
    );
  }
}
