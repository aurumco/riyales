// Flutter imports
import 'package:flutter/material.dart';

// Third-party packages
import 'package:palette_generator/palette_generator.dart';

/// Wraps a child widget with a circular glow derived from its image colors.
class DynamicGlow extends StatefulWidget {
  final ImageProvider imageProvider;
  final Widget child;
  final double size;
  final Color defaultGlowColor;
  final Color? preferredGlowColor;

  const DynamicGlow({
    super.key,
    required this.imageProvider,
    required this.child,
    required this.size,
    required this.defaultGlowColor,
    this.preferredGlowColor,
  });

  @override
  State<DynamicGlow> createState() => _DynamicGlowState();
}

class _DynamicGlowState extends State<DynamicGlow> {
  Color? _glowColor;

  // Simple in-memory cache to avoid recomputing palette for the same image.
  // Key is derived from ImageProvider's unique identifier (URL or asset name).
  static final Map<String, Color> _paletteCache = {};

  String _providerKey(ImageProvider provider) {
    if (provider is NetworkImage) {
      return 'network:${provider.url}';
    } else if (provider is AssetImage) {
      return 'asset:${provider.assetName}';
    } else {
      return provider.hashCode.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.preferredGlowColor != null) {
      _glowColor = widget.preferredGlowColor;
    } else {
      final key = _providerKey(widget.imageProvider);
      if (_paletteCache.containsKey(key)) {
        _glowColor = _paletteCache[key];
      } else {
        _glowColor = widget.defaultGlowColor;
        _initPalette(key);
      }
    }
  }

  Future<void> _initPalette(String cacheKey) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        widget.imageProvider,
        size: const Size(50, 50),
      );
      final color = palette.dominantColor?.color;
      if (mounted && color != null) {
        setState(() {
          _glowColor = color;
        });
        _paletteCache[cacheKey] = color;
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant DynamicGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider ||
        widget.preferredGlowColor != oldWidget.preferredGlowColor) {
      if (widget.preferredGlowColor != null) {
        if (_glowColor != widget.preferredGlowColor) {
          setState(() {
            _glowColor = widget.preferredGlowColor;
          });
        }
      } else {
        // preferredGlowColor is null, try to generate from imageProvider
        // but first set to default to avoid showing old glow with new image
        final key = _providerKey(widget.imageProvider);
        if (_paletteCache.containsKey(key)) {
          _glowColor = _paletteCache[key];
        } else {
          _initPalette(key);
        }
      }
    } else if (widget.defaultGlowColor != oldWidget.defaultGlowColor &&
        _glowColor == oldWidget.defaultGlowColor) {
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
