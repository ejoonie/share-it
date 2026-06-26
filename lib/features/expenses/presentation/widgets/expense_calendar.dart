import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';

class ExpenseCalendar extends ConsumerWidget {
  final ExpenseState state;

  const ExpenseCalendar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TableCalendar<Object>(
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      focusedDay: state.focusedMonth,
      selectedDayPredicate: (day) =>
          isSameDay(day, DateTime.utc(state.year, state.month, state.day)),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerVisible: false,
      daysOfWeekHeight: 38,
      rowHeight: 62,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2328),
        ),
        weekendStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4FA26A),
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        cellMargin: const EdgeInsets.all(3),
      ),
      // calendar day selected
      onDaySelected: (selectedUtc, focusedUtc) {
        ref.read(expenseNotifierProvider.notifier).selectDate(
              selectedUtc.year,
              selectedUtc.month,
              selectedUtc.day,
            );
      },
      onPageChanged: (focusedDay) {
        ref
            .read(expenseNotifierProvider.notifier)
            .changeMonth(DateTime.utc(focusedDay.year, focusedDay.month));
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, utc, focusedDay) {
          // print('defaultBuilder: ${utc.toIso8601String()}, timezone: ${utc.timeZoneName}');
          return _CalendarCell(
            day: utc,
            summary: state.monthlySummary[
                DateTime(utc.year, utc.month, utc.day)],
            isSelected: false,
            isToday: false,
          );
        },
        selectedBuilder: (context, utc, focusedDay) {
          // print('selectedBuilder: ${day.toIso8601String()}, timezone: ${day.timeZoneName}');
          return _CalendarCell(
            day: utc,
            summary: state.monthlySummary[
                DateTime(utc.year, utc.month, utc.day)],
            isSelected: true,
            isToday: false,
          );
        },
        todayBuilder: (context, utc, focusedDay) {
          // print('todayBuilder: ${utc.toIso8601String()}, timezone: ${utc.timeZoneName}');
          return _CalendarCell(
            day: utc,
            summary: state.monthlySummary[
                DateTime(utc.year, utc.month, utc.day)],
            isSelected:
                isSameDay(utc, DateTime.utc(state.year, state.month, state.day)),
            isToday: true,
          );
        },
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime day;
  final Map<String, int>? summary;
  final bool isSelected;
  final bool isToday;

  const _CalendarCell({
    required this.day,
    required this.summary,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final income = summary?['income'] ?? 0;
    final expense = summary?['expense'] ?? 0;
    final primary = Theme.of(context).colorScheme.primary;

    Color bgColor = Colors.transparent;
    Color textColor =
        day.weekday == DateTime.sunday || day.weekday == DateTime.saturday
            ? const Color(0xFF4FA26A)
            : const Color(0xFF1F2328);

    if (isSelected) {
      bgColor = primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = primary.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: isToday && !isSelected ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isToday && !isSelected ? BorderRadius.circular(14) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            ),
          ),
          if (income > 0)
            Text(
              _formatShort(income),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF43A047),
                height: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (expense > 0)
            Text(
              _formatShort(expense),
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? Colors.white70 : const Color(0xFFE53935),
                height: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String _formatShort(int cents) {
    final dollars = cents / 100.0;
    if (dollars >= 1000) {
      return '\$${(dollars / 1000).toStringAsFixed(1)}k';
    }
    return NumberFormat.simpleCurrency(decimalDigits: 0).format(dollars);
  }
}
