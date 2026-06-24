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

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 4.0),
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
                      fontSize: 32,
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
                ? theme.colorScheme.surfaceContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest
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

class GroupedHeaderActions extends StatelessWidget {
  const GroupedHeaderActions({
    super.key,
    required this.actions,
  });

  final List<GroupedActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 8.0),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFE5E5E5),
          width: 1.0,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(actions.length, (index) {
            final item = actions[index];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedTapScale(
                  onTap: item.onTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: item.badgeCount > 0
                          ? Badge(
                              label: Text('${item.badgeCount}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                              backgroundColor:
                                  item.badgeColor ?? theme.colorScheme.primary,
                              child: Icon(item.icon,
                                  size: 20, color: theme.colorScheme.onSurface),
                            )
                          : Icon(item.icon,
                              size: 20, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                if (index < actions.length - 1)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFFE5E5E5),
                    indent: 8,
                    endIndent: 8,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class GroupedActionItem {
  const GroupedActionItem({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? badgeColor;
}
