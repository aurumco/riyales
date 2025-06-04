import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added Provider import
import 'package:vibration/vibration.dart';
import 'package:smooth_corner/smooth_corner.dart'; // Added import

// Config
import '../../config/app_config.dart'; // Added import

// Models
import '../../models/asset_models.dart' as models;

// Providers (new paths)
import '../../providers/locale_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/data_providers/currency_data_provider.dart';
import '../../providers/data_providers/gold_data_provider.dart';
import '../../providers/data_providers/crypto_data_provider.dart';
import '../../providers/data_providers/stock_tse_ifb_data_provider.dart';
import '../../providers/data_providers/stock_debt_securities_data_provider.dart';
import '../../providers/data_providers/stock_futures_data_provider.dart';
import '../../providers/data_providers/stock_housing_facilities_data_provider.dart';

// import '../../services/api_service.dart'; // ApiService might not be directly used in HomeScreen UI

// UI Widgets
import '../widgets/asset_list_page.dart';
import '../widgets/stock_page.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/common/error_placeholder.dart'; // If used directly
import '../widgets/common/connection_aware_widgets.dart'; // For NetworkAwareWidget etc.

// Localization
import '../../localization/app_localizations.dart';

// Utils
import '../../utils/color_utils.dart'; // For _hexToColor
import '../../utils/helpers.dart'; // For containsPersian, _findScrollController etc.

class HomeScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> // Changed from ConsumerState
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin<HomeScreen> {
  late TabController _tabController;
  final List<Tab> _mainTabs = [];
  final List<Widget> _mainTabViews = [];
  // ConnectionStatus _connectionStatus = ConnectionStatus.connected; // Handled by NetworkAwareWidget
  // late StreamSubscription<ConnectionStatus> _connectionSubscription; // Handled by NetworkAwareWidget
  bool _showSearchBar = false;
  bool _isSearchActive = false;
  bool _tabListenerAdded = false;
  final Map<int, ScrollController?> _tabScrollControllers = {};
  final Map<int, void Function()> _tabScrollListeners = {};

  final currencyTabKey = GlobalKey<AssetListPageState<models.CurrencyAsset>>();
  final goldTabKey = GlobalKey<AssetListPageState<models.GoldAsset>>();
  final cryptoTabKey = GlobalKey<AssetListPageState<models.CryptoAsset>>();
  final stockTabKey = GlobalKey<StockPageState>();

  void _setupScrollListener(int tabIndex) {
    if (_tabScrollListeners.containsKey(tabIndex)) {
      final controller = _tabScrollControllers[tabIndex];
      if (controller != null && controller.hasClients) {
        // Ensure controller has clients
        controller.removeListener(_tabScrollListeners[tabIndex]!);
      }
      _tabScrollListeners.remove(tabIndex);
    }

    final controller = _findScrollController(tabIndex);
    if (controller != null && controller.hasClients) {
      void listener() {
        if (_isSearchActive) {
          if (controller.offset <= 0) {
            if (!_showSearchBar) {
              if (mounted) {
                setState(() => _showSearchBar = true);
              }
            }
          } else {
            if (_showSearchBar) {
              if (mounted) {
                setState(() => _showSearchBar = false);
              }
            }
          }
        }
      }

      controller.addListener(listener);
      _tabScrollListeners[tabIndex] = listener;
    }
  }

  void _initializeTab(int index) {
    // Riverpod specific ref.read calls will be updated later
    // For now, assuming these providers are Riverpod StateNotifierProviders
    // and their notifiers have an initialize() and refresh() method.
    // Accessing ChangeNotifiers using context.read<NotifierClass>().fetchInitialData()
    // Assumes fetchInitialData() is the method to call.
    switch (index) {
      case 0:
        context.read<CurrencyDataNotifier>().fetchInitialData();
        _tabScrollControllers[0] = _findScrollController(index);
        _setupScrollListener(0);
        break;
      case 1:
        context.read<GoldDataNotifier>().fetchInitialData();
        _tabScrollControllers[1] = _findScrollController(index);
        _setupScrollListener(1);
        break;
      case 2:
        context.read<CryptoDataNotifier>().fetchInitialData();
        _tabScrollControllers[2] = _findScrollController(index);
        _setupScrollListener(2);
        break;
      case 3:
        context.read<StockTseIfbDataNotifier>().fetchInitialData();
        // Also initialize other stock notifiers if this tab hosts all of them
        // and they are not individually initialized when their sub-tabs become visible.
        // For now, only initializing the primary one for the main "Stock" tab selection.
        _tabScrollControllers[3] = _findScrollController(index);
        _setupScrollListener(3);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Connection status is handled by NetworkAwareWidget, no direct subscription needed here.
    // _setupTabs() is called in didChangeDependencies
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabListenerAdded = false;
    _tabScrollControllers.clear();
    _tabScrollListeners.clear(); // Clear listeners as well

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // check mounted, removed _tabController.hasListeners
        _initializeTab(_tabController.index);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) {
      return;
    } // Ensure widget is mounted

    if (state == AppLifecycleState.resumed) {
      final currentTabIndex = _tabController.index;
      // Using context.read<NotifierClass>().fetchInitialData(isRefresh: true) or a dedicated refreshData()
      switch (currentTabIndex) {
        case 0:
          {
            context
                .read<CurrencyDataNotifier>()
                .fetchInitialData(isRefresh: true);
            break;
          }
        case 1:
          {
            context.read<GoldDataNotifier>().fetchInitialData(isRefresh: true);
            break;
          }
        case 2:
          {
            context
                .read<CryptoDataNotifier>()
                .fetchInitialData(isRefresh: true);
            break;
          }
        case 3:
          {
            final stockState = stockTabKey.currentState;
            if (stockState != null) {
              final activeStockTabIndex = stockState.stockTabController.index;
              if (activeStockTabIndex == 0) {
                context
                    .read<StockTseIfbDataNotifier>()
                    .fetchInitialData(isRefresh: true);
              } else if (activeStockTabIndex == 1) {
                context
                    .read<StockDebtSecuritiesDataNotifier>()
                    .fetchInitialData(isRefresh: true);
              } else if (activeStockTabIndex == 2) {
                context
                    .read<StockFuturesDataNotifier>()
                    .fetchInitialData(isRefresh: true);
              } else if (activeStockTabIndex == 3) {
                context
                    .read<StockHousingFacilitiesDataNotifier>()
                    .fetchInitialData(isRefresh: true);
              }
            }
            break;
          }
      }
    }
  }

  void _setupTabs() {
    if (!mounted) {
      return;
    }

    _mainTabs.clear();
    _mainTabViews.clear();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return;
    }

    _mainTabs.addAll([
      Tab(text: l10n.tabCurrency),
      Tab(text: l10n.tabGold),
      Tab(text: l10n.tabCrypto),
      Tab(text: l10n.tabStock),
    ]);

    // Refactored to use Consumer for each AssetListPage and pass required props
    _mainTabViews.addAll([
      Consumer<CurrencyDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.CurrencyAsset>(
          key: currencyTabKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.currency,
        ),
      ),
      Consumer<GoldDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.GoldAsset>(
          key: goldTabKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.gold,
        ),
      ),
      Consumer<CryptoDataNotifier>(
        builder: (context, notifier, _) => AssetListPage<models.CryptoAsset>(
          key: cryptoTabKey,
          items: notifier.items,
          fullItemsListForSearch: notifier.fullDataList,
          isLoading: notifier.isLoading,
          error: notifier.error,
          onRefresh: () async => notifier.fetchInitialData(isRefresh: true),
          onLoadMore: () => notifier.loadMore(),
          onInitialize: () async => notifier.fetchInitialData(),
          assetType: AssetType.crypto,
        ),
      ),
      StockPage(
          key: stockTabKey,
          showSearchBar: _showSearchBar,
          isSearchActive: _isSearchActive),
    ]);

    int previousIndex = _tabController.index; // Save before disposing
    if (_tabListenerAdded) {
      // Remove old listener if added
      previousIndex = _tabController.index;
      _tabController.removeListener(_handleTabSelection);
      _tabListenerAdded = false;
    }
    _tabController.dispose();

    _tabController = TabController(
      length: _mainTabs.length,
      vsync: this,
      initialIndex: previousIndex < _mainTabs.length ? previousIndex : 0,
    );

    if (!_tabListenerAdded) {
      // This logic might need re-evaluation
      _initializeTab(_tabController.index); // Initialize the first tab
      _tabController.addListener(_handleTabSelection);
      _tabListenerAdded = true;
    }
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      // check mounted
      _initializeTab(_tabController.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize TabController on first dependency change
    if (!_tabListenerAdded) {
      _tabController = TabController(length: 4, vsync: this);
    }
    _setupTabs(); // This will re-configure tabs and controller.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _connectionSubscription.cancel(); // Handled by NetworkAwareWidget
    _tabScrollListeners.forEach((_, listener) {
      // Find controller and remove listener
      // This needs careful handling if controllers are disposed elsewhere
    });
    _tabScrollControllers.values
        .where((c) => c != null)
        .forEach((c) => c!.dispose()); // Dispose scroll controllers
    _tabScrollListeners.clear();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>(); // Using Provider
    final l10n = AppLocalizations.of(context)!;

    // AppConfig is guaranteed by FutureProvider's initialData not to be null here in terms of object existence,
    // but its content might be the default if the future hasn't completed or failed.
    // The main.dart's Consumer<AppConfig> and its builder already handle the loading/error state for AppConfig for RiyalesApp.
    // So, direct use here is fine. If appConfig could truly be null (e.g. if initialData was null),
    // a null check or Consumer would be needed here too.
    // For simplicity, we assume appConfig is available as per MultiProvider setup.
    // if (appConfig == null) { // This specific null check might be redundant due to FutureProvider's initialData
    //   return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    // }

    if (appConfig.appName == "Riyales Default Fallback") {
      // Check if it's the default fallback from FutureProvider
      return const Scaffold(
          body: Center(child: Text("App configuration is using fallback.")));
    }

    // Accessing other providers
    final localeNotifier = context.watch<LocaleNotifier>();
    // final themeNotifier = context.watch<ThemeNotifier>(); // Not directly used in this build method, but available

    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark; // This is fine
    final tealGreen = hexToColor(isDarkMode
        ? appConfig.themeOptions.dark.accentColorGreen
        : appConfig.themeOptions.light.accentColorGreen);
    final themeConfig =
        isDarkMode ? appConfig.themeOptions.dark : appConfig.themeOptions.light;
    final segmentInactiveBackground = isDarkMode
        ? const Color(0xFF161616) // Match card background
        : hexToColor(themeConfig.cardColor);
    final segmentActiveBackground = isDarkMode
        ? tealGreen.withAlpha((255 * 0.15).round())
        : Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withAlpha(128); // Adjusted opacity
    final segmentActiveTextColor = isDarkMode
        ? tealGreen.withAlpha((255 * 0.9).round())
        : Theme.of(context)
            .colorScheme
            .onSecondaryContainer; // Adjusted opacity
    final screenWidth = MediaQuery.of(context).size.width;
    final tabFontSize = screenWidth < 360 ? 12.0 : 14.0;

    final selectedTextStyle = TextStyle(
        color: segmentActiveTextColor,
        fontSize: tabFontSize,
        fontWeight: FontWeight.w600);
    final unselectedTextStyle = TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: tabFontSize,
        fontWeight: FontWeight.w600);

    Widget mainScaffold = Scaffold(
      appBar: AppBar(
        // Use static title text to avoid animated language transition
        title: Text(
          l10n.riyalesAppTitle,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          AnimatedAlign(
            alignment: localeNotifier.locale.languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center, // Using localeNotifier
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isSearchActive
                      ? CupertinoIcons.clear
                      : CupertinoIcons.search,
                  key: ValueKey<bool>(_isSearchActive),
                  color: _showSearchBar
                      ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                      : (isDarkMode ? Colors.white : Colors.black),
                  size: 28,
                ),
              ),
              onPressed: () {
                if (_isSearchActive) {
                  if (mounted) {
                    setState(() {
                      context.read<SearchQueryNotifier>().query =
                          ''; // Using Provider
                      _showSearchBar = false;
                      _isSearchActive = false;
                    });
                  }
                  return;
                }
                final currentTabIndex = _tabController.index;
                _tabScrollControllers[currentTabIndex] ??=
                    _findScrollController(currentTabIndex);
                final controller = _tabScrollControllers[currentTabIndex];
                if (controller != null && controller.hasClients) {
                  if (controller.offset <= 0) {
                    if (mounted) {
                      setState(() {
                        _showSearchBar = true;
                        _isSearchActive = true;
                      });
                    }
                    _setupScrollListener(currentTabIndex);
                  } else {
                    controller.jumpTo(controller.offset);
                    controller
                        .animateTo(0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutQuart)
                        .then((_) {
                      if (mounted) {
                        setState(() {
                          _showSearchBar = true;
                          _isSearchActive = true;
                        });
                      }
                      _setupScrollListener(currentTabIndex);
                    });
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      _showSearchBar = true;
                      _isSearchActive = true;
                    });
                  }
                }
              },
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent)),
            ),
          ),
          AnimatedAlign(
            alignment: Localizations.localeOf(context).languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (_isSearchActive) {
                        context.read<SearchQueryNotifier>().query =
                            ''; // Using Provider
                        _showSearchBar = false;
                        _isSearchActive = false;
                      }
                    });
                  }
                  showCupertinoModalPopup(
                      context: context, builder: (_) => const SettingsSheet());
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.person_crop_circle,
                      size: 28, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0 + 2.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 2.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final horizontalMargin = isMobile ? 4.0 : 0.0;
                final BorderRadius tabBorderRadius = BorderRadius.circular(
                    20.0); // Increased radius (Could be 14.0)
                return Row(
                  mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isSelected = _tabController.index == index;
                    final label = [
                      l10n.tabCurrency,
                      l10n.tabGold,
                      l10n.tabCrypto,
                      l10n.tabStock
                    ][index];
                    void onTabTap() {
                      if (_tabController.index == index) {
                        final controller = _tabScrollControllers[index] ??=
                            _findScrollController(index);
                        if (controller != null && controller.hasClients) {
                          controller.jumpTo(controller.offset);
                          controller.animateTo(0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutQuart);
                        }
                      } else {
                        if (mounted) {
                          setState(() => _tabController.animateTo(index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutQuart));
                        }
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
                            vertical: 10.0, horizontal: 16.0),
                        child: Center(
                          child: Builder(builder: (context) {
                            Widget textWidget = Text(label,
                                style: isSelected
                                    ? selectedTextStyle
                                    : unselectedTextStyle,
                                textAlign: TextAlign.center);
                            Widget fittedText = FittedBox(
                                fit: BoxFit.scaleDown, child: textWidget);
                            if (isSelected && !isDarkMode) {
                              fittedText = Transform.translate(
                                  offset: const Offset(0, 1),
                                  child: fittedText);
                            }
                            return fittedText;
                          }),
                        ),
                      ),
                    );
                    final wrapped = GestureDetector(
                      onTap: onTabTap,
                      onLongPress: () {
                        Vibration.vibrate(duration: 60);
                        final isFa =
                            Localizations.localeOf(context).languageCode ==
                                'fa';
                        final sortOptions = [
                          SortMode.defaultOrder,
                          SortMode.highestPrice,
                          SortMode.lowestPrice,
                        ];
                        final optionLabels = [
                          isFa ? 'پیشفرض' : 'Default',
                          isFa ? 'بیشترین قیمت' : 'Highest Price',
                          isFa ? 'کمترین قیمت' : 'Lowest Price',
                        ];
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => CupertinoTheme(
                            data: CupertinoThemeData(
                                brightness: isDarkMode
                                    ? Brightness.dark
                                    : Brightness.light),
                            child: CupertinoActionSheet(
                              title: Text(isFa ? 'مرتب‌سازی' : 'Sort By',
                                  style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black)),
                              actions: List.generate(sortOptions.length, (i) {
                                return CupertinoActionSheetAction(
                                  onPressed: () {
                                    GlobalKey<AssetListPageState<models.Asset>>?
                                        currentKey;
                                    if (index == 0) {
                                      currentKey = currencyTabKey as GlobalKey<
                                          AssetListPageState<models.Asset>>?;
                                    } else if (index == 1) {
                                      currentKey = goldTabKey as GlobalKey<
                                          AssetListPageState<models.Asset>>?;
                                    } else if (index == 2) {
                                      currentKey = cryptoTabKey as GlobalKey<
                                          AssetListPageState<models.Asset>>?;
                                    }
                                    // Stock page sorting is internal or not available via this menu
                                    currentKey?.currentState
                                        ?.setSortMode(sortOptions[i]);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(optionLabels[i],
                                      style: TextStyle(
                                          fontFamily:
                                              isFa ? 'Vazirmatn' : 'SF-Pro',
                                          fontSize: 17,
                                          fontWeight: FontWeight.normal,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black)),
                                );
                              }),
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(isFa ? 'انصراف' : 'Cancel',
                                    style: TextStyle(
                                        fontFamily:
                                            isFa ? 'Vazirmatn' : 'SF-Pro',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: tealGreen)),
                              ),
                            ),
                          ),
                        );
                      },
                      child: segment,
                    );
                    return isMobile
                        ? Expanded(child: wrapped)
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalMargin),
                            child: wrapped);
                  }),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index !=
              3) // Search bar not shown on stock page (it has its own)
            AnimatedContainer(
              duration: _showSearchBar
                  ? const Duration(milliseconds: 400)
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuart,
              height: _showSearchBar ? 48.0 : 0.0,
              margin: _showSearchBar
                  ? const EdgeInsets.only(top: 10.0, bottom: 4.0)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AnimatedOpacity(
                opacity: _showSearchBar ? 1.0 : 0.0,
                duration: _showSearchBar
                    ? const Duration(milliseconds: 300)
                    : const Duration(milliseconds: 200),
                child: _isSearchActive
                    ? Builder(builder: (context) {
                        final searchQueryNotifier = context
                            .watch<SearchQueryNotifier>(); // Using Provider
                        final searchText = searchQueryNotifier.query;
                        final isRTL =
                            Localizations.localeOf(context).languageCode ==
                                    'fa' ||
                                containsPersian(searchText);
                        final textColor =
                            isDarkMode ? Colors.grey[300] : Colors.grey[700];
                        final placeholderColor =
                            isDarkMode ? Colors.grey[600] : Colors.grey[500];
                        final iconColor =
                            isDarkMode ? Colors.grey[400] : Colors.grey[600];
                        final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';
                        return Container(
                          decoration: ShapeDecoration(
                            color: isDarkMode
                                ? const Color(
                                    0xFF161616) // Match card background
                                : Colors.white,
                            shape: SmoothRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                smoothness: 0.7),
                          ),
                          child: CupertinoTextField(
                            controller: TextEditingController(text: searchText)
                              ..selection = TextSelection.fromPosition(
                                  TextPosition(offset: searchText.length)),
                            onChanged: (v) => context
                                .read<SearchQueryNotifier>()
                                .query = v, // Using Provider
                            placeholder: l10n.searchPlaceholder,
                            placeholderStyle: TextStyle(
                                color: placeholderColor,
                                fontFamily: fontFamily),
                            prefix: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 18),
                                child: Icon(CupertinoIcons.search,
                                    size: 20, color: iconColor)),
                            suffix: searchText.isNotEmpty
                                ? CupertinoButton(
                                    padding: const EdgeInsetsDirectional.only(
                                        end: 18),
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
                                bottom: 11),
                            style: TextStyle(
                                color: textColor, fontFamily: fontFamily),
                            cursorColor: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                            decoration:
                                null, // Important: use null to avoid double background
                          ),
                        );
                      })
                    : const SizedBox(),
              ),
            ),
          Expanded(
            child: AnimatedBuilder(
              // Using AnimatedBuilder to react to TabController changes
              animation: _tabController,
              builder: (context, child) {
                final index = _tabController.index;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOutQuart,
                  switchOutCurve: Curves.easeInOutQuart,
                  transitionBuilder: (Widget c, Animation<double> a) =>
                      FadeTransition(opacity: a, child: c),
                  child: Container(
                    key: ValueKey<int>(index), // Key for AnimatedSwitcher
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: index == 3
                        ? StockPage(
                            key: stockTabKey,
                            showSearchBar: _showSearchBar,
                            isSearchActive: _isSearchActive)
                        : _mainTabViews[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return NetworkAwareWidget(
      onlineWidget: mainScaffold,
      offlineBuilder: (status) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.riyalesAppTitle),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      // Added curly braces for the 'if (mounted)'
                      setState(() {
                        if (_isSearchActive) {
                          context.read<SearchQueryNotifier>().query = '';
                          _showSearchBar = false;
                          _isSearchActive = false;
                        }
                      });
                    }
                    showCupertinoModalPopup(
                        context: context,
                        builder: (_) => const SettingsSheet());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.person_crop_circle,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
          body: Center(child: ErrorPlaceholder(status: status)),
        );
      },
    );
  }

  ScrollController? _findScrollController(int tabIndex) {
    if (!mounted) {
      return null;
    }
    try {
      switch (tabIndex) {
        case 0:
          return currencyTabKey.currentState?.scrollController;
        case 1:
          return goldTabKey.currentState?.scrollController;
        case 2:
          return cryptoTabKey.currentState?.scrollController;
        case 3:
          final stockState = stockTabKey.currentState;
          if (stockState != null) {
            final activeStockTabIndex =
                stockState.stockTabController.index; // Getter needed
            // Ensure stockScrollControllers is accessible or a method to get it
            return stockState
                .stockScrollControllers[activeStockTabIndex]; // Getter needed
          }
          return null;
        default:
          return null;
      }
    } catch (e) {
      // print('Error finding scroll controller for tab $tabIndex: $e');
      return null;
    }
  }
}
