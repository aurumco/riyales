import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/connection_service.dart';
import '../../../localization/l10n_utils.dart';
import '../../../providers/locale_provider.dart';
import '../../../config/app_config.dart';

/// Snackbar shown when network connectivity changes.
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
            ? Theme.of(context).colorScheme.secondary
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

/// Offline indicator shown when network is not available.
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

/// Widget that switches UI based on network connectivity.
class NetworkAwareWidget extends StatefulWidget {
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
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  late StreamSubscription<ConnectionStatus> _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.connected;
  final ConnectionService connectionService = ConnectionService();

  @override
  void initState() {
    super.initState();

    _currentStatus = connectionService.isOnline
        ? ConnectionStatus.connected
        : ConnectionStatus.internetDown;

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
          setState(() {
            _currentStatus = status;
          });
        }

        if (mounted && context.mounted) {
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
    if (!mounted) return;
    final appConfig = context.read<AppConfig>();
    if (appConfig.remoteConfigUrl.isNotEmpty) {
      await connectionService
          .checkConnection(appConfig.apiEndpoints.currencyUrl);
    } else {
      await connectionService.checkConnection('https://www.google.com');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    return Stack(
      alignment: Alignment.center,
      children: [
        widget.onlineWidget,
        const OfflineIndicator(),
      ],
    );
  }
}
