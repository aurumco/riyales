import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added Provider

import '../../../services/connection_service.dart'; // For ConnectionStatus and ConnectionService
import '../../../localization/l10n_utils.dart';
import '../../../providers/locale_provider.dart'; // For RTL check in Snackbar
import '../../../config/app_config.dart'; // For AppConfig type
// import '../../../providers/app_config_provider.dart'; // No longer needed for FutureProvider access here

// --- ConnectionSnackbar ---
class ConnectionSnackbar {
  static void show(
    BuildContext context, {
    required bool isConnected,
    required bool isRTL,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.secondary // Consider theming this
            : Theme.of(context).colorScheme.error,
        margin: const EdgeInsets.only(
          bottom: 10,
          left: 10,
          right: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Icon(
              isConnected ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              isConnected
                  ? AppLocalizations.of(context).youreBackOnline
                  : AppLocalizations.of(context).youreOffline,
              style: TextStyle(
                fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                color: Colors.white,
              ),
            ),
          ],
        ),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

// --- OfflineIndicator ---
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.wifi_slash,
        size: 80,
        color: Colors.grey.withAlpha((255 * 0.2).round()),
      ),
    );
  }
}

// --- NetworkAwareWidget ---
class NetworkAwareWidget extends StatefulWidget {
  // Changed to StatefulWidget
  final Widget onlineWidget;
  final Widget Function(ConnectionStatus)? offlineBuilder;
  final bool checkOnInit;

  const NetworkAwareWidget({
    super.key,
    required this.onlineWidget,
    this.offlineBuilder,
    this.checkOnInit = false,
  });

  @override
  State<NetworkAwareWidget> createState() =>
      _NetworkAwareWidgetState(); // Changed
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  // Changed from ConsumerState
  late StreamSubscription<ConnectionStatus> _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.connected;
  final ConnectionService connectionService = ConnectionService();

  @override
  void initState() {
    super.initState();

    _currentStatus = connectionService.isOnline
        ? ConnectionStatus.connected
        : ConnectionStatus.internetDown;

    // Access AppConfig via Provider within initState or didChangeDependencies for checkOnInit
    // This requires context, so typically done in didChangeDependencies or after first frame.
    // For simplicity, if checkOnInit is true, we'll try to read it here, assuming AppConfig is readily available.
    // A more robust way is to use a flag and check in didChangeDependencies or a post-frame callback.
    if (widget.checkOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure it's still mounted
          _checkConnectionOnInitWithProvider();
        }
      });
    }

    _subscription = connectionService.statusStream.listen((status) {
      if (_currentStatus != status) {
        if (mounted) {
          // Check if mounted before calling setState
          setState(() {
            _currentStatus = status;
          });
        }

        // Snackbar display should be safe as it uses the widget's context
        if (mounted && context.mounted) {
          // Ensure context is valid
          final localeNotifier = context.read<LocaleNotifier>();
          final isRTL = localeNotifier.locale.languageCode == 'fa';
          ConnectionSnackbar.show(
            context,
            isConnected: status == ConnectionStatus.connected,
            isRTL: isRTL,
          );
        }
      }
    });
  }

  Future<void> _checkConnectionOnInitWithProvider() async {
    if (!mounted) return; // Check mounted before using context
    final appConfig =
        context.read<AppConfig>(); // Using Provider to read AppConfig
    if (appConfig.remoteConfigUrl.isNotEmpty) {
      // Check if it's not the default empty config
      await connectionService
          .checkConnection(appConfig.apiEndpoints.currencyUrl);
    } else {
      // If AppConfig is the default one (e.g. FutureProvider hasn't resolved yet or failed with default),
      // use a generic ping URL or handle appropriately.
      await connectionService.checkConnection('https://www.google.com');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If checkOnInit is false, we might still want to update if the widget becomes visible
    // or if dependencies change that might affect connectivity checks (e.g. appConfig availability)
    // For now, keeping it simple and only re-checking if checkOnInit was true or based on initState.
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == ConnectionStatus.connected) {
      return widget.onlineWidget;
    }

    if (widget.offlineBuilder != null) {
      return widget.offlineBuilder!(_currentStatus);
    }

    // Default offline UI: show onlineWidget with OfflineIndicator overlay
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.onlineWidget,
        const OfflineIndicator(), // Ensure this doesn't obstruct interaction if onlineWidget is interactive
      ],
    );
  }
}

/*
// --- ConnectionServiceExtension (Commented out as WidgetRef is Riverpod specific) ---
// This extension will need to be re-evaluated.
// If the goal is to call checkConnectionBeforeLoading from a widget context,
// it might become a helper function taking BuildContext and reading ConnectionService via Provider.
// Or, the logic might be directly incorporated into ViewModels/ChangeNotifiers.

extension ConnectionServiceExtension on WidgetRef {
  Future<bool> checkConnectionBeforeLoading(String apiUrl) async {
    // Accessing ConnectionService directly, not via Riverpod provider for the service itself
    final connectionService = ConnectionService();
    final isConnected = await connectionService.checkConnection(apiUrl);
    return isConnected;
  }
}
*/
