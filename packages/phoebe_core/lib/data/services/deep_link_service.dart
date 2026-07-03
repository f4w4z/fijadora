import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'supabase_service.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  StreamSubscription? _sub;

  Future<void> init(GoRouter router) async {
    final appLinks = AppLinks();

    // The initial link is already processed during the startup sequence
    // to configure the router's initialLocation.
    _sub = appLinks.uriLinkStream.listen((uri) {
      debugPrint('DeepLinkService - Incoming link: $uri');
      _handleLink(router, uri);
    });
  }

  void _handleLink(GoRouter router, Uri uri) {
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

    _navigate(router, uri.toString());
  }

  void _navigate(GoRouter router, String uri) {
    final path = Uri.tryParse(uri)?.path;
    if (path != null && path.isNotEmpty) {
      router.go(path);
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
