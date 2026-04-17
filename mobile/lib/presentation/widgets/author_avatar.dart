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
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
          backgroundImage: CachedNetworkImageProvider(p),
        );
      }
    }
    final s = fallbackLabel.trim();
    final ch = s.isNotEmpty ? s[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
      child: Text(
        ch,
        style: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.95,
        ),
      ),
    );
  }
}
