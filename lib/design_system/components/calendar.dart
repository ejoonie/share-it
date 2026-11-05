import 'package:flutter/material.dart';

import '../tokens.dart';

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
