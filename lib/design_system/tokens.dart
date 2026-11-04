import 'package:flutter/material.dart';

/// Sharable Piggy v1: warm surfaces, expressive accents, readable amounts.
abstract final class PiggyColors {
  static const background = Color(0xFFFFFBF6);
  static const surface = Colors.white;
  static const ink = Color(0xFF303047);
  static const secondary = Color(0xFF6D6A80);
  static const muted = Color(0xFF9C97A7);
  static const line = Color(0xFFEDE6E0);
  static const accent = Color(0xFF5355D9);
  static const accentSoft = Color(0xFFF0EDFF);
  static const income = Color(0xFF3966CE);
  static const incomeSoft = Color(0xFFEDF2FF);
  static const expense = Color(0xFFB9473E);
  static const expenseSoft = Color(0xFFFFEEE5);
  // Feedback is independent of transaction type: spending is not an error.
  static const error = Color(0xFFB52D45);
  static const errorSoft = Color(0xFFFFEDEF);
  static const success = Color(0xFF287452);
  static const successSoft = Color(0xFFEAF5EF);
  static const warning = Color(0xFF8F5B10);
  static const warningSoft = Color(0xFFFFF3D9);
}

enum PiggyTone {
  brand(PiggyColors.accent, PiggyColors.accentSoft),
  income(PiggyColors.income, PiggyColors.incomeSoft),
  expense(PiggyColors.expense, PiggyColors.expenseSoft),
  neutral(PiggyColors.secondary, PiggyColors.background);

  const PiggyTone(this.foreground, this.background);
  final Color foreground;
  final Color background;
}

abstract final class PiggySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const page = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class PiggyRadius {
  static const small = 12.0;
  static const card = 16.0;
  static const summary = 18.0;
  static const sheet = 24.0;
}

abstract final class PiggySize {
  static const tapTarget = 44.0;
  static const button = 48.0;
  static const categoryTile = 38.0;
  static const categoryIcon = 19.0;
  static const dayMarker = 30.0;
  static const calendarRow = 56.0;
  static const navigation = 64.0;
  static const contentMaxWidth = 640.0;
}

/// Native system fonts; no network font loading or fixed text scaling.
abstract final class PiggyType {
  static const pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: PiggyColors.ink,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: PiggyColors.ink,
  );
  static const summaryAmount = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const amount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const body = TextStyle(fontSize: 14, color: PiggyColors.ink);
  static const itemTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: PiggyColors.ink,
  );
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: PiggyColors.secondary,
  );
  static const caption = TextStyle(fontSize: 12, color: PiggyColors.secondary);
  static const metadata = TextStyle(fontSize: 11, color: PiggyColors.secondary);
  static const calendarDay = TextStyle(fontSize: 13, height: 1);
  // Calendar-only abbreviation. Full values belong in the daily ledger.
  static const calendarAmount = TextStyle(
    fontSize: 9,
    height: 1.1,
    letterSpacing: -0.2,
  );
}
