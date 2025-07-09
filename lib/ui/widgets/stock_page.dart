import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';

import '../../models/asset_models.dart' as models;
import '../../config/app_config.dart';
import '../../providers/data_providers/stock_tse_ifb_data_provider.dart';
import '../../providers/data_providers/stock_debt_securities_data_provider.dart';
import '../../providers/data_providers/stock_futures_data_provider.dart';
import '../../providers/data_providers/stock_housing_facilities_data_provider.dart';
import '../../localization/l10n_utils.dart';
import '../../utils/color_utils.dart';
import 'asset_list_page.dart';
import '../../services/analytics_service.dart';
import './search/shimmering_search_field.dart';

// Stock Page with Sub-Tabs
class StockPage extends StatefulWidget {
  // Changed to StatefulWidget
  final bool showSearchBar;
  final bool isSearchActive;
  final double topPadding;
  // Gap between main tabs and the stock sub-tabs. Can be adjusted as needed.
  final double subTabGap;
  const StockPage({
    super.key,
    required this.showSearchBar,
    required this.isSearchActive,
    this.topPadding = 0.0,
    this.subTabGap = 4.0,
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
  final List<String> _englishStockTabNames = const [
    'Symbols',
    'Debt Securities',
    'Futures',
    'Housing Facilities'
  ];
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
    final l10n = AppLocalizations.of(context);

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
          onLoadMore: () =>
              notifier.fetchInitialData(isLoadMore: true), // Changed
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
          onLoadMore: () =>
              notifier.fetchInitialData(isLoadMore: true), // Changed
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
          onLoadMore: () =>
              notifier.fetchInitialData(isLoadMore: true), // Changed
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
          onLoadMore: () =>
              notifier.fetchInitialData(isLoadMore: true), // Changed
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.stock,
        ),
      ),
    ]);
    _stockTabController = TabController(length: _stockTabs.length, vsync: this);
    _fetchDataForStockSubTab(_stockTabController
        .index); // Initial load for the first visible sub-tab
    _stockTabController
        .addListener(_handleStockSubTabSelection); // Add listener
    // Initialize scroll controllers after tabs are set up
    _updateStockScrollControllers();
  }

  void _handleStockSubTabSelection() {
    if (!_stockTabController.indexIsChanging && mounted) {
      final index = _stockTabController.index;
      if (index < _englishStockTabNames.length) {
        final englishTabName = _englishStockTabNames[index];
        AnalyticsService.instance
            .logEvent('bourse_tab_visit', {'tab_id': englishTabName});
      }
      _fetchDataForStockSubTab(index);
      _updateStockScrollControllers();
    }
  }

  void _fetchDataForStockSubTab(int index) {
    if (!mounted) return;
    switch (index) {
      case 0:
        context.read<StockTseIfbDataNotifier>().fetchInitialData();
        break;
      case 1:
        context.read<StockDebtSecuritiesDataNotifier>().fetchInitialData();
        break;
      case 2:
        context.read<StockFuturesDataNotifier>().fetchInitialData();
        break;
      case 3:
        context.read<StockHousingFacilitiesDataNotifier>().fetchInitialData();
        break;
    }
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

  // Show sorting options bottom sheet for stock tabs
  void _showSortSheet(int index) {
    if (!kIsWeb) Vibration.vibrate(duration: 30);
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    final sortOptions = [
      SortMode.defaultOrder,
      SortMode.highestPrice,
      SortMode.lowestPrice
    ];
    final optionLabels = [
      isFa ? 'پیشفرض' : 'Default',
      isFa ? 'بیشترین قیمت' : 'Highest Price',
      isFa ? 'کمترین قیمت' : 'Lowest Price',
    ];
    final appConfig = context.read<AppConfig>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = hexToColor(
      isDark
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoTheme(
        data: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: CupertinoActionSheet(
          title: Text(
            isFa ? 'مرتب‌سازی' : 'Sort By',
            style: TextStyle(
              fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: List.generate(sortOptions.length, (i) {
            return CupertinoActionSheetAction(
              onPressed: () {
                GlobalKey<AssetListPageState<models.StockAsset>>? currentKey;
                if (index == 0) {
                  currentKey = stockTseIfbKey;
                } else if (index == 1) {
                  currentKey = stockDebtKey;
                } else if (index == 2) {
                  currentKey = stockFuturesKey;
                } else if (index == 3) {
                  currentKey = stockHousingKey;
                }
                currentKey?.currentState?.setSortMode(sortOptions[i]);
                Navigator.of(context).pop();
              },
              child: Text(
                optionLabels[i],
                style: TextStyle(
                  fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isFa ? 'انصراف' : 'Cancel',
              style: TextStyle(
                fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: tealGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void refreshCurrentSubTabDataIfStale(
      {Duration staleness = const Duration(minutes: 5)}) {
    if (!mounted) return;
    final activeStockTabIndex = _stockTabController.index;
    switch (activeStockTabIndex) {
      case 0:
        context
            .read<StockTseIfbDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 1:
        context
            .read<StockDebtSecuritiesDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 2:
        context
            .read<StockFuturesDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 3:
        context
            .read<StockHousingFacilitiesDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
    }
  }

  @override
  void dispose() {
    _stockTabController
        .removeListener(_handleStockSubTabSelection); // Remove listener
    _stockTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>(); // Using Provider
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final stockTabBar = Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
            top: widget.subTabGap, bottom: 2, left: 8, right: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Shared group for uniform label scaling
            final AutoSizeGroup subTabLabelGroup = AutoSizeGroup();
            const double horizontalMargin = 1.0; // Made const and typed
            // Use fixed tab radius and smoothness from theme, not from provider
            final themeConfig = isDark
                ? appConfig.themeOptions.dark
                : appConfig.themeOptions.light;
            final BorderRadius tabBorderRadius = BorderRadius.circular(20.0);
            final segmentInactiveBackground = isDark
                ? const Color(0xFF161616)
                : hexToColor(themeConfig.cardColor);
            final segmentActiveBackground = isDark
                ? hexToColor(themeConfig.accentColorGreen).withAlpha(38)
                : Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withAlpha(128);
            final segmentActiveTextColor = isDark
                ? hexToColor(themeConfig.accentColorGreen).withAlpha(230)
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
                  borderRadius: tabBorderRadius,
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
                          // Adaptive text that scales uniformly across sub-tabs
                          Widget autoText = AutoSizeText(
                            label,
                            style: isSelected
                                ? selectedTextStyle
                                : unselectedTextStyle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            group: subTabLabelGroup,
                            minFontSize: 8,
                            overflow: TextOverflow.ellipsis,
                          );
                          if (isSelected && !isDark) {
                            autoText = Transform.translate(
                              offset: const Offset(0, 1),
                              child: autoText,
                            );
                          }
                          return autoText;
                        },
                      ),
                    ),
                  ),
                );
                final wrappedWithLongPress = GestureDetector(
                  onTap: onTap,
                  onLongPress: () => _showSortSheet(index),
                  child: segment,
                );
                return isMobile
                    ? Expanded(child: wrappedWithLongPress)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalMargin,
                        ),
                        child: wrappedWithLongPress,
                      );
              }),
            );
          },
        ),
      ),
    );

    final searchBar = AnimatedContainer(
      duration: widget.showSearchBar
          ? const Duration(milliseconds: 400) // Already const
          : const Duration(milliseconds: 300), // Already const
      curve: Curves.easeInOutQuart, // Already const
      height: widget.showSearchBar ? 48.0 : 0.0,
      margin: widget.showSearchBar
          ? const EdgeInsets.only(
              top: 10.0,
              bottom: 4.0) // Increased gap above and below search field
          : EdgeInsets.zero, // Ensure const
      padding: const EdgeInsets.symmetric(horizontal: 12), // Already const
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedOpacity(
        opacity: widget.showSearchBar ? 1.0 : 0.0,
        duration: widget.showSearchBar
            ? const Duration(milliseconds: 300) // Already const
            : const Duration(milliseconds: 200), // Already const
        child: widget.isSearchActive
            ? const ShimmeringSearchField()
            : const SizedBox(),
      ),
    );

    final pageContent = AnimatedBuilder(
      animation: _stockTabController,
      builder: (context, child) {
        final index = _stockTabController.index;
        Widget content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 300), // Already const
          switchInCurve: Curves.easeInOutQuart, // Already const
          switchOutCurve: Curves.easeInOutQuart, // Already const
          transitionBuilder: (Widget child, Animation<double> anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Container(
            key: ValueKey<int>(index),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _stockTabViews[index],
          ),
        );

        // Update scroll controllers after tab change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateStockScrollControllers();
        });

        // For desktop web platform, enable middle-click scrolling and smooth scrolling
        if (kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux)) {
          // Get the current scroll controller for this tab
          _updateStockScrollControllers();
          final controller = _stockScrollControllers[index];

          if (controller != null) {
            return WebSmoothScroll(
              controller: controller,
              scrollSpeed: 1.8,
              scrollAnimationLength: 600,
              curve: Curves.easeOutQuart,
              child: content,
            );
          }
        }

        return content;
      },
    );

    return Column(
      children: [
        // Offset for app bar and main tabs
        SizedBox(height: widget.topPadding),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: stockTabBar,
          ),
        ),
        searchBar,
        Expanded(
          child: pageContent,
        ),
      ],
    );
  }
}
