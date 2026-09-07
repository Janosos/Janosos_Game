import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('janososPromptInstall')
external JSPromise<JSBoolean>? _janososPromptInstall();

@JS('janososEnterFullscreen')
external JSPromise<JSBoolean>? _janososEnterFullscreen();

@JS('janososIsStandalone')
external JSBoolean? _janososIsStandalone();

bool checkIsStandalone() {
  try {
    final res = _janososIsStandalone();
    return res?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool checkIsIosWeb() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    final hasTouch = web.window.navigator.maxTouchPoints > 0;
    return ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod') ||
        (ua.contains('macintosh') && hasTouch);
  } catch (_) {
    return false;
  }
}

bool checkIsAndroidWeb() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('android');
  } catch (_) {
    return false;
  }
}

Future<bool> triggerPromptInstall() async {
  try {
    final promise = _janososPromptInstall();
    if (promise != null) {
      final res = await promise.toDart;
      return res.toDart;
    }
  } catch (_) {}
  return false;
}

Future<bool> triggerEnterFullscreen() async {
  try {
    final promise = _janososEnterFullscreen();
    if (promise != null) {
      final res = await promise.toDart;
      return res.toDart;
    }
  } catch (_) {}
  return false;
}
