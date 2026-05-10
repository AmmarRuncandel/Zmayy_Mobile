import 'package:flutter_test/flutter_test.dart';
import 'package:zmayy_mobile/main.dart';

void main() {
  testWidgets('Zmayy bootstrap smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(const ZmayyBootstrap());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Zmayy'), findsOneWidget);
  });
}
