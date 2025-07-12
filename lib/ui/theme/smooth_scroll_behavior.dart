import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provides a smooth scroll behavior with bounce physics and custom scrollbar styling for web.
class SmoothScrollBehavior extends ScrollBehavior {
  /// Removes the default overscroll indicator.
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  /// Uses bounce physics for all scrollable widgets.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  /// Builds CSS-styled scrollbar on web (vertical axis); otherwise returns the child unchanged.
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    if (kIsWeb && axisDirectionToAxis(details.direction) == Axis.vertical) {
      return Container(
        key: const ValueKey('flutter-scrollbar'),
        child: RawScrollbar(
          interactive: true,
          thickness: 6.0,
          radius: const Radius.circular(3.0),
          child: child,
        ),
      );
    }
    return child;
  }
}
