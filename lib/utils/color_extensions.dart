import 'dart:ui';

// Extension methods
extension ColorExtension on Color {
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      a, // .alpha -> .a
      (r * value).round(), // .red -> .r
      (g * value).round(), // .green -> .g
      (b * value).round(), // .blue -> .b
    );
  }

  Color lighten(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      a, // .alpha -> .a
      (r + ((255 - r) * value)).round(), // .red -> .r
      (g + ((255 - g) * value)).round(), // .green -> .g
      (b + ((255 - b) * value)).round(), // .blue -> .b
    );
  }
}
