import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_config.dart';
import 'data/services/supabase_service.dart';
import 'data/services/telemetry_service.dart';
import 'ui/core/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/theme_provider.dart';

void runPhoebeApp(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const PhoebeApp(),
    ),
  );
}

class PhoebeApp extends ConsumerWidget {
  const PhoebeApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ),
      ),
    );
  }
}
