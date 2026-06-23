import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  late final SupabaseClient client;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load from dart-define environment variables
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://placeholder-url.supabase.co',
    );
    const anonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'placeholder-anon-key',
    );

    if (url == 'https://placeholder-url.supabase.co' || anonKey == 'placeholder-anon-key') {
      debugPrint('WARNING: Supabase URL/Anon Key not provided via environment. Using placeholders.');
    }

    try {
      final supabase = await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      client = supabase.client;
      _isInitialized = true;
      debugPrint('Supabase initialized successfully.');
    } catch (e, stack) {
      debugPrint('Error initializing Supabase: $e');
      debugPrint(stack.toString());
      // Re-throw so the app initialization knows it failed
      rethrow;
    }
  }
}
