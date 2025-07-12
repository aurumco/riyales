import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/connection_service.dart';

import '../../../localization/l10n_utils.dart';
import '../../../providers/locale_provider.dart';

/// Placeholder UI shown when connectivity errors occur.
class ErrorPlaceholder extends StatelessWidget {
  final ConnectionStatus status;

  const ErrorPlaceholder({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = context.watch<LocaleNotifier>();
    final currentLocale = localeNotifier.locale;
    final isRTL = currentLocale.languageCode == 'fa';

    String title = '';
    String message = '';
    IconData icon = CupertinoIcons.wifi_slash;
    Color iconColor = isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;

    switch (status) {
      case ConnectionStatus.internetDown:
        title = l10n.errorNoInternet;
        message = l10n.errorCheckConnection;
        icon = CupertinoIcons.wifi_slash;
        break;
      case ConnectionStatus.serverDown:
        title = l10n.errorServerUnavailable;
        message = l10n.errorServerMessage;
        icon = CupertinoIcons.exclamationmark_circle;
        break;
      case ConnectionStatus.connected:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: iconColor,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 10),
              const SizedBox(width: 12),
              Text(
                l10n.retrying,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
