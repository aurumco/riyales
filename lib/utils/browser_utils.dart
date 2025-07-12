/// Exports platform-specific browser utilities for web and non-web platforms.
library;

export 'browser_utils_stub.dart'
    if (dart.library.html) 'browser_utils_web.dart';
