import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase_service.dart';
import 'push_notification_service.dart';
import '../../domain/models/user_role.dart';
import '../../ui/core/router.dart';
import '../../ui/features/auth/view_models/auth_view_model.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  StreamSubscription? _sub;
  StreamSubscription? _notificationSub;
  GoRouter? _router;
  WidgetRef? _ref;

  Future<void> init(GoRouter router, WidgetRef ref) async {
    _router = router;
    _ref = ref;
    final appLinks = AppLinks();

    _sub = appLinks.uriLinkStream.listen((uri) {
      debugPrint('DeepLinkService - Incoming link: $uri');
      _handleLink(uri);
    });

    _notificationSub = PushNotificationService.instance.onMessage.listen((message) {
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        debugPrint('DeepLinkService - Push notification route tapped: $route');
        handlePath(route);
      }
    });
  }

  void handlePath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null) {
      _handleLink(uri);
    }
  }

  void _handleLink(Uri uri) {
    final router = _router;
    final ref = _ref;
    if (router == null || ref == null) return;

    final path = uri.path;

    // Check if this is a Supabase auth callback (recovery/verification)
    if (uri.toString().contains('type=recovery') ||
        uri.toString().contains('access_token') ||
        uri.fragment.contains('type=recovery')) {
      try {
        SupabaseService.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('DeepLinkService - getSessionFromUrl error: $e');
      }
      _navigate(router, '/reset-password');
      return;
    }

    final role = ref.read(authViewModelProvider).user?.role;

    if (role == UserRole.customer) {
      if (path == '/services') {
        ref.read(customerTabProvider.notifier).state = 0;
        _navigate(router, '/');
        return;
      } else if (path == '/shop') {
        ref.read(customerTabProvider.notifier).state = 1;
        _navigate(router, '/');
        return;
      } else if (path == '/collections') {
        ref.read(customerTabProvider.notifier).state = 2;
        _navigate(router, '/');
        return;
      } else if (path == '/home') {
        ref.read(customerTabProvider.notifier).state = 3;
        _navigate(router, '/');
        return;
      }
    } else if (role == UserRole.admin || role == UserRole.manager) {
      final isAdmin = role == UserRole.admin;
      if (path == '/dashboard') {
        ref.read(staffTabProvider.notifier).state = 0;
        _navigate(router, '/');
        return;
      } else if (path == '/properties') {
        ref.read(staffTabProvider.notifier).state = 1;
        _navigate(router, '/');
        return;
      } else if (path == '/approvals') {
        ref.read(staffTabProvider.notifier).state = isAdmin ? 0 : 2; // For manager, approvals is index 2
        _navigate(router, '/');
        return;
      } else if (path == '/workers') {
        ref.read(staffTabProvider.notifier).state = 2; // For admin, workers is index 2
        _navigate(router, '/');
        return;
      } else if (path == '/profile') {
        ref.read(staffTabProvider.notifier).state = 3;
        _navigate(router, '/');
        return;
      }
    } else if (role == UserRole.worker) {
      if (path == '/dashboard') {
        ref.read(workerTabProvider.notifier).state = 0;
        _navigate(router, '/');
        return;
      } else if (path == '/schedule') {
        ref.read(workerTabProvider.notifier).state = 1;
        _navigate(router, '/');
        return;
      } else if (path == '/profile') {
        ref.read(workerTabProvider.notifier).state = 2;
        _navigate(router, '/');
        return;
      }
    }

    final pathWithQuery = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    _navigate(router, pathWithQuery);
  }

  void _navigate(GoRouter router, String path) {
    if (path.isNotEmpty) {
      router.go(path);
    }
  }

  void dispose() {
    _sub?.cancel();
    _notificationSub?.cancel();
  }
}
