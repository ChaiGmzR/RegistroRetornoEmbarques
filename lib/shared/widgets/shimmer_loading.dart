import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shimmer loading effect para placeholders.
/// 
/// Muestra una animación suave mientras se carga el contenido,
/// dando feedback visual sin sensación de "app congelada".
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? AppColors.darkSurfaceElevated 
        : AppColors.lightSurfaceSecondary;
    final highlightColor = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder de tarjeta de estadísticas con shimmer.
class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerLoading(width: 36, height: 36, borderRadius: 8),
            SizedBox(height: 12),
            ShimmerLoading(width: 60, height: 24),
            SizedBox(height: 6),
            ShimmerLoading(width: 80, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Placeholder de tarjeta de escaneo con shimmer.
class ScanEntryCardShimmer extends StatelessWidget {
  const ScanEntryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const ShimmerLoading(width: 42, height: 42, borderRadius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLoading(width: 120, height: 16),
                  SizedBox(height: 6),
                  ShimmerLoading(width: 180, height: 12),
                  SizedBox(height: 4),
                  ShimmerLoading(width: 80, height: 12),
                ],
              ),
            ),
            const ShimmerLoading(width: 70, height: 24, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// Grid de estadísticas con shimmer.
class StatsGridShimmer extends StatelessWidget {
  const StatsGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: const [
        StatCardShimmer(),
        StatCardShimmer(),
        StatCardShimmer(),
        StatCardShimmer(),
      ],
    );
  }
}

/// Lista de escaneos con shimmer.
class ScanListShimmer extends StatelessWidget {
  final int itemCount;
  
  const ScanListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const ScanEntryCardShimmer(),
    );
  }
}
