import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

void runPhoebeApp(
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
    debugPrint('Firebase initialization failed: $e');
  }

  // Run Hive and Supabase initializations in parallel!
  await Future.wait([
    Future(() async {
      try {
        await Hive.initFlutter();
        await Hive.openBox('app_preferences');
        await LocalCacheService.instance.init();
      } catch (e) {
        debugPrint('Hive initialization failed: $e');
      }
    }),
    Future(() async {
      try {
        await SupabaseService.instance.initialize();
      } catch (e) {
        debugPrint('Supabase initialization failed: $e.');
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
      if (initialUri.toString().contains('type=recovery') ||
          initialUri.toString().contains('access_token') ||
          initialUri.fragment.contains('type=recovery')) {
        await SupabaseService.instance.client.auth.getSessionFromUrl(initialUri);
      }
    }
  } catch (e) {
    debugPrint('runPhoebeApp - Failed to fetch initial link: $e');
  }

  try {
    final telemetry = TelemetryService();
    telemetry.logEvent('app_launch', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'flutter',
    });
  } catch (e) {
    debugPrint('Failed to log telemetry launch: $e');
  }

  // Start listening for deep links before runApp to avoid missing initial links
  DeepLinkService.instance.startListening();

  // Initialize push notification services in the background so it doesn't block the UI.
  // Firebase is already initialized above, so we pass null to skip re-initialization.
  PushNotificationService.instance.init(options: null).catchError((e) {
    debugPrint('Push notification initialization failed: $e');
  });

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        initialUriProvider.overrideWithValue(initialUri),
      ],
      child: const PhoebeApp(),
    ),
  );

  // Allow the first frame to render now that runApp was called with all dependencies loaded
  binding.allowFirstFrame();
}

class PhoebeApp extends ConsumerStatefulWidget {
  const PhoebeApp({super.key});

  @override
  ConsumerState<PhoebeApp> createState() => _PhoebeAppState();
}

class _PhoebeAppState extends ConsumerState<PhoebeApp> with WidgetsBindingObserver {
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

    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3);

    return _TextScaleWrapper(
      textScale: textScale,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
        child: MaterialApp.router(
          title: 'Phoebe Homes',
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

class _TextScaleWrapper extends StatelessWidget {
  const _TextScaleWrapper({required this.textScale, required this.child});
  final double textScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
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
