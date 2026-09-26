import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
import '../firebase_options.dart';
import '../providers/invoice_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/business_setup/business_name_screen.dart';
import '../screens/home/invoices_home_screen.dart';
import '../screens/onboarding/google_login_screen.dart';
import '../screens/onboarding/language_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/subscription_service.dart';
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

Future<AppBootstrapResult> runAppBootstrap({
  BootstrapStatusCallback? onStatus,
  Duration minSplashDuration = const Duration(milliseconds: 1200),
  Duration adPreloadTimeout = const Duration(seconds: 14),
}) async {
  void status(String message) => onStatus?.call(message);

  final started = DateTime.now();

  status('Starting…');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final invoiceProvider = InvoiceProvider();
  invoiceProvider.onCloudSyncRequested = () => UserProfileSync.pushFromProvider(invoiceProvider);
  final themeProvider = ThemeProvider();
  final subscriptionService = SubscriptionService(invoiceProvider);
  final authService = AuthService(
    invoiceProvider: invoiceProvider,
    subscriptionService: subscriptionService,
  );

  status('Loading your data…');
  await Future.wait([
    invoiceProvider.load(),
    themeProvider.load(),
  ]);

  status('Checking subscription…');
  await subscriptionService.initialize();
  await authService.initialize();

  if (AdConfig.isSupported) {
    status('Preparing ads…');
    await MobileAds.instance.initialize();
    await AdRemoteConfig.instance.load();
    await AdService.instance.initialize();
    await AdService.instance.waitForStartupPreloads(
      tier: invoiceProvider.subscriptionTier,
      timeout: adPreloadTimeout,
    );
  }

  status('Almost ready…');
  await PushNotificationService.instance.initialize();

  final elapsed = DateTime.now().difference(started);
  if (elapsed < minSplashDuration) {
    await Future.delayed(minSplashDuration - elapsed);
  }

  return AppBootstrapResult(
    invoiceProvider: invoiceProvider,
    themeProvider: themeProvider,
    subscriptionService: subscriptionService,
    authService: authService,
    initialScreen: resolveInitialScreen(invoiceProvider),
  );
}
