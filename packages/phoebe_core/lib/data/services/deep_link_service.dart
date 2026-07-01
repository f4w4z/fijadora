import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  StreamSubscription? _sub;

  Future<void> init(GoRouter router) async {
    final appLinks = AppLinks();

    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('DeepLinkService - Initial link: $initialUri');
      _navigate(router, initialUri.toString());
    }

    _sub = appLinks.uriLinkStream.listen((uri) {
      debugPrint('DeepLinkService - Incoming link: $uri');
      _navigate(router, uri.toString());
    });
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
