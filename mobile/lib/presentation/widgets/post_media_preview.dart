import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        Uint8List,
        consolidateHttpClientResponseBytes,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import 'desktop_media_kit_video.dart';
import 'html5_video.dart';

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

  /// Windows / Linux : `video_player` desktop non implémenté — lecture via [DesktopMediaKitVideo].
  bool get _useDesktopMediaKitForNetworkVideo {
    if (kIsWeb) return false;
    final t = defaultTargetPlatform;
    return t == TargetPlatform.windows || t == TargetPlatform.linux;
  }

  static bool _isDataImage(String m) => m.startsWith('data:image');
  static bool _isDataVideo(String m) {
    final s = m.toLowerCase();
    return s.startsWith('data:video/');
  }

  static bool _isNet(String m) => m.startsWith('http://') || m.startsWith('https://');

  /// Extensions vidéo courantes (alignées sur l’API + sniff serveur).
  static final RegExp _videoFileExt = RegExp(
    r'\.(mp4|m4v|mov|qt|webm|mkv|3gp|3g2|avi|mpeg|mpg|mpe|m1v|vob|ts|mts|m2ts|flv|wmv|asf|ogv|divx|xvid)$',
    caseSensitive: false,
  );

  /// Sans la partie `?query` : sinon `.mp4?…` ne finit plus par `.mp4`.
  static bool _looksVideo(String m) {
    final t = m.trim();
    if (t.isEmpty) return false;
    final head = t.split('?').first.toLowerCase();
    if (head.startsWith('data:video/')) return true;
    // Fichiers servis par notre API (même sans extension dans l’URL).
    if (head.contains('/uploads/posts/')) return true;
    return _videoFileExt.hasMatch(head);
  }

  /// Plusieurs origines possibles : URL telle qu’en base, puis réécrite avec [ApiConfig.socketOrigin].
  static List<Uri> _playbackCandidateUris(String media) {
    final m = media.trim();
    final seen = <String>{};
    final out = <Uri>[];

    void add(Uri? u) {
      if (u == null) return;
      if (!(u.scheme == 'http' || u.scheme == 'https')) return;
      if (seen.add(u.toString())) out.add(u);
    }

    final direct = Uri.tryParse(m);
    add(direct);
    if (direct != null && direct.hasQuery) {
      add(Uri(
        scheme: direct.scheme,
        host: direct.host,
        port: direct.hasPort ? direct.port : null,
        path: direct.path,
      ));
    }
    add(ApiConfig.resolvedMediaUri(m));
    add(ApiConfig.resolvedMediaUri(m.split('?').first));

    return out;
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
      add('.mkv');
      add('.webm');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x41 &&
        bytes[9] == 0x56 &&
        bytes[10] == 0x49) {
      add('.avi');
    }
    if (bytes.length >= 4 && bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 1 && bytes[3] == 0xba) {
      add('.mpeg');
    }

    for (final s in [
      '.mp4',
      '.mov',
      '.m4v',
      '.webm',
      '.mkv',
      '.3gp',
      '.avi',
      '.mpeg',
      '.ts',
      '.flv',
      '.wmv',
      '.ogv',
    ]) {
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
    // Sur le web, video_player n’implémente pas initialize() — lecteur HTML5 dans build().
    if (kIsWeb && _isNet(widget.media) && _looksVideo(widget.media)) {
      return;
    }
    if (_isNet(widget.media) && _looksVideo(widget.media) && _useDesktopMediaKitForNetworkVideo) {
      return;
    }
    _maybeInitVideo();
  }

  @override
  void didUpdateWidget(PostMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media != widget.media) {
      _disposeVideo();
      _videoErr = false;
      if (!(kIsWeb && _isNet(widget.media) && _looksVideo(widget.media)) &&
          !(_isNet(widget.media) && _looksVideo(widget.media) && _useDesktopMediaKitForNetworkVideo)) {
        _maybeInitVideo();
      }
    }
  }

  void _disposeVideo() {
    _v?.dispose();
    _v = null;
  }

  static String _extFromPath(String path) {
    final lower = path.toLowerCase();
    const longerFirst = [
      '.m2ts',
      '.mts',
      '.mpeg',
      '.mpe',
      '.m1v',
      '.vob',
      '.divx',
      '.xvid',
      '.mov',
      '.m4v',
      '.webm',
      '.mkv',
      '.3gp',
      '.3g2',
      '.avi',
      '.mpg',
      '.ts',
      '.flv',
      '.wmv',
      '.asf',
      '.ogv',
      '.mp4',
    ];
    for (final e in longerFirst) {
      if (lower.endsWith(e)) return e;
    }
    return '.mp4';
  }

  /// Télécharge la vidéo puis lecture fichier — plus fiable que [networkUrl] avec HTTP local (Android/iOS).
  Future<VideoPlayerController> _downloadVideoToController(Uri uri) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 90);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, '*/*');
      final resp = await req.close();
      final code = resp.statusCode;
      if (code != 200 && code != 206) {
        throw Exception('HTTP $code');
      }
      final bytes = await consolidateHttpClientResponseBytes(resp);
      if (bytes.isEmpty) {
        throw Exception('Réponse vide');
      }
      final dir = await getTemporaryDirectory();
      final ext = _extFromPath(uri.path);
      final f = File('${dir.path}/alasel_net_${DateTime.now().millisecondsSinceEpoch}$ext');
      await f.writeAsBytes(bytes, flush: true);
      final ctl = VideoPlayerController.file(f);
      await ctl.initialize();
      if (!mounted) {
        await ctl.dispose();
        throw StateError('disposed');
      }
      return ctl;
    } finally {
      client.close(force: true);
    }
  }

  /// Toujours télécharger puis lire un fichier sur les plateformes natives : sur **Windows/macOS/Linux**,
  /// `VideoPlayerController.networkUrl` peut lever `UnimplementedError` avant même le fallback.
  Future<void> _tryOpenSingleNetworkUri(Uri uri) async {
    if (kIsWeb) {
      throw StateError('PostMediaPreview: le web utilise Html5NetworkVideo dans build()');
    }
    late VideoPlayerController c;
    try {
      c = await _downloadVideoToController(uri);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PostMediaPreview: téléchargement échoué ($uri) → essai flux réseau: $e');
      }
      try {
        final net = VideoPlayerController.networkUrl(uri);
        await net.initialize();
        c = net;
      } catch (e2) {
        throw Exception('$e | $e2');
      }
    }

    if (!mounted) {
      await c.dispose();
      return;
    }
    await c.setLooping(true);
    await c.play();
    setState(() => _v = c);
  }

  Future<void> _openNetworkVideoWithCandidates(String media) async {
    final uris = _playbackCandidateUris(media);
    Object? last;
    for (final uri in uris) {
      try {
        await _tryOpenSingleNetworkUri(uri);
        return;
      } catch (e) {
        last = e;
      }
    }
    if (kDebugMode) {
      debugPrint('PostMediaPreview: échec lecture vidéo (${uris.length} URL(s)) — $last — media="$media"');
    }
    throw last ?? Exception('Video playback failed');
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _maybeInitVideo() async {
    final m = widget.media;
    if (kIsWeb && _isNet(m) && _looksVideo(m)) return;
    if (_isNet(m) && _looksVideo(m) && _useDesktopMediaKitForNetworkVideo) return;
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
      try {
        await _openNetworkVideoWithCandidates(m);
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
    // Web : lecteur <video> (video_player non implémenté pour ce cas).
    if (kIsWeb && _isNet(m) && _looksVideo(m)) {
      final uris = _playbackCandidateUris(m);
      final url = uris.isNotEmpty ? uris.first.toString() : ApiConfig.resolvedMediaUri(m).toString();
      return Html5NetworkVideo(url: url, aspectRatio: widget.aspectRatio);
    }
    // Windows / Linux : lecture intégrée via media_kit (mpv).
    if (!kIsWeb && _isNet(m) && _looksVideo(m) && _useDesktopMediaKitForNetworkVideo) {
      final uris = _playbackCandidateUris(m);
      final url = uris.isNotEmpty ? uris.first.toString() : ApiConfig.resolvedMediaUri(m).toString();
      return DesktopMediaKitVideo(url: url, aspectRatio: widget.aspectRatio);
    }
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
                      if (kIsWeb && _isDataVideo(m)) ...[
                        const SizedBox(height: 8),
                        Text(
                          'معاينة الفيديو من البيانات المضمنة غير مدعومة في المتصفح',
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
