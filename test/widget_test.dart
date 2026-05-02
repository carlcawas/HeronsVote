import 'package:flutter_test/flutter_test.dart';

import 'package:heronsvote/main.dart';
import 'package:heronsvote/screens/splash_screen.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
