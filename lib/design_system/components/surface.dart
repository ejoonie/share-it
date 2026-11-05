import 'package:flutter/material.dart';

import '../tokens.dart';

class PiggySurface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  const PiggySurface({
    super.key,
    required this.child,
    this.color = PiggyColors.surface,
    this.padding = const EdgeInsets.all(PiggySpace.lg),
    this.radius = PiggyRadius.card,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}
