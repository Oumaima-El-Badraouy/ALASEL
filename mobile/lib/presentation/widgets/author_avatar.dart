import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avatar auteur (photo profil, data URL, ou initiale).
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({
    super.key,
    required this.radius,
    this.photoUrl,
    required this.fallbackLabel,
  });

  final double radius;
  final String? photoUrl;
  final String fallbackLabel;

  Widget _fallback(double r) {
    final s = fallbackLabel.trim();
    final ch = s.isNotEmpty ? s[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
      child: Text(
        ch,
        style: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w800,
          fontSize: r * 0.95,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = photoUrl?.trim();
    if (p != null && p.isNotEmpty) {
      if (p.startsWith('data:image')) {
        try {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(base64Decode(p.split(',').last)),
          );
        } catch (_) {}
      }
      if (p.startsWith('http://') || p.startsWith('https://')) {
        final d = radius * 2;
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: p,
            width: d,
            height: d,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.deepBlue.withValues(alpha: 0.08),
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => _fallback(radius),
          ),
        );
      }
    }
    return _fallback(radius);
  }
}
