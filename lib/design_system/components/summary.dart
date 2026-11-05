import 'package:flutter/material.dart';

import '../tokens.dart';
import 'surface.dart';

class PiggySummaryCard extends StatelessWidget {
  final String label;
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
            _AmountLabel(label: label, tone: tone, icon: icon),
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
          vertical: PiggySpace.md,
        ),
        child: Row(
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
                        style: PiggyType.summaryAmount
                            .copyWith(color: PiggyColors.ink, fontSize: 25),
                      ),
                      const SizedBox(width: PiggySpace.xs),
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
          _AmountLabel(label: label, tone: tone, icon: icon),
          const SizedBox(height: PiggySpace.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: PiggyType.summaryAmount
                  .copyWith(color: tone.foreground, fontSize: 17),
            ),
          ),
        ],
      );
}

class _AmountLabel extends StatelessWidget {
  final String label;
  final PiggyTone tone;
  final IconData icon;
  const _AmountLabel({
    required this.label,
    required this.tone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
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
      );
}
