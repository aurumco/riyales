import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riyales/ui/screens/terms_screen.dart';
import 'package:riyales/ui/widgets/settings_sheet.dart';
import 'package:riyales/providers/search_provider.dart';

class ActionHandler {
  static void handle(
      BuildContext context, String action, TabController? tabController) {
    if (kDebugMode) {
      print('[ActionHandler] Received action: "$action"');
    }

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
        if (kDebugMode) {
          print(
              '[ActionHandler] Navigating to tab: $tabName (index: $tabIndex)');
        }
        tabController.animateTo(tabIndex);
      } else {
        if (kDebugMode) {
          print(
              '[ActionHandler] Failed to navigate to tab: $tabName. TabController is ${tabController == null ? "null" : "not null"}.');
        }
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
          // This is a placeholder for how search might be activated.
          // The actual implementation in home_screen.dart is more complex
          // and relies on ValueNotifiers that aren't easily accessible here.
          // This might need a more robust state management solution (e.g., a provider)
          // to be triggered from here.
          final searchNotifier =
              Provider.of<SearchQueryNotifier>(context, listen: false);
          searchNotifier.query = '';
          if (kDebugMode) {
            print(
                '[ActionHandler] "open_search" action called, but UI toggling from here is complex. See handler comments.');
          }
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
          if (kDebugMode) {
            print('[ActionHandler] Unknown action received: "$action"');
          }
      }
    }
  }
}
