import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_colors.dart';

/// Lecture intégrée Windows / Linux (MP4 HTTP) — `video_player` desktop n’est pas implémenté.
class DesktopMediaKitVideo extends StatefulWidget {
  const DesktopMediaKitVideo({super.key, required this.url, required this.aspectRatio});

  final String url;
  final double aspectRatio;

  @override
  State<DesktopMediaKitVideo> createState() => _DesktopMediaKitVideoState();
}

class _DesktopMediaKitVideoState extends State<DesktopMediaKitVideo> {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player.open(Media(widget.url)).then((_) {}, onError: (Object e, StackTrace st) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ColoredBox(
          color: AppColors.sandDeep,
          child: Center(
            child: Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.muted.withValues(alpha: 0.7)),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Video(
        controller: _videoController,
        aspectRatio: widget.aspectRatio,
        fit: BoxFit.contain,
        fill: AppColors.sandDeep,
      ),
    );
  }
}
