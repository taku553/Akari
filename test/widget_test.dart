import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akari/main.dart';

void main() {
  testWidgets('App renders Home Screen with Level 1', (
    WidgetTester tester,
  ) async {
    // ProviderScopeでラップしてアプリを起動
    await tester.pumpWidget(const ProviderScope(child: MissionLevelerApp()));

    // Initial check
    expect(find.text('Level 1'), findsOneWidget);
  });
}
