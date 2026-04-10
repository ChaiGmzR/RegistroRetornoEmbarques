import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/optimistic_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/shipping_qr_parser.dart';
import '../../models/box_id_entry.dart';
import '../../shared/widgets/common_widgets.dart';

class ScanResultArguments {
  final String boxId;
  final MovementType status;
  final DateTime scannedAt;
  final String? partNumber;
  final int? quantity;
  final String? rawCode;
  final String? detail;
  final String? notes;
  final bool autoClose;
  final bool compactDetailView;

  const ScanResultArguments({
    required this.boxId,
    required this.status,
    required this.scannedAt,
    this.partNumber,
    this.quantity,
    this.rawCode,
    this.detail,
    this.notes,
    this.autoClose = false,
    this.compactDetailView = false,
  });
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: _ReturnScanAppBar(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ReturnScanForm(),
        ),
      ),
    );
  }
}

class ReturnScanForm extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onRegistered;

  const ReturnScanForm({
    super.key,
    this.embedded = false,
    this.onRegistered,
  });

  @override
  State<ReturnScanForm> createState() => _ReturnScanFormState();
}

class _ReturnScanFormState extends State<ReturnScanForm> {
  static const List<String> _returnTypes = ['Exceso', 'OS&D'];
  final _manualController = TextEditingController();
  final _quantityController = TextEditingController();
  final _qrFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  bool _isProcessing = false;
  String _selectedReturnType = _returnTypes.first;
  Timer? _normalizeTimer;

  @override
  void dispose() {
    _normalizeTimer?.cancel();
    _manualController.dispose();
    _quantityController.dispose();
    _qrFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _submitScan(String boxId) {
    _processScan(boxId);
  }

  Future<void> _processScan(String rawScan) async {
    final parsedQr = ShippingQrParser.parse(rawScan);
    if (parsedQr == null) {
      _showInvalidQrMessage();
      return;
    }

    final quantityValue = int.tryParse(_quantityController.text.trim());
    if (quantityValue == null || quantityValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Captura una cantidad valida antes de registrar.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final partNumber = parsedQr.partNumber;
      final quantity = quantityValue;
      final rawCode = parsedQr.rawValue;
      final user = AuthService.currentUser;
      final operatorName = user?.fullName ?? user?.username ?? 'Usuario local';

      final result = await OptimisticUpdateService.registerReturnOptimistic(
        boxId: partNumber,
        scannedBy: operatorName,
        returnType: _selectedReturnType,
        partNumber: partNumber,
        quantity: quantity,
        rawCode: rawCode,
        notes:
            'Tipo: $_selectedReturnType | QR: $rawCode | Qty registrada: $quantity'
            '${parsedQr.quantity != null ? ' | Qty QR: ${parsedQr.quantity}' : ''}',
      );

      if (!mounted) {
        return;
      }

      setState(() => _isProcessing = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ?? 'No se pudo registrar el retorno.',
            ),
            backgroundColor: AppColors.darkError,
          ),
        );
        return;
      }

