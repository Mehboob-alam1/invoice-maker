import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../ads/ad_manager.dart';
import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
import '../firebase_options.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/business_setup/business_name_screen.dart';
import '../screens/home/invoices_home_screen.dart';
import '../screens/onboarding/google_login_screen.dart';
import '../screens/onboarding/language_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/engagement_service.dart';
import '../services/push_notification_service.dart';
import '../services/invoice_reminder_service.dart';
import '../services/referral_service.dart';
import '../services/subscription_service.dart';
import '../services/user_database_service.dart';
import '../services/user_profile_sync.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.invoiceProvider,
    required this.themeProvider,
    required this.subscriptionService,
    required this.authService,
    required this.initialScreen,
  });

  final InvoiceProvider invoiceProvider;
  final ThemeProvider themeProvider;
  final SubscriptionService subscriptionService;
  final AuthService authService;
  final Widget initialScreen;
}

typedef BootstrapStatusCallback = void Function(String message);

Widget resolveInitialScreen(InvoiceProvider provider) {
  if (provider.hasCompletedOnboarding) {
    return const InvoicesHomeScreen();
  }
  if (!provider.onboardingLanguageDone) {
    return const LanguageScreen(fromOnboarding: true);
  }
  if (!provider.onboardingCarouselDone) {
    return const OnboardingScreen();
  }
  if (!provider.onboardingGoogleStepDone) {
    return const GoogleLoginScreen();
  }
  return const BusinessNameScreen();
}

/// Splash waits only for Firebase + local prefs. Ads, store, and push start later.
Future<AppBootstrapResult> runAppBootstrap({
  BootstrapStatusCallback? onStatus,
}) async {
  void status(String message) => onStatus?.call(message);

  status('Starting…');
  final invoiceProvider = InvoiceProvider();
  InvoiceReminderService.instance.afterSync =
      () => EngagementService.instance.reschedule(invoiceProvider);
  InvoiceProvider.onLocalDataWiped = () => EngagementService.instance.clearLocal();
  invoiceProvider.onLanguageChanged = () async {
    final channels = await EngagementService.instance.enabledChannels();
    await PushNotificationService.instance.syncTopics(
      languageCode: invoiceProvider.languageCode,
      pro: invoiceProvider.featureTier == SubscriptionTier.pro,
      channels: channels,
    );
  };
  invoiceProvider.onCloudSyncRequested = () => UserProfileSync.pushFromProvider(invoiceProvider);
  final themeProvider = ThemeProvider();
  final subscriptionService = SubscriptionService(invoiceProvider);

  status('Loading your data…');
  // Firebase must finish before AuthService (it reads FirebaseAuth.instance).
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    invoiceProvider.load(),
    themeProvider.load(),
  ]);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final authService = AuthService(
    invoiceProvider: invoiceProvider,
    subscriptionService: subscriptionService,
  );
  EngagementService.instance.applyDeviceLanguage(invoiceProvider);

  unawaited(_warmUp(
    invoiceProvider: invoiceProvider,
    subscriptionService: subscriptionService,
    authService: authService,
  ));

  return AppBootstrapResult(
    invoiceProvider: invoiceProvider,
    themeProvider: themeProvider,
    subscriptionService: subscriptionService,
    authService: authService,
    initialScreen: resolveInitialScreen(invoiceProvider),
  );
}

/// Store, account, config, and notifications. Ads start only when a slot asks.
Future<void> _warmUp({
  required InvoiceProvider invoiceProvider,
  required SubscriptionService subscriptionService,
  required AuthService authService,
}) async {
  try {
    await UserDatabaseService.initialize();
    await Future.wait([
      subscriptionService.initialize(),
      authService.initialize(),
      AdRemoteConfig.instance.load(),
    ]);
    invoiceProvider.applyRemoteInvoiceLimits();
    AdManager.instance.hasCreatedInvoice = () => invoiceProvider.hasCreatedFirstInvoice;
    // Consent + SDK after the first screen is up — does not hold the splash.
    unawaited(AdService.instance.ensureMobileAdsReady());
    unawaited(PushNotificationService.instance.prepare());
    unawaited(() async {
      final channels = await EngagementService.instance.enabledChannels();
      await PushNotificationService.instance.syncTopics(
        languageCode: invoiceProvider.languageCode,
        pro: invoiceProvider.featureTier == SubscriptionTier.pro,
        channels: channels,
      );
    }());
    unawaited(ReferralService.instance.start(invoiceProvider));
    unawaited(InvoiceReminderService.instance.prepare());
  } catch (error, stack) {
    debugPrint('Background startup failed: $error\n$stack');
  }
}
