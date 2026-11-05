import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class PiggyTheme {
  static final navigation = NavigationBarThemeData(
    height: PiggySize.navigation,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    indicatorColor: PiggyColors.accentSoft.withValues(alpha: 0.82),
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: 22,
        color: states.contains(WidgetState.selected)
            ? PiggyColors.accent
            : PiggyColors.secondary,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => PiggyType.metadata.copyWith(
        letterSpacing: 0,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w400,
        color: states.contains(WidgetState.selected)
            ? PiggyColors.accent
            : PiggyColors.secondary,
      ),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.small),
        borderSide: BorderSide(color: color, width: width),
      );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PiggyColors.accent,
      primary: PiggyColors.accent,
      onPrimary: Colors.white,
      primaryContainer: PiggyColors.accentSoft,
      onPrimaryContainer: PiggyColors.accent,
      secondary: PiggyColors.income,
      onSecondary: Colors.white,
      secondaryContainer: PiggyColors.incomeSoft,
      onSecondaryContainer: PiggyColors.income,
      tertiary: PiggyColors.expense,
      onTertiary: Colors.white,
      tertiaryContainer: PiggyColors.expenseSoft,
      onTertiaryContainer: PiggyColors.expense,
      surface: PiggyColors.surface,
      onSurface: PiggyColors.ink,
      onSurfaceVariant: PiggyColors.secondary,
      outline: PiggyColors.secondary,
      outlineVariant: PiggyColors.line,
      error: PiggyColors.error,
      onError: Colors.white,
      errorContainer: PiggyColors.errorSoft,
      onErrorContainer: PiggyColors.error,
    ),
    scaffoldBackgroundColor: PiggyColors.background,
    disabledColor: PiggyColors.muted,
    textTheme: const TextTheme(
      titleLarge: PiggyType.pageTitle,
      titleMedium: PiggyType.sectionTitle,
      titleSmall: PiggyType.itemTitle,
      bodyLarge: TextStyle(fontSize: 16, color: PiggyColors.ink),
      bodyMedium: PiggyType.body,
      bodySmall: PiggyType.caption,
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: PiggyType.label,
      labelSmall: PiggyType.metadata,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PiggyColors.background,
      foregroundColor: PiggyColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: PiggyType.pageTitle,
      iconTheme: IconThemeData(color: PiggyColors.ink, size: 22),
    ),
    cardTheme: CardThemeData(
      color: PiggyColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PiggyColors.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PiggyColors.line,
        disabledForegroundColor: PiggyColors.secondary,
        minimumSize: const Size(PiggySize.tapTarget, PiggySize.button),
        padding: const EdgeInsets.symmetric(
          horizontal: PiggySpace.xl,
          vertical: PiggySpace.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiggyRadius.small),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: PiggyColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(PiggySize.tapTarget, PiggySize.button),
        padding: const EdgeInsets.symmetric(
          horizontal: PiggySpace.xl,
          vertical: PiggySpace.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiggyRadius.small),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PiggyColors.accent,
        minimumSize: const Size(PiggySize.tapTarget, PiggySize.button),
        side: const BorderSide(color: PiggyColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiggyRadius.small),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PiggyColors.accent,
        minimumSize: const Size(PiggySize.tapTarget, PiggySize.tapTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PiggyColors.surface,
      labelStyle: PiggyType.caption,
      hintStyle: PiggyType.body.copyWith(color: PiggyColors.secondary),
      errorStyle: PiggyType.caption.copyWith(color: PiggyColors.error),
      border: _inputBorder(PiggyColors.line),
      enabledBorder: _inputBorder(PiggyColors.line),
      disabledBorder: _inputBorder(PiggyColors.line),
      focusedBorder: _inputBorder(PiggyColors.accent, 2),
      errorBorder: _inputBorder(PiggyColors.error),
      focusedErrorBorder: _inputBorder(PiggyColors.error, 2),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: PiggySpace.lg, vertical: 14),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: PiggyColors.accent,
      selectionColor: PiggyColors.accent.withValues(alpha: 0.18),
      selectionHandleColor: PiggyColors.accent,
    ),
    dividerTheme: const DividerThemeData(color: PiggyColors.line, thickness: 1),
    navigationBarTheme: navigation,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: PiggyColors.accent,
      unselectedItemColor: PiggyColors.secondary,
      backgroundColor: PiggyColors.surface,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PiggyColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      highlightElevation: 0,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: PiggyColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.dialog),
      ),
      headerBackgroundColor: PiggyColors.card,
      headerForegroundColor: PiggyColors.ink,
      headerHeadlineStyle: PiggyType.pageTitle.copyWith(fontSize: 28),
      headerHelpStyle: PiggyType.label.copyWith(color: PiggyColors.accent),
      dividerColor: PiggyColors.line,
      todayBorder: const BorderSide(color: PiggyColors.accent),
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: PiggyColors.secondary,
        minimumSize: const Size(64, 48),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: PiggyColors.accent,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      dragHandleColor: PiggyColors.line,
      dragHandleSize: Size(36, 4),
      backgroundColor: PiggyColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PiggyRadius.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      titleTextStyle: PiggyType.pageTitle,
      contentTextStyle: PiggyType.body,
      backgroundColor: PiggyColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.dialog),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PiggyColors.ink,
      contentTextStyle: PiggyType.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.small),
      ),
    ),
  );
}
