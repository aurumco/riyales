import 'package:flutter/foundation.dart';

class SearchQueryNotifier extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  set query(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      notifyListeners();
    }
  }
}
