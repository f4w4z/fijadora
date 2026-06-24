import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/services/supabase_service.dart';
import 'data/services/telemetry_service.dart';
import 'ui/core/router.dart';
import 'ui/core/theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline cache
  try {
    await Hive.initFlutter();
    await Hive.openBox('cached_jobs');
    debugPrint('Hive initialized and cached_jobs box opened.');
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  // Initialize Supabase. Note: if environment variables are missing,
  // it uses safe placeholder values and logs a warning, falling back to mock mode.
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e. Running with mock fallback.');
  }

  // Log App Launch telemetry event
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
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Phoebe Homes',
      debugShowCheckedModeBanner: false,
      
      // Light-only theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Routing configuration
      routerConfig: router,
    );
  }
}
