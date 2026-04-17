import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';

/// Affiche image ou vidéo (réseau, data URL, ou fichier local).
class PostMediaPreview extends StatefulWidget {
  const PostMediaPreview({super.key, required this.media, this.aspectRatio = 1.0});

  final String media;
  final double aspectRatio;

  @override
  State<PostMediaPreview> createState() => _PostMediaPreviewState();
}

class _PostMediaPreviewState extends State<PostMediaPreview> {
  VideoPlayerController? _v;
  bool _videoErr = false;

  static bool _isDataImage(String m) => m.startsWith('data:image');
  static bool _isDataVideo(String m) {
    final s = m.toLowerCase();
    return s.startsWith('data:video/');
  }

  static bool _isNet(String m) => m.startsWith('http://') || m.startsWith('https://');

  static bool _looksVideo(String m) {
    final x = m.toLowerCase();
    return x.startsWith('data:video/') ||
        x.contains('video/') ||
        x.endsWith('.mp4') ||
        x.endsWith('.mov') ||
        x.endsWith('.m4v') ||
        x.endsWith('.webm') ||
        x.endsWith('.3gp');
  }

  /// Ordre d’essai des extensions pour [VideoPlayerController.file] (MP4/MOV partagent souvent ftyp).
  static List<String> _suffixTryOrder(String mediaMeta, Uint8List bytes) {
    final seen = <String>{};
    final out = <String>[];

    void add(String s) {
      if (seen.add(s)) out.add(s);
    }

    final low = mediaMeta.toLowerCase();
    if (low.contains('quicktime')) add('.mov');
    if (low.contains('webm')) add('.webm');
    if (low.contains('3gpp') || low.contains('/3gp')) add('.3gp');
    if (low.contains('matroska') || low.contains('mkv')) add('.mkv');

    if (bytes.length >= 12) {
      final ftyp = String.fromCharCodes(bytes.sublist(4, 8));
      if (ftyp == 'ftyp' && bytes.length >= 16) {
        final brand = String.fromCharCodes(bytes.sublist(8, 12));
        final b = brand.toLowerCase();
        if (b.contains('qt') || b.startsWith('qt')) {
          add('.mov');
        }
        add('.mp4');
      }
    }
    if (bytes.length >= 4 && bytes[0] == 0x1a && bytes[1] == 0x45 && bytes[2] == 0xdf && bytes[3] == 0xa3) {
      add('.webm');
    }

    for (final s in ['.mp4', '.mov', '.webm', '.3gp', '.mkv']) {
      add(s);
    }
    return out;
  }

  static String? _extractBase64Payload(String m) {
    final i = m.indexOf('base64,');
    if (i >= 0) {
      return m.substring(i + 7).replaceAll(RegExp(r'\s'), '');
    }
    final comma = m.indexOf(',');
    if (comma >= 0) {
      return m.substring(comma + 1).replaceAll(RegExp(r'\s'), '');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _maybeInitVideo();
  }

  @override
  void didUpdateWidget(PostMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media != widget.media) {
      _disposeVideo();
      _videoErr = false;
      _maybeInitVideo();
    }
  }

  void _disposeVideo() {
    _v?.dispose();
    _v = null;
  }

