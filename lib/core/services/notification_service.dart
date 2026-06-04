import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_app/data/datasources/firebase_firestore_datasource.dart';
import 'package:delivery_app/data/repositories/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final FirebaseFirestoreDataSource _firestore;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _notifSubscription;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _onMessageSubscription;
  StreamSubscription? _onMessageOpenedAppSubscription;
  static GoRouter? _router;
  bool _initialized = false;

  NotificationService(this._firestore);

  static void initRouter(GoRouter router) {
    _router = router;
  }

  Future<void> initialize({required String userId}) async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _initLocalNotifications();
      await _setupTokenHandling(userId);
      _setupMessageHandlers();
      _setupNotificationListener(userId);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _setupTokenHandling(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((t) => _saveToken(userId, t));
  }

  Future<void> _saveToken(String userId, String token) async {
    final path = 'users/$userId';
    await _firestore.updateData(path, {
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  void _setupMessageHandlers() {
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    _fcm.getInitialMessage().then((m) {
      if (m != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleRemoteMessageTap(m));
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final route = message.data['route']?.toString();
    await _showLocalNotification(
      id: message.messageId.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      route: route,
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? route,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for order updates and messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: route,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && _router != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _router!.go(route);
      });
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final route = message.data['route']?.toString();
    if (route != null && _router != null) {
      _router!.go(route);
    }
  }

  void _setupNotificationListener(String userId) {
    final repo = NotificationRepository(_firestore);
    _notifSubscription?.cancel();
    _notifSubscription = repo.streamNotifications(userId).listen((notifs) {
      for (final notif in notifs) {
        if (notif['read'] == true) continue;
        final route = notif['route']?.toString();
        _showLocalNotification(
          id: notif['id'].hashCode,
          title: notif['title']?.toString() ?? '',
          body: notif['body']?.toString() ?? '',
          route: route,
        );
        repo.markRead(userId, notif['id'] as String);
      }
    });
  }

  void dispose() {
    _notifSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
  }
}
