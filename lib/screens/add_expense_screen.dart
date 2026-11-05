import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../widgets/expense_form.dart';

class AddExpenseScreen extends StatelessWidget {
  final int initYear;
  final int initMonth;
  final int initDay;
  final String initialAmount;
  final ExpenseType initialType;

  const AddExpenseScreen({
    super.key,
    required this.initYear,
    required this.initMonth,
    required this.initDay,
    required this.initialAmount,
    required this.initialType,
  });

  @override
  Widget build(BuildContext context) => ExpenseForm(
        initYear: initYear,
        initMonth: initMonth,
        initDay: initDay,
        initialAmount: initialAmount,
        initialType: initialType,
        fullScreen: true,
        onSaved: () {
          // Close the details and calculator routes after saving.
          Navigator.of(context)
            ..pop()
            ..pop();
        },
      );
}
