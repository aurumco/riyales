import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:riyales/models/alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' show ImageFilter;

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
  bool _badgeVisible = false;
  bool _isPaused = false;
  bool _hasCompleted = false;

  File? _tempVideoFile;

  @override
  void initState() {
    super.initState();
    _isMuted = kIsWeb;
    _badgeVisible = kIsWeb;
    WidgetsBinding.instance.addObserver(this);

    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    final url = widget.entry.url;
    _isVideo = widget.entry.isVideo;

    try {
      if (_isVideo) {
        // Download video completely with 10s timeout
        try {
          if (!kIsWeb) {
            // create temp file
            _tempVideoFile = File(
                '${Directory.systemTemp.path}/ad_${DateTime.now().millisecondsSinceEpoch}.tmp');
            final httpClient = HttpClient();
            final request = await httpClient.getUrl(Uri.parse(url));
            final response =
                await request.close().timeout(const Duration(seconds: 5));
            if (response.statusCode != 200) throw Exception('Bad status');
            // accumulate bytes with an enforced timeout
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
            // direct network playback on web
            _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
          }
        } catch (_) {
          // timeout or network error: skip ad
          if (mounted) Navigator.of(context).pop();
          return;
        }

        await _videoController!.initialize();
        if (!mounted) return;

        _videoController!
          ..setLooping(false)
          ..setVolume(_isMuted ? 0.0 : 0.7);

        if (kIsWeb) {
          // Attempt to raise volume after short delay (may be blocked until user gesture)
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
        // Autoplay video always (muted on web initially)
        _videoController!.play();

        // Mark ready
        if (mounted) setState(() => _mediaReady = true);
      } else {
        // Image ad: mark ready
        if (mounted) setState(() => _mediaReady = true);
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
    } catch (e) {
      debugPrint('Failed to load ad media: $e');
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
    // clean up temp file
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
    // Stop without cancelling so animation resumes from current value
    _progressController?.stop(canceled: false);
    _videoController?.pause();
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    // Continue from where we paused
    _progressController?.forward();
    _videoController?.play();
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

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isVideo && _badgeVisible) {
            _videoController?.setVolume(0.7);
            setState(() {
              _isMuted = false;
              _badgeVisible = false;
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
            // Unmute badge for web
            if (_isVideo && _badgeVisible)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _badgeVisible ? 1.0 : 0.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: () {
                          if (_isMuted) {
                            _videoController?.setVolume(0.7);
                            setState(() {
                              _isMuted = false;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                setState(() => _badgeVisible = false);
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isMuted
                                ? CupertinoIcons.volume_off
                                : CupertinoIcons.volume_up,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 12,
              right: 12,
              child: _StoryProgressBar(
                  progress: _isVideo
                      ? _videoProgress.clamp(0.0, 1.0)
                      : (_progressController?.value ?? 0.0)),
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
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      return Image.network(
        widget.entry.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CupertinoActivityIndicator());
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(CupertinoIcons.exclamationmark_circle)),
      );
    }
  }
}

class _StoryProgressBar extends StatelessWidget {
  final double progress;
  const _StoryProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    // A rounded progress bar: elapsed (white) and remaining (gray).
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: double.infinity,
        height: 4,
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
              height: 4,
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
