import 'package:flutter/material.dart';

import '../design_system/tokens.dart';

/// Startup logo matches the native launch screen; in-page loads omit it.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.showLogo = true});

  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    const spinner = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: PiggyColors.accent,
        semanticsLabel: 'Loading',
      ),
    );
    if (!showLogo) return const Center(child: spinner);

    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              'assets/playstore.png',
              width: 160,
              height: 160,
              excludeFromSemantics: true,
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, 116),
              child: spinner,
            ),
          ),
        ],
      ),
    );
  }
}
