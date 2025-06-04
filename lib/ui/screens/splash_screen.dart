import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_config.dart' as config_model; // Aliased to avoid conflict with widget's config parameter
import './home_screen.dart';
import '../../utils/color_utils.dart'; // For hexToColor

class SplashScreen extends StatefulWidget {
  final config_model.SplashScreenConfig config; // Use aliased config
  const SplashScreen({super.key, required this.config});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(milliseconds: (widget.config.durationSeconds * 1000).toInt()),
      () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Use the iconPath from config directly.
    // If specific dark/light mode icons are needed, the config should provide them or logic here should adapt.
    final imagePath = widget.config.iconPath;

    // Use scaffoldBackgroundColor as SplashScreenConfig doesn't define background colors.
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Define fixed values for layout as these are not in SplashScreenConfig
    const double logoTopMarginFactor = 0.25; // Adjusted factor
    const double logoSize = 120.0; // Fixed size for width and height
    const double loaderBottomMarginFactor = 0.15; // Adjusted factor
    const double loaderRadius = 14.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * logoTopMarginFactor),
            Center(
              child: SvgPicture.asset(
                imagePath, // Use path from config
                width: logoSize,
                height: logoSize,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * loaderBottomMarginFactor),
              child: CupertinoActivityIndicator(
                radius: loaderRadius,
                color: hexToColor(widget.config.loadingIndicatorColor), // Use color from config
              ),
            ),
          ],
        ),
      ),
    );
  }
}
