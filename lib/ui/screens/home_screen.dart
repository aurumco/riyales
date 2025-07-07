import 'package:flutter/cupertino.dart';
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' show ImageFilter;
import 'package:auto_size_text/auto_size_text.dart';

// Config
import '../../config/app_config.dart';

// Models
import '../../models/asset_models.dart' as models;

// Providers (new paths)
import '../../providers/locale_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/data_providers/currency_data_provider.dart';
import '../../providers/data_providers/gold_data_provider.dart';
import '../../providers/data_providers/crypto_data_provider.dart';
// import '../../providers/data_providers/stock_tse_ifb_data_provider.dart'; // Removed
// import '../../providers/data_providers/stock_debt_securities_data_provider.dart'; // Removed
// import '../../providers/data_providers/stock_futures_data_provider.dart'; // Removed
// import '../../providers/data_providers/stock_housing_facilities_data_provider.dart'; // Removed

// UI Widgets
import '../widgets/asset_list_page.dart';
import '../widgets/stock_page.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/common/error_placeholder.dart';
import '../widgets/common/connection_aware_widgets.dart';

// Localization
import '../../localization/l10n_utils.dart';

// Utils
import '../../utils/color_utils.dart';
import '../../services/analytics_service.dart';

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
  final List<String> _englishTabNames = const [
    'Currency',
    'Gold',
    'Crypto',
    'Stock'
  ];
  final ValueNotifier<bool> _showSearchBarNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isSearchActiveNotifier = ValueNotifier(false);
  bool _tabListenerAdded = false;
  final Map<int, ScrollController?> _tabScrollControllers = {};
  final Map<int, void Function()> _tabScrollListeners = {};

  Timer? _autoRefreshTimer; // Added timer instance variable

  final currencyTabKey = GlobalKey<AssetListPageState<models.CurrencyAsset>>();
  final goldTabKey = GlobalKey<AssetListPageState<models.GoldAsset>>();
  final cryptoTabKey = GlobalKey<AssetListPageState<models.CryptoAsset>>();
  final stockTabKey = GlobalKey<StockPageState>();

  // Flag to track if device is desktop web
  bool _isDesktopWeb = false;
  // Title tap tracking for easter-egg
  int _titleTapCount = 0;
  DateTime? _firstTitleTapTime;

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
        // Maintain search bar visibility regardless of scroll
        if (_isSearchActiveNotifier.value && controller.offset <= 0) {
          // If scrolled to top and search bar was hidden, open it
          if (!_showSearchBarNotifier.value && mounted) {
            _toggleSearchBar(true);
          }
        }
      }

      controller.addListener(listener);
      _tabScrollListeners[tabIndex] = listener;
    }
  }

  void _initializeTab(int index) {
    switch (index) {
      case 0:
        _tabScrollControllers[0] = _findScrollController(index);
        _setupScrollListener(0);
        break;
      case 1:
        _tabScrollControllers[1] = _findScrollController(index);
        _setupScrollListener(1);
        break;
      case 2:
        _tabScrollControllers[2] = _findScrollController(index);
        _setupScrollListener(2);
        break;
      case 3:
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
    // Check if the device is desktop web
    _checkDeviceType();
    _startAutoRefreshTimer(); // Added call to start timer
  }

  // Function to check device type and set _isDesktopWeb flag
  Future<void> _checkDeviceType() async {
    // Detect desktop web by checking for mobile keywords in the user agent
    if (kIsWeb) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final webInfo = await deviceInfo.webBrowserInfo;
        final ua = webInfo.userAgent?.toLowerCase() ?? '';
        // Consider mobile if UA contains common mobile phone identifiers
        final isMobile = ua.contains('mobile') ||
            ua.contains('iphone') ||
            (ua.contains('android') && ua.contains('mobile'));
        final isDesktop = !isMobile;
        if (mounted) setState(() => _isDesktopWeb = isDesktop);
      } catch (_) {
        if (mounted) setState(() => _isDesktopWeb = false);
      }
    } else {
      // Not web
      if (mounted) setState(() => _isDesktopWeb = false);
    }
  }

  // Function to launch download URL
  Future<void> _launchDownloadUrl() async {
    const url = 'https://dl.ryls.ir';
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      // Handle error silently or show a snackbar
    }
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
      // Send any events from previous session when app is resumed
      AnalyticsService.instance.sendPreviousEvents();
      _startAutoRefreshTimer(); // Restart timer on resume
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Save current events to storage when app goes to background
      AnalyticsService.instance.saveEvents();
      _autoRefreshTimer?.cancel(); // Cancel timer on pause/inactive/detached
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel(); // Cancel any existing timer
    // Call _checkAutoRefresh immediately, then set up periodic timer
    // Using a separate Future.delayed to avoid issues if _checkAutoRefresh itself takes time or calls notifyListeners
    Future.delayed(Duration.zero, () => _checkAutoRefresh(null));
    _autoRefreshTimer =
        Timer.periodic(const Duration(minutes: 1), _checkAutoRefresh);
  }

  void _checkAutoRefresh(Timer? timer) {
    // Timer can be null for the initial immediate call
    if (!mounted) return; // Ensure widget is still mounted

    final currentTabIndex = _tabController.index;
    const staleness = Duration(minutes: 5);

    switch (currentTabIndex) {
      case 0: // Currency
        context
            .read<CurrencyDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 1: // Gold
        context
            .read<GoldDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 2: // Crypto
        context
            .read<CryptoDataNotifier>()
            .fetchDataIfStaleOrNeverFetched(staleness: staleness);
        break;
      case 3: // Stock
        stockTabKey.currentState
            ?.refreshCurrentSubTabDataIfStale(staleness: staleness);
        break;
    }
  }

  void _setupTabs() {
    if (!mounted) {
      return;
    }

    if (_tabController.index >= _mainTabs.length) {
      _tabController.index = 0;
    }

    final l10n = AppLocalizations.of(context);

    if (_mainTabs.isEmpty) {
      _mainTabs.addAll([
        Tab(text: l10n.tabCurrency),
        Tab(text: l10n.tabGold),
        Tab(text: l10n.tabCrypto),
        Tab(text: l10n.tabStock),
      ]);
    }

    int previousIndex = _tabController.index;
    if (_tabListenerAdded) {
      previousIndex = _tabController.index;
      _tabController.removeListener(_handleTabSelection);
      _tabListenerAdded = false;
    }

    // Dispose old controller only if it's going to be replaced
    if (_tabController.length != _mainTabs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: _mainTabs.length,
        vsync: this,
        initialIndex: previousIndex < _mainTabs.length ? previousIndex : 0,
      );
    }

    if (!_tabListenerAdded) {
      _initializeTab(_tabController.index);
      _tabController.addListener(_handleTabSelection);
      _tabListenerAdded = true;
    }
  }

  void _handleTabSelection() {
    if (mounted) {
      setState(() {
        // This call ensures the UI (like the TabBar and NavigationRail) rebuilds
        // when the tab index changes, either by user tap or programmatically.
      });
    }
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
    _tabScrollListeners.clear();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _showSearchBarNotifier.dispose();
    _isSearchActiveNotifier.dispose();
    _autoRefreshTimer?.cancel(); // Added timer cancellation

    // Save any tracked events before the app is completely closed
    AnalyticsService.instance.saveEvents();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>(); // Using Provider
    final l10n = AppLocalizations.of(context);

    _setupTabs();

    final isLargeScreen = MediaQuery.of(context).size.width >= 600;
    final topPadding = kToolbarHeight +
        MediaQuery.of(context).viewPadding.top +
        (isLargeScreen ? 8.0 : 0.0) +
        (isLargeScreen ? 0 : (56.0 + 2.0));

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
          // Made const
          body: Center(
              child:
                  Text("App configuration is using fallback."))); // Made const
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

    final mainTabViews = [
      ValueListenableBuilder<bool>(
          valueListenable: _isSearchActiveNotifier,
          builder: (context, isSearchActive, child) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, child) {
                  return Consumer<CurrencyDataNotifier>(
                    builder: (context, notifier, _) =>
                        AssetListPage<models.CurrencyAsset>(
                      key: currencyTabKey,
                      topPadding: topPadding,
                      items: notifier.items,
                      fullItemsListForSearch: notifier.fullDataList,
                      isLoading: notifier.isLoading,
                      error: notifier.error,
                      onRefresh: () async =>
                          notifier.fetchInitialData(isRefresh: true),
                      onLoadMore: () =>
                          notifier.fetchInitialData(isLoadMore: true),
                      onInitialize: () async => notifier.fetchInitialData(),
                      assetType: AssetType.currency,
                      showSearchBar: showSearchBar,
                      isSearchActive: isSearchActive,
                      tabController: _tabController,
                    ),
                  );
                });
          }),
      ValueListenableBuilder<bool>(
          valueListenable: _isSearchActiveNotifier,
          builder: (context, isSearchActive, child) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, child) {
                  return Consumer<GoldDataNotifier>(
                    builder: (context, notifier, _) =>
                        AssetListPage<models.GoldAsset>(
                      key: goldTabKey,
                      topPadding: topPadding,
                      items: notifier.items,
                      fullItemsListForSearch: notifier.fullDataList,
                      isLoading: notifier.isLoading,
                      error: notifier.error,
                      onRefresh: () async =>
                          notifier.fetchInitialData(isRefresh: true),
                      onLoadMore: () =>
                          notifier.fetchInitialData(isLoadMore: true),
                      onInitialize: () async => notifier.fetchInitialData(),
                      assetType: AssetType.gold,
                      showSearchBar: showSearchBar,
                      isSearchActive: isSearchActive,
                      tabController: _tabController,
                    ),
                  );
                });
          }),
      ValueListenableBuilder<bool>(
          valueListenable: _isSearchActiveNotifier,
          builder: (context, isSearchActive, child) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, child) {
                  return Consumer<CryptoDataNotifier>(
                    builder: (context, notifier, _) =>
                        AssetListPage<models.CryptoAsset>(
                      key: cryptoTabKey,
                      topPadding: topPadding,
                      items: notifier.items,
                      fullItemsListForSearch: notifier.fullDataList,
                      isLoading: notifier.isLoading,
                      error: notifier.error,
                      onRefresh: () async =>
                          notifier.fetchInitialData(isRefresh: true),
                      onLoadMore: () =>
                          notifier.fetchInitialData(isLoadMore: true),
                      onInitialize: () async => notifier.fetchInitialData(),
                      assetType: AssetType.crypto,
                      showSearchBar: showSearchBar,
                      isSearchActive: isSearchActive,
                      tabController: _tabController,
                      useCardAnimation: false,
                    ),
                  );
                });
          }),
      ValueListenableBuilder<bool>(
        valueListenable: _isSearchActiveNotifier,
        builder: (context, isSearchActive, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: _showSearchBarNotifier,
            builder: (context, showSearchBar, child) {
              return StockPage(
                  key: stockTabKey,
                  topPadding: topPadding,
                  showSearchBar: showSearchBar,
                  isSearchActive: isSearchActive);
            },
          );
        },
      ),
    ];

    Widget mainScaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 21, sigmaY: 21),
            child: Container(
              color: isDarkMode
                  ? const Color.fromARGB(255, 9, 9, 9).withAlpha(210)
                  : Theme.of(context).scaffoldBackgroundColor.withAlpha(180),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: _onTitleTapped,
          child: Text(
            l10n.riyalesAppTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ),
        actions: [
          AnimatedAlign(
            alignment: localeNotifier.locale.languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center, // Using localeNotifier
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isSearchActiveNotifier,
              builder: (context, isSearchActive, child) {
                // Extracted IconButton to a separate const widget if possible, or a private method
                // For now, let's assume the Icon can be const if its color logic is simplified or passed
                final icon = Icon(
                  isSearchActive // From builder
                      ? CupertinoIcons.clear
                      : CupertinoIcons.search,
                  key: ValueKey<bool>(isSearchActive), // From builder
                  color: _showSearchBarNotifier
                          .value // Using notifier's value directly
                      ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                      : (isDarkMode ? Colors.white : Colors.black),
                  size: 28,
                );

                return IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: icon, // Use the extracted icon
                  ),
                  onPressed: () {
                    AnalyticsService.instance
                        .logEvent('button_click', {'button': 'search'});
                    if (isSearchActive) {
                      // From builder
                      context.read<SearchQueryNotifier>().query = '';
                      _toggleSearchBar(false);
                      return;
                    }
                    final currentTabIndex = _tabController.index;
                    _tabScrollControllers[currentTabIndex] ??=
                        _findScrollController(currentTabIndex);
                    final controller = _tabScrollControllers[currentTabIndex];
                    if (controller != null && controller.hasClients) {
                      if (controller.offset <= 0) {
                        _toggleSearchBar(true);
                        _setupScrollListener(currentTabIndex);
                      } else {
                        controller.jumpTo(controller.offset);
                        controller
                            .animateTo(0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutQuart)
                            .then((_) {
                          if (mounted) {
                            // Keep mounted for async operations
                            _toggleSearchBar(true);
                            _setupScrollListener(currentTabIndex);
                          }
                        });
                      }
                    } else {
                      _toggleSearchBar(true);
                    }
                  },
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  style: ButtonStyle(
                      overlayColor:
                          WidgetStateProperty.all(Colors.transparent)),
                );
              },
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _isSearchActiveNotifier,
                builder: (context, isSearchActive, child) {
                  return GestureDetector(
                    onTap: () {
                      AnalyticsService.instance
                          .logEvent('button_click', {'button': 'settings'});
                      if (isSearchActive) {
                        // Use 'isSearchActive' from builder
                        context.read<SearchQueryNotifier>().query = '';
                        _toggleSearchBar(false);
                      }
                      showCupertinoModalPopup(
                          context: context,
                          builder: (_) => const SettingsSheet());
                    },
                    child:
                        child,
                  );
                },
                // Made the child of ValueListenableBuilder const as it does not depend on isSearchActive
                child: const SizedBox( // Replaced Container with SizedBox for simplicity if only for Icon
                  width: 40,
                  height: 40,
                  // decoration: BoxDecoration(shape: BoxShape.circle), // Removed if not strictly needed for tap target
                  child: Icon(CupertinoIcons.person_crop_circle,
                      size: 28), // Color will be inherited from IconTheme or default
                ),
              ),
            ),
          ),
        ],
        bottom: isLargeScreen
            ? null
            : PreferredSize(
                preferredSize:
                    const Size.fromHeight(56.0 + 2.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8.0, right: 8.0, bottom: 2.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final horizontalMargin = isMobile ? 4.0 : 0.0;
                      final AutoSizeGroup tabLabelGroup = AutoSizeGroup();
                      final BorderRadius tabBorderRadius =
                          BorderRadius.circular(
                              20.0);
                      return Row(
                        mainAxisSize:
                            isMobile ? MainAxisSize.max : MainAxisSize.min,
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
                            final englishTabName = _englishTabNames[index];
                            AnalyticsService.instance.logEvent(
                                'tab_visit', {'tab_id': englishTabName});
                            if (_tabController.index == index) {
                              final controller =
                                  _tabScrollControllers[index] ??=
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

                          final tabContent = Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 16.0),
                            child: Center(
                              child: Builder(builder: (context) {
                                Widget autoText = AutoSizeText(
                                  label, // Dynamic
                                  style: isSelected // Dynamic
                                      ? selectedTextStyle
                                      : unselectedTextStyle,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  group: tabLabelGroup, // Dynamic
                                  minFontSize: 8,
                                  overflow: TextOverflow.ellipsis,
                                );
                                if (isSelected && !isDarkMode) {
                                  autoText = Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: autoText);
                                }
                                return autoText;
                              }),
                            ),
                          );

                          Widget segment;
                          if (isSelected) {
                            segment = SmoothCard(
                              smoothness: themeConfig.cardCornerSmoothness, // Dynamic
                              borderRadius: tabBorderRadius, // Dynamic
                              elevation: 0,
                              color: segmentActiveBackground, // Dynamic
                              child: tabContent, // Dynamic
                            );
                          } else {
                            segment = SmoothCard(
                              smoothness: themeConfig.cardCornerSmoothness, // Dynamic
                              borderRadius: tabBorderRadius, // Dynamic
                              elevation: 0,
                              color: Colors.transparent,
                              child: ClipPath(
                                clipper: ShapeBorderClipper(
                                  shape: SmoothRectangleBorder( // Dynamic
                                    borderRadius: tabBorderRadius,
                                    smoothness:
                                        themeConfig.cardCornerSmoothness,
                                  ),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur( // Dynamic
                                      sigmaX: 15.0, sigmaY: 15.0),
                                  child: Container(
                                    decoration: BoxDecoration( // Dynamic
                                      color: isDarkMode
                                          ? const Color.fromARGB(
                                                  255, 90, 90, 90)
                                              .withAlpha(38)
                                          : const Color.fromARGB(
                                                  255, 255, 255, 255)
                                              .withAlpha(252),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: tabContent, // Dynamic
                                  ),
                                ),
                              ),
                            );
                          }

                          final wrapped = GestureDetector(
                            onTap: onTabTap,
                            onLongPress: () {
                              if (!kIsWeb) Vibration.vibrate(duration: 30);
                              final isFa = Localizations.localeOf(context)
                                      .languageCode ==
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
                                    title: Text(isFa ? 'مرتب‌سازی' : 'Sort By', // Cannot be const
                                        style: TextStyle( // Cannot be const
                                            fontFamily:
                                                isFa ? 'Vazirmatn' : 'SF-Pro',
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black)),
                                    actions:
                                        List.generate(sortOptions.length, (i) {
                                      return CupertinoActionSheetAction(
                                        onPressed: () {
                                          GlobalKey<
                                              AssetListPageState<
                                                  models.Asset>>? currentKey;
                                          if (index == 0) {
                                            currentKey = currencyTabKey
                                                as GlobalKey<
                                                    AssetListPageState<
                                                        models.Asset>>?;
                                          } else if (index == 1) {
                                            currentKey = goldTabKey
                                                as GlobalKey<
                                                    AssetListPageState<
                                                        models.Asset>>?;
                                          } else if (index == 2) {
                                            currentKey = cryptoTabKey
                                                as GlobalKey<
                                                    AssetListPageState<
                                                        models.Asset>>?;
                                          }
                                          // Stock page sorting is internal or not available via this menu
                                          currentKey?.currentState
                                              ?.setSortMode(sortOptions[i]);
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(optionLabels[i], // Cannot be const
                                            style: TextStyle( // Cannot be const
                                                fontFamily: isFa
                                                    ? 'Vazirmatn'
                                                    : 'SF-Pro',
                                                fontSize: 17,
                                                fontWeight: FontWeight.normal,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black)),
                                      );
                                    }),
                                    cancelButton: CupertinoActionSheetAction(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(isFa ? 'انصراف' : 'Cancel', // Cannot be const
                                          style: TextStyle( // Cannot be const
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile: original column layout
            return Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    // Using AnimatedBuilder to react to TabController changes
                    animation: _tabController,
                    builder: (context, child) {
                      final index = _tabController.index;
                      // Use direct display with AnimatedSwitcher instead of Container
                      // to avoid potential gesture detection issues
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOutQuart,
                        switchOutCurve: Curves.easeInOutQuart,
                        transitionBuilder: (Widget c, Animation<double> a) =>
                            FadeTransition(opacity: a, child: c),
                        child: KeyedSubtree(
                          key: ValueKey<int>(index),
                          child: mainTabViews[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          // Desktop/Tablet: use NavigationRail for vertical tabs under the app title with search field
          final isRTL = Localizations.localeOf(context).languageCode == 'fa';
          return Row(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align row contents from top
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [ // Removed const from children as spacing is not used here
              // Wrap NavigationRail in a Column with the same top padding as search field to align with cards
              Padding(
                padding: EdgeInsets.only(
                    top: 7.0,
                    // Adjust padding based on text direction
                    left: isRTL ? 0.0 : 7.0,
                    right: isRTL ? 7.0 : 0.0), // Cannot be const due to isRTL
                child: Theme(
                  data: Theme.of(context).copyWith(
                    // Disable all hover and touch feedback effects
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: NavigationRail(
                    // ======== VISUAL PROPERTIES ========
                    // Match page background
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    // Badge-style indicator color for selected tab
                    indicatorColor: isDarkMode
                        ? tealGreen
                            .withAlpha(38) // Light teal background in dark mode
                        : Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withAlpha(128),
                    useIndicator: true,

                    // ======== SIZING PROPERTIES ========
                    minWidth: 68, // Slightly narrower for better proportions
                    minExtendedWidth: 130,

                    // ======== LAYOUT PROPERTIES ========
                    labelType: NavigationRailLabelType.all,
                    groupAlignment:
                        -1.0, // Align tabs from top (-1.0) to bottom (1.0)

                    // ======== TEXT & ICON STYLING ========
                    selectedIconTheme: IconThemeData( // Cannot be const
                      color:
                          isDarkMode ? tealGreen.withAlpha(230) : Colors.white,
                      size: 22, // Size of icons
                    ),
                    selectedLabelTextStyle: TextStyle( // Cannot be const
                      color: isDarkMode
                          ? tealGreen.withAlpha(230)
                          : tealGreen.withAlpha(430),
                      fontWeight: FontWeight.w500,
                      fontFamily:
                          Localizations.localeOf(context).languageCode == 'fa'
                              ? 'Vazirmatn'
                              : 'SF-Pro',
                    ),
                    unselectedIconTheme: IconThemeData( // Cannot be const
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      size: 22,
                    ),
                    unselectedLabelTextStyle: TextStyle( // Cannot be const
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontFamily:
                          Localizations.localeOf(context).languageCode == 'fa'
                              ? 'Vazirmatn'
                              : 'SF-Pro',
                    ),

                    // ======== NAVIGATION BEHAVIOR ========
                    selectedIndex: _tabController.index,
                    onDestinationSelected: (index) {
                      if (_isDesktopWeb && index == _mainTabs.length) {
                        // If it's the download button (last item)
                        _launchDownloadUrl();
                      } else {
                        // Regular tab selection
                        if (index < _mainTabs.length &&
                            _mainTabs[index].text != null) {
                          final englishTabName = _englishTabNames[index];
                          AnalyticsService.instance.logEvent(
                              'tab_visit', {'tab_id': englishTabName});
                        }
                        setState(() => _tabController.animateTo(index));
                      }
                    },

                    // ======== TAB DESTINATIONS ========
                    destinations: [
                      NavigationRailDestination(
                        icon: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(0),
                          onDoubleTap: () => _showSortSheet(0),
                          child: const Icon(CupertinoIcons.money_dollar,
                              size: 22),
                        ),
                        label: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(0),
                          onDoubleTap: () => _showSortSheet(0),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 22),
                            child: Text(l10n.tabCurrency), // Cannot be const
                          ),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(1),
                          onDoubleTap: () => _showSortSheet(1),
                          child: const Icon(CupertinoIcons.sparkles,
                              size: 22),
                        ),
                        label: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(1),
                          onDoubleTap: () => _showSortSheet(1),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 22),
                            child: Text(l10n.tabGold), // Cannot be const
                          ),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(2),
                          onDoubleTap: () => _showSortSheet(2),
                          child: const Icon(
                              CupertinoIcons.bitcoin_circle,
                              size: 22),
                        ),
                        label: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _showSortSheet(2),
                          onDoubleTap: () => _showSortSheet(2),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 22),
                            child: Text(l10n.tabCrypto), // Cannot be const
                          ),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.trending_up,
                            size: 22),
                        label: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 22),
                          child: Text(l10n.tabStock), // Cannot be const
                        ),
                      ),
                      // Download button for desktop web users
                      if (_isDesktopWeb)
                        NavigationRailDestination(
                          icon: const Icon(
                              CupertinoIcons.cloud_download,
                              size: 22),
                          label: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 22),
                            child: Text(isRTL ? "دانلود" : "App"), // Cannot be const
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final index = _tabController.index;
                          return mainTabViews[index];
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return NetworkAwareWidget(
      onlineWidget: mainScaffold,
      offlineBuilder: (status) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.riyalesAppTitle), // Cannot be const
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isSearchActiveNotifier,
                  builder: (context, isSearchActiveValue, child) {
                    return GestureDetector(
                      onTap: () {
                        // mounted check is less critical here as we are not calling setState.
                        // ValueNotifier updates are safe even if listeners are gone.
                        if (isSearchActiveValue) {
                          context.read<SearchQueryNotifier>().query = '';
                          _toggleSearchBar(false);
                        }
                        showCupertinoModalPopup(
                            context: context,
                            builder: (_) =>
                                const SettingsSheet());
                      },
                      child: child, // Use child from builder
                    );
                  },
                  child: Container(
                    // This is the child for ValueListenableBuilder
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.person_crop_circle,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
          body: Center(
              child: ErrorPlaceholder( // ErrorPlaceholder not const
                  status: status)),
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

  // Handle title taps for easter-egg
  void _onTitleTapped() {
    final now = DateTime.now();
    if (_firstTitleTapTime == null ||
        now.difference(_firstTitleTapTime!).inSeconds > 5) {
      _firstTitleTapTime = now;
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    if (_titleTapCount >= 10) {
      _titleTapCount = 0;
      _firstTitleTapTime = null;
      final isRTL = Localizations.localeOf(context).languageCode == 'fa';
      final message = isRTL
          ? 'به دستور شرکت ارتباطات و راهکارهای مانا.'
          : 'By order of Aurum Co.';
      // Show a custom overlay snack bar
      _showCustomSnackBar(message, isRTL);
    }
  }

  // Custom overlay snack bar that slides up/down with easeInOutQuart
  void _showCustomSnackBar(String message, bool isRTL) {
    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutQuart,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: Material(
            elevation: 0,
            color: const Color.fromARGB(255, 2, 110, 200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(CupertinoIcons.checkmark_seal_fill,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
    overlay.insert(entry);
    // Animate in
    controller.forward();
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () async {
      await controller.reverse();
      entry.remove();
      controller.dispose();
    });
  }

  void _showSortSheet(int index) {
    // Show sorting options for asset tabs
    if (!kIsWeb) Vibration.vibrate(duration: 30);
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
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
    // Determine accent color for cancel button
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
                GlobalKey<AssetListPageState<models.Asset>>? currentKey;
                if (index == 0) {
                  currentKey = currencyTabKey
                      as GlobalKey<AssetListPageState<models.Asset>>?;
                } else if (index == 1) {
                  currentKey = goldTabKey
                      as GlobalKey<AssetListPageState<models.Asset>>?;
                } else if (index == 2) {
                  currentKey = cryptoTabKey
                      as GlobalKey<AssetListPageState<models.Asset>>?;
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

  // Add a method to toggle search bar visibility
  void _toggleSearchBar(bool show) {
    if (_showSearchBarNotifier.value != show) {
      _showSearchBarNotifier.value = show;
      _isSearchActiveNotifier.value = show;

      // Clear search query when hiding search bar
      if (!show) {
        context.read<SearchQueryNotifier>().query = '';
      }
    }
  }
}
