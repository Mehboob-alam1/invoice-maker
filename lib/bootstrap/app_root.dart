import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_config.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_languages.dart';
import '../navigation/app_route_observer.dart';
import '../widgets/app_open_lifecycle.dart';
import '../widgets/splash_launch_view.dart';
import 'app_bootstrap.dart';

/// Single [MaterialApp]: light window matches splash, then same app shows logo + loading.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppBootstrapResult? _result;
  String? _status;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    try {
      final result = await runAppBootstrap(
        onStatus: (message) {
          if (mounted) setState(() => _status = message);
        },
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e, st) {
      debugPrint('App bootstrap failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final ready = result != null;

    return ListenableBuilder(
      listenable: ready
          ? Listenable.merge([result.themeProvider, result.invoiceProvider])
          : _StaticListenable.instance,
      builder: (context, _) {
        final themeMode = result?.themeProvider.themeMode ?? ThemeMode.light;
        final locale = Locale(result?.invoiceProvider.languageCode ?? 'en');

        return MaterialApp(
          title: AppConfig.appDisplayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: locale,
          supportedLocales: AppLanguages.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorObservers: ready ? [appRouteObserver] : const [],
          builder: (context, child) {
            final body = child ?? const SizedBox.shrink();
            if (!ready) return body;
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: result.themeProvider),
                ChangeNotifierProvider.value(value: result.invoiceProvider),
                ChangeNotifierProvider.value(value: result.subscriptionService),
                ChangeNotifierProvider.value(value: result.authService),
              ],
              child: AppOpenLifecycle(child: body),
            );
          },
          home: ready ? result.initialScreen : SplashLaunchView(statusText: _status),
        );
      },
    );
  }
}

class _StaticListenable implements Listenable {
  _StaticListenable._();
  static final _StaticListenable instance = _StaticListenable._();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
