import 'package:flutter/material.dart';

import '../design_system/tokens.dart';

/// Shared loading composition for session startup and the first ledger load.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/playstore.png',
              width: 160,
              height: 160,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: PiggyColors.accent,
                semanticsLabel: 'Loading',
              ),
            ),
          ],
        ),
      );
}
