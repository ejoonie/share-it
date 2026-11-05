import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/widgets/verification_code_field.dart';

void main() {
  testWidgets('six boxes support full-code paste, digits only, deletion and submission', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? submitted;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(
      width: 232,
      child: VerificationCodeField(controller: controller, onSubmitted: (value) => submitted = value),
    )))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12a34567');
    await tester.pump();
    expect(controller.text, '123456');
    for (final digit in '123456'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '123456');
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(find.text('6'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
