import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Need ProviderScope because the app uses Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: Deliver4MeApp(),
      ),
    );

    // Verify the app title or a key widget appears
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
