import 'package:flutter/material.dart';

// Add a custom title widget that handles the sequential animation
// Custom title widget for smooth language transition
class TitleWithLanguageTransition extends StatefulWidget {
  final String title;
  final bool isRTL;

  const TitleWithLanguageTransition({
    super.key,
    required this.title,
    required this.isRTL,
  });

  @override
  State<TitleWithLanguageTransition> createState() =>
      _TitleWithLanguageTransitionState();
}

class _TitleWithLanguageTransitionState
    extends State<TitleWithLanguageTransition> {
  // Unused fields and animation controller logic removed as AnimatedSwitcher handles the transition.

  @override
  void initState() {
    super.initState();
    // No manual animation setup needed with AnimatedSwitcher
  }

  @override
  void didUpdateWidget(TitleWithLanguageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AnimatedSwitcher reacts to widget.title changes automatically.
  }

  @override
  void dispose() {
    // No manual controller to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily:
          widget.isRTL ? 'Vazirmatn' : 'Onest', // Use Onest for English title
      fontSize: 22, // Consistent font size
      fontWeight: FontWeight.w600, // Consistent font weight
      color: Theme.of(context).textTheme.titleLarge?.color, // Use theme color
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Determine if the child being built is the new title or the old one
        final bool isNewTitle =
            (child.key as ValueKey<String>).value == widget.title;

        double dxEntry =
            widget.isRTL ? -1.0 : 1.0; // New title enters from opposite side
        double dxExit = widget.isRTL
            ? 1.0
            : -1.0; // Old title exits towards its language direction

        Offset entryOffset = Offset(dxEntry, 0.0);
        Offset exitOffset = Offset(dxExit, 0.0);

        // If it's the new title, it should enter. Otherwise (old title), it should exit.
        final slideTween = Tween<Offset>(
          begin: isNewTitle ? entryOffset : Offset.zero,
          end: isNewTitle ? Offset.zero : exitOffset,
        );

        return SlideTransition(
          position: slideTween.animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutQuart)),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        widget.title, // The current title to display
        key: ValueKey<String>(widget.title), // Key to trigger animation
        style: textStyle,
      ),
    );
  }
}
