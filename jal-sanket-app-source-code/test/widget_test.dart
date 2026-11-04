import 'package:flutter_test/flutter_test.dart';
import 'package:jal_sanket_2/main.dart';

void main() {
  testWidgets('JalSanket app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JalSanketApp());
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Enter Dashboard'), findsOneWidget);
  });
}
