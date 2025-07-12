import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyales/models/alert.dart';
import 'package:riyales/providers/alert_provider.dart';
import 'package:riyales/providers/locale_provider.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';

// Dart imports
import 'dart:ui' as ui;
import 'package:riyales/providers/card_corner_settings_provider.dart';

/// Alert card widget showing notifications with optional actions.
class AlertCard extends StatefulWidget {
  final Alert alert;
  final Function(String) onAction;
  const AlertCard({super.key, required this.alert, required this.onAction});

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!_animationController.isAnimating) {
      _animationController.forward();
      Provider.of<AlertProvider>(context, listen: false)
          .dismissAndRememberAlert();
    }
  }

  void _handleAction(String action) {
    if (action == 'close_alert') {
      _dismiss();
    } else if (action.startsWith('open_url:') ||
        action.startsWith('open_link:')) {
      final uriString = action.startsWith('open_url:')
          ? action.substring('open_url:'.length)
          : action.substring('open_link:'.length);
      launchUrl(Uri.parse(uriString), mode: LaunchMode.externalApplication);
    } else {
      widget.onAction(action);
    }
  }

  Color _getDarkerShade(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    // Reduce lightness by 40-50% for a deep, rich color that's still visibly related to the base.
    final HSLColor darkerHsl =
        hsl.withLightness((hsl.lightness - 0.45).clamp(0.0, 1.0));
    return darkerHsl.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final locale = Provider.of<LocaleNotifier>(context).locale.languageCode;
    final isRTL = locale == 'fa';
    final content = isRTL ? widget.alert.fa : widget.alert.en;
    final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

    final Map<String, IconData> alertIcons = {
      'green': CupertinoIcons.checkmark_seal_fill,
      'blue': CupertinoIcons.info_circle_fill,
      'red': CupertinoIcons.exclamationmark_triangle_fill,
      'yellow': CupertinoIcons.exclamationmark_triangle_fill,
      'orange': CupertinoIcons.flame_fill,
    };

    final iconData =
        alertIcons[widget.alert.color] ?? CupertinoIcons.info_circle_fill;

    // Restructured and vibrant color system
    final Map<String, Map<String, Color>> alertPalettes = {
      'green': {
        'baseColorLight': const Color(0xFF10B981),
        'bgColorLight': const Color.fromARGB(29, 16, 185, 129),
        'baseColorDark': const Color(0xFF10B981),
        'bgColorDark': const Color.fromARGB(210, 4, 47, 29),
      },
      'blue': {
        'baseColorLight': const Color.fromARGB(255, 27, 117, 255),
        'bgColorLight': const Color.fromARGB(27, 27, 117, 255),
        'baseColorDark': const Color.fromARGB(255, 27, 117, 255),
        'bgColorDark': const Color.fromARGB(120, 12, 34, 65),
      },
      'yellow': {
        'baseColorLight': const Color(0xFFF59E0B),
        'bgColorLight': const Color.fromARGB(36, 243, 149, 9),
        'baseColorDark': const Color(0xFFFBBF24),
        'bgColorDark': const Color.fromARGB(72, 63, 45, 5),
      },
      'red': {
        'baseColorLight': const Color(0xFFEF4444),
        'bgColorLight': const Color.fromARGB(28, 239, 68, 68),
        'baseColorDark': const Color(0xFFEF4444),
        'bgColorDark': const Color.fromARGB(81, 66, 16, 16),
      },
      'orange': {
        'baseColorLight': const Color(0xFFF97316),
        'bgColorLight': const Color.fromARGB(29, 249, 116, 22),
        'baseColorDark': const Color(0xFFF97316),
        'bgColorDark': const Color.fromARGB(99, 67, 30, 4),
      },
    };

    final palette = alertPalettes[widget.alert.color] ?? alertPalettes['blue']!;

    final style = {
      'bgColor': isDarkMode ? palette['bgColorDark'] : palette['bgColorLight'],
      'iconColor':
          isDarkMode ? palette['baseColorDark'] : palette['baseColorLight'],
      'textColor':
          isDarkMode ? palette['baseColorDark'] : palette['baseColorLight'],
      'descriptionColor': isDarkMode
          ? Colors.white.withAlpha(217)
          : Colors.black.withAlpha(166),
      'buttonColor':
          isDarkMode ? palette['baseColorDark'] : palette['baseColorLight'],
      'buttonTextColor': isDarkMode
          ? _getDarkerShade(palette['baseColorDark']!)
          : Colors.white,
      'secondaryBgColor': isDarkMode
          ? Colors.grey[700]!.withAlpha(18)
          : palette['baseColorLight']!.withAlpha(24),
      'secondaryTextColor':
          isDarkMode ? Colors.white : palette['baseColorLight'],
    };

    final cornerSettings = context.watch<CardCornerSettingsNotifier>().settings;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: !_isVisible
              ? const SizedBox.shrink()
              : FadeTransition(
                  opacity: _opacityAnimation,
                  child: Directionality(
                    textDirection:
                        isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: ShapeDecoration(
                        color: style['bgColor'],
                        shape: SmoothRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          smoothness: cornerSettings.smoothness,
                          side: BorderSide.none,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    iconData,
                                    color: style['iconColor'],
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AutoSizeText(
                                    content.title,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: style['textColor'],
                                    ),
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    minFontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AutoSizeText(
                              content.description,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                color: style['descriptionColor'],
                              ),
                              textAlign: TextAlign.start,
                              maxLines: 4,
                              minFontSize: 14,
                            ),
                            if (widget.alert.buttonCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child:
                                    _buildButtons(content, style, fontFamily),
                              )
                            else
                              const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// Builds action buttons for the alert, if any.
  Widget _buildButtons(
      AlertContent content, Map<String, dynamic> style, String fontFamily) {
    final button1 = content.button1;
    final button2 = content.button2;
    final buttonCount = widget.alert.buttonCount;

    final cornerSettings = context.watch<CardCornerSettingsNotifier>().settings;
    final buttonShape = SmoothRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      smoothness: cornerSettings.smoothness,
    );

    Widget createButton(AlertButton button, bool isPrimary) {
      return SizedBox(
        height: 39,
        child: ElevatedButton(
          onPressed: () => _handleAction(button.action),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              isPrimary ? style['buttonColor'] : style['secondaryBgColor'],
            ),
            foregroundColor: WidgetStateProperty.all(
              isPrimary
                  ? style['buttonTextColor']
                  : style['secondaryTextColor'],
            ),
            shape: WidgetStateProperty.all(buttonShape),
            elevation: WidgetStateProperty.all(0),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: AutoSizeText(
            button.text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.5,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            minFontSize: 12,
          ),
        ),
      );
    }

    if (buttonCount == 0) return const SizedBox.shrink();

    return buttonCount == 1
        ? Row(children: [Expanded(child: createButton(button1!, true))])
        : Row(
            children: [
              Expanded(child: createButton(button1!, true)),
              const SizedBox(width: 10),
              Expanded(child: createButton(button2!, false)),
            ],
          );
  }
}
