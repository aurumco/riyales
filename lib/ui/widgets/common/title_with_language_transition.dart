import 'package:flutter/material.dart';

/// Widget to animate title text when language direction changes.
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TitleWithLanguageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: widget.isRTL ? 'Vazirmatn' : 'Onest',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).textTheme.titleLarge?.color,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool isNewTitle =
            (child.key as ValueKey<String>).value == widget.title;

        double dxEntry = widget.isRTL ? -1.0 : 1.0;
        double dxExit = widget.isRTL ? 1.0 : -1.0;

        Offset entryOffset = Offset(dxEntry, 0.0);
        Offset exitOffset = Offset(dxExit, 0.0);

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
        widget.title,
        key: ValueKey<String>(widget.title),
        style: textStyle,
      ),
    );
  }
}
