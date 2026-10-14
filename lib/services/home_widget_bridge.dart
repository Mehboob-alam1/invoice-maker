import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes the unpaid total the Android home widget reads, then asks it to refresh.
class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _channel = MethodChannel(
    'com.invoice.maker.estimate.billing.ocr.appomatrix/shortcuts',
  );

  static Future<void> publish(String label) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_unpaid', label);
      await _channel.invokeMethod<void>('refreshWidget');
    } catch (_) {}
  }

  static Future<String?> takeLaunchAction() async {
    try {
      return await _channel.invokeMethod<String>('takeLaunchAction');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isOnWifi() async {
    try {
      return await _channel.invokeMethod<bool>('isOnWifi') ?? false;
    } catch (_) {
      return false;
    }
  }
}
