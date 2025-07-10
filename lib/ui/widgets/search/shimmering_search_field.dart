import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../providers/search_provider.dart';
import '../../../localization/l10n_utils.dart';
import '../../../utils/helpers.dart';
import '../../../utils/browser_utils.dart';

class ShimmeringSearchField extends StatefulWidget {
  const ShimmeringSearchField({super.key});

  @override
  ShimmeringSearchFieldState createState() => ShimmeringSearchFieldState();
}

class ShimmeringSearchFieldState extends State<ShimmeringSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  final FocusNode _focusNode = FocusNode();
  bool _isShimmering = true; // Start shimmering by default
  bool _showCursor = false; // Hide cursor initially until user taps

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Start shimmer after a short delay to allow the search bar to animate in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    // No focus listener to remove
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQueryNotifier = context.watch<SearchQueryNotifier>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final searchText = searchQueryNotifier.query;
    final isRTL = Localizations.localeOf(context).languageCode == 'fa' ||
        containsPersian(searchText);

    // Detect Firefox on web: disable shimmer due to lack of proper shader support
    final bool isFirefoxBrowser = kIsWeb && isFirefox();

    // Determine if shimmer should be active based on whether user typed anything
    bool shouldShimmer = searchText.isEmpty && !isFirefoxBrowser;

    if (shouldShimmer && !_isShimmering) {
      _shimmerController.repeat();
      _isShimmering = true;
    } else if (!shouldShimmer && _isShimmering) {
      _shimmerController.stop();
      _isShimmering = false;
    }

    final textColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];
    final placeholderColor = isDarkMode ? Colors.grey[500] : Colors.grey[500];
    final iconColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

    final placeholderTextWidget = Text(
      l10n.searchPlaceholder,
      style: TextStyle(
          color: placeholderColor, fontFamily: fontFamily, fontSize: 16),
    );

    final shimmerColors = isDarkMode
        ? [
            Colors.grey[600]!,
            Colors.grey[400]!,
            Colors.grey[600]!,
          ]
        : [
            Colors.grey[500]!,
            Colors.grey[600]!,
            Colors.grey[500]!,
          ];

    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      },
      child: Container(
        height: 48,
        decoration: ShapeDecoration(
          color: isDarkMode ? const Color(0xFF161616) : Colors.white,
          shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(12), smoothness: 0.7),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shimmering placeholder (drawn first, so it's behind)
            if (searchText.isEmpty && _isShimmering && !isFirefoxBrowser)
              Align(
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45.0),
                  child: AnimatedBuilder(
                    animation: CurvedAnimation(
                        parent: _shimmerController, curve: Curves.easeInOut),
                    builder: (context, child) {
                      final animationValue = _shimmerController.value;
                      final beginX = isRTL
                          ? 2.0 - (animationValue * 3.5)
                          : -2.0 + (animationValue * 3.5);
                      final endX = isRTL
                          ? 1.0 - (animationValue * 3.5)
                          : -1.0 + (animationValue * 3.5);

                      final gradient = LinearGradient(
                        colors: shimmerColors,
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(beginX, 0),
                        end: Alignment(endX, 0),
                      );
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => gradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: child,
                      );
                    },
                    child: placeholderTextWidget,
                  ),
                ),
              ),
            // Static placeholder when not shimmering (drawn after shimmer, also behind text field)
            if (searchText.isEmpty && (!_isShimmering || isFirefoxBrowser))
              Align(
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45.0),
                  child: placeholderTextWidget,
                ),
              ),
            // The actual text field (drawn last, so it's on top and interactive)
            CupertinoTextField(
              controller: TextEditingController(text: searchText)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: searchText.length)),
              onChanged: (v) => context.read<SearchQueryNotifier>().query = v,
              focusNode: _focusNode,
              placeholder: '', // Placeholder is visually handled by the widgets above
              prefix: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 18),
                  child: Icon(CupertinoIcons.search, size: 20, color: iconColor)),
              suffix: searchText.isNotEmpty
                  ? CupertinoButton(
                      padding: const EdgeInsetsDirectional.only(end: 18),
                      minSize: 30,
                      child: Icon(CupertinoIcons.clear, size: 18, color: iconColor),
                      onPressed: () =>
                          context.read<SearchQueryNotifier>().query = '',
                    )
                  : null,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
              padding: EdgeInsetsDirectional.only(
                  start: 9,
                  end: searchText.isNotEmpty ? 28 : 12,
                  top: 11,
                  bottom: 11),
              style: TextStyle(color: textColor, fontFamily: fontFamily),
              cursorColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              decoration: const BoxDecoration(color: Colors.transparent), // Essential for placeholders behind to be visible
              autofocus: true,
              showCursor: _showCursor,
              onTap: () {
                if (!_showCursor) {
                  setState(() => _showCursor = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
