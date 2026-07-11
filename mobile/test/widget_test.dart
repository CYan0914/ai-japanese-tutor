import 'package:flutter_test/flutter_test.dart';
import 'package:sakura_tutor/app.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SakuraApp());
    expect(find.text('Sakura'), findsOneWidget);
  });
}
