import 'package:dino_run_flame/game/presentation/dino_run_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the current game version', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: JanososVersionLabel())),
    );

    expect(find.text('V6 PREVIEW'), findsOneWidget);
  });
}
