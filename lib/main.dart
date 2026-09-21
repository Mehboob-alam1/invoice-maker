import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/ad_config.dart';
import 'app.dart';
import 'providers/invoice_provider.dart';
import 'providers/theme_provider.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AdConfig.isSupported) {
    await MobileAds.instance.initialize();
  }
  final invoiceProvider = InvoiceProvider();
  final themeProvider = ThemeProvider();
  await Future.wait([
    invoiceProvider.load(),
    themeProvider.load(),
  ]);
  runApp(InvoiceApp(
    invoiceProvider: invoiceProvider,
    themeProvider: themeProvider,
  ));
}
