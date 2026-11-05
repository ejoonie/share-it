import 'package:flutter/material.dart';

import '../tokens.dart';

class PiggyAddButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const PiggyAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add transaction',
  });

  @override
  Widget build(BuildContext context) => IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: PiggyColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PiggyColors.line,
          disabledForegroundColor: PiggyColors.secondary,
          minimumSize: const Size(PiggySize.tapTarget, PiggySize.tapTarget),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
      );
}

class PiggyFloatingAddButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final Object? heroTag;

  const PiggyFloatingAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add transaction',
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        heroTag: heroTag,
        tooltip: tooltip,
        elevation: 3,
        highlightElevation: 1,
        onPressed: onPressed,
        child: const Icon(Icons.add_rounded, size: 27),
      );
}
