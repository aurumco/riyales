import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Only show scrollbars on web platform
    if (kIsWeb) {
      switch (axisDirectionToAxis(details.direction)) {
        case Axis.vertical:
          // Use a container with the flutter-scrollbar class for styling via CSS
          return Container(
            // Apply CSS class for web styling
            decoration: const BoxDecoration(),
            // This key is used by web renderer to apply the CSS class
            key: const ValueKey<String>('flutter-scrollbar'),
            child: RawScrollbar(
              // Hide thumbVisibility since we'll use CSS for showing/hiding
              thumbVisibility: false,
              // Make scrollbar appear only during scrolling on mobile
              interactive: true,
              thickness: 6.0,
              radius: const Radius.circular(3.0),
              child: child,
            ),
          );
        default:
          return child;
      }
    } else {
      // Don't show scrollbars on mobile/desktop
      return child;
    }
  }
}
