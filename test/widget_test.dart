import 'package:flutter_test/flutter_test.dart';
import 'package:auremind_offline/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const AureMindApp());
  });
}