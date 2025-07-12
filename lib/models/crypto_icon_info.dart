import 'package:flutter/material.dart';

/// Stores the icon path and display color for a cryptocurrency.
class CryptoIconInfo {
  final String iconPath;
  final Color color;

  /// Creates a [CryptoIconInfo] with the given icon path and color.
  const CryptoIconInfo({required this.iconPath, required this.color});
}
