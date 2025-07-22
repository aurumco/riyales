import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_config.dart';
import '../../../providers/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateBlocker extends StatelessWidget {
  const ForceUpdateBlocker({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appConfig = context.read<AppConfig>();
    final locale = context.read<LocaleNotifier>().locale;
    final isRTL = locale.languageCode == 'fa';
    final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';
    final primaryGreen = isDarkMode
        ? Color.fromARGB(255, 0, 202, 104)
        : Color.fromARGB(255, 0, 192, 92);
    final updateInfo = appConfig.updateInfo;

    final String title = isRTL ? 'بروزرسانی ضروری' : 'Mandatory Update';
    final String message = isRTL
        ? 'برای استفاده از ریالِس باید نسخه جدید را نصب کنید.\nاین نسخه دیگر پشتیبانی نمی‌شود.'
        : 'A new version of the app is required.\nThis version is no longer supported.';
    final String marketBtn =
        isRTL ? 'بروزرسانی از مارکت' : 'Update from Market';
    final String siteBtn = isRTL ? 'بروزرسانی از سایت' : 'Update from Website';
    final String marketPackage = updateInfo.updatePackage;
    final String siteUrl = updateInfo.updateLink;

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final iconAndTitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final messageColor = isDarkMode ? Colors.grey[500] : Colors.grey[700];
    return Container(
      width: double.infinity,
      color: scaffoldBg,
      child: SafeArea(
        bottom: false, // Only avoid system insets at the top
        child: Container(
          width: double.infinity,
          color: scaffoldBg,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down_circle,
                            size: 56,
                            color: iconAndTitleColor,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: iconAndTitleColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              message,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                color: messageColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? const Color.fromARGB(255, 27, 27, 27)
                                  : const Color.fromARGB(255, 229, 229, 229),
                              foregroundColor:
                                  isDarkMode ? Colors.white : Colors.black,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              minimumSize: Size.fromHeight(isRTL ? 42 : 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ).copyWith(
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              shadowColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              surfaceTintColor:
                                  WidgetStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () async {
                              final storeUri = Uri.parse(
                                  'market://details?id=$marketPackage');
                              if (await canLaunchUrl(storeUri)) {
                                await launchUrl(storeUri);
                              } else {
                                final webUri = Uri.parse(siteUrl);
                                await launchUrl(webUri);
                              }
                            },
                            child: Text(
                              marketBtn,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isRTL ? 6 : 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              minimumSize: Size.fromHeight(isRTL ? 42 : 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ).copyWith(
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              shadowColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              surfaceTintColor:
                                  WidgetStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(siteUrl);
                              await launchUrl(uri);
                            },
                            child: Text(
                              siteBtn,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
