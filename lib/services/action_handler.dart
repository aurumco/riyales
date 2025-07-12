import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riyales/ui/screens/terms_screen.dart';
import 'package:riyales/ui/widgets/settings_sheet.dart';
import 'package:riyales/providers/search_provider.dart';

/// Handles user-triggered actions and executes navigation or UI commands.
class ActionHandler {
  /// Executes the given [action] within [context], using [tabController] for tab navigation when applicable.
  static void handle(
      BuildContext context, String action, TabController? tabController) {
    if (action.startsWith('open_tab:')) {
      final tabName = action.substring('open_tab:'.length);
      int tabIndex = -1;
      switch (tabName) {
        case 'currency':
          tabIndex = 0;
          break;
        case 'gold':
          tabIndex = 1;
          break;
        case 'crypto':
          tabIndex = 2;
          break;
        case 'stock':
          tabIndex = 3;
          break;
      }
      if (tabIndex != -1 && tabController != null) {
        tabController.animateTo(tabIndex);
      } else {
        // No matching action; no operation.
      }
    } else {
      switch (action) {
        case 'open_settings':
          showCupertinoModalPopup(
            context: context,
            builder: (_) => const SettingsSheet(),
          );
          break;
        case 'open_terms':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TermsAndConditionsScreen(),
            ),
          );
          break;
        case 'open_search':
          final searchNotifier =
              Provider.of<SearchQueryNotifier>(context, listen: false);
          searchNotifier.query = '';
          break;
        case 'open_contact':
          // Get the current locale to determine the language for the email
          final locale = Localizations.localeOf(context);
          // Build mailto URL manually to avoid '+' encoding for spaces
          final subject = locale.languageCode == 'fa'
              ? Uri.encodeComponent('درخواست پشتیبانی')
              : Uri.encodeComponent('Support Request');
          final body = locale.languageCode == 'fa'
              ? Uri.encodeComponent('سلام،\n\nلطفاً به من در مورد...')
              : Uri.encodeComponent('Hello,\n\nPlease assist me with...');
          final emailUrl = 'mailto:info@ryls.ir?subject=$subject&body=$body';
          launchUrl(Uri.parse(emailUrl));
          break;
        default:
        // No matching action; no operation.
      }
    }
  }
}
