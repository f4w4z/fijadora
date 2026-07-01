import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

extension NotificationExtension on BuildContext {
  void showSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    String? title,
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

    final overlay = Overlay.of(this);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        action: action,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _TopToast extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String? title;
  final String message;
  final SnackBarAction? action;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopToast({
    required this.icon,
    required this.iconColor,
    this.title,
    required this.message,
    this.action,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _controller.reverse().then((_) => widget.onDismissed());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              margin: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16),
              child: Material(
                color: const Color(0xFF2A2A28),
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
                shadowColor: const Color(0x4C000000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.iconColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: widget.title != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                widget.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      if (widget.action != null)
                        GestureDetector(
                          onTap: () {
                            widget.action!.onPressed();
                            _dismiss();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              widget.action!.label,
                              style: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
