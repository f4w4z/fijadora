import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/views/services_tab_view.dart';
import '../../shop/views/shop_tab_view.dart';
import '../../collections/views/collections_tab_view.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../shared/utils/notification_helper.dart';
import 'home_view.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../core/router.dart';

// ─── Shell ────────────────────────────────────────────────────────────────────
class HomeShellView extends ConsumerStatefulWidget {
  const HomeShellView({super.key});

  @override
  ConsumerState<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends ConsumerState<HomeShellView>
    with TickerProviderStateMixin {
  StreamSubscription<AppNotification>? _notificationSubscription;

  late final List<AnimationController> _bounceControllers = List.generate(_navItems.length, (_) {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  });
  late final List<Animation<double>> _bounceAnimations = _bounceControllers.map((ctrl) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
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
      icon: CupertinoIcons.tray_full,
      activeIcon: CupertinoIcons.tray_full_fill,
      label: 'Collections',
    ),
    _NavItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home',
    ),
  ];

  final List<Widget> _tabs = const [
    RepaintBoundary(child: ServicesTabView()),
    RepaintBoundary(child: ShopTabView()),
    RepaintBoundary(child: CollectionsTabView()),
    RepaintBoundary(child: HomeView()),
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
          context.showSnackBar(
            notification.body,
            title: notification.title,
          );
        }
      });
    });
  }

  void _onTabTap(int index) {
    final currentIndex = ref.read(customerTabProvider);
    if (index == currentIndex) return;
    HapticFeedback.lightImpact();
    _bounceControllers[index].forward(from: 0.0);
    ref.read(customerTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = ref.watch(customerTabProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _onTabTap(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _onTabTap(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _onTabTap(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _onTabTap(3),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Tab content with state preservation ───────────────────────
              FadeIndexedStack(
                index: currentIndex,
                children: _tabs,
              ),

              // ── Floating nav bar ──────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: SizedBox(
                      width: 330,
                      child: _FloatingNavBar(
                        currentIndex: currentIndex,
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
        ),
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

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF0F1718)
            : Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark 
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.15) 
              : const Color(0xFFE8E8E8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.08),
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
            inactiveColor: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF8E8E93),
          );
        }),
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
    final double targetWidth = isSelected ? 136.0 : 52.0;

    return Semantics(
      label: item.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: targetWidth,
        height: 52,
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1F2E30)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.all(6.0),
        child: Stack(
          children: [
            // Text label positioned next to the icon area
            Positioned(
              left: 42, // 36 (icon width) + 6 (spacing)
              right: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    width: 80,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                            : Colors.transparent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      child: Text(item.label),
                    ),
                  ),
                ),
              ),
            ),
            // Icon wrapper circle
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: isSelected ? Alignment.centerLeft : Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: 36,
                height: 36,
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
                    size: 20,
                    color: isSelected ? theme.colorScheme.onPrimary : inactiveColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
