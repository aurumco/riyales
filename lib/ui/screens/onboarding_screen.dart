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
      if (isPersian) {
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black),
            children: [
              const TextSpan(text: 'چه خبر\n'),
              const TextSpan(text: 'در '),
              TextSpan(text: 'ریالس', style: TextStyle(color: tealGreen)),
            ],
          ),
        );
      } else {
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
                fontFamily: 'SF-Pro',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black),
            children: [
              const TextSpan(text: "What's New\n"),
              const TextSpan(text: 'in '),
              TextSpan(text: 'Riyales', style: TextStyle(color: tealGreen)),
            ],
          ),
        );
      }
    }

    List<WhatsNewFeature> feats = isPersian
        ? [
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.pin, color: tealGreen),
              title: buildText('پین سریع'),
              description: buildText(
                  'فقط کافیست انگشت خود را روی یک دارایی نگه دارید تا پین شود.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.arrow_up_circle, color: tealGreen),
              title: buildText('بازگشت به بالا'),
              description: buildText(
                  'با یک ضربه روی تَب فعلی، لیست به ابتدای صفحه اسکرول می‌شود.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.sort_down, color: tealGreen),
              title: buildText('مرتب‌سازی هوشمند'),
              description: buildText(
                  'برای مرتب کردن بر اساس قیمت، انگشت خود را روی تَب فعلی نگه دارید.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.person_circle, color: tealGreen),
              title: buildText('تنظیمات سریع'),
              description: buildText(
                  'برای تغییر زبان، تم و سایر گزینه‌ها روی آیکون پروفایل بزنید.'),
            ),
          ]
        : [
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.pin, color: tealGreen),
              title: buildText('Quick Pin'),
              description: buildText(
                  'Long-press any asset card and it will be pinned on top.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.arrow_up_circle, color: tealGreen),
              title: buildText('Scroll to Top'),
              description: buildText(
                  'Tap the active tab again to instantly scroll back to top.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.sort_down, color: tealGreen),
              title: buildText('Smart Sorting'),
              description: buildText(
                  'Long-press the active tab to sort prices high-to-low or low-to-high.'),
            ),
            WhatsNewFeature(
              icon: Icon(CupertinoIcons.person_circle, color: tealGreen),
              title: buildText('Quick Settings'),
              description: buildText(
                  'Tap the profile icon to adjust language, theme, and more.'),
            ),
          ];

    // Link to Terms & Conditions displayed above the Continue button
    final termsLink = CupertinoButton(
      padding: EdgeInsets.zero,
      child: Text(
        isPersian
            ? 'استفاده از اپلیکیشن به منزلهٔ پذیرش قوانین است'
            : 'By using the app you accept the Terms of Service',
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
            // Save that onboarding was shown and dismissed by user
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_shown_v1', true);

            // Navigate back to HomeScreen with slide animation
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
                isPersian ? 'ادامه' : 'Continue',
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
