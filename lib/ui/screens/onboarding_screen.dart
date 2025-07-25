// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local project imports
import '../../config/app_config.dart';
import '../../providers/locale_provider.dart';
import '../../utils/color_utils.dart';
import 'terms_screen.dart';
import 'home_screen.dart';
import '../../generated/app_localizations.dart';

/// Shows onboarding screens with feature highlights and navigates to HomeScreen.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appConfig = context.watch<AppConfig>();
    final isPersian = locale.languageCode == 'fa';

    final tealGreen = hexToColor(isDark
        ? appConfig.themeOptions.dark.accentColorGreen
        : appConfig.themeOptions.light.accentColorGreen);

    // Helper to build text with correct theme-aware colors.
    Text buildText(
      String txt, {
      bool title = false,
      Color? color,
      TextAlign align = TextAlign.start,
    }) {
      // Title texts get full-contrast color; description slightly faded.
      final defaultColor = title
          ? (isDark ? CupertinoColors.white : CupertinoColors.black)
          : (isDark
              ? CupertinoColors.white.withAlpha(204) // ~0.8 opacity
              : CupertinoColors.black.withAlpha(153)); // ~0.6 opacity

      return Text(
        txt,
        textAlign: align,
        style: TextStyle(
          fontFamily: isPersian ? 'Vazirmatn' : 'SF-Pro',
          fontSize: title ? 28 : 17,
          height: 1.25,
          fontWeight: title ? FontWeight.w700 : FontWeight.normal,
          color: color ?? defaultColor,
        ),
      );
    }

    // title two-line with colored app name
    Widget titleWidget() {
      final l10n = AppLocalizations.of(context);
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
              fontFamily: isPersian ? 'Vazirmatn' : 'SF-Pro',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : CupertinoColors.black),
          children: [
            TextSpan(text: "${l10n.onboardingWhatsNew}\n"),
            TextSpan(text: "${l10n.onboardingIn} "),
            TextSpan(
                text: l10n.onboardingAppName,
                style: TextStyle(color: tealGreen)),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    List<WhatsNewFeature> feats = [
      WhatsNewFeature(
        icon: Icon(CupertinoIcons.pin, color: tealGreen),
        title: buildText(l10n.onboardingQuickPin),
        description: buildText(l10n.onboardingQuickPinDesc),
      ),
      WhatsNewFeature(
        icon: Icon(CupertinoIcons.share, color: tealGreen),
        title: buildText(l10n.onboardingShareCard),
        description: buildText(l10n.onboardingShareCardDesc),
      ),
      WhatsNewFeature(
        icon: Icon(CupertinoIcons.arrow_up_circle, color: tealGreen),
        title: buildText(l10n.onboardingScrollToTop),
        description: buildText(l10n.onboardingScrollToTopDesc),
      ),
      WhatsNewFeature(
        icon: Icon(CupertinoIcons.person_circle, color: tealGreen),
        title: buildText(l10n.onboardingQuickSettings),
        description: buildText(l10n.onboardingQuickSettingsDesc),
      ),
    ];

    // Link to Terms & Conditions displayed above the Continue button
    final termsLink = CupertinoButton(
      padding: EdgeInsets.zero,
      child: Text(
        l10n.onboardingTermsAccept,
        style: TextStyle(
          fontFamily: isPersian ? 'Vazirmatn' : 'SF-Pro',
          fontSize: 15,
          color: tealGreen,
        ),
        textAlign: TextAlign.center,
      ),
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => const TermsAndConditionsScreen(),
        ),
      ),
    );

    // Custom continue button
    Widget customContinueButton() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: GestureDetector(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_shown_v1', true);
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, animation, secondaryAnimation) =>
                      const HomeScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutQuart;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 360),
                ),
              );
            }
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: tealGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                l10n.onboardingContinue,
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontFamily: isPersian ? 'Vazirmatn' : 'SF-Pro',
                  fontSize: isPersian ? 17 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: isPersian ? -0.5 : 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Create a custom page transition animation
    Widget buildContent() {
      return Column(
        children: [
          Expanded(
            child: WhatsNewPage(
              title: titleWidget(),
              features: feats,
              titleToBodySpacing: 65,
              featuresSeperator: const SizedBox(height: 35),
            ),
          ),
          // Footer with terms link and continue button
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                termsLink,
                const SizedBox(height: 16),
                customContinueButton(),
              ],
            ),
          ),
        ],
      );
    }

    // Use a custom route animation for both languages
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: buildContent(),
      ),
    );
  }
}
