import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_languages.dart';
import 'providers/invoice_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/invoices_home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/native_ad_host.dart';

class InvoiceApp extends StatelessWidget {
  final InvoiceProvider invoiceProvider;
  final ThemeProvider themeProvider;

  const InvoiceApp({
    super.key,
    required this.invoiceProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: invoiceProvider),
      ],
      child: Consumer2<ThemeProvider, InvoiceProvider>(
        builder: (context, theme, invoices, _) {
          return MaterialApp(
            title: 'Invoice Maker',
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
            builder: (context, child) => NativeAdHost(child: child),
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    return invoiceProvider.hasCompletedOnboarding
        ? const InvoicesHomeScreen()
        : const OnboardingScreen();
  }
}
