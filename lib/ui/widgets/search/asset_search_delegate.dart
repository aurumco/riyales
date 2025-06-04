import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../asset_list_page.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/data_providers/data_providers.dart';
import '../../../models/asset_models.dart' as models;
import '../../../utils/helpers.dart'; // For _containsPersian

class AssetSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  final int currentTabIndex; // To know which asset type to search
  late final TextEditingController queryTextEditingController;

  AssetSearchDelegate({required this.ref, required this.currentTabIndex}) {
    queryTextEditingController = TextEditingController(text: query);
    queryTextEditingController.addListener(() {
      if (queryTextEditingController.text != query) {
        query = queryTextEditingController.text;
      }
    });
  }

  @override
  void close(BuildContext context, String result) {
    // Reset search query when closing search screen
    WidgetsBinding.instance.addPostFrameCallback((_) { // Ensure provider update happens after build
      ref.read(searchQueryProvider.notifier).state = '';
    });
    queryTextEditingController.dispose();
    super.close(context, result);
  }

  @override
  String get searchFieldLabel =>
      AppLocalizations.of(ref.context)!.searchPlaceholder;

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
            AppLocalizations.of(context)!.dialogClose, // Changed to use AppLocalizations
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
    final bool isRTLQuery = containsPersian(query); // from utils/helpers.dart

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
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
    final bool isRTLQuery = containsPersian(query); // from utils/helpers.dart

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
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
    switch (currentTabIndex) {
      case 0: // Currency
        listToShow = AssetListPage<models.CurrencyAsset>(
          provider: currencyProvider,
          assetType: AssetType.currency,
        );
        break;
      case 1: // Gold
        listToShow = AssetListPage<models.GoldAsset>(
          provider: goldProvider,
          assetType: AssetType.gold,
        );
        break;
      case 2: // Crypto
        listToShow = AssetListPage<models.CryptoAsset>(
          provider: cryptoProvider,
          assetType: AssetType.crypto,
        );
        break;
      case 3: // Stock
        // For StockPage, the search is handled within its own context if active.
        // This delegate is typically for the main AssetListPages.
        // If AssetSearchDelegate were to be used for StockPage's internal search,
        // it would need to know which sub-tab of StockPage is active.
        // For now, assuming this delegate is used for the main tabs,
        // the Stock tab's search is integrated differently.
        // As a fallback or if this delegate IS used for a unified stock search:
        listToShow = AssetListPage<models.StockAsset>(
          provider: stockTseIfbProvider, // Default to primary stock list
          assetType: AssetType.stock,
        );
        break;
      default:
        listToShow = Center(child: Text(l10n.searchNoResults));
    }

    // The AssetListPage itself handles filtering based on searchQueryProvider.
    return listToShow;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: isDarkMode
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
          size: 22,
        ),
        toolbarHeight: 44.0,
      ),
      scaffoldBackgroundColor: isDarkMode
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF2F2F7),
      dividerTheme: DividerThemeData(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        thickness: 0.5,
        space: 0.5,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle( // For AppBar title
          fontFamily: 'SF-Pro',
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 17,
        ),
        bodyMedium: TextStyle( // Default text style for content
          fontFamily: 'SF-Pro',
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.colorScheme.primary,
        selectionColor: theme.colorScheme.primary.withAlpha(77),
        selectionHandleColor: theme.colorScheme.primary,
      ),
    );
  }

  @override
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
         onSubmitted: (String _) { // Ensure search results are shown on submit
          showResults(context);
        },
      ),
    );
  }
}
