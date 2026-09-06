import 'package:flutter/foundation.dart';
import 'device_input_detector_stub.dart'
    if (dart.library.js_interop) 'device_input_detector_web.dart'
    as impl;

/// Returns true if the current environment is a mobile or tablet device.
///
/// Supports both native (Android, iOS) and web (browsers on Android, iOS, iPadOS,
/// and mobile browsers hosted on GitHub Pages).
/// On desktop web or desktop native (Windows, macOS, Linux), returns false.
bool isMobileOrTabletDevice() {
  if (kIsWeb) {
    if (impl.detectWebMobileOrTablet()) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
