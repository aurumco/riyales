import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../asset_list_page.dart';
import '../../../providers/search_provider.dart';
// Specific data provider imports (assuming they will export the provider variables for now)
import '../../../providers/data_providers/currency_data_provider.dart';
import '../../../providers/data_providers/gold_data_provider.dart';
import '../../../providers/data_providers/crypto_data_provider.dart';
import '../../../providers/data_providers/stock_tse_ifb_data_provider.dart';
// import '../../../providers/data_providers/stock_debt_securities_data_provider.dart'; // If needed
// import '../../../providers/data_providers/stock_futures_data_provider.dart'; // If needed
// import '../../../providers/data_providers/stock_housing_facilities_data_provider.dart'; // If needed

import '../../../models/asset_models.dart' as models;
import '../../../utils/helpers.dart'; // For containsPersian
// import '../../../providers/locale_provider.dart';
import 'package:provider/provider.dart'; // Added Provider

class AssetSearchDelegate extends SearchDelegate<String> {
  // final WidgetRef ref; // Removed ref
  final SearchQueryNotifier searchQueryNotifier; // Pass Notifier directly
  final int currentTabIndex;
  late final TextEditingController queryTextEditingController;

  AssetSearchDelegate({
    // required this.ref, // Removed
    required this.searchQueryNotifier,
    required this.currentTabIndex,
  }) {
    queryTextEditingController = TextEditingController(text: query);
    // Listener might not be needed if query is updated directly via searchQueryNotifier
    queryTextEditingController.addListener(() {
      if (queryTextEditingController.text != query) {
        // This delegate's 'query' field is automatically updated by SearchDelegate
        // We need to sync it with our external notifier if we want two-way binding
        // For now, let SearchDelegate handle its internal query state primarily.
        // The external notifier is updated in buildSuggestions/buildResults.
      }
    });
  }

  @override
  void close(BuildContext context, String result) {
    // Reset search query using the passed notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchQueryNotifier.query = '';
    });
    queryTextEditingController.dispose();
    super.close(context, result);
  }

  // searchFieldLabel is now built in buildSearchField or passed via constructor if needed earlier.
  // For simplicity, we'll use AppLocalizations directly in buildSearchField.

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Hide clear action since we have it in the search field itself
    if (query.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 30,
          child: Text(
            AppLocalizations.of(context)!
                .dialogClose, // Changed to use AppLocalizations
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontFamily: 'SF-Pro', // iOS system font
              fontWeight: FontWeight.w400,
            ),
          ),
          onPressed: () {
            query = '';
            queryTextEditingController.clear(); // Also clear controller
            showSuggestions(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Not used
    final bool isRTL = Localizations.localeOf(context).languageCode == 'fa';

    // iOS-style back button
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
      searchQueryNotifier.query = query; // Update external notifier
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
      searchQueryNotifier.query = query; // Update external notifier
    });

    ui.TextDirection direction =
        isRTLQuery ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: _buildFilteredList(context),
    );
  }

  Widget _buildFilteredList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget listToShow;
    // Based on currentTabIndex, watch the appropriate notifier and pass data to AssetListPage.
    // Note: AssetListPage itself uses searchQueryNotifier via context.watch for filtering.
    switch (currentTabIndex) {
      case 0: // Currency
        final currencyNotifier = Provider.of<CurrencyDataNotifier>(context);
        listToShow = AssetListPage<models.CurrencyAsset>(
          items: currencyNotifier.items,
          fullItemsListForSearch: currencyNotifier.fullDataList,
          isLoading: currencyNotifier.isLoading,
          error: currencyNotifier.error,
          onRefresh: () => currencyNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => currencyNotifier.loadMore(),
          onInitialize: () => currencyNotifier
              .fetchInitialData(), // May not be strictly needed here if already loaded
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
          onLoadMore: () => goldNotifier.loadMore(),
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
          onLoadMore: () => cryptoNotifier.loadMore(),
          onInitialize: () => cryptoNotifier.fetchInitialData(),
          assetType: AssetType.crypto,
        );
        break;
      case 3: // Stock - Assuming TSE/IFB for the generic stock search for now
        final stockTseIfbNotifier =
            Provider.of<StockTseIfbDataNotifier>(context);
        listToShow = AssetListPage<models.StockAsset>(
          items: stockTseIfbNotifier.items,
          fullItemsListForSearch: stockTseIfbNotifier.fullDataList,
          isLoading: stockTseIfbNotifier.isLoading,
          error: stockTseIfbNotifier.error,
          onRefresh: () =>
              stockTseIfbNotifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => stockTseIfbNotifier.loadMore(),
          onInitialize: () => stockTseIfbNotifier.fetchInitialData(),
          assetType: AssetType
              .stock, // This might need to be more specific if StockPage uses this delegate
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
            isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : Colors.black, size: 22),
        toolbarHeight: 44.0,
      ),
      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
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

    final bgColor = isDarkMode
        ? const Color(0xFF2C2C2E) // Slightly darker than nav bar for contrast
        : const Color(0xFFE5E5EA);

    bool isRTLQuery = containsPersian(query); // from utils/helpers.dart
    String fontFamily = isRTLQuery ? 'Vazirmatn' : 'SF-Pro';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoTextField(
        controller: queryTextEditingController,
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
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
        decoration: BoxDecoration(
          color: Colors.transparent, // Handled by outer container
          borderRadius: BorderRadius.circular(10),
        ),
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
                    minSize: 30,
                    child: Icon(
                      CupertinoIcons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      size: 18,
                    ),
                    onPressed: () {
                      query = '';
                      queryTextEditingController.clear();
                      showSuggestions(context);
                    },
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
          // query = newQuery; // Already handled by listener
          // Update text direction and font as user types
          final isRTL = containsPersian(newQuery); // from utils/helpers.dart
          if (isRTL != isRTLQuery) {
            // Force rebuild of suggestions with new direction if RTL status changed
            // This is a bit tricky as showSuggestions rebuilds the whole delegate.
            // The controller listener handles query state, this onChanged handles UI update.
            showSuggestions(context);
          } else {
            showSuggestions(context);
          }
        },
        onSubmitted: (String _) {
          // Ensure search results are shown on submit
          showResults(context);
        },
      ),
    );
  }
}
