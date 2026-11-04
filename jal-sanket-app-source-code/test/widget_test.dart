import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jal_sanket_2/main.dart';
import 'package:jal_sanket_2/screens/login_screen.dart';

void main() {
  testWidgets('JalSanket app loads login screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const JalSanketApp());
    expect(find.byType(JalSanketApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
