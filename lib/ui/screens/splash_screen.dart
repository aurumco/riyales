import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:riyales/providers/alert_provider.dart';
import 'package:riyales/services/analytics_service.dart';
import 'package:riyales/services/device_info_service.dart';
import 'package:riyales/ui/screens/home_screen.dart';

import '../../config/app_config.dart'
    as config_model; // Aliased to avoid conflict with widget's config parameter

class SplashScreen extends StatefulWidget {
  final config_model.SplashScreenConfig config; // Use aliased config
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
    // No need to await, it can load while the splash screen is visible
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
          transitionDuration: const Duration(milliseconds: 500),
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

    // Use scaffoldBackgroundColor as SplashScreenConfig doesn't define background colors.
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Define fixed values for layout as these are not in SplashScreenConfig
    const double logoTopMarginFactor = 0.20; // Raised icon higher
    const double logoSize = 62.0; // Increased icon size by 2
    const double loaderBottomMarginFactor = 0.15; // Adjusted factor
    const double loaderRadius = 10.0; // Smaller loading indicator

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * logoTopMarginFactor),
            Center(
              child: SvgPicture.asset(
                imagePath, // Use path from config based on theme
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
                // Made const
                radius: loaderRadius,
                color: Colors.grey, // Use default iOS grey color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
