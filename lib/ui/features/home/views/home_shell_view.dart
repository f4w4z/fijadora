import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/views/services_tab_view.dart';
import '../../shop/views/shop_tab_view.dart';
import '../../profile/views/profile_tab_view.dart';
import '../../../../data/services/notification_service.dart';
import 'dart:async';

class HomeShellView extends ConsumerStatefulWidget {
  const HomeShellView({super.key});

  @override
  ConsumerState<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends ConsumerState<HomeShellView> {
  int _currentIndex = 0;
  StreamSubscription<AppNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationSubscription = ref.read(notificationServiceProvider).notificationsStream.listen((notification) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  final List<Widget> _tabs = const [
    ServicesTabView(),
    ShopTabView(),
    ProfileTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF222222)
                  : const Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.hammer, size: 20),
              activeIcon: Icon(CupertinoIcons.hammer_fill, size: 20),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bag, size: 20),
              activeIcon: Icon(CupertinoIcons.bag_fill, size: 20),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 20),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 20),
              label: 'Home Hub',
            ),
          ],
        ),
      ),
    );
  }
}
