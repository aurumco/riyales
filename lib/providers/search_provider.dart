import 'package:flutter/foundation.dart';

/// Manages the current search query state.
class SearchQueryNotifier extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  /// Updates the search query and notifies listeners if it changes.
  set query(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      notifyListeners();
    }
  }
}
