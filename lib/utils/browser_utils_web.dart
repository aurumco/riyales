// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Returns true if the current browser is Firefox.
bool isFirefox() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('firefox');
} 