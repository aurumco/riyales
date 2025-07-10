import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Added Provider
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/asset_models.dart' as models;
import '../../models/crypto_icon_info.dart';
import '../../config/app_config.dart'; // For AppConfig type
import '../widgets/asset_list_page.dart'; // Re-added import for AssetType
import '../../providers/locale_provider.dart';
import '../../providers/currency_unit_provider.dart'; // For CurrencyUnit enum and Notifier
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
// Import the new widget
// Removed: import '../widgets/asset_list_page.dart';

// Create a dedicated cache manager with smaller capacity for crypto icons
class CryptoIconCacheManager extends CacheManager {
  static const key = 'cryptoIconCache';
  
  static final CryptoIconCacheManager _instance = CryptoIconCacheManager._();
  factory CryptoIconCacheManager() => _instance;
  
  CryptoIconCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100, // Limit cache size
    repo: JsonCacheInfoRepository(databaseName: key),
  ));
}

// Helper to detect if the web build is using CanvasKit or HTML renderer.
// Flutter defines the compile-time env var FLUTTER_WEB_USE_SKIA=true for CanvasKit builds.
const bool _isCanvasKit = bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);
bool get _supportsColorFilter => !kIsWeb || _isCanvasKit;

// Define manual crypto icon mapping constant at top level before AssetCard
// Manually map cryptos to their asset icons by name
const Map<String, CryptoIconInfo> cryptoIconMap = {
  'bitcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/btc.svg',
    color: Color(0xFFF7931A), // Orange/gold for Bitcoin
  ),
  'ethereum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ethereum.svg',
    color: Color(0xFF627EEA), // Blue/purple for Ethereum
  ),
  'tether': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Tether.svg',
    color: Color(0xFF50AF95), // Teal for Tether
  ),
  'xrp': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ripple.svg',
    color: Color(0xFF00AEEF), // Blue for Ripple
  ),
  'binance coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Binance Coin (BNB).svg',
    color: Color(0xFFF0B90B), // Gold/yellow for Binance Coin
  ),
  'usd coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/usd.svg',
    color: Color(0xFF82BC67), // Green for USD Coin
  ),
  'dogecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dogecoin (DOGE).svg',
    color: Color(0xFFCB9800), // Gold for Dogecoin
  ),
  'cardano': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Cardano.svg',
    color: Color(0xFF00AD99), // Teal for Cardano
  ),
  'litecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/lite.svg',
    color: Color(0xFF029404), // Green for Litecoin
  ),
  'monero': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Monero.svg',
    color: Color(0xFFFF6600), // Orange for Monero
  ),
  'ethereum classic': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ethereum Classic (ETH).svg',
    color: Color(0xFF39B339), // Green for Ethereum Classic
  ),
  'stellar': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Stellar.svg',
    color: Color(0xFF00ADEF), // Blue for Stellar
  ),
  'bitcoin cash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Bitcoin Cash.svg',
    color: Color(0xFF8DC351), // Green for Bitcoin Cash
  ),
  'litecoin cash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Litecoin Cash (LCC).svg',
    color: Color(0xFF19191A), // Silver like Litecoin
  ),
  'nem': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/NEM (XEM).svg',
    color: Color(0xFF4FC8AE), // Teal for NEM
  ),
  'nano': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/nano (NANO).svg',
    color: Color(0xFF4A90E2), // Blue for Nano
  ),
  'tezos': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Tezos (XTZ).svg',
    color: Color(0xFF3286E2), // Blue for Tezos
  ),
  'eos': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/EOS.svg',
    color: Color(0xFF19191A), // Black/dark gray for EOS
  ),
  'decred': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Decred (DCR).svg',
    color: Color(0xFF4772D6), // Blue/purple for Decred
  ),
  'vechain': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/VeChain (VET).svg',
    color: Color(0xFF896BC7), // Purple for VeChain
  ),
  'ontology': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ontology (ONT).svg',
    color: Color(0xFF36A9AE), // Teal for Ontology
  ),
  'syscoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Syscoin (SYS).svg',
    color: Color(0xFF0089BC), // Blue for Syscoin
  ),
  'digibyte': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/DigiByte (DGB).svg',
    color: Color(0xFF0074B4), // Blue for DigiByte
  ),
  'verge': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Verge (XVG).svg',
    color: Color(0xFF40CCEA), // Cyan for Verge
  ),
  'siacoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Siacoin (SC).svg',
    color: Color(0xFF00CBA1), // Teal for Siacoin
  ),
  'namecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Namecoin (NMC).svg',
    color: Color(0xFF4FC8AE), // Teal for Namecoin
  ),
  'horizen': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Horizen (ZEN).svg',
    color: Color(0xFF2C84DF), // Blue for Horizen
  ),
  'waves': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Waves (WAVES).svg',
    color: Color(0xFF2F82DE), // Blue for Waves
  ),
  'nuls': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Nuls (NULS).svg',
    color: Color(0xFF65A034), // Green for NULS
  ),
  'dash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/dash.svg',
    color: Color(0xFF008CE7), // Blue for Dash
  ),
  'wanchain': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Wanchain.svg',
    color: Color(0xFF266187), // Dark blue for Wanchain
  ),
  'zilliqa': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Zilliqa (ZIL).svg',
    color: Color(0xFF48C9B9), // Teal for Zilliqa
  ),
  'qtum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Qtum (QTUM).svg',
    color: Color(0xFF00B8DC), // Blue for Qtum
  ),
  'basic attention token': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Basic Attention Token.svg',
    color: Color(0xFFFF5200), // Orange for BAT
  ),
  'neo': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/NEO.svg',
    color: Color(0xFF58B700), // Green for Neo
  ),
  'particl': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Particl (PART).svg',
    color: Color(0xFF50AF95), // Green for Particl
  ),
  'whitecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/WhiteCoin (XWC).svg',
    color: Color(0xFF8d51ea), // Purple for WhiteCoin
  ),
  'smartcash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/SmartCash (SMART).svg',
    color: Color(0xFFf4b711), // Yellow for SmartCash
  ),
  'steem': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Steem (STEEM).svg',
    color: Color(0xFF4682B4), // Blue for Steem
  ),
  'steem dollars': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Steem Dollars (SBD).svg',
    color: Color(0xFF4682B4), // Blue for Steem Dollars (same as Steem)
  ),
  'primecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Primecoin (XPM).svg',
    color: Color(0xFFF99D1C), // Orange for Primecoin
  ),
  'lbry credits': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/LBRY Credits (LBC).svg',
    color: Color(0xFF19191A), // Orange for LBRY
  ),
  'callisto network': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Callisto Network (CLO).svg',
    color: Color(0xFF51B06F), // Green for Callisto Network
  ),
  'cloakcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/CloakCoin (CLOAK).svg',
    color: Color(0xFFea3b21), // Red for CloakCoin
  ),
  'colossusxt': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ColossusXT (COLX).svg',
    color: Color(0xFF53a278), // Green for ColossusXT
  ),
  'counterparty': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Counterparty (XCP).svg',
    color: Color(0xFFeb154e), // Pink for Counterparty
  ),
  'crown': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Crown (CRW).svg',
    color: Color(0xFF126343), // Dark green for Crown
  ),
  'dero': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dero (DERO).svg',
    color: Color(0xFF00223B), // Dark blue for Dero
  ),
  'dent': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dent (DENT).svg',
    color: Color(0xFF19191A), // Green for Dent
  ),
  'electroneum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Electroneum (ETN).svg',
    color: Color(0xFF2180FF), // Blue for Electroneum
  ),
  'gamecredits': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/GameCredits (GAME).svg',
    color: Color(0xFF19191A), // Orange for GameCredits
  ),
  'nimiq': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Nimiq (NIM).svg',
    color: Color(0xFFf6ae2d), // Yellow for Nimiq
  ),
  'omisego': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/OmiseGO (OMG).svg',
    color: Color(0xFF1A53F0), // Blue for OmiseGO
  ),
  'pascal coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Pascal Coin (PASC).svg',
    color: Color(0xFFF09033), // Orange for Pascal Coin
  ),
  'peercoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Peercoin (PPC).svg',
    color: Color(0xFF3EB049), // Green for Peercoin
  ),
  'pivx': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/PIVX (PIVX).svg',
    color: Color(0xFF4C2757), // Purple for PIVX
  ),
  'power ledger': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Power Ledger (POWR).svg',
    color: Color(0xFF29af92), // Green for Power Ledger
  ),
  'prizm': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/PRIZM (PZM).svg',
    color: Color(0xFF700366), // Cyan for PRIZM
  ),
  'trueusd': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/TrueUSD (TUSD).svg',
    color: Color(0xFF6cb0fd), // Blue for TrueUSD
  ),
  'vertcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Vertcoin (VTC).svg',
    color: Color(0xFF046B2D), // Green for Vertcoin
  ),
  'xtrabytes': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/XTRABYTES (XBY).svg',
    color: Color(0xFF00B0FF), // Blue for XTRABYTES
  ),
  'zclassic': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ZClassic (ZCL).svg',
    color: Color(0xFF423C32), // Dark brown for ZClassic
  ),
  'aelf': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Baelf (ELF).svg',
    color: Color(0xFF305B9C), // Blue for aelf
  ),
  'bytecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Bytecoin (BCN).svg',
    color: Color(0xFF402660), // Purple for Bytecoin
  ),
  'zcash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/zec.svg',
    color: Color(0xFFF3BA2F), // Yellow/gold for Zcash
  ),
};

