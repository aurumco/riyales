import 'package:intl/intl.dart'; // For NumberFormat
import 'dart:math' as math; // For math.min

String getGoldIconPath(String symbol) {
  const base = 'assets/icons/commodity/';
  final sym = symbol.toLowerCase();
  switch (sym) {
    case '18k':
      return '${base}18_carat.png';
    case '24k':
      return '${base}24_carat.png';
    case 'bahar':
      return '${base}bahar.png';
    case 'emami':
      return '${base}emami.png';
    case '1g':
      return '${base}1g.png';
    case 'melted':
      return '${base}melted.png';
    case 'half':
      return '${base}half.png';
    case 'quarter':
      return '${base}quarter.png';
    case 'xauusd':
      return '${base}gold_ounce.png';
    case 'xagusd':
      return '${base}silver_ounce.png';
    case 'xptusd':
    case 'xpdusd':
      return '${base}p_ounce.png';
    case 'cu':
    case 'al':
    case 'zn':
    case 'pb':
    case 'ni':
    case 'sn':
      return '${base}element.png';
    case 'brent':
    case 'wti':
    case 'opec':
      return '${base}oil.png';
    case 'gasoil':
    case 'rbob':
      return '${base}gas_oil.png';
    case 'gas':
      return '${base}gas.png';
    default:
      return '${base}blank.png';
  }
}

String formatPrice(num price, String locale, {bool showSign = false}) {
  // Use NumberFormat for locale-aware formatting
  final format = NumberFormat.currency(
    locale: locale == 'fa'
        ? 'fa_IR'
        : 'en_US', // fa_IR for Persian numerals and grouping
    symbol: '', // No currency symbol, unit is separate
    decimalDigits: (price < 10 && price != 0 && price.remainder(1) != 0)
        ? 4
        : (price < 1000 ? 2 : 0), // More decimals for small prices
  );
  String formattedPrice = format.format(price);
  if (showSign && price > 0) {
    formattedPrice = '+$formattedPrice';
  }
  return formattedPrice;
}

String formatPercentage(num percentage, String locale) {
  final format = NumberFormat("#,##0.##", locale == 'fa' ? 'fa_IR' : 'en_US');
  return format.format(percentage);
}

// Add new helper functions
// Helper for mapping currency codes to country codes
String getCurrencyCountryCode(String currencyCode) {
  // Map of currency codes to ISO country codes
  Map<String, String> currencyToCountry = {
    'usd': 'us',
    'eur': 'eu', // European Union
    'gbp': 'gb',
    'jpy': 'jp',
    'cad': 'ca',
    'aud': 'au',
    'chf': 'ch',
    'cny': 'cn',
    'aed': 'ae',
    'try': 'tr',
    'rub': 'ru',
    'inr': 'in',
    'brl': 'br',
    'myr': 'my',
    'sgd': 'sg',
    'nzd': 'nz',
    'hkd': 'hk',
    'sek': 'se',
    'nok': 'no',
    'dkk': 'dk',
    'mxn': 'mx',
    'zar': 'za',
    'thb': 'th',
    'krw': 'kr',
    'pkr': 'pk',
    'pln': 'pl',
    'czk': 'cz',
    'ils': 'il',
    'twd': 'tw',
    'idr': 'id',
    'php': 'ph',
    'rsd': 'rs',
    'egp': 'eg',
    'sar': 'sa',
    'qar': 'qa',
    'bhd': 'bh',
    'omr': 'om',
    'kwd': 'kw',
    'irr': 'ir',
    'afn': 'af',
    'dzd': 'dz',
    'jod': 'jo',
    'lbp': 'lb',
    'mad': 'ma',
    'tnd': 'tn',
    'azn': 'az',
  };

  return currencyToCountry[currencyCode] ??
      currencyCode.substring(0, math.min(currencyCode.length, 2));
}

// Helper to detect Persian text
bool containsPersian(String text) {
  // Unicode range for Arabic and Persian characters
  final RegExp persianChars = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  return persianChars.hasMatch(text);
}
