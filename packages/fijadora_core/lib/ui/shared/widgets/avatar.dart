import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A circular avatar showing the user's initials over a deterministic color.
/// Used where we don't have a photo URL (worker/customer profiles).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = 44,
    this.fontSize,
    super.key,
  });

  final String name;
  final double size;
  final double? fontSize;

  static const _palette = [
    Color(0xFF155B60),
    Color(0xFF7A5CC9),
    Color(0xFFC9627A),
    Color(0xFF3F8F6B),
    Color(0xFFC9883F),
    Color(0xFF4A6FC9),
  ];

  Color get _color {
    final key = name.trim().isEmpty ? 'x' : name.trim();
    return _palette[key.codeUnits.fold(0, (a, b) => a + b) % _palette.length];
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: fontSize ?? size * 0.38,
          ),
        ),
      ),
    );
  }
}

/// A network image with a soft rounded clip and a placeholder shimmer fallback.
class RoundedNetworkImage extends StatelessWidget {
  const RoundedNetworkImage({
    required this.url,
    this.height,
    this.width,
    this.radius = 12,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = url != null && url!.isNotEmpty
        ? Image.network(
            url!,
            height: height,
            width: width,
            fit: fit,
            loadingBuilder: (c, child, progress) {
              if (progress == null) return child;
              return Container(
                height: height,
                width: width,
                color: theme.colorScheme.surfaceContainerHighest,
              );
            },
            errorBuilder: (c, e, s) => Container(
              height: height,
              width: width,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(CupertinoIcons.photo, color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        : Container(
            height: height,
            width: width,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(CupertinoIcons.photo, color: theme.colorScheme.onSurfaceVariant),
          );
    if (height == null && width == null) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
