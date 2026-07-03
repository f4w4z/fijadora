import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';
import 'deep_link_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('PushNotificationService - Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init({FirebaseOptions? options}) async {
    try {
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      debugPrint('PushNotificationService - Firebase initialized');
    } catch (e) {
      debugPrint('PushNotificationService - Firebase init failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    await _requestPermission(messaging);

    _fcmToken = await messaging.getToken();
    debugPrint('PushNotificationService - FCM Token: $_fcmToken');
    if (_fcmToken != null) {
      await _storeToken(_fcmToken!);
    }

    messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('PushNotificationService - Token refreshed: $token');
      _storeToken(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('PushNotificationService - Local notification tapped: ${response.payload}');
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          DeepLinkService.instance.handlePath(payload);
        }
      },
    );
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('PushNotificationService - Notification permission denied');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('PushNotificationService - Foreground message: ${message.messageId}');
    _messageController.add(message);
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('PushNotificationService - Notification tapped: ${message.data}');
    _messageController.add(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'],
    );
  }

  Future<void> createNotificationChannel({
    required String id,
    required String name,
    String description = '',
  }) async {
    final androidChannel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: Importance.high,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      androidChannel,
    );
  }

  Future<void> _storeToken(String token) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
      }, onConflict: 'user_id,token');
    } catch (e) {
      debugPrint('PushNotificationService - Failed to store FCM token: $e');
    }
  }

  void dispose() {
    _messageController.close();
  }
}
