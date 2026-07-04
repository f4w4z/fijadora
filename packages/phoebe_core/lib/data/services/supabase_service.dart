import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  late final SupabaseClient client;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw ArgumentError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define',
      );
    }

    try {
      final supabase = await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        httpClient: _createHttpClient(),
      ).timeout(const Duration(seconds: 15));
      client = supabase.client;
      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('Error initializing Supabase: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  http.Client _createHttpClient() {
    const fingerprintHex = String.fromEnvironment('SUPABASE_CERT_FINGERPRINT');
    if (fingerprintHex.isEmpty || !kReleaseMode) {
      return http.Client();
    }

    Digest? expectedHash;
    try {
      expectedHash = sha256.convert(_hexDecode(fingerprintHex));
    } catch (_) {
      return http.Client();
    }

    final ioClient = HttpClient();
    ioClient.badCertificateCallback = (cert, host, port) {
      final pem = cert.pem;
      if (pem.isEmpty) return false;
      final derB64 = pem
          .split('\n')
          .where((l) => !l.startsWith('---'))
          .join();
      final der = base64.decode(derB64);
      final certHash = sha256.convert(der);
      return certHash == expectedHash;
    };
    return IOClient(ioClient);
  }

  List<int> _hexDecode(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
