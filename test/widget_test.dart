import 'package:flutter_test/flutter_test.dart';
import 'package:bright_future_classes/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BrightFutureApp());
    expect(find.text("Let's Sign in"), findsOneWidget);
  });
}
