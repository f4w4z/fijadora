import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingService {
  static Future<void> init() async {
    if (kReleaseMode) {
      await SentryFlutter.init(
        (options) {
          options.dsn =
              const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
          options.tracesSampleRate = 0.2;
          options.enableAppHangTracking = true;
          options.environment =
              const String.fromEnvironment('APP_ENV', defaultValue: 'development');
        },
        appRunner: () {},
      );
    }
  }

  static void captureException(dynamic exception, {StackTrace? stackTrace}) {
    if (kReleaseMode) {
      Sentry.captureException(exception, stackTrace: stackTrace);
    } else {
      debugPrint('CrashReportingService: $exception');
    }
  }

  static void captureMessage(String message) {
    if (kReleaseMode) {
      Sentry.captureMessage(message);
    } else {
      debugPrint('CrashReportingService: $message');
    }
  }
}
