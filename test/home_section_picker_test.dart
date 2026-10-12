import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohammed_store/presentation/screens/home/home_screen.dart';

void main() {
  testWidgets('home displays only the section choices before entry',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('اختر القسم'), findsOneWidget);
    expect(find.text('اتصالات'), findsOneWidget);
    expect(find.text('فودافون'), findsOneWidget);
    expect(find.text('فواتير'), findsOneWidget);
    expect(find.text('لا توجد عروض'), findsNothing);
    expect(find.text('أحدث العروض من الإدارة'), findsNothing);
  });
}
