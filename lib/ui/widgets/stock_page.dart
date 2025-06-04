import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added Provider
import 'package:smooth_corner/smooth_corner.dart';

import '../../models/asset_models.dart' as models;
import '../../config/app_config.dart';
// Specific stock data provider imports (assuming they export the provider variables for now)
import '../../providers/data_providers/stock_tse_ifb_data_provider.dart';
import '../../providers/data_providers/stock_debt_securities_data_provider.dart';
import '../../providers/data_providers/stock_futures_data_provider.dart';
import '../../providers/data_providers/stock_housing_facilities_data_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/locale_provider.dart'; // Added import
import '../../localization/app_localizations.dart';
import '../../utils/color_utils.dart';
import '../../utils/helpers.dart';
import 'asset_list_page.dart';

// Stock Page with Sub-Tabs
class StockPage extends StatefulWidget {
  // Changed to StatefulWidget
  final bool showSearchBar;
  final bool isSearchActive;
  const StockPage({
    super.key,
    required this.showSearchBar,
    required this.isSearchActive,
  });

  @override
  StockPageState createState() => StockPageState();
}

class StockPageState extends State<StockPage> // Changed from ConsumerState
    with
        TickerProviderStateMixin<StockPage> {
  late TabController _stockTabController;
  final List<Tab> _stockTabs = [];
  final List<Widget> _stockTabViews = [];
  // Add keys for each stock sub-tab to access their scroll controllers
  final stockTseIfbKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockDebtKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockFuturesKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockHousingKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  // Map to store scroll controllers for each stock sub-tab
  final Map<int, ScrollController?> _stockScrollControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    _stockTabs.clear();
    _stockTabViews.clear();

    _stockTabs.addAll([
      Tab(text: l10n.stockTabSymbols), // TSE/IFB Symbols (نمادها) - Priority
      Tab(text: l10n.stockTabDebtSecurities), // اوراق بدهی
      Tab(text: l10n.stockTabFutures), // آتی
      Tab(text: l10n.stockTabHousingFacilities), // تسهیلات مسکن
    ]);

    _stockTabViews.addAll([
      Consumer<StockTseIfbDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
          key: stockTseIfbKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.stock, // Consider a more specific type if needed
        ),
      ),
      Consumer<StockDebtSecuritiesDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
          key: stockDebtKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.stock,
        ),
      ),
      Consumer<StockFuturesDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
          key: stockFuturesKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.stock,
        ),
      ),
      Consumer<StockHousingFacilitiesDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
          key: stockHousingKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.stock,
        ),
      ),
    ]);
    _stockTabController = TabController(length: _stockTabs.length, vsync: this);
    // Initialize scroll controllers after tabs are set up
    _updateStockScrollControllers();
  }

  // Method to update the scroll controllers map
  void _updateStockScrollControllers() {
    _stockScrollControllers[0] = stockTseIfbKey.currentState?.scrollController;
    _stockScrollControllers[1] = stockDebtKey.currentState?.scrollController;
    _stockScrollControllers[2] = stockFuturesKey.currentState?.scrollController;
    _stockScrollControllers[3] = stockHousingKey.currentState?.scrollController;
  }

  // Getter for stockTabController to be accessed by HomeScreen
  TabController get stockTabController => _stockTabController;

  // Getter for stockScrollControllers to be accessed by HomeScreen
  Map<int, ScrollController?> get stockScrollControllers =>
      _stockScrollControllers;

  @override
  void dispose() {
    _stockTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>(); // Using Provider
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = hexToColor(
      isDarkMode
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 0.0,
          ), // Reduced vertical padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              const horizontalMargin = 1.0; // Reduced horizontal spacing
              // Use fixed tab radius and smoothness from theme, not from provider
              final themeConfig = isDarkMode
                  ? appConfig.themeOptions.dark
                  : appConfig.themeOptions.light;
              final BorderRadius tabBorderRadius =
                  BorderRadius.circular(20.0); // Increased radius
              final segmentInactiveBackground = isDarkMode
                  ? const Color(0xFF161616) // Match card background
                  : hexToColor(themeConfig.cardColor);
              final segmentActiveBackground = isDarkMode
                  ? tealGreen.withAlpha(38)
                  : Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withAlpha(128);
              final segmentActiveTextColor = isDarkMode
                  ? tealGreen.withAlpha(230)
                  : Theme.of(context).colorScheme.onSecondaryContainer;
              final selectedTextStyle = TextStyle(
                color: segmentActiveTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              );
              final unselectedTextStyle = TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              );
              return Row(
                mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_stockTabs.length, (index) {
                  final isSelected = _stockTabController.index == index;
                  final label = _stockTabs[index].text!;
                  void onTap() {
                    if (_stockTabController.index == index) {
                      _updateStockScrollControllers();
                      final controller = _stockScrollControllers[index];
                      if (controller != null && controller.hasClients) {
                        controller.jumpTo(controller.offset);
                        controller.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutQuart,
                        );
                      }
                    } else {
                      setState(() {
                        _stockTabController.animateTo(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutQuart,
                        );
                      });
                    }
                  }

                  final segment = SmoothCard(
                    smoothness: themeConfig.cardCornerSmoothness,
                    borderRadius:
                        tabBorderRadius, // Use new BorderRadius object
                    elevation: 0,
                    color: isSelected
                        ? segmentActiveBackground
                        : segmentInactiveBackground,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 12.0,
                      ),
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            Widget textWidget = Text(
                              label,
                              style: isSelected
                                  ? selectedTextStyle
                                  : unselectedTextStyle,
                              textAlign: TextAlign.center,
                            );
                            Widget fittedText = FittedBox(
                              fit: BoxFit.scaleDown,
                              child: textWidget,
                            );
                            if (isSelected && !isDarkMode) {
                              fittedText = Transform.translate(
                                offset: const Offset(0, 1),
                                child: fittedText,
                              );
                            }
                            return fittedText;
                          },
                        ),
                      ),
                    ),
                  );
                  final wrapped = GestureDetector(onTap: onTap, child: segment);
                  return isMobile
                      ? Expanded(child: wrapped)
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            // Made const
                            horizontal: horizontalMargin,
                          ),
                          child: wrapped,
                        );
                }),
              );
            },
          ),
        ),
        // Add search bar after stock tabs
        AnimatedContainer(
          duration: widget.showSearchBar
              ? const Duration(milliseconds: 400)
              : const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart,
          height: widget.showSearchBar ? 48.0 : 0.0,
          margin: widget.showSearchBar
              ? const EdgeInsets.only(top: 10.0, bottom: 2.0)
              : EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AnimatedOpacity(
            opacity: widget.showSearchBar ? 1.0 : 0.0,
            duration: widget.showSearchBar
                ? const Duration(milliseconds: 300)
                : const Duration(milliseconds: 200),
            child: widget.isSearchActive
                ? Builder(
                    builder: (context) {
                      final searchQueryNotifier = context
                          .watch<SearchQueryNotifier>(); // Using Provider
                      final searchText = searchQueryNotifier.query;
                      final localeNotifier =
                          context.watch<LocaleNotifier>(); // For RTL check
                      final isRTL =
                          localeNotifier.locale.languageCode == 'fa' ||
                              containsPersian(searchText);

                      final textColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700];
                      final placeholderColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[500];
                      final iconColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600];
                      final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

                      return Container(
                        decoration: ShapeDecoration(
                          color:
                              (Theme.of(context).brightness == Brightness.dark)
                                  ? const Color(0xFF161616)
                                  : Colors.white,
                          shape: SmoothRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            smoothness: 0.7,
                          ),
                        ),
                        child: CupertinoTextField(
                          controller: TextEditingController(text: searchText)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: searchText.length),
                            ),
                          onChanged: (v) => context
                              .read<SearchQueryNotifier>()
                              .query = v, // Using Provider
                          placeholder:
                              AppLocalizations.of(context)!.searchPlaceholder,
                          placeholderStyle: TextStyle(
                            color: placeholderColor,
                            fontFamily: fontFamily,
                          ),
                          prefix: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 18),
                            child: Icon(CupertinoIcons.search,
                                size: 20, color: iconColor),
                          ),
                          suffix: searchText.isNotEmpty
                              ? CupertinoButton(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 18),
                                  minSize: 30,
                                  child: Icon(CupertinoIcons.clear,
                                      size: 18, color: iconColor),
                                  onPressed: () => context
                                      .read<SearchQueryNotifier>()
                                      .query = '', // Using Provider
                                )
                              : null,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          padding: EdgeInsetsDirectional.only(
                            start: 9,
                            end: searchText.isNotEmpty ? 28 : 12,
                            top: 11,
                            bottom: 11,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontFamily: fontFamily,
                          ),
                          cursorColor: iconColor,
                          decoration:
                              null, // No decoration to avoid double background
                        ),
                      );
                    },
                  )
                : const SizedBox(),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _stockTabController,
            builder: (context, child) {
              final index = _stockTabController.index;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutQuart,
                switchOutCurve: Curves.easeInOutQuart,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey<int>(index),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _stockTabViews[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
