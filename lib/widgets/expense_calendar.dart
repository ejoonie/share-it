import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../theme/ledger_style.dart';
import '../design_system/design_system.dart';
import '../providers/expense_provider.dart';

class ExpenseCalendar extends ConsumerWidget {
  final ExpenseState state;

  const ExpenseCalendar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = DateTime(state.year, state.month, state.day);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;

    Widget cell(DateTime day, {bool outside = false}) => _CalendarCell(
          day: day,
          summary: outside
              ? null
              : state.monthlySummary[DateTime(day.year, day.month, day.day)],
          isSelected: isSameDay(day, selected),
          isToday: isSameDay(day, DateTime.now()),
          outside: outside,
        );

    return TableCalendar<Object>(
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      focusedDay: state.focusedMonth,
      selectedDayPredicate: (day) => isSameDay(day, selected),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      availableGestures: AvailableGestures.horizontalSwipe,
      headerVisible: false,
      rowHeight: PiggySize.calendarRow + (scale - 1).clamp(0, 2) * 30,
      daysOfWeekHeight: 30 + (scale - 1).clamp(0, 2) * 14,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 11, color: LedgerStyle.secondary),
        weekendStyle: TextStyle(fontSize: 11, color: LedgerStyle.secondary),
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        cellMargin: EdgeInsets.zero,
      ),
      onDaySelected: (day, _) => ref
          .read(expenseNotifierProvider.notifier)
          .selectDate(day.year, day.month, day.day),
      onPageChanged: (day) {
        // Selecting an adjacent-month day also moves the calendar page.
        // Avoid issuing a second request when selectDate already moved it.
        final current = ref.read(expenseNotifierProvider).focusedMonth;
        if (current.year != day.year || current.month != day.month) {
          ref.read(expenseNotifierProvider.notifier).changeMonth(day);
        }
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (_, day, __) => cell(day),
        selectedBuilder: (_, day, __) => cell(day),
        todayBuilder: (_, day, __) => cell(day),
        outsideBuilder: (_, day, __) => cell(day, outside: true),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime day;
  final Map<String, int>? summary;
  final bool isSelected;
  final bool isToday;
  final bool outside;

  const _CalendarCell({
    required this.day,
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.outside,
  });

  @override
  Widget build(BuildContext context) {
    final income = summary?['income'] ?? 0;
    final expense = summary?['expense'] ?? 0;
    return Semantics(
      label: '${DateFormat.yMMMMd().format(day)}${isToday ? ', Today' : ''}'
          '${income > 0 ? ', income ${_money(income)}' : ''}'
          '${expense > 0 ? ', expense ${_money(expense)}' : ''}',
      selected: isSelected,
      excludeSemantics: true,
      child: Column(
        children: [
          PiggyDayMarker(
            containerKey: ValueKey(
              'calendar-day-${DateFormat('yyyy-MM-dd').format(day)}',
            ),
            day: day.day,
            selected: isSelected,
            today: isToday,
            outside: outside,
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 12,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (income > 0) _amount(income, LedgerStyle.income),
                  if (income > 0 && expense > 0) const SizedBox(width: 3),
                  if (expense > 0) _amount(expense, LedgerStyle.expense),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amount(int cents, Color color) => Text(
        _short(cents),
        maxLines: 1,
        style: PiggyType.calendarAmount.copyWith(color: color),
      );

  String _money(int cents) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(cents / 100);

  String _short(int cents) {
    final value = cents / 100;
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
  }
}
