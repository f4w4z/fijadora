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
          options.beforeSend = (event, hint) {
            return _scrubPii(event);
          };
        },
        appRunner: () {},
      );
    }
  }

  static SentryEvent _scrubPii(SentryEvent event) {
    final exceptions = event.exceptions;
    if (exceptions != null) {
      for (final exc in exceptions) {
        final value = exc.value;
        if (value != null) {
          exc.value = value
              .replaceAllMapped(_emailPattern, (_) => '[EMAIL]')
              .replaceAllMapped(_uuidPattern, (_) => '[UUID]');
        }
      }
    }
    return event;
  }

  static final _emailPattern = RegExp(r'[\w\.\-]+@[\w\-]+\.\w{2,4}');
  static final _uuidPattern = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    caseSensitive: false,
  );

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