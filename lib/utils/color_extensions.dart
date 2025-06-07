import 'dart:ui';

// Extension methods
extension ColorExtension on Color {
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      a.round(), // Defensive: Changed from a
      (r * value).round(),
      (g * value).round(),
      (b * value).round(),
    );
  }

  Color lighten(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      a.round(), // Defensive: Changed from a
      (r + ((255 - r) * value)).round(),
      (g + ((255 - g) * value)).round(),
      (b + ((255 - b) * value)).round(),
    );
  }
}
