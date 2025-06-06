import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

// Dynamic glow effect widget using palette_generator
class DynamicGlow extends StatefulWidget {
  final ImageProvider imageProvider;
  final Widget child;
  final double size;
  final Color defaultGlowColor; // This is the ultimate fallback
  final Color?
      preferredGlowColor; // If provided, use this and skip PaletteGenerator

  const DynamicGlow({
    super.key,
    required this.imageProvider,
    required this.child,
    required this.size,
    required this.defaultGlowColor,
    this.preferredGlowColor, // New parameter
  });
  @override
  State<DynamicGlow> createState() => _DynamicGlowState();
}

class _DynamicGlowState extends State<DynamicGlow> {
  Color? _glowColor;

  @override
  void initState() {
    super.initState();
    if (widget.preferredGlowColor != null) {
      // If preferred color exists
      _glowColor = widget.preferredGlowColor;
    } else {
      // Otherwise, initialize with default and try to generate from image
      _glowColor = widget.defaultGlowColor;
      _initPalette();
    }
  }

  Future<void> _initPalette() async {
    // Only called if preferredGlowColor is null
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        widget.imageProvider,
        size: const Size(50, 50), // Resize for faster palette generation
      );
      final color = palette.dominantColor?.color;
      if (mounted && color != null) {
        // Only update if a dominant color was found
        setState(() {
          _glowColor = color;
        });
      }
      // If color is null, _glowColor remains widget.defaultGlowColor (which was set in initState)
    } catch (_) {
      // On error, _glowColor remains widget.defaultGlowColor (set in initState)
      // Optionally log the error: print("PaletteGenerator failed: $_");
    }
  }

  @override
  void didUpdateWidget(covariant DynamicGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider || widget.preferredGlowColor != oldWidget.preferredGlowColor) {
      if (widget.preferredGlowColor != null) {
        if (_glowColor != widget.preferredGlowColor) {
          setState(() {
            _glowColor = widget.preferredGlowColor;
          });
        }
      } else {
        // preferredGlowColor is null, try to generate from imageProvider
        // but first set to default to avoid showing old glow with new image
        setState(() {
           _glowColor = widget.defaultGlowColor;
        });
        _initPalette();
      }
    } else if (widget.defaultGlowColor != oldWidget.defaultGlowColor && _glowColor == oldWidget.defaultGlowColor) {
      // If only defaultGlowColor changed and we were using it, update to new default.
      // This case handles if palette generation failed or wasn't applicable.
       setState(() {
           _glowColor = widget.defaultGlowColor;
        });
    }
  }


  @override
  Widget build(BuildContext context) {
    final glow = _glowColor ?? widget.defaultGlowColor;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withAlpha((255 * 0.5).round()),
            blurRadius: 60,
            spreadRadius: 6,
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
