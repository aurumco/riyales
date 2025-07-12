import 'package:flutter/material.dart';

/// Converts a hex [hexString] to a [Color], returns black if parsing fails.
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return Colors.black;
  }
}
