import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/design_system/design_system.dart';
import 'package:share_it/widgets/category_field.dart';

void main() {
  testWidgets('confirmation returns true only for an explicit confirm',
      (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPiggyConfirmation(
                  context: context,
                  title: 'Delete this piggy?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete'));
    expect(button.style!.backgroundColor!.resolve({}), PiggyColors.error);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets('large text and long content remain scrollable on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPiggyConfirmation(
                context: context,
                title: 'Delete this piggy?',
                message:
                    'You and your followers will lose access to this piggy and its entries. You can’t undo this in the app.',
                detail: 'A very long shared household budget name',
                confirmLabel: 'Delete',
                destructive: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Delete')).dy,
      lessThan(tester.getTopLeft(find.text('Cancel')).dy),
    );
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(PiggyConfirmationDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date picker preserves cancel and selected-date behavior',
      (tester) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPiggyDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 11, 5),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 11, 5));
  });

  testWidgets('category sheet stays usable above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        home: Scaffold(body: CategoryField(controller: controller)),
      ),
    );
    await tester.tap(find.byType(CategoryField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Food');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    expect(controller.text, 'Food');
    expect(tester.takeException(), isNull);
  });
}
