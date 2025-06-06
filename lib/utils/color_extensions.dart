import 'dart:ui';

// Extension methods
extension ColorExtension on Color {
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      a, // Changed from alpha
      (r * value).round(), // Changed from red
      (g * value).round(), // Changed from green
      (b * value).round(), // Changed from blue
    );
  }

  Color lighten(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      a, // Changed from alpha
      (r + ((255 - r) * value)).round(), // Changed from red
      (g + ((255 - g) * value)).round(), // Changed from green
      (b + ((255 - b) * value)).round(), // Changed from blue
    );
  }
}
