import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_config.dart';
import 'data/services/connectivity_provider.dart';
import 'data/services/crash_reporting_service.dart';
import 'data/services/deep_link_service.dart';
import 'data/services/local_cache_service.dart';
import 'data/services/push_notification_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/telemetry_service.dart';
import 'ui/core/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/theme_provider.dart';

void runFijadoraApp(
  AppConfig config, {
  FirebaseOptions? firebaseOptions,
}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame(); // Keep native splash screen visible while initializing

  await CrashReportingService.init();

  FlutterError.onError = (details) {
    CrashReportingService.captureException(
      details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    CrashReportingService.captureException(exception, stackTrace: stackTrace);
    return true;
  };

  // Initialize Firebase eagerly so FirebaseAnalytics.instance is available
  // before runApp() is called and providers are first read.
  try {
    if (firebaseOptions != null) {
      await Firebase.initializeApp(options: firebaseOptions);
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    CrashReportingService.captureException(e);
  }

  const secureStorage = FlutterSecureStorage();

  Future<List<int>> _getOrCreateKey(String key) async {
    final stored = await secureStorage.read(key: key);
    if (stored != null) return base64.decode(stored);
    final k = sha256.convert(sha256.convert([DateTime.now().microsecondsSinceEpoch]).bytes).bytes;
    await secureStorage.write(key: key, value: base64.encode(k));
    return k;
  }

  // Run Hive and Supabase initializations in parallel!
  await Future.wait([
    Future(() async {
      try {
        await Hive.initFlutter();
        final prefsKey = await _getOrCreateKey('hive_key_prefs');
        await Hive.openBox('app_preferences', encryptionCipher: HiveAesCipher(prefsKey));
        await LocalCacheService.instance.init();
      } catch (e) {
        CrashReportingService.captureException(e);
      }
    }),
    Future(() async {
      try {
        await SupabaseService.instance.initialize();
      } catch (e) {
        CrashReportingService.captureException(e);
        rethrow;
      }
    }),
  ]);

  // Synchronously configure the initial status bar and navigation bar brightness
  // using the saved user theme from Hive, preventing dark/light overlay flashes on startup.
  try {
    final box = Hive.box('app_preferences');
    final storedTheme = box.get('theme_mode', defaultValue: 'system') as String;
    final isDark = storedTheme == 'dark' ||
        (storedTheme == 'system' && PlatformDispatcher.instance.platformBrightness == Brightness.dark);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  } catch (e) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  // Retrieve initial deep link during startup
  Uri? initialUri;
  try {
    initialUri = await AppLinks().getInitialLink();
    if (initialUri != null) {
      final fragment = initialUri.fragment;
      if (fragment.contains('type=recovery') ||
          fragment.contains('type=signup') ||
          fragment.contains('access_token=') ||
          fragment.contains('access_token&')) {
        await SupabaseService.instance.client.auth.getSessionFromUrl(initialUri);
      }
    }
  } catch (e) {
    CrashReportingService.captureException(e);
  }

  try {
    final telemetry = TelemetryService();
    telemetry.logEvent('app_launch', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'flutter',
    });
  } catch (e) {
    CrashReportingService.captureException(e);
  }

  // Start listening for deep links before runApp to avoid missing initial links
  DeepLinkService.instance.startListening();

  // Initialize push notification services in the background so it doesn't block the UI.
  // Firebase is already initialized above, so we pass null to skip re-initialization.
  PushNotificationService.instance.init(options: null).catchError((e) {
    CrashReportingService.captureException(e);
  });

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        initialUriProvider.overrideWithValue(initialUri),
      ],
      child: const FijadoraApp(),
    ),
  );

  // Allow the first frame to render now that runApp was called with all dependencies loaded
  binding.allowFirstFrame();
}

class FijadoraApp extends ConsumerStatefulWidget {
  const FijadoraApp({super.key});

  @override
  ConsumerState<FijadoraApp> createState() => _FijadoraAppState();
}

class _FijadoraAppState extends ConsumerState<FijadoraApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      DeepLinkService.instance.init(router, ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.invalidate(connectivityProvider);
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // NOTE: Clamp text scaling via MediaQuery.withClampedTextScaling, which only
    // creates an aspect dependency on the text scaler. Using MediaQuery.of(context)
    // here would subscribe to *all* MediaQuery aspects (including viewInsets), so
    // every keyboard animation would rebuild MaterialApp — and the whole app from
    // [root] — orphaning any open dialog's InputDecorator mid-animation and
    // throwing "Tried to build dirty widget in the wrong build scope".
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.3,
        child: MaterialApp.router(
          title: 'Fijadora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          scrollBehavior: _PlatformScrollBehavior(),
          supportedLocales: const [
            Locale('en', 'US'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}

class _PlatformScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.iOS || 
           defaultTargetPlatform == TargetPlatform.macOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
