import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android POST_NOTIFICATIONS via Activity — reliable on API 33+.
class NotificationPermissionPlatform {
  NotificationPermissionPlatform._();
  static const MethodChannel _channel = MethodChannel(
    'com.invoice.maker.estimate.billing.ocr.appomatrix/notifications',
  );

  /// `granted` | `denied` | `not_required` (API below 33)
  static Future<String> requestAndroidPostNotifications() async {
    if (!Platform.isAndroid) return 'not_required';
    try {
      final result = await _channel.invokeMethod<String>('requestPostNotifications');
      return result ?? 'denied';
    } on PlatformException catch (e) {
      debugPrint('NotificationPermissionPlatform: $e');
      return 'denied';
    } on MissingPluginException catch (e) {
      debugPrint('NotificationPermissionPlatform: $e');
      return 'denied';
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final enabled = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return enabled ?? false;
    } catch (e) {
      debugPrint('NotificationPermissionPlatform.areNotificationsEnabled: $e');
      return false;
    }
  }
}
