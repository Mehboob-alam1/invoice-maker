import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ads/ad_remote_config.dart';
import 'notification_permission_platform.dart';
import 'user_firestore_service.dart';

/// Firebase Cloud Messaging — token sync + foreground hooks.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;
  bool _listenersAttached = false;
  bool _permissionRequestInFlight = false;

  String? get token => _token;

  /// Wire FCM without showing the system permission dialog (safe during splash).
  Future<void> prepare() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      if (!AdRemoteConfig.instance.pushNotificationsEnabled) {
        debugPrint('PushNotificationService: disabled via Remote Config');
        return;
      }
      await _messaging.setAutoInitEnabled(true);
      _attachListeners();

      if (await _hasNotificationPermission()) {
        await _syncToken();
      }
    } catch (e) {
      debugPrint('PushNotificationService.prepare: $e');
    }
  }

  /// Whether the user has allowed notifications (Android 13+ / iOS).
  Future<bool> notificationsAreEnabled() => _hasNotificationPermission();

  /// Settings — always offer the system prompt (ignores Remote Config kill switch).
  Future<void> requestPermissionFromSettings() => _requestPermission(
        respectRemoteConfig: false,
        openSettingsIfPermanentlyDenied: true,
      );

  /// Home / first launch — respects [push_notifications_enabled] in Remote Config.
  Future<void> requestPermissionIfNeeded() => _requestPermission(
        respectRemoteConfig: true,
        openSettingsIfPermanentlyDenied: false,
      );

  Future<void> _requestPermission({
    required bool respectRemoteConfig,
    required bool openSettingsIfPermanentlyDenied,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_permissionRequestInFlight) return;
    if (respectRemoteConfig && !AdRemoteConfig.instance.pushNotificationsEnabled) {
      debugPrint('PushNotificationService: push disabled via Remote Config');
      return;
    }

    _permissionRequestInFlight = true;
    try {
      await _messaging.setAutoInitEnabled(true);
      _attachListeners();

      if (await _hasNotificationPermission()) {
        debugPrint('PushNotificationService: already granted');
        await _syncToken();
        return;
      }

      var status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        debugPrint('PushNotificationService: permanently denied');
        if (openSettingsIfPermanentlyDenied) {
          await openAppSettings();
        }
        return;
      }

      if (Platform.isAndroid) {
        final outcome =
            await NotificationPermissionPlatform.requestAndroidPostNotifications();
        debugPrint('PushNotificationService: Android native result=$outcome');
        if (outcome == 'granted' || await _hasNotificationPermission()) {
          await _syncToken();
          return;
        }
      }

      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint(
          'PushNotificationService: iOS FCM=${settings.authorizationStatus}',
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          await _syncToken();
          return;
        }
      }

      status = await Permission.notification.request();
      debugPrint('PushNotificationService: permission_handler=$status');
      if (status.isGranted) {
        await _syncToken();
      } else if (status.isPermanentlyDenied && openSettingsIfPermanentlyDenied) {
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('PushNotificationService._requestPermission: $e');
    } finally {
      _permissionRequestInFlight = false;
    }
  }

  Future<bool> _hasNotificationPermission() async {
    if (Platform.isAndroid) {
      return NotificationPermissionPlatform.areNotificationsEnabled();
    }
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });

    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _syncToken();
    });
  }

  Future<void> _syncToken() async {
    try {
      _token = await _messaging.getToken();
      await _persistToken(_token);
    } catch (e) {
      debugPrint('PushNotificationService._syncToken: $e');
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
