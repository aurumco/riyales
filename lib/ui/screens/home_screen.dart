// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Dart imports
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:seo/seo.dart';
import 'dart:math';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local project imports
import '../../config/app_config.dart';
import '../../models/asset_models.dart' as models;
import '../../providers/locale_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/data_providers/currency_data_provider.dart';
import '../../providers/data_providers/gold_data_provider.dart';
import '../../providers/data_providers/crypto_data_provider.dart';
import '../widgets/asset_list_page.dart';
import '../widgets/stock_page.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/common/error_placeholder.dart';
import '../widgets/common/connection_aware_widgets.dart';
import 'onboarding_screen.dart';
import '../../localization/l10n_utils.dart';
import '../../utils/color_utils.dart';
import '../../services/analytics_service.dart';
import '../../services/connection_service.dart';
import '../../providers/alert_provider.dart';
import 'ad_screen.dart';

/// The main application screen with asset tabs, search, and settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

/// State for [HomeScreen], managing UI controllers and app lifecycle events.
class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin<HomeScreen> {
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

  Timer? _autoRefreshTimer;

  final currencyTabKey = GlobalKey<AssetListPageState<models.CurrencyAsset>>();
  final goldTabKey = GlobalKey<AssetListPageState<models.GoldAsset>>();
  final cryptoTabKey = GlobalKey<AssetListPageState<models.CryptoAsset>>();
  final stockTabKey = GlobalKey<StockPageState>();

  /// Whether the app is running as desktop web.
  bool _isDesktopWeb = false;
  AlertProvider? _alertProvider;

  /// Tap count for Easter egg activation.
  int _titleTapCount = 0;
  DateTime? _firstTitleTapTime;

  /// Sets up a scroll listener for the specified tab index.
  void _setupScrollListener(int tabIndex) {
    if (_tabScrollListeners.containsKey(tabIndex)) {
      final controller = _tabScrollControllers[tabIndex];
      if (controller != null && controller.hasClients) {
        controller.removeListener(_tabScrollListeners[tabIndex]!);
      }
      _tabScrollListeners.remove(tabIndex);
    }

    final controller = _findScrollController(tabIndex);
    if (controller != null && controller.hasClients) {
      void listener() {
        if (_isSearchActiveNotifier.value && controller.offset <= 0) {
          if (!_showSearchBarNotifier.value && mounted) {
            _toggleSearchBar(true);
          }
        }
      }

      controller.addListener(listener);
      _tabScrollListeners[tabIndex] = listener;
    }
  }

