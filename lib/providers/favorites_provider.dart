import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Manages the set of user favorite asset IDs.
class FavoritesNotifier extends ChangeNotifier {
  Set<String> _favorites = {};

  FavoritesNotifier() {
    _loadFavorites();
  }

  /// Returns the current set of favorite asset IDs.
  Set<String> get favorites => _favorites;
  static const _favoritesKey = 'favorite_assets';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_favoritesKey);
    if (favoriteList != null) {
      _favorites = favoriteList.toSet();
      notifyListeners();
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
      if (!kIsWeb) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) Vibration.vibrate(duration: 30);
      }
    } catch (_) {}
  }

  /// Checks if the given asset ID is in favorites.
  bool isFavorite(String assetId) => _favorites.contains(assetId);
}
