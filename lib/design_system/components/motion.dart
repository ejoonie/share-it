import 'package:flutter/material.dart';

/// Hides floating chrome without changing the surrounding layout size.
class PiggySlideVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Offset hiddenOffset;

  const PiggySlideVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.hiddenOffset = const Offset(0, 1.1),
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : hiddenOffset,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: visible ? 1 : 0,
            child: child,
          ),
        ),
      );
}
