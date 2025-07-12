// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Dart imports
import 'dart:ui' as ui;

// Third-party packages
import 'package:smooth_corner/smooth_corner.dart';
import 'package:provider/provider.dart';

// Local project imports
import '../../../localization/l10n_utils.dart';
import '../../../utils/helpers.dart';
import '../../../models/asset_models.dart' as models;
import '../../../providers/search_provider.dart';
import '../../../providers/data_providers/currency_data_provider.dart';
import '../../../providers/data_providers/gold_data_provider.dart';
import '../../../providers/data_providers/crypto_data_provider.dart';
import '../../../providers/data_providers/stock_tse_ifb_data_provider.dart';
import '../asset_list_page.dart';

/// A search delegate that filters and displays assets across different categories.
class AssetSearchDelegate extends SearchDelegate<String> {
  final SearchQueryNotifier searchQueryNotifier;
  final int currentTabIndex;
  late final TextEditingController queryTextEditingController;

  /// Creates an [AssetSearchDelegate] with the provided notifier and tab index.
  AssetSearchDelegate({
    required this.searchQueryNotifier,
    required this.currentTabIndex,
  }) {
    queryTextEditingController = TextEditingController(text: query);
    queryTextEditingController.addListener(() {
      // No-op: SearchDelegate manages query state; external notifier updated in buildSuggestions/buildResults.
    });
  }

  @override
  void close(BuildContext context, String result) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchQueryNotifier.query = '';
    });
    queryTextEditingController.dispose();
    super.close(context, result);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            query = '';
            queryTextEditingController.clear();
            showSuggestions(context);
          },
          minimumSize: Size(30, 30),
          child: Text(
            AppLocalizations.of(context).dialogClose,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontFamily: 'SF-Pro',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final bool isRTL = Localizations.localeOf(context).languageCode == 'fa';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => close(context, ''),
        child: Icon(
          isRTL ? CupertinoIcons.forward : CupertinoIcons.back,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final bool isRTLQuery = containsPersian(query);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchQueryNotifier.query = query;
    });

    ui.TextDirection direction =
        isRTLQuery ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: _buildFilteredList(context),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final bool isRTLQuery = containsPersian(query);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchQueryNotifier.query = query;
    });

    ui.TextDirection direction =
        isRTLQuery ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: _buildFilteredList(context),
    );
  }

  Widget _buildFilteredList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget listToShow;
    switch (currentTabIndex) {
      case 0:
        final currencyNotifier = Provider.of<CurrencyDataNotifier>(context);
        listToShow = AssetListPage<models.CurrencyAsset>(
          items: currencyNotifier.items,
          fullItemsListForSearch: currencyNotifier.fullDataList,
          isLoading: currencyNotifier.isLoading,
          error: currencyNotifier.error,
          onRefresh: () => currencyNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => currencyNotifier.fetchInitialData(isLoadMore: true),
          onInitialize: () => currencyNotifier.fetchInitialData(),
          assetType: AssetType.currency,
        );
        break;
      case 1: // Gold
        final goldNotifier = Provider.of<GoldDataNotifier>(context);
        listToShow = AssetListPage<models.GoldAsset>(
          items: goldNotifier.items,
          fullItemsListForSearch: goldNotifier.fullDataList,
          isLoading: goldNotifier.isLoading,
          error: goldNotifier.error,
          onRefresh: () => goldNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () =>
              goldNotifier.fetchInitialData(isLoadMore: true), // Changed
          onInitialize: () => goldNotifier.fetchInitialData(),
          assetType: AssetType.gold,
        );
        break;
      case 2: // Crypto
        final cryptoNotifier = Provider.of<CryptoDataNotifier>(context);
        listToShow = AssetListPage<models.CryptoAsset>(
          items: cryptoNotifier.items,
          fullItemsListForSearch: cryptoNotifier.fullDataList,
          isLoading: cryptoNotifier.isLoading,
          error: cryptoNotifier.error,
          onRefresh: () => cryptoNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () =>
              cryptoNotifier.fetchInitialData(isLoadMore: true), // Changed
          onInitialize: () => cryptoNotifier.fetchInitialData(),
          assetType: AssetType.crypto,
        );
        break;
      case 3: // Stock - Assuming TSE/IFB for the generic stock search
        final stockTseIfbNotifier =
            Provider.of<StockTseIfbDataNotifier>(context);
        listToShow = AssetListPage<models.StockAsset>(
          items: stockTseIfbNotifier.items,
          fullItemsListForSearch: stockTseIfbNotifier.fullDataList,
          isLoading: stockTseIfbNotifier.isLoading,
          error: stockTseIfbNotifier.error,
          onRefresh: () =>
              stockTseIfbNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () =>
              stockTseIfbNotifier.fetchInitialData(isLoadMore: true), // Changed
          onInitialize: () => stockTseIfbNotifier.fetchInitialData(),
          assetType: AssetType.stock,
        );
        break;
      default:
        listToShow = Center(child: Text(l10n.searchNoResults));
    }

    return listToShow;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor:
            isDarkMode ? const Color(0xFF090909) : const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : Colors.black, size: 22),
        toolbarHeight: 44.0,
      ),
      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF090909) : const Color(0xFFF2F2F7),
      dividerTheme: DividerThemeData(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          thickness: 0.5,
          space: 0.5),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
            fontFamily: 'SF-Pro',
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 17),
        bodyMedium: TextStyle(
            fontFamily: 'SF-Pro',
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.colorScheme.primary,
        selectionColor: theme.colorScheme.primary.withAlpha(77),
        selectionHandleColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFE5E5EA);

    bool isRTLQuery = containsPersian(query);
    String fontFamily = isRTLQuery ? 'Vazirmatn' : 'SF-Pro';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 40,
      child: Container(
        decoration: ShapeDecoration(
          color: bgColor,
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            smoothness: 0.75,
          ),
        ),
        child: CupertinoTextField(
          controller: queryTextEditingController,
          padding: EdgeInsets.only(
            top: 11,
            bottom: 11,
            left: isRTLQuery ? 8 : 30,
            right: isRTLQuery ? 30 : 8,
          ),
          textInputAction: TextInputAction.search,
          textAlign: isRTLQuery ? TextAlign.right : TextAlign.left,
          textAlignVertical: TextAlignVertical.center,
          placeholderStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          decoration: null,
          prefix: isRTLQuery
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    CupertinoIcons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 18,
                  ),
                ),
          suffix: isRTLQuery
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    CupertinoIcons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 18,
                  ),
                )
              : query.isNotEmpty
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        query = '';
                        queryTextEditingController.clear();
                        showSuggestions(context);
                      },
                      minimumSize: Size(30, 30),
                      child: Icon(
                        CupertinoIcons.clear,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                    )
                  : null,
          placeholder: searchFieldLabel,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          cursorColor: theme.colorScheme.primary,
          cursorWidth: 1.5,
          onChanged: (newQuery) {
            final isRTL = containsPersian(newQuery);
            if (isRTL != isRTLQuery) {
              showSuggestions(context);
            } else {
              showSuggestions(context);
            }
          },
          onSubmitted: (String _) {
            showResults(context);
          },
        ),
      ),
    );
  }
}
