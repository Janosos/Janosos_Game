import 'package:web/web.dart' as web;

bool detectWebMobileOrTablet() {
  final nav = web.window.navigator;
  final userAgent = nav.userAgent.toLowerCase();
  final isMobileUA = userAgent.contains('android') ||
      userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod') ||
      userAgent.contains('mobile') ||
      userAgent.contains('tablet');

  final touchPoints = nav.maxTouchPoints;
  final hasTouch = touchPoints > 0;

  // iPadOS sends 'macintosh' user agent but has touch points
  final isIPad = userAgent.contains('macintosh') && hasTouch;

  return isMobileUA || isIPad;
}
