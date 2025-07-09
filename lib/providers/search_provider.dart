import 'package:flutter/foundation.dart';
import 'dart:async';

class SearchQueryNotifier extends ChangeNotifier {
  String _query = '';
  String get query => _query;
  Timer? _debounce;

  set query(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;

      // Debounce the notification
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
