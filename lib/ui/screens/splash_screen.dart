// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Third-party packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Local project imports
import 'package:riyales/providers/alert_provider.dart';
import 'package:riyales/services/analytics_service.dart';
import 'package:riyales/services/device_info_service.dart';
import 'package:riyales/ui/screens/home_screen.dart';
import '../../config/app_config.dart' as config_model;

/// Displays the splash screen, initializes services, and navigates to HomeScreen.
class SplashScreen extends StatefulWidget {
  final config_model.SplashScreenConfig config;
  const SplashScreen({super.key, required this.config});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // First send any events from previous session
    await AnalyticsService.instance.sendPreviousEvents();

    // Then collect device info (will only send if not sent before)
    DeviceInfoService().collectAndSendDeviceInfo();

    // Fetch alert data in the background
    if (mounted) {
      Provider.of<AlertProvider>(context, listen: false).fetchAlert();
    }

    // Navigate after splash duration
    await Future.delayed(
        Duration(milliseconds: (widget.config.durationSeconds * 1000).toInt()));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final basePath = widget.config.iconPath;
    final imagePath = isDarkMode
        ? basePath.replaceAll('light', 'dark')
        : basePath.replaceAll('dark', 'light');

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    const double logoTopMarginFactor = 0.20;
    const double logoSize = 62.0;
    const double loaderBottomMarginFactor = 0.15;
    const double loaderRadius = 10.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * logoTopMarginFactor),
            Center(
              child: SvgPicture.asset(
                imagePath,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                allowDrawingOutsideViewBox: true,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(
                  bottom: screenHeight * loaderBottomMarginFactor),
              child: const CupertinoActivityIndicator(
                radius: loaderRadius,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
