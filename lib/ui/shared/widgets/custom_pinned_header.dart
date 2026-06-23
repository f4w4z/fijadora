import 'package:flutter/material.dart';
import 'animated_tap_scale.dart';

class CustomPinnedHeader extends StatelessWidget {
  const CustomPinnedHeader({
    super.key,
    required this.title,
    required this.actions,
    this.bottomChild,
  });

  final String title;
  final List<Widget> actions;
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1F1F1F)
                : const Color(0xFFEEEEEE),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
                ],
              ),
              if (bottomChild != null) ...[
                const SizedBox(height: 12.0),
                bottomChild!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget iconWidget = Icon(
      icon,
      size: 20,
      color: theme.colorScheme.onSurface,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text('$badgeCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        backgroundColor: badgeColor ?? theme.colorScheme.primary,
        child: iconWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 8.0),
      child: AnimatedTapScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF121212)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF222222)
                  : const Color(0xFFE5E5E5),
              width: 1.0,
            ),
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}
