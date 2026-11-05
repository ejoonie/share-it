import 'package:flutter/material.dart';

import '../tokens.dart';

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
                  PiggySpace.md,
                  trailing == null ? PiggySpace.lg : PiggySpace.xs,
                  PiggySpace.md,
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
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: PiggyColors.line,
                  ),
                ),
            ],
          ),
        ),
      );
}