  /// Initializes the scroll controller for the specified tab index.
  void _initializeTab(int index) {
    _tabScrollControllers[index] = _findScrollController(index);
    _setupScrollListener(index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDeviceType();
    _startAutoRefreshTimer();
    _scheduleOnboarding();

    // Listen for alert updates to trigger ad display.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alertProvider = Provider.of<AlertProvider>(context, listen: false);
      _alertProvider!.addListener(() => _attemptShowAd());
      _attemptShowAd();
    });
  }

  /// Detects if the app is running on desktop web.
  Future<void> _checkDeviceType() async {
    if (kIsWeb) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final webInfo = await deviceInfo.webBrowserInfo;
        final ua = webInfo.userAgent?.toLowerCase() ?? '';
        final isMobile = ua.contains('mobile') ||
            ua.contains('iphone') ||
            (ua.contains('android') && ua.contains('mobile'));
        final isDesktop = !isMobile;
        if (mounted) setState(() => _isDesktopWeb = isDesktop);
      } catch (_) {
        if (mounted) setState(() => _isDesktopWeb = false);
      }
    } else {
      if (mounted) setState(() => _isDesktopWeb = false);
    }
  }

  /// Opens the app download URL for web users.
  Future<void> _launchDownloadUrl() async {
    const url = 'https://dl.ryls.ir';
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabListenerAdded = false;
    _tabScrollControllers.clear();
    _tabScrollListeners.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeTab(_tabController.index);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      AnalyticsService.instance.sendPreviousEvents();
      _startAutoRefreshTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AnalyticsService.instance.saveEvents();
      _autoRefreshTimer?.cancel();
    }
  }

  /// Starts the periodic data refresh timer.
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    Future.delayed(Duration.zero, () => _checkAutoRefresh(null));
    _autoRefreshTimer =
        Timer.periodic(const Duration(minutes: 1), _checkAutoRefresh);
  }

  /// Refreshes data for the current tab if it's stale.
  void _checkAutoRefresh(Timer? timer) {
    if (!mounted) return;

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

  /// Shows the onboarding screen if it hasn't been shown before.
  void _scheduleOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      const key = 'onboarding_shown_v1';
      if (!(prefs.getBool(key) ?? false)) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    });
  }

  /// Attempts to show the full-screen advertisement if it should be visible.
  Future<void> _attemptShowAd() async {
    if (!mounted) return;

    final adInfo = _alertProvider?.alert?.ad;
    if (adInfo == null || !adInfo.enabled) return;

    // Determine native mobile vs desktop (exclude web)
    final isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    // Get available ads that respect repeat limits
    final availableAds = await _alertProvider!.getAvailableAds(isMobileNative);
    if (!mounted || availableAds.isEmpty) return;

    final entry = availableAds[Random().nextInt(availableAds.length)];

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) =>
            AdScreen(entry: entry, imageDurationMs: adInfo.timeMs),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Sets up the tab controller and tab items.
  void _setupTabs() {
    if (!mounted) return;

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

  /// Handles tab selection changes.
  void _handleTabSelection() {
    if (mounted) {
      setState(() {});
    }
    if (!_tabController.indexIsChanging && mounted) {
      _initializeTab(_tabController.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabListenerAdded) {
      _tabController = TabController(length: 4, vsync: this);
    }
    _setupTabs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabScrollListeners.clear();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _showSearchBarNotifier.dispose();
    _isSearchActiveNotifier.dispose();
    _autoRefreshTimer?.cancel();
    _alertProvider?.removeListener(_attemptShowAd);
    AnalyticsService.instance.saveEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final l10n = AppLocalizations.of(context);

    _setupTabs();

    final isLargeScreen = MediaQuery.of(context).size.width >= 600;
    final topPadding = kToolbarHeight +
        MediaQuery.of(context).viewPadding.top +
        (isLargeScreen ? 8.0 : 0.0) +
        (isLargeScreen ? 0 : (56.0 + 2.0));

    if (appConfig.appName == "Riyales Default Fallback") {
      return const Scaffold(
          body: Center(child: Text("App configuration is using fallback.")));
    }

    final localeNotifier = context.watch<LocaleNotifier>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = hexToColor(isDarkMode
        ? appConfig.themeOptions.dark.accentColorGreen
        : appConfig.themeOptions.light.accentColorGreen);
    final themeConfig =
        isDarkMode ? appConfig.themeOptions.dark : appConfig.themeOptions.light;
    final segmentActiveBackground = isDarkMode
        ? tealGreen.withAlpha((255 * 0.15).round())
        : Theme.of(context).colorScheme.secondaryContainer.withAlpha(160);
    final segmentActiveTextColor = isDarkMode
        ? tealGreen.withAlpha((255 * 0.9).round())
        : Theme.of(context).colorScheme.onSecondaryContainer;
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

    final mainTabViews = _buildTabViews(topPadding);

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
                  : Theme.of(context).scaffoldBackgroundColor.withAlpha(160),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: _onTitleTapped,
          child: Seo.text(
            text: l10n.riyalesAppTitle,
            style: TextTagStyle.h1,
            child: Text(
              l10n.riyalesAppTitle,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        actions: _buildAppBarActions(isDarkMode, localeNotifier),
        bottom: isLargeScreen
            ? null
            : _buildTabBar(l10n, isDarkMode,
                tabLabelGroup: AutoSizeGroup(),
                selectedTextStyle: selectedTextStyle,
                unselectedTextStyle: unselectedTextStyle,
                themeConfig: themeConfig,
                segmentActiveBackground: segmentActiveBackground,
                tealGreen: tealGreen),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return _buildMobileLayout(mainTabViews);
          }
          return _buildDesktopLayout(mainTabViews, l10n, isDarkMode, tealGreen);
        },
      ),
    );

    return NetworkAwareWidget(
      onlineWidget: mainScaffold,
      offlineBuilder: (status) => _buildOfflineScaffold(l10n, status),
    );
  }

  /// Builds the tab views for all asset types.
  List<Widget> _buildTabViews(double topPadding) {
    return [
      ValueListenableBuilder<bool>(
          valueListenable: _isSearchActiveNotifier,
          builder: (context, isSearchActive, _) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, _) {
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
          builder: (context, isSearchActive, _) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, _) {
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
          builder: (context, isSearchActive, _) {
            return ValueListenableBuilder<bool>(
                valueListenable: _showSearchBarNotifier,
                builder: (context, showSearchBar, _) {
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
                      useCardAnimation: true,
                    ),
                  );
                });
          }),
      ValueListenableBuilder<bool>(
        valueListenable: _isSearchActiveNotifier,
        builder: (context, isSearchActive, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: _showSearchBarNotifier,
            builder: (context, showSearchBar, _) {
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
  }

  /// Builds the app bar actions (search and settings buttons).
  List<Widget> _buildAppBarActions(
      bool isDarkMode, LocaleNotifier localeNotifier) {
    return [
      AnimatedAlign(
        alignment: localeNotifier.locale.languageCode == 'fa'
            ? Alignment.centerLeft
            : Alignment.center,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isSearchActiveNotifier,
          builder: (context, isSearchActive, _) {
            final icon = Icon(
              isSearchActive ? CupertinoIcons.clear : CupertinoIcons.search,
              key: ValueKey<bool>(isSearchActive),
              color: _showSearchBarNotifier.value
                  ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                  : (isDarkMode ? Colors.white : Colors.black),
              size: 28,
            );

            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: icon,
              ),
              onPressed: () => _handleSearchButtonPressed(isSearchActive),
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent)),
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
                onTap: () => _handleSettingsButtonPressed(isSearchActive),
                child: child,
              );
            },
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(CupertinoIcons.person_crop_circle, size: 28),
            ),
          ),
        ),
      ),
    ];
  }

  /// Handles the search button press.
  void _handleSearchButtonPressed(bool isSearchActive) {
    AnalyticsService.instance.logEvent('button_click', {'button': 'search'});
    if (isSearchActive) {
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
        final maxScroll = controller.position.maxScrollExtent;
        final offset = controller.offset;
        final ratio =
            maxScroll > 0 ? (offset / maxScroll).clamp(0.0, 1.0) : 0.0;
        final durationMs = (300 + (500 * ratio)).toInt();

        controller
            .animateTo(0,
                duration: Duration(milliseconds: durationMs),
                curve: Curves.easeInOutQuart)
            .then((_) {
          if (mounted) {
            _toggleSearchBar(true);
            _setupScrollListener(currentTabIndex);
          }
        });
      }
    } else {
      _toggleSearchBar(true);
    }
  }

  /// Handles the settings button press.
  void _handleSettingsButtonPressed(bool isSearchActive) {
    AnalyticsService.instance.logEvent('button_click', {'button': 'settings'});
    if (isSearchActive) {
      context.read<SearchQueryNotifier>().query = '';
      _toggleSearchBar(false);
    }
    showCupertinoModalPopup(
        context: context,
        useRootNavigator: true,
        builder: (_) => const SettingsSheet());
  }

  /// Builds the tab bar for mobile layout.
  PreferredSize _buildTabBar(
    AppLocalizations l10n,
    bool isDarkMode, {
    required AutoSizeGroup tabLabelGroup,
    required TextStyle selectedTextStyle,
    required TextStyle unselectedTextStyle,
    required dynamic themeConfig,
    required Color segmentActiveBackground,
    required Color tealGreen,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0 + 2.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 2.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final horizontalMargin = isMobile ? 4.0 : 0.0;
            final BorderRadius tabBorderRadius = BorderRadius.circular(21.0);

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

                return isMobile
                    ? Expanded(
                        child: _buildTabButton(
                            index,
                            label,
                            isSelected,
                            isDarkMode,
                            tabBorderRadius,
                            tabLabelGroup,
                            selectedTextStyle,
                            unselectedTextStyle,
                            themeConfig,
                            segmentActiveBackground,
                            tealGreen))
                    : Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalMargin),
                        child: _buildTabButton(
                            index,
                            label,
                            isSelected,
                            isDarkMode,
                            tabBorderRadius,
                            tabLabelGroup,
                            selectedTextStyle,
                            unselectedTextStyle,
                            themeConfig,
                            segmentActiveBackground,
                            tealGreen));
              }),
            );
          },
        ),
      ),
    );
  }

  /// Builds an individual tab button.
  Widget _buildTabButton(
      int index,
      String label,
      bool isSelected,
      bool isDarkMode,
      BorderRadius tabBorderRadius,
      AutoSizeGroup tabLabelGroup,
      TextStyle selectedTextStyle,
      TextStyle unselectedTextStyle,
      dynamic themeConfig,
      Color segmentActiveBackground,
      Color tealGreen) {
    final tabContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Center(
        child: Builder(builder: (context) {
          Widget autoText = AutoSizeText(
            label,
            style: isSelected ? selectedTextStyle : unselectedTextStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            group: tabLabelGroup,
            minFontSize: 8,
            overflow: TextOverflow.ellipsis,
          );

          if (isSelected && !isDarkMode) {
            autoText = Transform.translate(
                offset: const Offset(0, 1), child: autoText);
          }

          return autoText;
        }),
      ),
    );

    Widget segment = isSelected
        ? SmoothCard(
            smoothness: themeConfig.cardCornerSmoothness,
            borderRadius: tabBorderRadius,
            elevation: 0,
            color: segmentActiveBackground,
            child: tabContent,
          )
        : SmoothCard(
            smoothness: themeConfig.cardCornerSmoothness,
            borderRadius: tabBorderRadius,
            elevation: 0,
            color: Colors.transparent,
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: SmoothRectangleBorder(
                  borderRadius: tabBorderRadius,
                  smoothness: themeConfig.cardCornerSmoothness,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color.fromARGB(255, 90, 90, 90).withAlpha(38)
                        : const Color.fromARGB(255, 255, 255, 255)
                            .withAlpha(252),
                    borderRadius: BorderRadius.circular(21.0),
                  ),
                  child: tabContent,
                ),
              ),
            ),
          );

    return GestureDetector(
      onTap: () => _handleTabTap(index),
      onLongPress: () => _showSortSheet(index),
      child: segment,
    );
  }

  /// Handles tab tap events.
  void _handleTabTap(int index) {
    final englishTabName = _englishTabNames[index];
    AnalyticsService.instance.logEvent('tab_visit', {'tab_id': englishTabName});

    if (_tabController.index == index) {
      final controller =
          _tabScrollControllers[index] ??= _findScrollController(index);
      if (controller != null && controller.hasClients) {
        final maxScroll = controller.position.maxScrollExtent;
        final offset = controller.offset;
        final ratio =
            maxScroll > 0 ? (offset / maxScroll).clamp(0.0, 1.0) : 0.0;
        final durationMs = (300 + (500 * ratio)).toInt();

        controller.animateTo(0,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeInOutQuart);
      }
    } else if (mounted) {
      setState(() => _tabController.animateTo(index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart));
    }
  }

  /// Builds the mobile layout with tab views.
  Widget _buildMobileLayout(List<Widget> mainTabViews) {
    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final index = _tabController.index;
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

  /// Builds the desktop layout with navigation rail.
  Widget _buildDesktopLayout(List<Widget> mainTabViews, AppLocalizations l10n,
      bool isDarkMode, Color tealGreen) {
    final isRTL = Localizations.localeOf(context).languageCode == 'fa';

    return Row(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: 15.0, left: isRTL ? 0.0 : 7.0, right: isRTL ? 7.0 : 0.0),
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: _buildNavigationRail(l10n, isDarkMode, tealGreen, isRTL),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
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
  }

  /// Builds the navigation rail for desktop layout.
  NavigationRail _buildNavigationRail(
      AppLocalizations l10n, bool isDarkMode, Color tealGreen, bool isRTL) {
    return NavigationRail(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      indicatorColor: isDarkMode
          ? tealGreen.withAlpha(38)
          : Theme.of(context).colorScheme.secondaryContainer.withAlpha(160),
      useIndicator: true,
      minWidth: 68,
      minExtendedWidth: 130,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -1.0,
      selectedIconTheme: IconThemeData(
        color: isDarkMode ? tealGreen.withAlpha(230) : Colors.white,
        size: 22,
      ),
      selectedLabelTextStyle: TextStyle(
        color: isDarkMode ? tealGreen.withAlpha(230) : tealGreen.withAlpha(430),
        fontWeight: FontWeight.w500,
        fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
      ),
      unselectedIconTheme: IconThemeData(
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
        size: 22,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
        fontWeight: FontWeight.w500,
        fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
      ),
      selectedIndex: _tabController.index,
      onDestinationSelected: (index) =>
          _handleNavigationRailItemSelected(index),
      destinations: _buildNavigationRailDestinations(l10n, isRTL),
    );
  }

  /// Builds the navigation rail destinations.
  List<NavigationRailDestination> _buildNavigationRailDestinations(
      AppLocalizations l10n, bool isRTL) {
    final destinations = [
      NavigationRailDestination(
        icon: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(0),
          onDoubleTap: () => _showSortSheet(0),
          child: const Icon(CupertinoIcons.money_dollar, size: 22),
        ),
        label: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(0),
          onDoubleTap: () => _showSortSheet(0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(l10n.tabCurrency),
          ),
        ),
      ),
      NavigationRailDestination(
        icon: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(1),
          onDoubleTap: () => _showSortSheet(1),
          child: const Icon(CupertinoIcons.sparkles, size: 22),
        ),
        label: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(1),
          onDoubleTap: () => _showSortSheet(1),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(l10n.tabGold),
          ),
        ),
      ),
      NavigationRailDestination(
        icon: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(2),
          onDoubleTap: () => _showSortSheet(2),
          child: const Icon(CupertinoIcons.bitcoin_circle, size: 22),
        ),
        label: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showSortSheet(2),
          onDoubleTap: () => _showSortSheet(2),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(l10n.tabCrypto),
          ),
        ),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.trending_up, size: 22),
        label: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(l10n.tabStock),
        ),
      ),
    ];

    if (_isDesktopWeb) {
      destinations.add(NavigationRailDestination(
        icon: const Icon(CupertinoIcons.cloud_download, size: 22),
        label: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(isRTL ? "دانلود" : "App"),
        ),
      ));
    }

    return destinations;
  }

  /// Handles navigation rail item selection.
  void _handleNavigationRailItemSelected(int index) {
    if (_isDesktopWeb && index == _mainTabs.length) {
      _launchDownloadUrl();
    } else {
      if (index < _mainTabs.length && _mainTabs[index].text != null) {
        final englishTabName = _englishTabNames[index];
        AnalyticsService.instance
            .logEvent('tab_visit', {'tab_id': englishTabName});
      }

      // Check if the same tab is already selected - scroll to top
      if (_tabController.index == index) {
        _scrollToTopForDesktop(index);
      } else {
        setState(() => _tabController.animateTo(index));
      }
    }
  }

  /// Scrolls to top for desktop navigation rail when the same tab is tapped.
  void _scrollToTopForDesktop(int index) {
    final controller =
        _tabScrollControllers[index] ??= _findScrollController(index);
    if (controller != null && controller.hasClients) {
      final maxScroll = controller.position.maxScrollExtent;
      final offset = controller.offset;
      final ratio = maxScroll > 0 ? (offset / maxScroll).clamp(0.0, 1.0) : 0.0;
      final durationMs = (300 + (500 * ratio)).toInt();

      controller.animateTo(0,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeInOutQuart);
    }
  }

  /// Builds the scaffold for offline mode.
  Widget _buildOfflineScaffold(AppLocalizations l10n, ConnectionStatus status) {
    return Scaffold(
      appBar: AppBar(
        title: Seo.text(
          text: l10n.riyalesAppTitle,
          style: TextTagStyle.h1,
          child: Text(l10n.riyalesAppTitle),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isSearchActiveNotifier,
              builder: (context, isSearchActiveValue, child) {
                return GestureDetector(
                  onTap: () {
                    if (isSearchActiveValue) {
                      context.read<SearchQueryNotifier>().query = '';
                      _toggleSearchBar(false);
                    }
                    showCupertinoModalPopup(
                        context: context,
                        useRootNavigator: true,
                        builder: (_) => const SettingsSheet());
                  },
                  child: child,
                );
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
        ],
      ),
      body: Center(child: ErrorPlaceholder(status: status)),
    );
  }

  /// Finds the appropriate scroll controller for the current tab.
  ScrollController? _findScrollController(int tabIndex) {
    if (!mounted) return null;

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
            final activeStockTabIndex = stockState.stockTabController.index;
            return stockState.stockScrollControllers[activeStockTabIndex];
          }
          return null;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Handles title taps for easter egg activation.
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
      _showCustomSnackBar(message, isRTL);
    }
  }

  /// Shows a custom overlay snack bar.
  void _showCustomSnackBar(String message, bool isRTL) {
    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
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
    controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      await controller.reverse();
      entry.remove();
      controller.dispose();
    });
  }

  /// Shows sort options sheet for the specified tab index.
  void _showSortSheet(int index) {
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

    final appConfig = context.read<AppConfig>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = hexToColor(
      isDark
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

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

  /// Toggles search bar visibility and updates related state.
  void _toggleSearchBar(bool show) {
    if (_showSearchBarNotifier.value != show) {
      _showSearchBarNotifier.value = show;
      _isSearchActiveNotifier.value = show;

      if (!show) {
        context.read<SearchQueryNotifier>().query = '';
      }
    }
  }
}
