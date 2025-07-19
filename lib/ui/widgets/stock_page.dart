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
// browser_utils removed

/// Stock Page with sub-tabs for different stock categories
class StockPage extends StatefulWidget {
  /// Whether to show the search bar
  final bool showSearchBar;

  /// Whether search is currently active
  final bool isSearchActive;

  /// Padding from top of the screen
  final double topPadding;

  /// Gap between main tabs and stock sub-tabs
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

class StockPageState extends State<StockPage>
    with TickerProviderStateMixin<StockPage> {
  /// Tab controller for stock sub-tabs
  late TabController _stockTabController;

  /// List of tab widgets for stock sub-tabs
  final List<Tab> _stockTabs = [];

  /// List of tab view widgets for stock sub-tabs
  final List<Widget> _stockTabViews = [];

  /// English names of stock tabs for analytics tracking
  final List<String> _englishStockTabNames = const [
    'Symbols',
    'Debt Securities',
    'Futures',
    'Housing Facilities'
  ];

  /// Keys for accessing each stock sub-tab
  final stockTseIfbKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockDebtKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockFuturesKey = GlobalKey<AssetListPageState<models.StockAsset>>();
  final stockHousingKey = GlobalKey<AssetListPageState<models.StockAsset>>();

  /// Map to store scroll controllers for each stock sub-tab
  final Map<int, ScrollController?> _stockScrollControllers = {};

  @override
  void initState() {
    super.initState();
    // Tabs initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTabs();
    _stockTabController = TabController(length: _stockTabs.length, vsync: this);
    _fetchDataForStockSubTab(_stockTabController.index);
    _stockTabController.addListener(_handleStockSubTabSelection);
    _updateStockScrollControllers();
  }

  /// Initialize tabs based on localization
  void _initializeTabs() {
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
      _buildTseIfbTabView(),
      _buildDebtSecuritiesTabView(),
      _buildFuturesTabView(),
      _buildHousingFacilitiesTabView(),
    ]);
  }

  /// Build TSE/IFB symbols tab view
  Widget _buildTseIfbTabView() {
    return Consumer<StockTseIfbDataNotifier>(
      builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
        key: stockTseIfbKey,
        items: notifier.items,
        fullItemsListForSearch: notifier.fullDataList,
        isLoading: notifier.isLoading,
        error: notifier.error,
        onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
        onLoadMore: () => notifier.fetchInitialData(isLoadMore: true),
        onInitialize: () async => notifier.fetchInitialData(),
        assetType: AssetType.stock,
      ),
    );
  }

  /// Build debt securities tab view
  Widget _buildDebtSecuritiesTabView() {
    return Consumer<StockDebtSecuritiesDataNotifier>(
      builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
        key: stockDebtKey,
        items: notifier.items,
        fullItemsListForSearch: notifier.fullDataList,
        isLoading: notifier.isLoading,
        error: notifier.error,
        onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
        onLoadMore: () => notifier.fetchInitialData(isLoadMore: true),
        onInitialize: () async => notifier.fetchInitialData(),
        assetType: AssetType.stock,
      ),
    );
  }

  /// Build futures tab view
  Widget _buildFuturesTabView() {
    return Consumer<StockFuturesDataNotifier>(
      builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
        key: stockFuturesKey,
        items: notifier.items,
        fullItemsListForSearch: notifier.fullDataList,
        isLoading: notifier.isLoading,
        error: notifier.error,
        onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
        onLoadMore: () => notifier.fetchInitialData(isLoadMore: true),
        onInitialize: () async => notifier.fetchInitialData(),
        assetType: AssetType.stock,
      ),
    );
  }

  /// Build housing facilities tab view
  Widget _buildHousingFacilitiesTabView() {
    return Consumer<StockHousingFacilitiesDataNotifier>(
      builder: (context, notifier, _) => AssetListPage<models.StockAsset>(
        key: stockHousingKey,
        items: notifier.items,
        fullItemsListForSearch: notifier.fullDataList,
        isLoading: notifier.isLoading,
        error: notifier.error,
        onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
        onLoadMore: () => notifier.fetchInitialData(isLoadMore: true),
        onInitialize: () async => notifier.fetchInitialData(),
        assetType: AssetType.stock,
      ),
    );
  }

  /// Handle tab selection changes
  void _handleStockSubTabSelection() {
    if (!_stockTabController.indexIsChanging && mounted) {
      final index = _stockTabController.index;
      _logTabVisit(index);
      _fetchDataForStockSubTab(index);
      _updateStockScrollControllers();
      _animateTabItems(index);
    }
  }

  /// Log tab visit to analytics
  void _logTabVisit(int index) {
    if (index < _englishStockTabNames.length) {
      final englishTabName = _englishStockTabNames[index];
      AnalyticsService.instance
          .logEvent('bourse_tab_visit', {'tab_id': englishTabName});
    }
  }

  /// Animate items in the selected tab
  void _animateTabItems(int index) {
    switch (index) {
      case 0:
        stockTseIfbKey.currentState?.animateItems();
        break;
      case 1:
        stockDebtKey.currentState?.animateItems();
        break;
      case 2:
        stockFuturesKey.currentState?.animateItems();
        break;
      case 3:
        stockHousingKey.currentState?.animateItems();
        break;
    }
  }

  /// Fetch data for the selected stock sub-tab
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

  /// Update the scroll controllers map with current controllers
  void _updateStockScrollControllers() {
    _stockScrollControllers[0] = stockTseIfbKey.currentState?.scrollController;
    _stockScrollControllers[1] = stockDebtKey.currentState?.scrollController;
    _stockScrollControllers[2] = stockFuturesKey.currentState?.scrollController;
    _stockScrollControllers[3] = stockHousingKey.currentState?.scrollController;
  }

  /// Getter for stockTabController to be accessed by HomeScreen
  TabController get stockTabController => _stockTabController;

  /// Getter for stockScrollControllers to be accessed by HomeScreen
  Map<int, ScrollController?> get stockScrollControllers =>
      _stockScrollControllers;

  /// Show sorting options bottom sheet for stock tabs
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (defaultTargetPlatform == TargetPlatform.android) {
      _showMaterialSortSheet(index, sortOptions, optionLabels, isDark, isFa);
    } else {
      _showCupertinoSortSheet(index, sortOptions, optionLabels, isDark, isFa);
    }
  }

  /// Show Material Design sort sheet (for Android)
  void _showMaterialSortSheet(int index, List<SortMode> sortOptions,
      List<String> optionLabels, bool isDark, bool isFa) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: List.generate(sortOptions.length, (i) {
              return ListTile(
                title: Text(optionLabels[i],
                    style: TextStyle(
                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    )),
                onTap: () {
                  _applySortMode(index, sortOptions[i]);
                  Navigator.of(context).pop();
                },
              );
            }),
          ),
        );
      },
    );
  }

  /// Show Cupertino sort sheet
  void _showCupertinoSortSheet(int index, List<SortMode> sortOptions,
      List<String> optionLabels, bool isDark, bool isFa) {
    showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
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
                _applySortMode(index, sortOptions[i]);
                Navigator.of(context).pop();
              },
              child: Text(optionLabels[i],
                  style: TextStyle(
                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  )),
            );
          }),
        ),
      ),
    );
  }

  /// Apply the selected sort mode to the appropriate tab
  void _applySortMode(int tabIndex, SortMode sortMode) {
    GlobalKey<AssetListPageState<models.StockAsset>>? currentKey;
    switch (tabIndex) {
      case 0:
        currentKey = stockTseIfbKey;
        break;
      case 1:
        currentKey = stockDebtKey;
        break;
      case 2:
        currentKey = stockFuturesKey;
        break;
      case 3:
        currentKey = stockHousingKey;
        break;
    }
    currentKey?.currentState?.setSortMode(sortMode);
  }

  /// Refresh current sub-tab data if it's stale
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
    _stockTabController.removeListener(_handleStockSubTabSelection);
    _stockTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        SizedBox(height: widget.topPadding),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: _buildStockTabBar(appConfig, isDark, isMobile),
          ),
        ),
        _buildSearchBar(),
        Expanded(
          child: _buildPageContent(isDark),
        ),
      ],
    );
  }

  /// Build the stock tab bar
  Widget _buildStockTabBar(AppConfig appConfig, bool isDark, bool isMobile) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
            top: widget.subTabGap, bottom: 2, left: 8, right: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final AutoSizeGroup subTabLabelGroup = AutoSizeGroup();
            const double horizontalMargin = 1.0;

            final themeConfig = isDark
                ? appConfig.themeOptions.dark
                : appConfig.themeOptions.light;

            final BorderRadius tabBorderRadius = BorderRadius.circular(21.0);
            final segmentInactiveBackground = isDark
                ? const Color(0xFF161616)
                : hexToColor(themeConfig.cardColor);
            final segmentActiveBackground = isDark
                ? hexToColor(themeConfig.accentColorGreen).withAlpha(38)
                : hexToColor(themeConfig.accentColorGreen).withAlpha(160);
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
                return _buildTabSegment(
                  index: index,
                  isMobile: isMobile,
                  horizontalMargin: horizontalMargin,
                  tabBorderRadius: tabBorderRadius,
                  themeConfig: themeConfig,
                  segmentActiveBackground: segmentActiveBackground,
                  segmentInactiveBackground: segmentInactiveBackground,
                  selectedTextStyle: selectedTextStyle,
                  unselectedTextStyle: unselectedTextStyle,
                  subTabLabelGroup: subTabLabelGroup,
                  isDark: isDark,
                );
              }),
            );
          },
        ),
      ),
    );
  }

  /// Build an individual tab segment
  Widget _buildTabSegment({
    required int index,
    required bool isMobile,
    required double horizontalMargin,
    required BorderRadius tabBorderRadius,
    required dynamic themeConfig,
    required Color segmentActiveBackground,
    required Color segmentInactiveBackground,
    required TextStyle selectedTextStyle,
    required TextStyle unselectedTextStyle,
    required AutoSizeGroup subTabLabelGroup,
    required bool isDark,
  }) {
    final isSelected = _stockTabController.index == index;
    final label = _stockTabs[index].text!;

    final segment = SmoothCard(
      smoothness: themeConfig.cardCornerSmoothness,
      borderRadius: tabBorderRadius,
      elevation: 0,
      color: isSelected ? segmentActiveBackground : segmentInactiveBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 12.0,
        ),
        child: Center(
          child: Builder(
            builder: (context) {
              Widget autoText = AutoSizeText(
                label,
                style: isSelected ? selectedTextStyle : unselectedTextStyle,
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
      onTap: () => _handleTabTap(index),
      onLongPress: () => _showSortSheet(index),
      child: segment,
    );

    return isMobile
        ? Expanded(child: wrappedWithLongPress)
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
            child: wrappedWithLongPress,
          );
  }

  /// Handle tab tap - scroll to top if already selected
  void _handleTabTap(int index) {
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

  /// Build the search bar
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: widget.showSearchBar
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOutQuart,
      height: widget.showSearchBar ? 48.0 : 0.0,
      margin: widget.showSearchBar
          ? const EdgeInsets.only(top: 10.0, bottom: 4.0)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedOpacity(
        opacity: widget.showSearchBar ? 1.0 : 0.0,
        duration: widget.showSearchBar
            ? const Duration(milliseconds: 300)
            : const Duration(milliseconds: 200),
        child: widget.isSearchActive
            ? const ShimmeringSearchField()
            : const SizedBox(),
      ),
    );
  }

  /// Build the main page content with tab views
  Widget _buildPageContent(bool isDark) {
    return AnimatedBuilder(
      animation: _stockTabController,
      builder: (context, child) {
        final index = _stockTabController.index;
        Widget content = AnimatedSwitcher(
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateStockScrollControllers();
        });

        // Enable smooth scrolling for desktop web platforms
        if (kIsWeb && _isDesktopPlatform()) {
          _updateStockScrollControllers();
          final controller = _stockScrollControllers[index];

          if (controller != null) {
            return WebSmoothScroll(
              controller: controller,
              scrollSpeed: 1.4,
              scrollAnimationLength: 820,
              curve: Curves.easeOutCubic,
              child: content,
            );
          }
        }

        return content;
      },
    );
  }

  /// Check if current platform is desktop
  bool _isDesktopPlatform() {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }
}
