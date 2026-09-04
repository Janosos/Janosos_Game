import 'package:dino_run_flame/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'registers, navigates every local feature, restores session and deletes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await bootstrap();
      await tester.pumpAndSettle();
      expect(find.text('Continúa tu progreso'), findsOneWidget);

      await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
      await tester.pumpAndSettle();
      final registrationFields = find.byType(TextFormField);
      expect(registrationFields, findsNWidgets(3));
      await tester.enterText(registrationFields.at(0), 'Jugador Integración');
      await tester.enterText(registrationFields.at(1), 'journey@example.com');
      await tester.enterText(registrationFields.at(2), 'local-password');
      await tester.tap(find.text('CREAR CUENTA'));
      await _pumpUntilFound(tester, find.text('Hola, Jugador Integración'));

      expect(find.text('Hola, Jugador Integración'), findsOneWidget);
      expect(find.textContaining('campaña completa'), findsOneWidget);

      await _openDestination(tester, 'Personajes');
      for (final name in ['JANO', 'PARKER', 'CHEMA', 'CONRA']) {
        expect(find.text(name), findsOneWidget);
      }

      await _openDestination(tester, 'Ranking');
      expect(find.text('Leaderboard por personaje'), findsOneWidget);
      expect(find.text('Mi historial'), findsOneWidget);

      await _openDestination(tester, 'Campaña');
      expect(find.text('Progresión mundial'), findsOneWidget);
      expect(find.text('BLOQUEADO'), findsWidgets);
      expect(find.textContaining('Jinete sin Cabeza'), findsWidgets);

      await _openDestination(tester, 'Tienda');
      expect(find.text('Progresión del personaje'), findsOneWidget);
      expect(find.textContaining('Para comprar, completa'), findsOneWidget);

      await tester.tap(find.byTooltip('Configuración y cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Reducir movimiento'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Reducir movimiento'),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Continúa tu progreso'), findsOneWidget);

      final signInFields = find.byType(TextFormField);
      await tester.enterText(signInFields.at(0), 'journey@example.com');
      await tester.enterText(signInFields.at(1), 'local-password');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await _pumpUntilFound(tester, find.text('Jugador Integración'));
      expect(find.text('Configuración'), findsOneWidget);
      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirmación'),
        'ELIMINAR',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar definitivamente'));
      await _pumpUntilFound(tester, find.text('Continúa tu progreso'));
      expect(find.text('Continúa tu progreso'), findsOneWidget);
    },
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .where((text) => text.isNotEmpty)
      .join(' | ');
  fail('No apareció la pantalla esperada. Texto visible: $visibleText');
}

Future<void> _openDestination(WidgetTester tester, String label) async {
  final compactDestination = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  final wideDestination = find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(label),
  );
  final destination = compactDestination.evaluate().isNotEmpty
      ? compactDestination
      : wideDestination;
  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}
