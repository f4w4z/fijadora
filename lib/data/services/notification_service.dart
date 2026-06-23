import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class NotificationService {
  final _controller = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationsStream => _controller.stream;

  void sendNotification({required String title, required String body}) {
    final notification = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _controller.add(notification);
    debugPrint('[NOTIFICATION] Title: $title | Body: $body');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
