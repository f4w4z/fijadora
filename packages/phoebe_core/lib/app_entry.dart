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
  WidgetsFlutterBinding.ensureInitialized();

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

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  try {
    await Hive.initFlutter();
    await Hive.openBox('cached_jobs');
    await Hive.openBox('app_preferences');
    debugPrint('Hive initialized (cached_jobs, app_preferences).');
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e. Running with mock fallback.');
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

  final pushService = PushNotificationService.instance;
  try {
    await pushService.init(options: firebaseOptions);
  } catch (e) {
    debugPrint('Push notification initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const PhoebeApp(),
    ),
  );
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
      DeepLinkService.instance.init(router);
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
        debugPrint('PhoebeApp - resumed');
        ref.invalidate(connectivityProvider);
        break;
      case AppLifecycleState.paused:
        debugPrint('PhoebeApp - paused');
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
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final textScale = MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
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

class _PlatformScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const ClampingScrollPhysics();
    }
  }
}
