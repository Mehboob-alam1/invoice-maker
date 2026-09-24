import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../ads/ad_remote_config.dart';
import 'user_firestore_service.dart';

/// Firebase Cloud Messaging — token sync + foreground hooks.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    try {
      if (!AdRemoteConfig.instance.pushNotificationsEnabled) {
        debugPrint('PushNotificationService: disabled via Remote Config');
        return;
      }
      await _messaging.setAutoInitEnabled(true);
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('PushNotificationService: notifications denied');
        return;
      }

      _token = await _messaging.getToken();
      await _persistToken(_token);

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FCM foreground: ${message.notification?.title}');
      });

      FirebaseAuth.instance.authStateChanges().listen((_) async {
        _token = await _messaging.getToken();
        await _persistToken(_token);
      });
    } catch (e) {
      debugPrint('PushNotificationService.initialize: $e');
    }
  }

  Future<void> _persistToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserFirestoreService.instance.saveFcmToken(uid: uid, token: token);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}
