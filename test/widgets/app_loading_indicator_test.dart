import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/widgets/app_loading_indicator.dart';

void main() {
  testWidgets('startup logo stays centered independently of spinner and insets',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 59, bottom: 34)),
          child: Scaffold(body: AppLoadingIndicator()),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Image)), const Size(160, 160));
    expect(
      tester.getCenter(find.byType(Image)),
      tester.getCenter(find.byType(Scaffold)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('in-page loading does not repeat the startup logo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoadingIndicator(showLogo: false)),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
