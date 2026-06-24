import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/views/services_tab_view.dart';
import '../../shop/views/shop_tab_view.dart';
import '../../profile/views/profile_tab_view.dart';
import '../../../../data/services/notification_service.dart';

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
  ];

  final List<Widget> _tabs = const [
    ServicesTabView(),
    ShopTabView(),
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
          // ── Animated tab content ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _tabs[_currentIndex],
            ),
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
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                items: _navItems,
                bounceAnimations: _bounceAnimations,
                onTap: _onTabTap,
                theme: theme,
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
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding pill background
          _SlidingPill(
            currentIndex: currentIndex,
            itemCount: items.length,
            isDark: isDark,
          ),
          // Icons + labels row on top
          Row(
            children: List.generate(items.length, (i) {
              return _NavItemWidget(
                item: items[i],
                isSelected: i == currentIndex,
                bounceAnimation: bounceAnimations[i],
                onTap: () => onTap(i),
                isDark: isDark,
                inactiveColor: theme.colorScheme.onSurfaceVariant,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Sliding pill indicator ───────────────────────────────────────────────────
class _SlidingPill extends StatelessWidget {
  const _SlidingPill({
    required this.currentIndex,
    required this.itemCount,
    required this.isDark,
  });

  final int currentIndex;
  final int itemCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Map index 0..N-1 → alignment -1..1
    final double x = itemCount > 1
        ? -1.0 + (2.0 * currentIndex / (itemCount - 1))
        : 0.0;

    return AnimatedAlign(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment(x, 0),
      child: FractionallySizedBox(
        widthFactor: 1 / itemCount,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
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
    required this.isDark,
    required this.inactiveColor,
  });

  final _NavItem item;
  final bool isSelected;
  final Animation<double> bounceAnimation;
  final VoidCallback onTap;
  final bool isDark;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    // Active color is inverted to contrast against the filled pill
    final activeColor = isDark ? Colors.black : Colors.white;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bounce + icon swap animation
              AnimatedBuilder(
                animation: bounceAnimation,
                builder: (context, child) =>
                    Transform.scale(scale: bounceAnimation.value, child: child),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 20,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Label fades weight/size/color
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 9.5 : 9.0,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: isSelected ? 0.3 : 0.0,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
