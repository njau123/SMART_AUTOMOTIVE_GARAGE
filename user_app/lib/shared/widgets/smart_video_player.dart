import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video player widget yenye controls + thumbnail fallback.
class SmartVideoPlayer extends StatefulWidget {
  final String url;
  final double? height;
  final bool autoPlay;

  const SmartVideoPlayer({
    super.key,
    required this.url,
    this.height = 200,
    this.autoPlay = false,
  });

  @override
  State<SmartVideoPlayer> createState() => _SmartVideoPlayerState();
}

class _SmartVideoPlayerState extends State<SmartVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      setState(() => _error = true);
      return;
    }
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await ctrl.initialize();
      ctrl.setLooping(true);
      if (widget.autoPlay) ctrl.play();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _initialized = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      _controller!.value.isPlaying
          ? _controller!.pause()
          : _controller!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 48),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            // Play/Pause button
            GestureDetector(
              onTap: _togglePlay,
              child: AnimatedOpacity(
                opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Progress bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
