import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class TelemetryService {
  void logEvent(String name, [Map<String, dynamic>? properties]) {
    if (kReleaseMode) {
      Sentry.addBreadcrumb(Breadcrumb(
        message: name,
        data: properties,
        category: 'telemetry',
        level: SentryLevel.info,
      ));
    }
    debugPrint('\x1B[32m[TELEMETRY] Event: $name | $properties\x1B[0m');
  }

  void captureException(Object error, [StackTrace? stackTrace]) {
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    debugPrint('\x1B[31m[TELEMETRY] Error: $error\x1B[0m');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});
