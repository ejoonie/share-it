import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// A flat surface. Interactive content owns its own InkWell and semantics.
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

class PiggySummaryCard extends StatelessWidget {
  final String label;

  /// Already formatted by the feature, including its currency.
  final String amount;
  final PiggyTone tone;
  final IconData icon;
  const PiggySummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.tone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: tone.background,
        radius: PiggyRadius.summary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: tone.foreground),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PiggyType.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PiggySpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: PiggyType.summaryAmount.copyWith(color: tone.foreground),
              ),
            ),
          ],
        ),
      );
}

/// A selected day's identity and totals in one compact overview.
/// Values are already formatted by the feature, including their currency.
class PiggyDailySummaryCard extends StatelessWidget {
  final String eyebrow;
  final String date;
  final String metadata;
  final String income;
  final String expenses;

  const PiggyDailySummaryCard({
    super.key,
    required this.eyebrow,
    required this.date,
    required this.metadata,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: PiggyColors.card,
        radius: PiggyRadius.summary,
        padding: const EdgeInsets.symmetric(
          horizontal: PiggySpace.lg,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PiggyType.metadata.copyWith(
                      color: PiggyColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        date,
                        style: PiggyType.summaryAmount.copyWith(
                          color: PiggyColors.ink,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            metadata.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PiggyType.metadata,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: PiggySpace.md),
            const SizedBox(
              height: 42,
              child: VerticalDivider(width: 1, color: PiggyColors.line),
            ),
            const SizedBox(width: PiggySpace.md),
            Expanded(
              child: _DailyAmount(
                label: 'Income',
                amount: income,
                tone: PiggyTone.income,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: PiggySpace.sm),
            Expanded(
              child: _DailyAmount(
                label: 'Expenses',
                amount: expenses,
                tone: PiggyTone.expense,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
      );
}

class _DailyAmount extends StatelessWidget {
  final String label;
  final String amount;
  final PiggyTone tone;
  final IconData icon;

  const _DailyAmount({
    required this.label,
    required this.amount,
    required this.tone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: tone.foreground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PiggyType.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: PiggySpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: PiggyType.summaryAmount.copyWith(
                color: tone.foreground,
                fontSize: 17,
              ),
            ),
          ),
        ],
      );
}

class PiggyCategoryIcon extends StatelessWidget {
  final IconData icon;
  final PiggyTone tone;
  const PiggyCategoryIcon({
    super.key,
    required this.icon,
    this.tone = PiggyTone.brand,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: PiggySize.categoryTile,
          height: PiggySize.categoryTile,
          decoration: BoxDecoration(
            color: tone.background,
            borderRadius: BorderRadius.circular(PiggyRadius.small),
          ),
          child:
              Icon(icon, color: tone.foreground, size: PiggySize.categoryIcon),
        ),
      );
}

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

/// Visual marker only. The calendar owns the full-cell hit target and label.
/// Keep daily totals OUTSIDE this marker so selection never obscures amounts.
class PiggyDayMarker extends StatelessWidget {
  final int day;
  final bool selected;
  final bool today;
  final bool outside;
  final Key? containerKey;
  const PiggyDayMarker({
    super.key,
    required this.day,
    this.selected = false,
    this.today = false,
    this.outside = false,
    this.containerKey,
  });

  @override
  Widget build(BuildContext context) => Container(
        key: containerKey,
        width: PiggySize.dayMarker,
        height: PiggySize.dayMarker,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? PiggyColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: today && !selected
              ? Border.all(color: PiggyColors.expense, width: 1.4)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$day',
            style: PiggyType.calendarDay.copyWith(
              fontWeight: selected || today ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Colors.white
                  : outside
                      ? PiggyColors.muted
                      : PiggyColors.ink,
            ),
          ),
        ),
      );
}

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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: PiggyColors.surface,
          border: Border(top: BorderSide(color: PiggyColors.line)),
        ),
        child: NavigationBarTheme(
          data: PiggyTheme.navigation,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: destinations,
          ),
        ),
      );
}

/// Presentation only; features retain formatting, persistence and menus.
class PiggyTransactionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final PiggyTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool first;
  final bool last;
  const PiggyTransactionRow({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.tone,
    this.subtitle = '',
    this.onTap,
    this.trailing,
    this.first = true,
    this.last = true,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: PiggyColors.card,
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(PiggyRadius.card) : Radius.zero,
          bottom: last ? const Radius.circular(PiggyRadius.card) : Radius.zero,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  PiggySpace.lg,
                  trailing == null ? PiggySpace.lg : PiggySpace.xs,
                  PiggySpace.lg,
                ),
                child: Row(
                  children: [
                    PiggyCategoryIcon(icon: icon, tone: tone),
                    const SizedBox(width: PiggySpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PiggyType.itemTitle,
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PiggyType.metadata,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: PiggySpace.sm),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                      ),
                      child: Text(
                        amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            PiggyType.amount.copyWith(color: tone.foreground),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              if (!last)
                const Padding(
                  padding: EdgeInsets.only(left: 64, right: PiggySpace.lg),
                  child:
                      Divider(height: 1, thickness: 1, color: PiggyColors.line),
                ),
            ],
          ),
        ),
      );
}
