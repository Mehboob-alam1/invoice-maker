import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_languages.dart';
import 'providers/invoice_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'navigation/app_route_observer.dart';
import 'widgets/app_open_lifecycle.dart';

class InvoiceApp extends StatelessWidget {
  final InvoiceProvider invoiceProvider;
  final ThemeProvider themeProvider;
  final SubscriptionService subscriptionService;
  final AuthService authService;
  final Widget initialScreen;

  const InvoiceApp({
    super.key,
    required this.invoiceProvider,
    required this.themeProvider,
    required this.subscriptionService,
    required this.authService,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: invoiceProvider),
        ChangeNotifierProvider.value(value: subscriptionService),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: Consumer2<ThemeProvider, InvoiceProvider>(
        builder: (context, theme, invoices, _) {
          return MaterialApp(
            title: AppConfig.appDisplayName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.themeMode,
            locale: Locale(invoices.languageCode),
            supportedLocales: AppLanguages.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorObservers: [appRouteObserver],
            builder: (context, child) => AppOpenLifecycle(child: child ?? const SizedBox.shrink()),
            home: initialScreen,
          );
        },
      ),
    );
  }
}

