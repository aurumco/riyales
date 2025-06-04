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
    extends State<TitleWithLanguageTransition>
    with SingleTickerProviderStateMixin {
  String _lastTitle = '';
  String _currentTitle = '';
  bool _isAnimating = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _lastTitle = widget.title;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.isRTL ? -1.5 : 1.5, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(TitleWithLanguageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != _currentTitle && !_isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_controller.isAnimating) return;

    setState(() {
      _lastTitle = _currentTitle;
      _isAnimating = true;
    });

    // Update slide direction based on RTL/LTR
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.isRTL ? 1.5 : -1.5, 0), // Corrected direction for exit
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );

    _controller.forward(from: 0.0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentTitle = widget.title;
        _isAnimating = false;
         // Update slide animation for the new title's entrance
        _slideAnimation = Tween<Offset>(
          begin: Offset(widget.isRTL ? -1.5 : 1.5, 0), // Corrected direction for entry
          end: Offset.zero,
        ).animate(
           CurvedAnimation(parent: ReverseAnimation(_controller), curve: Curves.easeInOutQuart),
        );
      });
      _controller.reverse(from: 1.0); // Reverse to bring the new title in
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: widget.isRTL ? 'Vazirmatn' : 'SF-Pro', // Consistent font family
      fontSize: 22, // Consistent font size
      fontWeight: FontWeight.w600, // Consistent font weight
      color: Theme.of(context).textTheme.titleLarge?.color, // Use theme color
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Determine if the child being built is the new title or the old one
        final bool isNewTitle = (child.key as ValueKey<String>).value == widget.title;

        double dxEntry = widget.isRTL ? -1.0 : 1.0; // New title enters from opposite side
        double dxExit = widget.isRTL ? 1.0 : -1.0;   // Old title exits towards its language direction

        Offset entryOffset = Offset(dxEntry, 0.0);
        Offset exitOffset = Offset(dxExit, 0.0);

        // If it's the new title, it should enter. Otherwise (old title), it should exit.
        final slideTween = Tween<Offset>(
          begin: isNewTitle ? entryOffset : Offset.zero,
          end: isNewTitle ? Offset.zero : exitOffset,
        );

        return SlideTransition(
          position: slideTween.animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutQuart)
          ),
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
