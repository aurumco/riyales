import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class FavoritesNotifier extends ChangeNotifier {
  Set<String> _favorites = {};

  FavoritesNotifier() {
    _loadFavorites();
  }

  Set<String> get favorites =>
      _favorites; // Public getter for the favorites set
  static const _favoritesKey = 'favorite_assets';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_favoritesKey);
    if (favoriteList != null) {
      _favorites = favoriteList.toSet();
      notifyListeners(); // Notify after loading
    }
  }

  Future<void> toggleFavorite(String assetId) async {
    final newFavorites = Set<String>.from(_favorites);
    if (newFavorites.contains(assetId)) {
      newFavorites.remove(assetId);
    } else {
      newFavorites.add(assetId);
    }
    _favorites = newFavorites;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, newFavorites.toList());

    notifyListeners();

    try {
      final bool hasVibrator =
          await Vibration.hasVibrator(); // Made bool? to align with package
      if (hasVibrator) {
        // Added null check
        Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      // Vibration failed, log if necessary
      // print('Vibration failed: $e');
    }
  }

  bool isFavorite(String assetId) => _favorites.contains(assetId);
}
