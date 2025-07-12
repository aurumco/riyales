// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Local project imports
import '../../../providers/search_provider.dart';
import '../../../localization/l10n_utils.dart';
import '../../../utils/helpers.dart';
import '../../../utils/browser_utils.dart';

/// A shimmering search field widget that displays a placeholder effect when no text is entered.
class ShimmeringSearchField extends StatefulWidget {
  const ShimmeringSearchField({super.key});

  /// Creates a new [ShimmeringSearchField].
  @override
  ShimmeringSearchFieldState createState() => ShimmeringSearchFieldState();
}

class ShimmeringSearchFieldState extends State<ShimmeringSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  final FocusNode _focusNode = FocusNode();
  bool _isShimmering = true;
  bool _showCursor = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
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

    final bool isFirefoxBrowser = kIsWeb && isFirefox();

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
              borderRadius: BorderRadius.circular(12), smoothness: 0.75),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            if (searchText.isEmpty && (!_isShimmering || isFirefoxBrowser))
              Align(
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45.0),
                  child: placeholderTextWidget,
                ),
              ),
            CupertinoTextField(
              controller: TextEditingController(text: searchText)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: searchText.length)),
              onChanged: (v) => context.read<SearchQueryNotifier>().query = v,
              focusNode: _focusNode,
              placeholder: '',
              prefix: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 18),
                  child:
                      Icon(CupertinoIcons.search, size: 20, color: iconColor)),
              suffix: searchText.isNotEmpty
                  ? CupertinoButton(
                      padding: const EdgeInsetsDirectional.only(end: 18),
                      onPressed: () =>
                          context.read<SearchQueryNotifier>().query = '',
                      minimumSize: Size(30, 30),
                      child: Icon(CupertinoIcons.clear,
                          size: 18, color: iconColor),
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
              decoration: const BoxDecoration(color: Colors.transparent),
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
