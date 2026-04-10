import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/box_id_entry.dart';
import '../../shared/widgets/common_widgets.dart';
import 'scan_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanResultArguments? arguments;

  const ScanResultScreen({super.key, this.arguments});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Timer? _autoCloseTimer;

  ScanResultArguments get _args =>
      widget.arguments ??
      ScanResultArguments(
        boxId: 'EBR-000-TEST',
        status: MovementType.materialReturn,
        scannedAt: DateTime(2026, 2, 18, 14, 32),
        partNumber: 'EBR-000-TEST',
        quantity: 1,
        detail: 'Cant: 1 • Tipo: Exceso',
      );

  @override
  void initState() {
    super.initState();
    if (_args.autoClose) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoCloseTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) {
            return;
          }
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final args = _args;

    final status = args.status;
    final statusColor = status.color(context);
    final statusSoftColor = status.softColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Movimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!args.compactDetailView) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: statusSoftColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status.icon,
                        size: 48,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusTitle(status),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusMessage(status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Detalle del registro'),
                    const SizedBox(height: 14),
                    _DetailRow(
                      label: 'No. de parte',
                      value: args.partNumber ?? args.boxId,
                      icon: Icons.inventory_2_outlined,
                      isMono: true,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Cantidad',
                      value: args.quantity?.toString() ?? 'N/A',
                      icon: Icons.numbers_rounded,
                    ),
                    if (!args.compactDetailView && args.rawCode != null && args.rawCode!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'QR escaneado',
                        value: args.rawCode!,
                        icon: Icons.qr_code_rounded,
                        isMono: true,
                      ),
                    ],
                    if (!args.compactDetailView &&
                        args.detail != null &&
                        args.detail!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'Detalle',
                        value: args.detail!,
                        icon: Icons.info_outline_rounded,
                      ),
                    ],
                    if (!args.compactDetailView &&
                        args.notes != null &&
                        args.notes!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'Resultado',
                        value: args.notes!,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ],
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Fecha',
                      value: _formatDate(args.scannedAt),
                      icon: Icons.calendar_today_rounded,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Hora',
                      value: _formatTime(args.scannedAt),
                      icon: Icons.access_time_rounded,
                    ),
                    if (!args.compactDetailView) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextDisabled
                                : AppColors.lightTextDisabled,
                          ),
                          const SizedBox(width: 10),
                          Text('Movimiento', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          SizedBox(
                            width: 110,
                            child: StatusBadge(status: status),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(MovementType status) {
    switch (status) {
      case MovementType.entry:
        return 'El material fue agregado correctamente al inventario compartido.';
      case MovementType.exit:
        return 'El material fue descontado correctamente del inventario compartido.';
      case MovementType.materialReturn:
        return 'El retorno quedó registrado correctamente en inventario.';
      case MovementType.adjustment:
        return 'El ajuste quedó registrado correctamente.';
    }
  }

  String _getStatusTitle(MovementType status) {
    switch (status) {
      case MovementType.entry:
        return 'ENTRADA REGISTRADA';
      case MovementType.exit:
        return 'SALIDA REGISTRADA';
      case MovementType.materialReturn:
        return 'RETORNO REGISTRADO';
      case MovementType.adjustment:
        return 'AJUSTE REGISTRADO';
    }
  }
  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute hrs';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMono;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color:
              isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: isMono ? 'monospace' : null,
            ),
            textAlign: TextAlign.end,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
