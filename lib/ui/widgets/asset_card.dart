import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:seo/seo.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/asset_models.dart' as models;
import '../../models/crypto_icon_info.dart';
import '../../config/app_config.dart';
import '../widgets/asset_list_page.dart';
import '../../providers/locale_provider.dart';
import '../../providers/currency_unit_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/data_providers/currency_data_provider.dart';
import '../../providers/card_corner_settings_provider.dart';
import '../../localization/l10n_utils.dart';
import '../../utils/color_utils.dart';
import '../../utils/helpers.dart';
import './common/dynamic_glow.dart';
import './common/asset_card_badges.dart';
import '../../services/analytics_service.dart';
import 'package:equatable/equatable.dart';
import '../../generated/app_localizations.dart';
import '../../utils/flag_colors.dart';
import '../../utils/crypto_icon_map.dart';

class CryptoIconCacheManager extends CacheManager {
  static const key = 'cryptoIconCache';

  static final CryptoIconCacheManager _instance = CryptoIconCacheManager._();
  factory CryptoIconCacheManager() => _instance;

  CryptoIconCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
        ));
}

const bool _isCanvasKit =
    bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);
bool get _supportsColorFilter => !kIsWeb || _isCanvasKit;

void showCustomErrorSnackBar(BuildContext context) {
  final overlay = Overlay.of(context);
  final controller = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 180),
  );
  final curved = CurvedAnimation(
    parent: controller,
    curve: Curves.easeInOut,
  );
  final locale = Localizations.localeOf(context);
  final isRTL = locale.languageCode == 'fa';
  final l10n = AppLocalizations.of(context);
  final message = l10n.error_image_generation_or_sharing;

  late OverlayEntry entry;
  entry = OverlayEntry(builder: (context) {
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: Material(
          elevation: 0,
          color: const ui.Color.fromARGB(255, 247, 37, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                      color: Colors.white,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });

  overlay.insert(entry);
  controller.forward();

  Future.delayed(const Duration(seconds: 4), () async {
    await controller.reverse();
    entry.remove();
    controller.dispose();
  });
}

class AssetCard extends StatelessWidget {
  final models.Asset asset;
  final AssetType assetType;

  AssetCard({
    super.key,
    required this.asset,
    required this.assetType,
  });

  final GlobalKey _cardKey = GlobalKey();

  Future<ui.Image> _loadUiImageFromAsset(String assetPath,
      {double? targetHeight}) async {
    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetHeight: targetHeight?.round(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _shareCardImage(BuildContext context) async {
    try {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final pixelRatio = math.max(3.0, devicePixelRatio * 1.5);
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final cardImage = await boundary.toImage(pixelRatio: pixelRatio);
      final cardByteData =
          await cardImage.toByteData(format: ui.ImageByteFormat.png);
      if (cardByteData == null) {
        if (context.mounted) showCustomErrorSnackBar(context);
        return;
      }
      // Load brand image and fit to card height
      final brandImage = await _loadUiImageFromAsset('assets/images/brand.png',
          targetHeight: cardImage.height.toDouble());
      // Add padding
      const int padding = 30;
      final combinedWidth = cardImage.width + brandImage.width + 2 * padding;
      final combinedHeight = cardImage.height + 2 * padding;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
          recorder,
          ui.Rect.fromLTWH(
              0, 0, combinedWidth.toDouble(), combinedHeight.toDouble()));
      canvas.drawImage(cardImage,
          ui.Offset(padding.toDouble(), padding.toDouble()), ui.Paint());
      canvas.drawImage(
          brandImage,
          ui.Offset((padding + cardImage.width).toDouble(), padding.toDouble()),
          ui.Paint());
      final finalImage =
          await recorder.endRecording().toImage(combinedWidth, combinedHeight);
      final finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) {
        if (context.mounted) showCustomErrorSnackBar(context);
        return;
      }
      final pngBytes = finalByteData.buffer.asUint8List();
      // Generate filename based on asset type
      String fileName = '';
      if (asset is models.CurrencyAsset) {
        fileName = (asset as models.CurrencyAsset).symbol.toLowerCase();
      } else if (asset is models.GoldAsset) {
        fileName = (asset as models.GoldAsset).symbol.toLowerCase();
      } else if (asset is models.CryptoAsset) {
        fileName = (asset as models.CryptoAsset)
            .name
            .toLowerCase()
            .replaceAll(' ', '_');
      } else {
        fileName = asset.name.toLowerCase().replaceAll(' ', '_');
      }
      fileName = fileName.isNotEmpty ? fileName : 'asset_card';
      fileName += '.png';

      // Platform-specific sharing/saving
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final xFile = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
        );
        final params = ShareParams(
          files: [xFile],
          fileNameOverrides: [fileName],
          downloadFallbackEnabled: true,
        );
        await SharePlus.instance.share(params);
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Save to Downloads folder
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir == null) {
            throw Exception('Downloads directory not found');
          }
          final file = File('${downloadsDir.path}/$fileName');
          await file.writeAsBytes(pngBytes);
          if (context.mounted) {
            _showCustomSuccessSnackBar(context, fileName);
          }
        } catch (e) {
          if (context.mounted) showCustomErrorSnackBar(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomErrorSnackBar(context);
      }
    }
  }

  void _showCustomSuccessSnackBar(BuildContext context, String fileName) {
    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 180),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    final locale = Localizations.localeOf(context);
    final isRTL = locale.languageCode == 'fa';
    final l10n = AppLocalizations.of(context);
    final message = l10n.card_image_saved_to_downloads;
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: Material(
            elevation: 0,
            color: const ui.Color.fromARGB(255, 39, 197, 73),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                        color: Colors.white,
                      ),
                      textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
    overlay.insert(entry);
    controller.forward();
    Future.delayed(const Duration(seconds: 4), () async {
      await controller.reverse();
      entry.remove();
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Selectors for AppConfig
    final themeConfig = context.select<AppConfig, ThemeConfig>((config) =>
        isDarkMode ? config.themeOptions.dark : config.themeOptions.light);
    final cryptoIconFilterConfig =
        context.select<AppConfig, CryptoIconFilterConfig>(
            (config) => config.cryptoIconFilter);

    final tealGreen = hexToColor(themeConfig.accentColorGreen);

    // Selector for FavoritesNotifier
    final isFavorite = context.select<FavoritesNotifier, bool>(
        (notifier) => notifier.isFavorite(asset.id));

    // Selector for LocaleNotifier
    final currentLocale =
        context.select<LocaleNotifier, Locale>((notifier) => notifier.locale);

    // Selector for CurrencyUnitNotifier
    final currencyUnit = context.select<CurrencyUnitNotifier, CurrencyUnit>(
        (notifier) => notifier.unit);

    // Selector for CardCornerSettingsNotifier
    final cornerSettings =
        context.select<CardCornerSettingsNotifier, CardCornerSettings>(
            (notifier) => notifier.settings);

    final priceConversionData =
        context.select<CurrencyDataNotifier, _PriceConversionRates>((notifier) {
      if (notifier.items.isEmpty) {
        return const _PriceConversionRates.defaultValues();
      }
      num usdRate = 0;
      num eurRate = 0;
      try {
        usdRate = notifier.items.firstWhere((c) => c.symbol == 'USD').price;
        eurRate = notifier.items.firstWhere((c) => c.symbol == 'EUR').price;
      } catch (e) {
        return const _PriceConversionRates.defaultValues();
      }
      return _PriceConversionRates(
          usdToToman: usdRate, eurToToman: eurRate, ratesAvailable: true);
    });

    double numericPrice = 0.0;
    String displayUnit = '';
    num priceToConvert = asset.price;
    String originalUnitSymbol = '';

    if (asset is models.CurrencyAsset) {
      originalUnitSymbol = (asset as models.CurrencyAsset).unit;
    } else if (asset is models.GoldAsset) {
      originalUnitSymbol = (asset as models.GoldAsset).unit;
    } else if (asset is models.CryptoAsset) {
      originalUnitSymbol = "USD";
      if (currencyUnit == CurrencyUnit.toman) {
        priceToConvert = num.tryParse(
              (asset as models.CryptoAsset).priceToman.replaceAll(',', ''),
            ) ??
            asset.price;
        originalUnitSymbol = "تومان";
      }
    } else if (asset is models.StockAsset) {
      originalUnitSymbol = "ریال";
      priceToConvert = asset.price / 10;
    }

    if (priceConversionData.ratesAvailable) {
      num finalPrice = priceToConvert;
      if (currencyUnit == CurrencyUnit.toman) {
        if (originalUnitSymbol.toLowerCase() == "usd" ||
            originalUnitSymbol.toLowerCase() == "دلار") {
          finalPrice = priceToConvert * priceConversionData.usdToToman;
        } else if (originalUnitSymbol.toLowerCase() == "eur" ||
            originalUnitSymbol.toLowerCase() == "یورو") {
          finalPrice = priceToConvert * priceConversionData.eurToToman;
        }
        // If originalUnitSymbol is "تومان" or "ریال" (already converted to Toman for stocks), no change.
        displayUnit = l10n.currencyUnitToman;
        numericPrice = finalPrice.toDouble();
      } else if (currencyUnit == CurrencyUnit.usd) {
        if (originalUnitSymbol.toLowerCase() == "toman" ||
            originalUnitSymbol.toLowerCase() == "تومان" ||
            originalUnitSymbol.toLowerCase() == "ریال") {
          finalPrice = priceToConvert / priceConversionData.usdToToman;
        } else if (originalUnitSymbol.toLowerCase() == "eur" ||
            originalUnitSymbol.toLowerCase() == "یورو") {
          finalPrice = (priceToConvert * priceConversionData.eurToToman) /
              priceConversionData.usdToToman;
        }
        // No change if original is USD
        displayUnit = l10n.currencyUnitUSD;
        numericPrice = finalPrice.toDouble();
      } else if (currencyUnit == CurrencyUnit.eur) {
        if (originalUnitSymbol.toLowerCase() == "toman" ||
            originalUnitSymbol.toLowerCase() == "تومان" ||
            originalUnitSymbol.toLowerCase() == "ریال") {
          finalPrice = priceToConvert / priceConversionData.eurToToman;
        } else if (originalUnitSymbol.toLowerCase() == "usd" ||
            originalUnitSymbol.toLowerCase() == "دلار") {
          finalPrice = (priceToConvert * priceConversionData.usdToToman) /
              priceConversionData.eurToToman;
        }
        // No change if original is EUR
        displayUnit = l10n.currencyUnitEUR;
        numericPrice = finalPrice.toDouble();
      }
    } else {
      numericPrice = priceToConvert.toDouble();
      displayUnit = (asset is models.StockAsset)
          ? l10n.currencyUnitToman // Stocks default to Toman if rates missing
          : (asset is models.CryptoAsset)
              ? originalUnitSymbol // Use USD or تومان that we set earlier
              : (asset as dynamic).unit ?? '';
    }

    Widget iconWidget;
    if (assetType == AssetType.crypto &&
        (asset as models.CryptoAsset).iconUrl != null) {
      final double contrastValue = (1 + cryptoIconFilterConfig.contrast + 0.2);
      final matrix = <double>[
        contrastValue,
        0,
        0,
        0,
        cryptoIconFilterConfig.brightness * 255,
        0,
        contrastValue,
        0,
        0,
        cryptoIconFilterConfig.brightness * 255,
        0,
        0,
        contrastValue,
        0,
        cryptoIconFilterConfig.brightness * 255,
        0,
        0,
        0,
        1,
        0,
      ];
      final defaultGlow = isDarkMode
          ? const ui.Color.fromARGB(255, 116, 158, 177)
          : const ui.Color.fromARGB(255, 94, 150, 255);

      final String cryptoName =
          (asset as models.CryptoAsset).name.toLowerCase();
      final CryptoIconInfo? cryptoIconInfo = cryptoIconMap[cryptoName];

      if (cryptoIconInfo != null) {
        iconWidget = DynamicGlow(
          key: ValueKey('${asset.id}_local_icon'),
          imageProvider: AssetImage(cryptoIconInfo.iconPath),
          preferredGlowColor: cryptoIconInfo.color,
          defaultGlowColor: defaultGlow,
          size: 32.0,
          child: ClipOval(
            child: SvgPicture.asset(
              cryptoIconInfo.iconPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        iconWidget = DynamicGlow(
          key: ValueKey('${asset.id}_network_icon'),
          imageProvider: (kIsWeb
              ? NetworkImage((asset as models.CryptoAsset).iconUrl!)
              : CachedNetworkImageProvider(
                  (asset as models.CryptoAsset).iconUrl!)) as ImageProvider,
          defaultGlowColor: defaultGlow,
          size: 32.0,
          child: (_supportsColorFilter)
              ? ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrix),
                  child: _buildNetworkCryptoImage(
                      isDarkMode, asset as models.CryptoAsset),
                )
              : _buildNetworkCryptoImage(
                  isDarkMode, asset as models.CryptoAsset),
        );
      }
    } else if (assetType == AssetType.currency &&
        asset is models.CurrencyAsset) {
      String currencyCode =
          (asset as models.CurrencyAsset).symbol.toLowerCase();
      String countryCode = getCurrencyCountryCode(currencyCode);
      String flagPath = 'assets/icons/flags/$countryCode.svg';

      final flagColor = flagColors[countryCode] ?? tealGreen;

      Widget flagImage = SvgPicture.asset(
        flagPath,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        placeholderBuilder: (BuildContext context) => CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(
            (asset as models.CurrencyAsset).symbol.substring(0, 1),
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ),
      );

      if (_supportsColorFilter) {
        flagImage = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1.1,
            0,
          ]),
          child: flagImage,
        );
      }

      iconWidget = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: flagColor.withAlpha((255 * 0.5).round()),
              blurRadius: 60,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipOval(child: flagImage),
      );
    } else if (assetType == AssetType.gold) {
      final symbol = asset.symbol.toUpperCase();
      final String iconPath = getGoldIconPath(symbol);
      iconWidget = DynamicGlow(
        key: ValueKey('${asset.id}_gold_icon'),
        imageProvider: AssetImage(iconPath),
        defaultGlowColor: const Color(0x4DFFFF00), // yellow with 0.3 opacity
        size: 32.0,
        child: ClipOval(
          child:
              Image.asset(iconPath, width: 32, height: 32, fit: BoxFit.cover),
        ),
      );
    } else {
      // Fallback for stocks or missing icons
      final stockColor = isDarkMode
          ? const ui.Color.fromARGB(255, 116, 158, 177)
          : const ui.Color.fromARGB(255, 94, 150, 255);
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: stockColor.withAlpha((255 * 0.5).round()),
                blurRadius: 60,
                spreadRadius: 6),
          ],
        ),
        child: CircleAvatar(
          radius: 15,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          child: Text(
            asset.symbol.substring(0, math.min(asset.symbol.length, 1)),
            style:
                theme.textTheme.labelMedium?.copyWith(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    }

    String assetName =
        currentLocale.languageCode == 'fa' && asset is models.CryptoAsset
            ? (asset as models.CryptoAsset).nameFa
            : asset.name;
    if (currentLocale.languageCode == 'fa' && asset is models.CurrencyAsset) {
      assetName = asset.name;
    }
    if (currentLocale.languageCode == 'en' && asset is models.CurrencyAsset) {
      assetName = (asset as models.CurrencyAsset).nameEn;
    }
    if (currentLocale.languageCode == 'en' && asset is models.GoldAsset) {
      assetName = (asset as models.GoldAsset).nameEn;
    }

    iconWidget = Semantics(label: assetName, child: iconWidget);

    bool hasPersianChars = containsPersian(assetName);
    String nameFontFamily = hasPersianChars ? 'Vazirmatn' : 'SF-Pro';

    final accentColorGreen = tealGreen;
    final accentColorRed = isDarkMode
        ? hexToColor(themeConfig.accentColorRed)
        : hexToColor(themeConfig.accentColorRed);

    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isWideScreen = screenWidth >= 900;
    final bool useSmallDesktopText =
        isDesktop && (isTablet || isWideScreen) || isTablet;

    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.logEvent('card_tap', {
          'asset_type': assetType.toString().split('.').last,
          'asset_id': asset.id,
        });
        HapticFeedback.lightImpact();
      },
      onDoubleTap: () {
        AnalyticsService.instance.logEvent('pin_asset', {
          'asset_type': assetType.toString().split('.').last,
          'asset_id': asset.id,
        });
        Provider.of<FavoritesNotifier>(context, listen: false)
            .toggleFavorite(asset.id);
      },
      onLongPress: () => _shareCardImage(context),
      child: RepaintBoundary(
        key: _cardKey,
        child: SmoothCard(
          smoothness: cornerSettings.smoothness,
          borderRadius: BorderRadius.circular(cornerSettings.radius),
          elevation: 0,
          color: isDarkMode
              ? const Color(0xFF161616)
              : hexToColor(themeConfig.cardColor),
          child: SmoothClipRRect(
            borderRadius: BorderRadius.circular(cornerSettings.radius),
            smoothness: cornerSettings.smoothness,
            child: Container(
              decoration: BoxDecoration(
                // Cannot be const if theme changes
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [
                    theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        textDirection: ui.TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconWidget,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Seo.text(
                              text: assetName,
                              style: TextTagStyle.h2,
                              child: AutoSizeText(
                                assetName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: useSmallDesktopText
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: useSmallDesktopText ? 13 : 16,
                                  fontFamily: nameFontFamily,
                                ),
                                maxLines: 1,
                                minFontSize: useSmallDesktopText ? 11 : 14,
                                maxFontSize: useSmallDesktopText ? 14 : 17,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AssetCardBadges(
                          isFavorite: isFavorite,
                          tealGreen: tealGreen,
                          isDarkMode: isDarkMode,
                          assetType: assetType,
                          assetSymbol: asset.symbol),
                      const Spacer(),
                      if (asset.changePercent != null)
                        AnimatedAlign(
                          alignment: currentLocale.languageCode == 'en'
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          duration: const Duration(milliseconds: 400),
                          curve: const Cubic(0.77, 0, 0.175, 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment:
                                currentLocale.languageCode == 'en'
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                            children: currentLocale.languageCode == 'en'
                                ? [
                                    Text(
                                      '${formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: asset.changePercent! > 0
                                            ? accentColorGreen
                                            : asset.changePercent! < 0
                                                ? accentColorRed
                                                : Colors.grey,
                                        fontWeight: useSmallDesktopText
                                            ? FontWeight.w400
                                            : FontWeight.bold,
                                        fontSize: useSmallDesktopText ? 11 : 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      asset.changePercent! > 0
                                          ? CupertinoIcons.arrow_up_right
                                          : asset.changePercent! < 0
                                              ? CupertinoIcons.arrow_down_right
                                              : CupertinoIcons.minus,
                                      color: asset.changePercent! > 0
                                          ? accentColorGreen
                                          : asset.changePercent! < 0
                                              ? accentColorRed
                                              : Colors.grey,
                                      size: 12,
                                    ),
                                  ]
                                : [
                                    Icon(
                                      asset.changePercent! > 0
                                          ? CupertinoIcons.arrow_up_right
                                          : asset.changePercent! < 0
                                              ? CupertinoIcons.arrow_down_right
                                              : CupertinoIcons.minus,
                                      color: asset.changePercent! > 0
                                          ? accentColorGreen
                                          : asset.changePercent! < 0
                                              ? accentColorRed
                                              : Colors.grey,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: asset.changePercent! > 0
                                            ? accentColorGreen
                                            : asset.changePercent! < 0
                                                ? accentColorRed
                                                : Colors.grey,
                                        fontWeight: useSmallDesktopText
                                            ? FontWeight.w400
                                            : FontWeight.bold,
                                        fontSize: useSmallDesktopText ? 11 : 12,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedAlign(
                        alignment: currentLocale.languageCode == 'en'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(milliseconds: 400),
                        curve: const Cubic(0.77, 0, 0.175, 1),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: numericPrice),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutQuart,
                          builder: (context, value, child) {
                            final priceText =
                                formatPrice(value, currentLocale.languageCode);
                            return Seo.text(
                              text: priceText,
                              style: TextTagStyle.p,
                              child: AutoSizeText(
                                priceText,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: useSmallDesktopText
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: useSmallDesktopText ? 17 : 24,
                                  fontFamily: containsPersian(priceText)
                                      ? 'Vazirmatn'
                                      : 'SF-Pro',
                                ),
                                maxLines: 1,
                                minFontSize: useSmallDesktopText ? 13 : 18,
                                maxFontSize: useSmallDesktopText ? 18 : 28,
                                stepGranularity: 0.1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: currentLocale.languageCode == 'en'
                                    ? TextAlign.left
                                    : TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      AnimatedAlign(
                        alignment: currentLocale.languageCode == 'en'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(milliseconds: 400),
                        curve: const Cubic(0.77, 0, 0.175, 1),
                        child: Text(
                          displayUnit,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: useSmallDesktopText
                                ? FontWeight.w400
                                : FontWeight.w500,
                            fontSize: useSmallDesktopText ? 11 : 12,
                            fontFamily: containsPersian(displayUnit)
                                ? 'Vazirmatn'
                                : 'SF-Pro',
                          ),
                          textAlign: currentLocale.languageCode == 'en'
                              ? TextAlign.left
                              : TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildNetworkCryptoImage(bool isDarkMode, models.CryptoAsset asset) {
  if (kIsWeb) {
    return ClipOval(
      child: Image.network(
        asset.iconUrl!,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(CupertinoIcons.exclamationmark_circle, size: 16),
        ),
      ),
    );
  } else {
    return CachedNetworkImage(
      cacheManager: CryptoIconCacheManager(),
      imageUrl: asset.iconUrl!,
      width: 32,
      height: 32,
      imageBuilder: (context, imageProvider) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: const Icon(CupertinoIcons.exclamationmark_circle, size: 16),
      ),
    );
  }
}

// Helper class for selected price conversion rates
class _PriceConversionRates extends Equatable {
  final num usdToToman;
  final num eurToToman;
  final bool ratesAvailable;

  const _PriceConversionRates({
    required this.usdToToman,
    required this.eurToToman,
    required this.ratesAvailable,
  });

  @override
  List<Object?> get props => [usdToToman, eurToToman, ratesAvailable];

  const _PriceConversionRates.defaultValues()
      : usdToToman = 0,
        eurToToman = 0,
        ratesAvailable = false;
}
