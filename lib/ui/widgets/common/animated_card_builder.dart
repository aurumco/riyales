// Dart imports
import 'dart:math' as math;

// Flutter imports
import 'package:flutter/material.dart';

/// Smoothly animates cards into view with fade, slide, and scale effects.
class AnimatedCardBuilder extends StatefulWidget {
  final int index;
  final Widget child;
  final bool initialLoad;

  const AnimatedCardBuilder({
    super.key,
    required this.index,
    required this.child,
    this.initialLoad = false,
  });

  @override
  State<AnimatedCardBuilder> createState() => _AnimatedCardBuilderState();
}

class _AnimatedCardBuilderState extends State<AnimatedCardBuilder>
    with SingleTickerProviderStateMixin {
  /// Controls the fade, slide, and scale animations.
  late AnimationController _controller;

  /// Animates opacity from transparent to fully visible.
  late Animation<double> _opacityAnimation;

  /// Animates sliding in from below.
  late Animation<Offset> _slideAnimation;

  /// Animates scaling from slightly smaller to full size.
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Simple stagger for fast, natural appearance
    final int staggerDelay = math.min(widget.index * 20, 120);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.99,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: staggerDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
