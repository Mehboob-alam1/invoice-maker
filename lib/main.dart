import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/ad_config.dart';
import 'ads/ad_remote_config.dart';
import 'ads/ad_service.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/invoice_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'services/subscription_service.dart';
import 'services/user_profile_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (AdConfig.isSupported) {
    await MobileAds.instance.initialize();
    await AdRemoteConfig.instance.load();
    await AdService.instance.initialize();
  }
  final invoiceProvider = InvoiceProvider();
  invoiceProvider.onCloudSyncRequested = () => UserProfileSync.pushFromProvider(invoiceProvider);
  final themeProvider = ThemeProvider();
  final subscriptionService = SubscriptionService(invoiceProvider);
  final authService = AuthService(
    invoiceProvider: invoiceProvider,
    subscriptionService: subscriptionService,
  );
  await Future.wait([
    invoiceProvider.load(),
    themeProvider.load(),
  ]);
  await subscriptionService.initialize();
  await authService.initialize();
  await PushNotificationService.instance.initialize();
  runApp(InvoiceApp(
    invoiceProvider: invoiceProvider,
    themeProvider: themeProvider,
    subscriptionService: subscriptionService,
    authService: authService,
  ));
}
