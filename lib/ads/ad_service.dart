import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/subscription_tier.dart';
import 'ad_config.dart';
import 'ad_remote_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  AppOpenAd? _appOpenAd;
  bool _isShowingFullScreenAd = false;
  bool _interstitialLoading = false;
  bool _appOpenLoading = false;
  DateTime? _lastAppOpenShown;
  DateTime? _lastInterstitialShown;

  Future<bool>? _interstitialLoadFuture;

  static const _minAppOpenInterval = Duration(minutes: 4);
  static const _minAppOpenIntervalPremium = Duration(minutes: 10);
  static const _minInterstitialInterval = Duration(seconds: 20);

  Future<void> initialize() async {
    if (!AdConfig.isSupported) return;
    await AdRemoteConfig.instance.load();
    preloadInterstitial();
    preloadAppOpen();
  }

  bool get isShowingFullScreenAd => _isShowingFullScreenAd;

  bool get interstitialReady => _interstitial != null;

  bool get isInterstitialLoadInProgress => _interstitialLoading || _interstitialLoadFuture != null;

  /// Whether an interstitial may be shown (tier, cooldown, not already showing).
  bool shouldAttemptInterstitial(SubscriptionTier tier) {
    if (!AdConfig.isSupported ||
        !AdRemoteConfig.instance.adsEnabled ||
        !tier.showInterstitialAds ||
        _isShowingFullScreenAd) {
      return false;
    }
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < _minInterstitialInterval) {
      return false;
    }
    return true;
  }

  /// Loads an interstitial if needed; returns `true` only when [interstitialReady].
  Future<bool> ensureInterstitialLoaded({Duration timeout = const Duration(seconds: 5)}) async {
    if (!AdConfig.isSupported) return false;
    if (_interstitial != null) return true;

    _interstitialLoadFuture ??= _loadInterstitialOnce();
    try {
      return await _interstitialLoadFuture!.timeout(
        timeout,
        onTimeout: () {
          debugPrint('Interstitial load timed out');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Interstitial load error: $e');
      return false;
    } finally {
      if (_interstitial == null) {
        _interstitialLoadFuture = null;
      }
    }
  }

  Future<bool> _loadInterstitialOnce() async {
    if (_interstitial != null) return true;
    if (_interstitialLoading) {
      while (_interstitialLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_interstitial != null) return true;
      }
      if (_interstitial != null) return true;
    }

    final completer = Completer<bool>();
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdRemoteConfig.instance.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          debugPrint('Interstitial load failed: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  void preloadInterstitial() {
    if (!AdConfig.isSupported || _interstitial != null || _interstitialLoadFuture != null) return;
    _interstitialLoadFuture = _loadInterstitialOnce().then((ok) {
      if (!ok) _interstitialLoadFuture = null;
      return ok;
    });
  }

  /// Shows a loaded interstitial. Returns whether the ad was presented.
  Future<bool> showInterstitialIfEligible({required SubscriptionTier tier}) async {
    if (!shouldAttemptInterstitial(tier)) return false;

    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }

    _interstitial = null;
    _interstitialLoadFuture = null;
    _isShowingFullScreenAd = true;

    final shown = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        _lastInterstitialShown = DateTime.now();
        preloadInterstitial();
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('Interstitial show failed: $error');
        preloadInterstitial();
        if (!shown.isCompleted) shown.complete(false);
      },
    );

    try {
      await ad.show();
      return await shown.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => true,
      );
    } catch (e) {
      debugPrint('Interstitial show exception: $e');
      _isShowingFullScreenAd = false;
      preloadInterstitial();
      return false;
    }
  }

  void preloadAppOpen() {
    if (!AdConfig.isSupported || _appOpenLoading || _appOpenAd != null) return;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: AdRemoteConfig.instance.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenLoading = false;
          debugPrint('App open load failed: $error');
        },
      ),
    );
  }

  Future<void> showAppOpenIfAvailable({SubscriptionTier tier = SubscriptionTier.free}) async {
    if (!AdConfig.isSupported ||
        !AdRemoteConfig.instance.adsEnabled ||
        !tier.showAppOpenAds ||
        _isShowingFullScreenAd) {
      return;
    }
    final now = DateTime.now();
    final minGap = tier.reducedAppOpenAds ? _minAppOpenIntervalPremium : _minAppOpenInterval;
    if (_lastAppOpenShown != null && now.difference(_lastAppOpenShown!) < minGap) {
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      preloadAppOpen();
      return;
    }
    _appOpenAd = null;
    _isShowingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        _lastAppOpenShown = DateTime.now();
        preloadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        preloadAppOpen();
      },
    );
    await ad.show();
  }

  Future<void> showColdStartAppOpen({SubscriptionTier tier = SubscriptionTier.free}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await showAppOpenIfAvailable(tier: tier);
  }
}
