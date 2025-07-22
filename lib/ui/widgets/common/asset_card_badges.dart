import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Local imports
import 'package:riyales/ui/widgets/asset_list_page.dart';

/// Displays badges (favorite or symbol) on asset cards.
class AssetCardBadges extends StatelessWidget {
  final bool isFavorite;
  final Color tealGreen;
  final bool isDarkMode;
  final AssetType assetType;
  final String assetSymbol;

  const AssetCardBadges({
    super.key,
    required this.isFavorite,
    required this.tealGreen,
    required this.isDarkMode,
    required this.assetType,
    required this.assetSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Build favorite badge
    Widget? pinBadgeWidget;
    if (isFavorite) {
      pinBadgeWidget = Container(
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDarkMode
              ? tealGreen.withAlpha(38)
              : theme.colorScheme.secondaryContainer.withAlpha(160),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          CupertinoIcons.eye_fill,
          size: 11,
          color: isDarkMode
              ? tealGreen.withAlpha(230)
              : theme.colorScheme.onSecondaryContainer,
        ),
      );
    }

    // Build symbol badge
    Widget? symbolBadgeInnerWidget;
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isWideScreen = screenWidth >= 900;
    final bool useSmallDesktopText =
        isDesktop && (isTablet || isWideScreen) || isTablet;
    if (assetType == AssetType.currency || assetType == AssetType.gold) {
      symbolBadgeInnerWidget = Container(
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDarkMode
              ? tealGreen.withAlpha(38)
              : theme.colorScheme.secondaryContainer.withAlpha(160),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          assetSymbol,
          style: TextStyle(
            fontFamily: 'CourierPrime',
            fontSize: 11,
            fontWeight: useSmallDesktopText ? FontWeight.w500 : FontWeight.w600,
            color: isDarkMode
                ? tealGreen.withAlpha(230)
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      );
    }

    // Combine badges
    if (pinBadgeWidget == null && symbolBadgeInnerWidget == null) {
      return const SizedBox.shrink();
    }

    List<Widget> badgeChildren = [];
    if (pinBadgeWidget != null) {
      badgeChildren.add(pinBadgeWidget);
    }
    if (symbolBadgeInnerWidget != null) {
      if (pinBadgeWidget != null) {
        badgeChildren.add(const SizedBox(width: 5));
      }
      badgeChildren.add(symbolBadgeInnerWidget);
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: badgeChildren,
        ),
      ),
    );
  }
}
