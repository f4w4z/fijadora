import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

extension NotificationExtension on BuildContext {
  void showSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(this);
    
    IconData icon;
    Color iconColor;
    switch (type) {
      case SnackBarType.success:
        icon = CupertinoIcons.checkmark_circle_fill;
        iconColor = Colors.greenAccent;
        break;
      case SnackBarType.error:
        icon = CupertinoIcons.exclamationmark_circle_fill;
        iconColor = theme.colorScheme.error;
        break;
      case SnackBarType.warning:
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        iconColor = Colors.orangeAccent;
        break;
      case SnackBarType.info:
        icon = CupertinoIcons.info_circle_fill;
        iconColor = Colors.lightBlueAccent;
        break;
    }

    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    final controller = ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: action,
      ),
    );

    Future.delayed(duration, () {
      try {
        controller.close();
      } catch (_) {}
    });
  }
}
