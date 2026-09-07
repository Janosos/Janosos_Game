import 'package:flutter/foundation.dart';
import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart' as impl;

/// Facilitates PWA installation and fullscreen mode for web platforms (Android & iOS Safari).
class PwaInstallService {
  const PwaInstallService._();

  static bool get isWeb => kIsWeb;

  /// Returns true if the app is already running in standalone/fullscreen PWA mode.
  static bool get isStandalone => kIsWeb && impl.checkIsStandalone();

  /// Returns true if the user is running on an iOS device (iPhone/iPad) in web.
  static bool get isIosWeb => kIsWeb && impl.checkIsIosWeb();

  /// Returns true if the user is running on an Android browser in web.
  static bool get isAndroidWeb => kIsWeb && impl.checkIsAndroidWeb();

  /// Returns true if running in any mobile browser on web.
  static bool get isMobileWeb => isIosWeb || isAndroidWeb;

  /// Prompts the browser's native PWA installation dialog (e.g. Android Chrome).
  static Future<bool> promptInstall() async {
    if (!kIsWeb) return false;
    return impl.triggerPromptInstall();
  }

  /// Requests the browser to enter landscape fullscreen mode.
  static Future<bool> enterFullscreen() async {
    if (!kIsWeb) return false;
    return impl.triggerEnterFullscreen();
  }
}
