import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/widgets/verification_code_field.dart';

void main() {
  testWidgets('six boxes support paste, digits only and automatic submission',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? submitted;
    var submissionCount = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
      width: 232,
      child: VerificationCodeField(
          controller: controller,
          onSubmitted: (value) {
            submitted = value;
            submissionCount++;
          }),
    )))));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).autofillHints,
      const [AutofillHints.oneTimeCode],
    );
    await tester.enterText(find.byType(TextField), '12a34567');
    await tester.pump();
    expect(controller.text, '123456');
    expect(submitted, '123456');
    for (final digit in '123456'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '123456');
    expect(submissionCount, 1);
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(find.text('6'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a complete code auto-submits once until the code is edited',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submissions = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VerificationCodeField(
          controller: controller,
          onSubmitted: submissions.add,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(submissions, ['123456']);

    controller.value = const TextEditingValue(text: '123456');
    await tester.pump();
    expect(submissions, ['123456']);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(submissions, ['123456', '123456']);
  });
}