      widget.onRegistered?.call();
      _manualController.clear();
      _quantityController.clear();
      FocusScope.of(context).unfocus();
      await _showSuccessOverlay(
        queuedForSync: result.queuedForSync,
        returnType: _selectedReturnType,
      );
      if (!mounted) {
        return;
      }
      _qrFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar: $e'),
          backgroundColor: AppColors.darkError,
        ),
      );
    }
  }

  void _showInvalidQrMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'QR no reconocido. Usa un formato valido que incluya el numero de parte.',
        ),
        backgroundColor: AppColors.darkError,
      ),
    );
  }

  void _handleQrChanged(String value) {
    _normalizeTimer?.cancel();
    _normalizeTimer = Timer(const Duration(milliseconds: 180), () {
      final parsed = ShippingQrParser.parse(value);
      if (parsed == null) {
        return;
      }

      final normalizedPart = parsed.partNumber;
      if (_manualController.text != normalizedPart) {
        _manualController.value = TextEditingValue(
          text: normalizedPart,
          selection: TextSelection.collapsed(offset: normalizedPart.length),
        );
      }

      if (!_quantityFocusNode.hasFocus) {
        _quantityFocusNode.requestFocus();
      }
    });
  }

  Future<void> _showSuccessOverlay({
    required bool queuedForSync,
    required String returnType,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (navigator.mounted && navigator.canPop()) {
          navigator.pop();
        }
      }),
    );

    final statusColor = queuedForSync ? AppColors.darkInfo : AppColors.darkSuccess;
    final statusSoftColor =
        queuedForSync ? AppColors.darkInfoSoft : AppColors.darkSuccessSoft;
    final title = queuedForSync
        ? 'RETORNO GUARDADO'
        : 'RETORNO REGISTRADO';
    final subtitle =
        (queuedForSync
            ? 'El retorno quedó pendiente de sincronizar.'
            : 'El material de retorno tipo $returnType fue agregado correctamente al inventario compartido.');

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'registro_exitoso',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: statusSoftColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.32),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            queuedForSync
                                ? Icons.sync_rounded
                                : MovementType.materialReturn.icon,
                            size: 48,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: statusColor.withValues(alpha: 0.88),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final isReverse = animation.status == AnimationStatus.reverse;
            final progress = isReverse ? 1 - animation.value : animation.value;
            final fade = isReverse
                ? 1 - Curves.easeInQuad.transform(progress)
                : Curves.easeOutCubic.transform(progress);
            final scale = isReverse
                ? 1.0 +
                    (0.08 * Curves.easeOut.transform(progress)) -
                    (0.22 * Curves.easeInBack.transform(progress))
                : 0.96 + (0.04 * Curves.easeOutBack.transform(progress));

            return FadeTransition(
              opacity: AlwaysStoppedAnimation(fade.clamp(0.0, 1.0)),
              child: Transform.scale(
                scale: scale.clamp(0.78, 1.04),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (isReverse)
                      _BurstBubbles(
                        progress: progress,
                        color: statusColor,
                      ),
                    child ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) ...[
          Icon(
            MovementType.materialReturn.icon,
            size: 56,
            color: MovementType.materialReturn.color(context).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 20),
          Text(
            'Registrar retorno',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea el QR del material de retorno para agregarlo al inventario.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        AppTextField(
          label: 'QR',
          hint: 'ingrese QR de etiqueta',
          prefixIcon: Icons.inventory_2_outlined,
          controller: _manualController,
          focusNode: _qrFocusNode,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onChanged: _handleQrChanged,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Cantidad',
          hint: 'Ej: 20',
          prefixIcon: Icons.numbers_rounded,
          controller: _quantityController,
          focusNode: _quantityFocusNode,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedReturnType,
          items: _returnTypes
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedReturnType = value);
          },
          decoration: const InputDecoration(
            labelText: 'Tipo de retorno',
            prefixIcon: Icon(Icons.category_outlined),
          ),
        ),
        const SizedBox(height: 16),
        AppPrimaryButton(
          label: 'Registrar retorno',
          icon: MovementType.materialReturn.icon,
          onPressed: () {
            if (_manualController.text.isNotEmpty) {
              _submitScan(_manualController.text);
            }
          },
        ),
        if (_isProcessing) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            backgroundColor: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'Registrando retorno...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkInfo : AppColors.lightInfo,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.embedded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: content,
      ),
    );
  }
}

class _BurstBubbles extends StatelessWidget {
  final double progress;
  final Color color;

  const _BurstBubbles({
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final burstProgress = Curves.easeOutExpo.transform(progress.clamp(0.0, 1.0));
    final fade = 1 - Curves.easeIn.transform(progress.clamp(0.0, 1.0));
    const angles = <double>[
      -1.85,
      -1.2,
      -0.55,
      -0.12,
      0.42,
      0.95,
      1.52,
      2.18,
      2.78,
    ];

    return IgnorePointer(
      child: SizedBox(
        width: 340,
        height: 240,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < angles.length; i++)
              _BurstBubbleParticle(
                angle: angles[i],
                distance: 36 + (92 * burstProgress) + ((i % 3) * 8),
                size: (i % 2 == 0 ? 18.0 : 12.0) * (1 - (0.72 * progress)),
                opacity: fade * (i.isEven ? 0.28 : 0.18),
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class _BurstBubbleParticle extends StatelessWidget {
  final double angle;
  final double distance;
  final double size;
  final double opacity;
  final Color color;

  const _BurstBubbleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.opacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dx = math.cos(angle) * distance;
    final dy = math.sin(angle) * distance;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: size.clamp(2.0, 18.0),
        height: size.clamp(2.0, 18.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          border: Border.all(
            color: color.withValues(
              alpha: (opacity * 1.35).clamp(0.0, 1.0),
            ),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ReturnScanAppBar extends StatelessWidget {
  const _ReturnScanAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Registrar Retorno'),
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }
}
