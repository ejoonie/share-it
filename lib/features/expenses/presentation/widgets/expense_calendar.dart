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
      selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerVisible: false,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: const TextStyle(fontSize: 12),
        weekendStyle: TextStyle(fontSize: 12, color: Colors.red.shade400),
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
        cellMargin: const EdgeInsets.all(2),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(expenseNotifierProvider.notifier).selectDate(selectedDay);
      },
      onPageChanged: (focusedDay) {
        ref
            .read(expenseNotifierProvider.notifier)
            .changeMonth(DateTime(focusedDay.year, focusedDay.month));
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _CalendarCell(
            day: day,
            summary: state.monthlySummary[
                DateTime(day.year, day.month, day.day)],
            isSelected: false,
            isToday: false,
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          return _CalendarCell(
            day: day,
            summary: state.monthlySummary[
                DateTime(day.year, day.month, day.day)],
            isSelected: true,
            isToday: false,
          );
        },
        todayBuilder: (context, day, focusedDay) {
          return _CalendarCell(
            day: day,
            summary: state.monthlySummary[
                DateTime(day.year, day.month, day.day)],
            isSelected: isSameDay(day, state.selectedDate),
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
            ? Colors.red.shade400
            : Colors.black87;

    if (isSelected) {
      bgColor = primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = primary.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          if (income > 0)
            Text(
              _formatShort(income),
              style: TextStyle(
                fontSize: 7,
                color: isSelected ? Colors.white : const Color(0xFF43A047),
                height: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (expense > 0)
            Text(
              _formatShort(expense),
              style: TextStyle(
                fontSize: 7,
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
