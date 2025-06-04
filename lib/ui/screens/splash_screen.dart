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
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final imagePath = isDarkMode
        ? widget.config.logoPathDark
        : widget.config.logoPathLight;

    final backgroundColor = isDarkMode
        ? hexToColor(widget.config.backgroundColorDark)
        : hexToColor(widget.config.backgroundColorLight);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * widget.config.logoTopMarginFactor), // Use factor from config
            Center(
              child: SvgPicture.asset(
                imagePath,
                width: widget.config.logoWidth,
                height: widget.config.logoHeight,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * widget.config.loaderBottomMarginFactor), // Use factor
              child: CupertinoActivityIndicator(
                radius: widget.config.loaderRadius, // Use config
                color: hexToColor(isDarkMode ? widget.config.loaderColorDark : widget.config.loaderColorLight), // Use config
              ),
            ),
          ],
        ),
      ),
    );
  }
}
