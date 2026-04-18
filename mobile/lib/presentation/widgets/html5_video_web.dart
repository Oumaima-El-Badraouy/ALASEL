// Lecteur <video> natif — nécessaire car video_player n’implémente pas initialize() sur le web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class Html5NetworkVideo extends StatefulWidget {
  const Html5NetworkVideo({super.key, required this.url, this.aspectRatio = 16 / 9});

  final String url;
  final double aspectRatio;

  @override
  State<Html5NetworkVideo> createState() => _Html5NetworkVideoState();
}

class _Html5NetworkVideoState extends State<Html5NetworkVideo> {
  late final String _viewType = 'alasel-h5-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final v = html.VideoElement()
        ..src = widget.url
        ..controls = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      v.setAttribute('playsinline', 'true');
      v.setAttribute('crossorigin', 'anonymous');
      return v;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
