import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohammed_store/presentation/widgets/gradient_logo_text.dart';

void main() {
  testWidgets('Mohammed Store branding renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GradientLogoText())));
    expect(find.text('Mohammed'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
  });
}
