import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays the application name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Center(child: Text('ParkirPintar'))),
      ),
    );

    expect(find.text('ParkirPintar'), findsOneWidget);
  });
}
