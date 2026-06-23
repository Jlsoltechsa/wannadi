import 'package:flutter/material.dart';

import 'colors.dart';
import 'theme_tokens.dart';

/// Skeleton con efecto shimmer reutilizable.
class Shimmer extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius radius;

  const Shimmer({
    super.key,
    this.height = 14,
    this.width,
    this.radius = const BorderRadius.all(Radius.circular(6)),
  });

  factory Shimmer.line({double width = 120, double height = 12}) =>
      Shimmer(height: height, width: width);

  factory Shimmer.box({double width = 64, double height = 64, double r = 12}) =>
      Shimmer(
        height: height,
        width: width,
        radius: BorderRadius.all(Radius.circular(r)),
      );

  factory Shimmer.circle({double size = 36}) => Shimmer(
        height: size,
        width: size,
        radius: BorderRadius.all(Radius.circular(size)),
      );

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.brightness == Brightness.dark
        ? const Color(0xFF1F2A48)
        : WannadiColors.surfaceMuted;
    final hi = cs.brightness == Brightness.dark
        ? const Color(0xFF2D3756)
        : const Color(0xFFEEF2F8);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            gradient: LinearGradient(
              begin: const Alignment(-1.0, 0),
              end: const Alignment(1.0, 0),
              colors: [base, hi, base],
              stops: [
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Filas tipo card-skeleton para listas en carga.
class ShimmerCardList extends StatelessWidget {
  final int items;
  final double itemHeight;
  const ShimmerCardList({super.key, this.items = 5, this.itemHeight = 70});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items, (i) {
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.summaCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.summaBorder),
            ),
            child: Row(
              children: [
                Shimmer.circle(size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.line(width: 140, height: 12),
                      const SizedBox(height: 8),
                      Shimmer.line(width: 220, height: 10),
                    ],
                  ),
                ),
                Shimmer.box(width: 50, height: 24, r: 8),
              ],
            ),
          ),
        );
      }),
    );
  }
}
