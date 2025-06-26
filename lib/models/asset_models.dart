import 'package:equatable/equatable.dart';
import 'dart:math' as math; // For math.min used in CryptoAsset

// Base class for asset items to share common properties like ID for favorites
abstract class Asset extends Equatable {
  final String
      id; // Unique identifier for the asset (e.g., symbol or a combination)
  final String name;
  final String symbol;
  final num price;
  final num? changePercent;
  final num? changeValue; // For currencies/gold that have it

  const Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    this.changePercent,
    this.changeValue,
  });
}

// Currency Model
class CurrencyAsset extends Asset {
  final String nameEn;
  final String unit; // e.g., "تومان"
  final String? iconEmoji; // For flag emoji

  const CurrencyAsset({
    required super.id, // Use symbol as ID
    required super.name, // Persian name
    required this.nameEn,
    required super.symbol,
    required super.price,
    super.changeValue,
    super.changePercent,
    required this.unit,
    this.iconEmoji,
  });

  factory CurrencyAsset.fromJson(Map<String, dynamic> json) {
    return CurrencyAsset(
      id: json['symbol'] as String? ?? 'UNKNOWN',
      name: json['name'] as String? ?? 'نامشخص',
      nameEn: json['name_en'] as String? ?? 'Unknown',
      symbol: json['symbol'] as String? ?? '---',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changeValue: (json['change_value'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'تومان',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameEn,
        symbol,
        price,
        changeValue,
        changePercent,
        unit,
        iconEmoji,
      ];
}

// Gold Model (includes precious metals from commodity)
class GoldAsset extends Asset {
  final String nameEn;
  final String unit;
  final String? customIconPath; // For specific gold icons
  final bool isCommodity; // Indicates if this asset is a commodity

  const GoldAsset({
    required super.id,
    required super.name,
    required this.nameEn,
    required super.symbol,
    required super.price,
    super.changeValue,
    super.changePercent,
    required this.unit,
    this.customIconPath,
    this.isCommodity = false,
  });

  factory GoldAsset.fromJson(
    Map<String, dynamic> json, {
    bool isCommodity = false,
  }) {
    if (isCommodity) {
      return GoldAsset(
        id: json['symbol'] as String? ?? 'UNKNOWN_COMM',
        name: json['nameFa'] as String? ?? json['name'] as String? ?? 'نامشخص',
        nameEn: json['nameEn'] as String? ??
            json['symbol'] as String? ??
            'Unknown Commodity',
        symbol: json['symbol'] as String? ?? '---',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        changePercent: (json['change_percent'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? 'دلار', // Commodity unit might be USD
        customIconPath: _getGoldIconPath(json['symbol'] as String? ?? ''),
        isCommodity: true,
      );
    }
    return GoldAsset(
      id: json['symbol'] as String? ?? 'UNKNOWN_GOLD',
      name: json['nameFa'] as String? ?? json['name'] as String? ?? 'نامشخص',
      nameEn: json['nameEn'] as String? ??
          json['name_en'] as String? ??
          'Unknown Gold',
      symbol: json['symbol'] as String? ?? '---',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changeValue: (json['change_value'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'تومان',
      customIconPath: _getGoldIconPath(json['symbol'] as String? ?? ''),
      isCommodity: false,
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        nameEn,
        symbol,
        price,
        changeValue,
        changePercent,
        unit,
        customIconPath,
        isCommodity,
      ];
}

// Crypto Model
class CryptoAsset extends Asset {
  final String nameFa;
  final String priceToman; // String because API provides it as string
  final String? iconUrl;
  final num? marketCap;

  const CryptoAsset({
    required super.id, // Use name as ID for crypto as symbols might not be unique across exchanges
    required super.name, // English name
    required this.nameFa,
    required super.symbol, // This is often the ticker like BTC, ETH
    required super.price, // USD Price
    required this.priceToman,
    super.changePercent,
    this.iconUrl,
    this.marketCap,
  });

  factory CryptoAsset.fromJson(Map<String, dynamic> json) {
    String name = json['name'] as String? ?? 'Unknown';
    // API returns price as string for crypto, need to parse it
    num usdPrice = 0;
    if (json['price'] is String) {
      usdPrice = num.tryParse(json['price'] as String) ?? 0;
    } else if (json['price'] is num) {
      usdPrice = json['price'] as num;
    }

    return CryptoAsset(
      id: name.toLowerCase().replaceAll(' ', '-'), // Create a slug-like ID
      name: name,
      nameFa: json['nameFa'] as String? ?? 'نامشخص',
      symbol: json['symbol'] as String? ??
          (json['name'] as String? ?? '---')
              .substring(0, math.min(3, (json['name'] as String? ?? '').length))
              .toUpperCase(), // Fallback symbol
      price: usdPrice,
      priceToman: json['price_toman'] as String? ?? '0',
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      iconUrl: json['link_icon'] as String?,
      marketCap: json['market_cap'] as num?,
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        nameFa,
        symbol,
        price,
        priceToman,
        changePercent,
        iconUrl,
        marketCap,
      ];
}

// Stock Model
class StockAsset extends Asset {
  final String l30; // Full name
  final String isin;
  final num? pc; // Closing price
  final num? pcp; // Closing price change percentage
  final num? pl; // Last trade price
  final num? plp; // Last trade price change percentage

  const StockAsset(
    this.isin,
    this.pl, {
    required super.id, // Use ISIN as ID
    required super.name, // Use l18 (short name) as name
    required this.l30,
    required super.symbol, // Same as l18 or a derived symbol
    required super.price, // Use 'pl' (last trade price) as primary display price
    this.pc,
    this.pcp,
    this.plp,
    super.changePercent,
  });

  factory StockAsset.fromJson(Map<String, dynamic> json) {
    final isin = json['isin'] as String? ?? 'UNKNOWN_STOCK_${json['l18']}';
    final pl = (json['pl'] as num?)?.toDouble() ?? 0.0;

    return StockAsset(
      isin,
      pl,
      id: isin,
      name: json['l18'] as String? ?? 'نامشخص',
      l30: json['l30'] as String? ?? 'نام کامل نامشخص',
      symbol: json['l18'] as String? ?? '---',
      price: pl, // Last trade price
      pc: (json['pc'] as num?)?.toDouble(), // Closing price
      pcp: (json['pcp'] as num?)?.toDouble(), // Closing price change percent
      plp: (json['plp'] as num?)?.toDouble(), // Last trade price change percent
      changePercent: (json['plp'] as num?)
          ?.toDouble(), // Use last trade % change for consistency with Asset.changePercent
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        l30,
        symbol,
        price,
        pc,
        pcp,
        plp,
        changePercent,
      ];
}

// Helper function (originally in main.dart, moved here as it's used by GoldAsset)
String _getGoldIconPath(String symbol) {
  // Map gold symbols to specific SVG icons in assets/icons/
  // Example:
  // if (symbol == 'IR_GOLD_18K') return 'assets/icons/gold_18k.svg';
  // if (symbol == 'XAUUSD') return 'assets/icons/gold_ounce.svg';
  return 'assets/icons/gold_generic.svg'; // Fallback generic gold icon
}
