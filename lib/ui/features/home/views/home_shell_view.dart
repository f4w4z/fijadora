import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/views/services_tab_view.dart';
import '../../shop/views/shop_tab_view.dart';
import '../../profile/views/profile_tab_view.dart';
import '../../../../data/services/notification_service.dart';
import 'home_view.dart';

// ─── Shell ────────────────────────────────────────────────────────────────────
class HomeShellView extends ConsumerStatefulWidget {
  const HomeShellView({super.key});

  @override
  ConsumerState<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends ConsumerState<HomeShellView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  StreamSubscription<AppNotification>? _notificationSubscription;

  late final List<AnimationController> _bounceControllers = List.generate(_navItems.length, (_) {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  });
  late final List<Animation<double>> _bounceAnimations = _bounceControllers.map((ctrl) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.1), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
  }).toList();

  static const _navItems = [
    _NavItem(
      icon: CupertinoIcons.hammer,
      activeIcon: CupertinoIcons.hammer_fill,
      label: 'Services',
    ),
    _NavItem(
      icon: CupertinoIcons.bag,
      activeIcon: CupertinoIcons.bag_fill,
      label: 'Shop',
    ),
    _NavItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home Hub',
    ),
    _NavItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Profile',
    ),
  ];

  final List<Widget> _tabs = const [
    ServicesTabView(),
    ShopTabView(),
    HomeView(),
    ProfileTabView(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    for (final ctrl in _bounceControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _listenToNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationSubscription = ref
          .read(notificationServiceProvider)
          .notificationsStream
          .listen((notification) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    });
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _bounceControllers[index].forward(from: 0.0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Tab content (kept alive with IndexedStack) ─────────────────────
          IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),

          // ── Bottom scrim ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating nav bar ──────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Center(
                child: SizedBox(
                  width: 340,
                  child: _FloatingNavBar(
                    currentIndex: _currentIndex,
                    items: _navItems,
                    bounceAnimations: _bounceAnimations,
                    onTap: _onTabTap,
                    theme: theme,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav item data ────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ─── Floating nav bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.bounceAnimations,
    required this.onTap,
    required this.theme,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final List<Animation<double>> bounceAnimations;
  final ValueChanged<int> onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF0F1718) // deep dark teal surface
            : const Color(0xFF1E293B), // slate surface
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark 
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.15) 
              : Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (i) {
          return _NavItemWidget(
            item: items[i],
            isSelected: i == currentIndex,
            bounceAnimation: bounceAnimations[i],
            onTap: () => onTap(i),
            theme: theme,
            inactiveColor: Colors.white.withValues(alpha: 0.5),
          );
        }),
      ),
    );
  }
}

// ─── Individual nav item ──────────────────────────────────────────────────────
class _NavItemWidget extends StatelessWidget {
  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.bounceAnimation,
    required this.onTap,
    required this.theme,
    required this.inactiveColor,
  });

  final _NavItem item;
  final bool isSelected;
  final Animation<double> bounceAnimation;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final double targetWidth = isSelected ? 144.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: targetWidth,
        height: 52,
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1F2E30) // subtle dark grey-teal
              : const Color(0xFF334155), // subtle dark grey-slate
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            // Icon wrapper circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              ),
              child: AnimatedBuilder(
                animation: bounceAnimation,
                builder: (context, child) =>
                    Transform.scale(scale: bounceAnimation.value, child: child),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22,
                  color: isSelected ? theme.colorScheme.onPrimary : inactiveColor,
                ),
              ),
            ),
            // Expanded text label with singlechildview to prevent overflow during resize
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: 84,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    child: Text(item.label),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
