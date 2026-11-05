import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

class PiggyNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  const PiggyNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: PiggyColors.ink.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PiggyColors.surface.withValues(alpha: 0.72),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: NavigationBarTheme(
                  data: PiggyTheme.navigation,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onSelected,
                    destinations: destinations,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
