// Dart imports
import 'dart:ui' as ui;

// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Third-party packages
import 'package:provider/provider.dart';

// Local project imports
import '../../providers/locale_provider.dart';
import '../../providers/terms_provider.dart';

/// Shows the Terms and Conditions content fetched by TermsNotifier.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final locale = localeNotifier.locale;

    final termsNotifier = context.watch<TermsNotifier>();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFa = locale.languageCode == 'fa';
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final fadedTextColor = isDarkMode ? Colors.grey[500] : Colors.grey[500];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Builder(
          // Use Builder to handle different states from TermsNotifier
          builder: (context) {
            if (termsNotifier.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (termsNotifier.error != null ||
                termsNotifier.termsData == null) {
              return Center(
                child: Text(
                  isFa ? 'خطا در بارگیری اطلاعات.' : 'Error loading data.',
                  style: TextStyle(
                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              );
            }
            final terms = termsNotifier.termsData!;
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: isFa
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Icon(
                                  isFa
                                      ? CupertinoIcons.chevron_right
                                      : CupertinoIcons.chevron_left,
                                  size: 18,
                                  color: fadedTextColor,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              terms.title,
                              style: TextStyle(
                                fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              terms.content,
                              style: TextStyle(
                                fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 1.7,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                              textAlign:
                                  isFa ? TextAlign.right : TextAlign.left,
                              textDirection: isFa
                                  ? ui.TextDirection.rtl
                                  : ui.TextDirection.ltr,
                            ),
                            if (terms.lastUpdated.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 24, bottom: 16),
                                child: Center(
                                  child: Text(
                                    isFa
                                        ? 'آخرین بروزرسانی: ${terms.lastUpdated}'
                                        : 'Last updated: ${terms.lastUpdated}',
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 12,
                                      color: fadedTextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
