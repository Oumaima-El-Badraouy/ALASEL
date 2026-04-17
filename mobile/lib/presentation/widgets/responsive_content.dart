import 'package:flutter/material.dart';

/// Limite la largeur sur tablette / bureau pour une meilleure lisibilité (mobile-first).
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final effective = w > maxWidth + 32 ? maxWidth : w;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: effective,
            child: child,
          ),
        );
      },
    );
  }
}
