import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_lineomatic_ai_vms/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows unit selection when none saved', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiVmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Unit 4'), findsOneWidget);
  });

  testWidgets('selecting a unit persists and shows check in/out options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiVmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unit 2'));
    await tester.pumpAndSettle();

    expect(find.text('Check In Visitor'), findsOneWidget);
    expect(find.text('Check Out Visitor'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('selected_unit_id'), 2);
  });
}
