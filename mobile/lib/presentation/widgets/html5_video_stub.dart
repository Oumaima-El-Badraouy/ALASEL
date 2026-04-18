import 'package:flutter/widgets.dart';

/// Implémentation vide (mobile / desktop) — le vrai lecteur est dans [html5_video_web.dart].
class Html5NetworkVideo extends StatelessWidget {
  const Html5NetworkVideo({super.key, required this.url, this.aspectRatio = 16 / 9});

  final String url;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
