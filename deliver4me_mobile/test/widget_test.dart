import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deliver4me_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Deliver4MeApp());

    // Verify the app title appears
    expect(find.text('Deliver4Me - All 16 Screens'), findsOneWidget);
  });
}