class AssetCard extends StatelessWidget {
  // Changed to StatelessWidget
  final models.Asset asset;
  final AssetType assetType;
  // final double? height;

  const AssetCard({
    super.key,
    required this.asset,
    required this.assetType /*this.height*/,
  });

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

    // Data for price conversion
    final priceConversionData =
        context.select<CurrencyDataNotifier, _PriceConversionRates>((notifier) {
      if (notifier.items.isEmpty) {
        // Use the new const constructor
        return const _PriceConversionRates.defaultValues();
      }
      num usdRate = 0;
      num eurRate = 0;
      try {
        usdRate = notifier.items.firstWhere((c) => c.symbol == 'USD').price;
        eurRate = notifier.items.firstWhere((c) => c.symbol == 'EUR').price;
      } catch (e) {
        // Handle case where USD/EUR might not be in the list, though unlikely for core function
        // Use the new const constructor
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
      originalUnitSymbol = "USD"; // Base currency for crypto prices from API
      if (currencyUnit == CurrencyUnit.toman) {
        // If target is Toman, and API provides priceToman, use it directly
        priceToConvert = num.tryParse(
              (asset as models.CryptoAsset).priceToman.replaceAll(',', ''),
            ) ??
            asset.price; // Fallback to USD price if toman price parsing fails
        originalUnitSymbol = "تومان"; // Now effectively dealing with Toman
      }
    } else if (asset is models.StockAsset) {
      originalUnitSymbol = "ریال"; // Stocks are in Rial
      priceToConvert = asset.price /
          10; // Convert Rial to Toman for internal consistency if needed
      // If currencyUnit is Toman, this is fine. If USD/EUR, further conversion happens below.
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
          : (asset is models.CryptoAsset && originalUnitSymbol == "USD"
              ? "USD" // Crypto defaults to USD if rates missing
              : (asset as dynamic).unit ?? '');
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
                  : CachedNetworkImageProvider((asset as models.CryptoAsset).iconUrl!))
              as ImageProvider,
          defaultGlowColor: defaultGlow,
          size: 32.0,
          child: (_supportsColorFilter)
              ? ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrix),
                  child: _buildNetworkCryptoImage(isDarkMode, asset as models.CryptoAsset),
                )
              : _buildNetworkCryptoImage(isDarkMode, asset as models.CryptoAsset),
        );
      }
    } else if (assetType == AssetType.currency &&
        asset is models.CurrencyAsset) {
      String currencyCode =
          (asset as models.CurrencyAsset).symbol.toLowerCase();
      String countryCode = getCurrencyCountryCode(currencyCode);
      String flagPath = 'assets/icons/flags/$countryCode.svg';

      // flagColors map remains as it's static data
      final Map<String, Color> flagColors = {
        'us': const Color(0xFFB7082A),
        'eu': const Color(0xFF0153B4),
        'ae': const Color(0xFF6DA445),
        'gb': const Color(0xFFD80027),
        'jp': const Color(0xFFD80027),
        'kw': const Color(0xFF6DA445),
        'au': const Color(0xFF0654B5),
        'ca': const Color(0xFFD80027),
        'cn': const Color(0xFFD80127),
        'tr': const Color(0xFFD80027),
        'sa': const Color(0xFF527538),
        'ch': const Color(0xFFD9042B),
        'in': const Color(0xFFFE9B17),
        'pk': const Color(0xFF486F2D),
        'iq': const Color(0xFFA30221),
        'sy': const Color(0xFF486F2D),
        'se': const Color(0xFF0D59AE),
        'qa': const Color(0xFF741B46),
        'om': const Color(0xFF709C42),
        'bh': const Color(0xFFD80027),
        'af': const Color(0xFF486F2D),
        'my': const Color(0xFF105BAD),
        'th': const Color(0xFF0153B4),
        'ru': const Color(0xFFD80027),
        'az': const Color(0xFF6DA445),
        'am': const Color(0xFFFF9811),
        'ge': const Color(0xFFD9082C),
      };
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
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1.1, 0,
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
            // This list cannot be const if stockColor is not const
            BoxShadow(
                color: stockColor.withAlpha((255 * 0.5).round()),
                blurRadius: 60,
                spreadRadius: 6),
          ],
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          child: Text(
            // This Text cannot be const
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

    bool hasPersianChars = containsPersian(assetName);
    String nameFontFamily = hasPersianChars ? 'Vazirmatn' : 'SF-Pro';

    final accentColorGreen = tealGreen;
    final accentColorRed = isDarkMode
        ? hexToColor(themeConfig.accentColorRed)
        : hexToColor(themeConfig.accentColorRed);

    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.logEvent('card_tap', {
          'asset_type': assetType.toString().split('.').last,
          'asset_id': asset.id,
        });
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        AnalyticsService.instance.logEvent('pin_asset', {
          'asset_type': assetType.toString().split('.').last,
          'asset_id': asset.id,
        });
        Provider.of<FavoritesNotifier>(context, listen: false)
            .toggleFavorite(asset.id);
      },
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
                          child: AutoSizeText(
                            assetName, // Dynamic
                            style: theme.textTheme.titleMedium?.copyWith(
                              // Dynamic
                              fontWeight: FontWeight.bold,
                              fontFamily: nameFontFamily, // Dynamic
                            ),
                            maxLines: 1,
                            minFontSize: 14,
                            maxFontSize: 17,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
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
                          mainAxisAlignment: currentLocale.languageCode == 'en'
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: currentLocale.languageCode == 'en'
                              ? [
                                  Text(
                                    // Dynamic
                                    '${formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      // Dynamic
                                      color: asset.changePercent! > 0
                                          ? accentColorGreen
                                          : asset.changePercent! < 0
                                              ? accentColorRed
                                              : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    // Dynamic
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
                                    // Dynamic
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
                                    // Dynamic
                                    '${formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      // Dynamic
                                      color: asset.changePercent! > 0
                                          ? accentColorGreen
                                          : asset.changePercent! < 0
                                              ? accentColorRed
                                              : Colors.grey,
                                      fontWeight: FontWeight.bold,
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
                          return AutoSizeText(
                            priceText, // Dynamic
                            style: theme.textTheme.headlineSmall?.copyWith(
                              // Dynamic
                              fontWeight: FontWeight.bold,
                              fontFamily: containsPersian(priceText)
                                  ? 'Vazirmatn'
                                  : 'SF-Pro', // Dynamic
                            ),
                            maxLines: 1,
                            minFontSize: 18,
                            maxFontSize: 28,
                            stepGranularity: 0.1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: currentLocale.languageCode == 'en'
                                ? TextAlign.left
                                : TextAlign.right,
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
                        // Dynamic
                        displayUnit,
                        style: theme.textTheme.labelMedium?.copyWith(
                          // Dynamic
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: containsPersian(displayUnit)
                              ? 'Vazirmatn'
                              : 'SF-Pro', // Dynamic
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

  // Added const constructor for potential optimization if an instance with default values is frequently used.
  const _PriceConversionRates.defaultValues()
      : usdToToman = 0,
        eurToToman = 0,
        ratesAvailable = false;
}
