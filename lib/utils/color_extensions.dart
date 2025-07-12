import 'dart:ui';

/// Provides methods to adjust color brightness.
extension ColorExtension on Color {
  /// Darkens the color by [percent] percent.
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      a.round(),
      (r * value).round(),
      (g * value).round(),
      (b * value).round(),
    );
  }

  /// Lightens the color by [percent] percent.
  Color lighten(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      a.round(),
      (r + ((255 - r) * value)).round(),
      (g + ((255 - g) * value)).round(),
      (b + ((255 - b) * value)).round(),
    );
  }
}
