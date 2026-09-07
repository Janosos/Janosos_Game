import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/features/settings/application/hud_settings_controller.dart';
import 'package:dino_run_flame/features/settings/presentation/hud_customizer_dialog.dart';
import 'package:dino_run_flame/game/domain/hud_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HudCustomizerDialog renders in landscape without overflow and interacts correctly', (tester) async {
    // Standard phone landscape resolution
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HudCustomizerDialog(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no RenderFlex overflows occurred
    expect(tester.takeException(), isNull);

    // Verify header and mode
    expect(find.text('PERSONALIZAR HUD & CONTROLES'), findsOneWidget);
    expect(find.text('MODO HORIZONTAL'), findsOneWidget);

    // Verify tabs
    expect(find.text('CRUCETA'), findsOneWidget);
    expect(find.text('HABILIDAD'), findsOneWidget);
    expect(find.text('GOLPE JEFE'), findsOneWidget);

    // Tap on HABILIDAD tab
    await tester.tap(find.text('HABILIDAD'));
    await tester.pumpAndSettle();
    expect(find.text('EDITANDO: BOTÓN DE HABILIDAD'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap on preset chip
    final preset130 = find.text('130% GRANDE').first;
    await tester.tap(preset130);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tap on GOLPE JEFE tab
    await tester.tap(find.text('GOLPE JEFE'));
    await tester.pumpAndSettle();
    expect(find.text('EDITANDO: BOTÓN GOLPE JEFE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap on GUARDAR AJUSTES button
    await tester.tap(find.text('GUARDAR AJUSTES'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
