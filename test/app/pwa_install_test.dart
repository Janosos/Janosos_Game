import 'package:dino_run_flame/app/widgets/pwa_install_dialog.dart';
import 'package:dino_run_flame/core/platform/pwa_install_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PwaInstallService defaults to non-web behavior in test environment', () async {
    expect(PwaInstallService.isWeb, isFalse);
    expect(PwaInstallService.isStandalone, isFalse);
    expect(PwaInstallService.isIosWeb, isFalse);
    expect(PwaInstallService.isAndroidWeb, isFalse);
    expect(PwaInstallService.isMobileWeb, isFalse);

    final promptResult = await PwaInstallService.promptInstall();
    expect(promptResult, isFalse);

    final fullscreenResult = await PwaInstallService.enterFullscreen();
    expect(fullscreenResult, isFalse);
  });

  testWidgets('PwaInstallDialog renders without errors and can be closed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PwaInstallDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INSTALAR COMO APP'), findsOneWidget);
    expect(find.text('PANTALLA COMPLETA'), findsOneWidget);
    expect(find.text('CERRAR'), findsOneWidget);

    await tester.tap(find.text('CERRAR'));
    await tester.pumpAndSettle();
  });
}
