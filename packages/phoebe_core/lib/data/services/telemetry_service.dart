import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelemetryService {
  void logEvent(String name, [Map<String, dynamic>? properties]) {
    final propsStr = properties != null ? ' | Properties: $properties' : '';
    debugPrint('\x1B[32m[POSTHOG ANALYTICS] Event: $name$propsStr\x1B[0m');
  }

  void captureException(Object error, [StackTrace? stackTrace]) {
    debugPrint('\x1B[31m[SENTRY CRASH REPORT] Error: $error\x1B[0m');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});
