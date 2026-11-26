import 'package:akari/features/profile/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('画像URLがない場合は頭文字を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(radius: 24, fontSize: 20, initial: 'A'),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
