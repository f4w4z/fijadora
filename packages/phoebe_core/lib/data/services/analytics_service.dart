import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((ref) {
  final analytics = ref.read(analyticsProvider);
  return FirebaseAnalyticsObserver(analytics: analytics);
});

void logAnalyticsEvent(FirebaseAnalytics analytics, String name, {Map<String, Object>? parameters}) {
  if (kReleaseMode) {
    analytics.logEvent(name: name, parameters: parameters);
  }
}
