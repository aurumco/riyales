import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:riyales/models/alert.dart';
import 'package:riyales/providers/alert_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class AdScreen extends StatefulWidget {
  final AdEntry entry;
  final int imageDurationMs;
  const AdScreen(
      {super.key, required this.entry, required this.imageDurationMs});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _progressController;
  VideoPlayerController? _videoController;
  late double _videoProgress = 0.0;

  bool _isVideo = false;
  bool _mediaReady = false;
  bool _isMuted = false;
  bool _isPaused = false;
  bool _hasCompleted = false;
  bool _adViewRecorded = false;

  File? _tempVideoFile;

  // Add GlobalKey to measure media width
  final GlobalKey _mediaKey = GlobalKey();
  double? _actualMediaWidth;

  @override
  void initState() {
    super.initState();
    _isMuted = kIsWeb;
    WidgetsBinding.instance.addObserver(this);

    _initializeMedia();
    _recordAdView();
  }

  /// Records that this ad has been viewed
  Future<void> _recordAdView() async {
    if (_adViewRecorded) return;

    try {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      await alertProvider.recordAdView(widget.entry.id);
      _adViewRecorded = true;
    } catch (e) {
      // Silent fail
    }
  }

  /// Starts the timer for image ads after the image is fully loaded
  void _startImageTimer() {
    if (_progressController != null) return; // Already started

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.imageDurationMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_hasCompleted) {
          _hasCompleted = true;
          if (mounted) Navigator.of(context).pop();
        }
      });
    _progressController!
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..forward();
  }

  Future<void> _initializeMedia() async {
    final url = widget.entry.url;
    _isVideo = widget.entry.isVideo;

    // Reset measured width for new media
    _actualMediaWidth = null;

    try {
      if (_isVideo) {
        try {
          if (!kIsWeb) {
            _tempVideoFile = File(
                '${Directory.systemTemp.path}/ad_${DateTime.now().millisecondsSinceEpoch}.tmp');
            final httpClient = HttpClient();
            final request = await httpClient.getUrl(Uri.parse(url));
            final response =
                await request.close().timeout(const Duration(seconds: 5));
            if (response.statusCode != 200) throw Exception('Bad status');
            final bytes = await (() async {
              final list = <int>[];
              await for (var chunk in response) {
                list.addAll(chunk);
              }
              return list;
            }())
                .timeout(const Duration(seconds: 5));
            await _tempVideoFile!.writeAsBytes(bytes);
            _videoController = VideoPlayerController.file(_tempVideoFile!);
          } else {
            _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
          }
        } catch (_) {
          if (mounted) Navigator.of(context).pop();
          return;
        }

        await _videoController!.initialize();
        if (!mounted) return;

        _videoController!
          ..setLooping(false)
          ..setVolume(_isMuted ? 0.0 : 0.7);

        if (kIsWeb) {
          Future.delayed(const Duration(seconds: 1), () {
            _videoController?.setVolume(0.7);
          });
        }

        // Video progress listener
        _videoController!.addListener(() {
          if (!mounted) return;
          final value = _videoController!.value;
          final position = value.position;
          final duration = value.duration;
          if (duration.inMilliseconds > 0) {
            setState(() {
              _videoProgress =
                  position.inMilliseconds / duration.inMilliseconds;
            });
          }
          if (value.isInitialized && position >= duration && !_hasCompleted) {
            _hasCompleted = true;
            if (mounted) Navigator.of(context).pop();
          }
        });
        _videoController!.play();

        if (mounted) setState(() => _mediaReady = true);
      } else {
        if (mounted) setState(() => _mediaReady = true);
      }
    } catch (e) {
      if (mounted && !_hasCompleted) {
        _hasCompleted = true;
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController?.dispose();
    _videoController?.dispose();
    _tempVideoFile?.delete();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_mediaReady) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pause();
    } else if (state == AppLifecycleState.resumed) {
      _resume();
    }
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController?.stop(canceled: false);
    _videoController?.pause();
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController?.forward();
    _videoController?.play();
  }

  void _measureMediaWidth() {
    if (_mediaKey.currentContext != null && _mediaReady) {
      final RenderBox renderBox =
          _mediaKey.currentContext!.findRenderObject() as RenderBox;
      final width = renderBox.size.width;
      if (width > 0 && _actualMediaWidth != width) {
        setState(() {
          _actualMediaWidth = width;
        });
      }
    }
  }

  Future<void> _openLink() async {
    final link = widget.entry.link;
    if (link.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.black;

    // Measure media width after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showFramed && _mediaReady) {
        _measureMediaWidth();
      }
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // First tap on video (web) enables sound; subsequent taps open the ad link.
          if (_isVideo && _isMuted) {
            _videoController?.setVolume(0.7);
            setState(() {
              _isMuted = false;
            });
          } else {
            _openLink();
          }
        },
        onLongPressDown: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 12,
              right: 12,
              child: _showFramed
                  ? Center(
                      child: _StoryProgressBar(
                        progress: _isVideo
                            ? _videoProgress.clamp(0.0, 1.0)
                            : (_progressController?.value ?? 0.0),
                        width: _actualMediaWidth ?? _framedWidth,
                      ),
                    )
                  : _StoryProgressBar(
                      progress: _isVideo
                          ? _videoProgress.clamp(0.0, 1.0)
                          : (_progressController?.value ?? 0.0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (!_mediaReady) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_isVideo) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: CupertinoActivityIndicator());
      }
      // Framed layout for desktop web vertical media
      if (_showFramed) {
        return Center(
          child: Container(
            key: _mediaKey,
            margin: const EdgeInsets.only(top: 10.0, bottom: 29.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        );
      }
      // Otherwise fill the screen.
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      final mediaQueryImg = MediaQuery.of(context);
      final bool isSmallScreen = mediaQueryImg.size.shortestSide < 600;
      final BoxFit fit = isSmallScreen ? BoxFit.fitHeight : BoxFit.contain;

      if (_showFramed) {
        return Center(
          child: Container(
            key: _mediaKey,
            margin: const EdgeInsets.only(top: 9.0, bottom: 28.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                widget.entry.url,
                fit: fit,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    // Image is fully loaded, start the timer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _progressController == null) {
                        _startImageTimer();
                      }
                    });
                    return child;
                  }
                  return const Center(child: CupertinoActivityIndicator());
                },
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(CupertinoIcons.exclamationmark_circle)),
              ),
            ),
          ),
        );
      }

      // Default behavior for mobile or non-framed
      return Image.network(
        widget.entry.url,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            // Image is fully loaded, start the timer
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _progressController == null) {
                _startImageTimer();
              }
            });
            return child;
          }
          return const Center(child: CupertinoActivityIndicator());
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(CupertinoIcons.exclamationmark_circle)),
      );
    }
  }

  // Helper getters
  bool get _showFramed {
    final mq = MediaQuery.of(context);
    final isDesktopSize = mq.size.width >= 700;
    final bool isVertical = _isVideo
        ? (_videoController?.value.size.height ?? 0) >
            (_videoController?.value.size.width ?? 1)
        : true;
    return kIsWeb && isDesktopSize && isVertical;
  }

  double get _framedWidth {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;

    final totalMargins = _isVideo ? 39.0 : 37.0;
    final availableHeight = screenHeight - totalMargins;

    // Calculate max width based on aspect ratio and available height
    double maxWidth;
    if (_isVideo &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      final aspectRatio = _videoController!.value.aspectRatio;
      maxWidth = availableHeight * aspectRatio;
    } else {
      maxWidth = availableHeight * (9 / 16);
    }

    final limitedWidth = (screenWidth * 0.6).clamp(320.0, 450.0);
    return maxWidth.clamp(320.0, limitedWidth);
  }
}

class _StoryProgressBar extends StatelessWidget {
  final double progress;
  final double? width;
  const _StoryProgressBar({required this.progress, this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: width ?? double.infinity,
        height: 3,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(158, 158, 158, 0.3),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
