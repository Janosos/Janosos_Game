import 'package:dino_run_flame/features/characters/presentation/characters_screen.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all characters with their complete descriptions', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharactersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Nanic description is fully present in the tree
    final nanicDesc = CharacterId.nanic.definition.description;
    expect(find.text(nanicDesc), findsOneWidget);

    // Verify Jano description is fully present in the tree
    final janoDesc = CharacterId.jano.definition.description;
    expect(find.text(janoDesc), findsOneWidget);
  });
}
