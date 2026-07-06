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
  final _pendingLinks = <Uri>[];

  /// Subscribe to link stream early (before runApp) to avoid missing links.
  /// Buffers events until [init] is called with a router and ref.
  void startListening() {
    final appLinks = AppLinks();
    _sub = appLinks.uriLinkStream.listen((uri) {
      debugPrint('DeepLinkService - Incoming link: ${uri.host}${uri.path}');
      if (_router != null && _ref != null) {
        _handleLink(uri);
      } else {
        _pendingLinks.add(uri);
      }
    });
  }

  Future<void> init(GoRouter router, WidgetRef ref) async {
    _router = router;
    _ref = ref;

    // Replay any links that arrived before init
    for (final uri in _pendingLinks) {
      _handleLink(uri);
    }
    _pendingLinks.clear();

    _notificationSub = PushNotificationService.instance.onMessage.listen((message) {
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        debugPrint('DeepLinkService - Push notification route tapped');
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

  /// Validates whether a URI is a Supabase auth callback by inspecting the fragment,
  /// not via substring matching. Prevents spoofed deeplinks with 'access_token' in the path.
  bool _isAuthCallback(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.contains('type=recovery')) return true;
    if (fragment.contains('access_token=') || fragment.contains('access_token&')) return true;
    return false;
  }

  void _handleLink(Uri uri) {
    final router = _router;
    final ref = _ref;
    if (router == null || ref == null) return;

    final path = uri.path;

    // Check if this is a Supabase auth callback (recovery/verification)
    if (_isAuthCallback(uri)) {
      SupabaseService.instance.client.auth.getSessionFromUrl(uri);
      if (uri.fragment.contains('type=recovery')) {
        _navigate(router, '/reset-password');
      } else {
        _navigate(router, '/');
      }
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
