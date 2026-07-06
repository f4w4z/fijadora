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
  }

  void captureException(Object error, [StackTrace? stackTrace]) {
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});