  static String _extFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return '.mov';
    if (lower.endsWith('.webm')) return '.webm';
    if (lower.endsWith('.mkv')) return '.mkv';
    return '.mp4';
  }

  /// Réseau puis, sur bureau, téléchargement vers fichier (video_player réseau peu fiable sur Windows).
  Future<void> _initNetworkVideo(Uri uri) async {
    VideoPlayerController? c;
    try {
      final net = VideoPlayerController.networkUrl(uri);
      await net.initialize();
      c = net;
    } catch (_) {
      if (kIsWeb) rethrow;
      final client = HttpClient();
      try {
        final req = await client.getUrl(uri);
        final resp = await req.close();
        if (resp.statusCode != 200) {
          throw Exception('HTTP ${resp.statusCode}');
        }
        final bytes = await consolidateHttpClientResponseBytes(resp);
        final dir = await getTemporaryDirectory();
        final ext = _extFromPath(uri.path);
        final f = File('${dir.path}/alasel_net_${DateTime.now().millisecondsSinceEpoch}$ext');
        await f.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        final fileCtl = VideoPlayerController.file(f);
        await fileCtl.initialize();
        c = fileCtl;
      } finally {
        client.close(force: true);
      }
    }
    final controller = c;
    if (!mounted) {
      await controller.dispose();
      return;
    }
    await controller.setLooping(true);
    await controller.play();
    setState(() => _v = controller);
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _maybeInitVideo() async {
    final m = widget.media;
    if (!_looksVideo(m) && !_isDataVideo(m)) return;

    if (_isDataVideo(m)) {
      final payload = _extractBase64Payload(m);
      if (payload == null || payload.isEmpty) {
        if (mounted) setState(() => _videoErr = true);
        return;
      }
      Uint8List bytes;
      try {
        bytes = base64Decode(payload);
      } catch (_) {
        if (mounted) setState(() => _videoErr = true);
        return;
      }
      if (bytes.isEmpty) {
        if (mounted) setState(() => _videoErr = true);
        return;
      }

      if (kIsWeb) {
        if (mounted) setState(() => _videoErr = true);
        return;
      }

      final dir = await getTemporaryDirectory();
      final id = DateTime.now().millisecondsSinceEpoch;
      final suffixes = _suffixTryOrder(m, bytes);

      for (final suf in suffixes) {
        File? f;
        try {
          f = File('${dir.path}/alasel_vid_$id$suf');
          await f.writeAsBytes(bytes, flush: true);
          if (!mounted) return;
          final c = VideoPlayerController.file(f);
          await c.initialize();
          if (!mounted) {
            await c.dispose();
            return;
          }
          await c.setLooping(true);
          await c.play();
          setState(() => _v = c);
          return;
        } catch (_) {
          try {
            await f?.delete();
          } catch (_) {}
        }
      }
      if (mounted) setState(() => _videoErr = true);
      return;
    }

    if (_isNet(m) && _looksVideo(m)) {
      final uri = ApiConfig.resolvedMediaUri(m);
      try {
        await _initNetworkVideo(uri);
      } catch (_) {
        if (mounted) setState(() => _videoErr = true);
      }
      return;
    }

    if (m.startsWith('/') || (m.length > 2 && m[1] == ':')) {
      try {
        final file = File(m);
        if (await file.exists()) {
          final c = VideoPlayerController.file(file);
          await c.initialize();
          if (!mounted) {
            await c.dispose();
            return;
          }
          await c.setLooping(true);
          await c.play();
          setState(() => _v = c);
        }
      } catch (_) {
        if (mounted) setState(() => _videoErr = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.media;
    if (_v != null && _v!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _v!.value.aspectRatio > 0 ? _v!.value.aspectRatio : widget.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_v!),
            Positioned(
              bottom: 8,
              child: Material(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  icon: Icon(_v!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  onPressed: () async {
                    if (_v!.value.isPlaying) {
                      await _v!.pause();
                    } else {
                      await _v!.play();
                    }
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    final loadingVideo = (_looksVideo(m) || _isDataVideo(m)) && _v == null && !_videoErr;
    if (_videoErr || loadingVideo) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ColoredBox(
          color: AppColors.sandDeep,
          child: Center(
            child: _videoErr
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.muted),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(
                          'معاينة الفيديو غير مدعومة في المتصفح',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.9)),
                        ),
                      ],
                    ],
                  )
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_isDataImage(m)) {
      try {
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Image.memory(
            base64Decode(m.split(',').last),
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return _bad();
      }
    }
    if (_isNet(m)) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: CachedNetworkImage(imageUrl: m, fit: BoxFit.cover),
      );
    }
    if (m.startsWith('/') || (m.length > 2 && m[1] == ':')) {
      final f = File(m);
      if (f.existsSync()) {
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Image.file(f, fit: BoxFit.cover),
        );
      }
    }
    return _bad();
  }

  Widget _bad() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ColoredBox(
        color: AppColors.sandDeep,
        child: Icon(Icons.perm_media_outlined, size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
      ),
    );
  }
}
