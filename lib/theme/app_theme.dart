import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Compatibility facade for existing screens. The system owns all defaults.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = PiggyColors.accent;
  static const Color primaryDark = PiggyColors.accent;
  static const Color primaryLight = PiggyColors.accentSoft;
  static const Color backgroundColor = PiggyColors.background;
  static const Color incomeColor = PiggyColors.income;
  static const Color expenseColor = PiggyColors.expense;
  static final ThemeData lightTheme = PiggyTheme.light;
}
