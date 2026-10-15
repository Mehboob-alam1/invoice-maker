import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import 'ad_config.dart';
import 'ad_consent.dart';
import 'ad_manager.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  AppOpenAd? _appOpenAd;
  bool _isShowingFullScreenAd = false;
  bool _interstitialLoading = false;
  bool _appOpenLoading = false;

  Future<bool>? _interstitialLoadFuture;
  Future<bool>? _appOpenLoadFuture;
  Future<bool>? _sdkReadyFuture;
  bool _awaitingMediaReturn = false;
  DateTime _suppressForegroundUntil = DateTime.fromMillisecondsSinceEpoch(0);

  RewardedAd? _rewarded;
  bool _rewardedLoading = false;

  /// Bumped after [MobileAds.initialize] so on-screen slots can request.
  final ValueNotifier<int> sdkReady = ValueNotifier<int>(0);

  bool get isSdkReady => sdkReady.value > 0;

  /// Consent + Mobile Ads SDK, started the first time an ad slot needs it.
  Future<bool> ensureMobileAdsReady({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!AdConfig.isSupported) return false;
    if (isSdkReady) return true;
    _sdkReadyFuture ??= _initMobileAds().then((ok) {
      if (!ok) _sdkReadyFuture = null;
      return ok;
    });
    try {
      return await _sdkReadyFuture!.timeout(
        timeout,
        onTimeout: () {
          debugPrint('Mobile Ads init timed out');
          return isSdkReady;
        },
      );
    } catch (error) {
      debugPrint('Mobile Ads init failed: $error');
      _sdkReadyFuture = null;
      return false;
    }
  }

  Future<bool> _initMobileAds() async {
    await AdRemoteConfig.instance.load();
    await AdManager.instance.loadCounters();
    await AdConsent.instance.gather();
    if (!AdConsent.instance.canRequestAds) {
      debugPrint('Ads skipped until consent allows requests.');
      return false;
    }
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      ),
    );
    sdkReady.value++;
    // Rebuild banner/native slots that were waiting on consent.
    AdRemoteConfig.instance.revision.value++;
    debugPrint('Mobile Ads SDK ready');
    return true;
  }

  /// Camera or gallery is about to cover the app. The next resume shows an app-open ad.
  void markAwaitingMediaReturn() {
    _awaitingMediaReturn = true;
  }

  /// True when the picker returned without a resume consuming the flag.
  bool takeMediaReturn() {
    if (!_awaitingMediaReturn) return false;
    _awaitingMediaReturn = false;
    return true;
  }

  bool get appOpenReady => _appOpenAd != null;

  bool get rewardedReady => _rewarded != null;

  bool get isShowingFullScreenAd => _isShowingFullScreenAd;

  bool get interstitialReady => _interstitial != null;

  bool get isInterstitialLoadInProgress => _interstitialLoading || _interstitialLoadFuture != null;

  /// Whether an interstitial may be shown (tier, cooldown, not already showing).
  bool shouldAttemptInterstitial(SubscriptionTier tier) {
    if (!AdConfig.isSupported || _isShowingFullScreenAd) return false;
    if (!tier.showInterstitialAds) return false;
    final decision = AdManager.instance.decideInterstitial(tier: tier);
    if (!decision.allow) {
      debugPrint('Interstitial skipped: ${decision.reason}');
    }
    return decision.allow;
  }

  Future<bool> _loadInterstitialOnce() async {
    if (_interstitial != null) return true;
    if (!(await ensureMobileAdsReady(timeout: const Duration(seconds: 4)))) {
      return false;
    }
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

  Future<bool> _ensureInterstitialLoaded({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_interstitial != null) return true;
    if (InvoiceProvider.adsHeldStatic || !_placementWanted(_interstitialPlacements)) {
      return false;
    }
    _interstitialLoadFuture ??= _loadInterstitialOnce().whenComplete(() {
      _interstitialLoadFuture = null;
    });
    try {
      return await _interstitialLoadFuture!.timeout(
        timeout,
        onTimeout: () {
          debugPrint('Interstitial load timed out');
          return _interstitial != null;
        },
      );
    } catch (_) {
      return _interstitial != null;
    }
  }

  static const _interstitialPlacements = [
    AdPlacement.interstitialMain,
    AdPlacement.interstitialUseTemplate,
    AdPlacement.interstitialOpenInvoice,
    AdPlacement.interstitialSharePdf,
    AdPlacement.interstitialPrint,
    AdPlacement.interstitialPdf,
    AdPlacement.interstitialCustomInvoice,
    AdPlacement.interstitialGenerateAi,
    AdPlacement.interstitialOcrCreate,
    AdPlacement.interstitialSaveInvoice,
    AdPlacement.interstitialPreviewBack,
  ];

  static const _rewardedPlacements = [
    AdPlacement.rewardedTemplate,
    AdPlacement.rewardedAiCredit,
    AdPlacement.rewardedExtraInvoice,
    AdPlacement.rewardedWatermark,
  ];

  bool _placementWanted(List<AdPlacement> placements) {
    final config = AdRemoteConfig.instance;
    for (final placement in placements) {
      if (config.isPlacementWanted(placement)) return true;
    }
    return false;
  }

  /// Loads an interstitial when needed, then shows it. No background preload.
  Future<bool> showInterstitialIfEligible({required SubscriptionTier tier}) async {
    await ensureMobileAdsReady(timeout: const Duration(seconds: 6));
    if (!shouldAttemptInterstitial(tier)) return false;

    final loaded = await _ensureInterstitialLoaded();
    final ad = _interstitial;
    if (!loaded || ad == null) return false;

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
        AdManager.instance.recordInterstitialShown();
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('Interstitial show failed: $error');
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
      return false;
    }
  }

  Future<bool> ensureAppOpenLoaded({Duration timeout = const Duration(seconds: 3)}) async {
    if (!AdConfig.isSupported) return false;
    if (_appOpenAd != null) return true;
    if (!(await ensureMobileAdsReady(timeout: timeout))) return false;

    _appOpenLoadFuture ??= _loadAppOpenOnce();
    try {
      return await _appOpenLoadFuture!.timeout(
        timeout,
        onTimeout: () {
          debugPrint('App open load timed out');
          return false;
        },
      );
    } catch (e) {
      debugPrint('App open load error: $e');
      return false;
    } finally {
      if (_appOpenAd == null) {
        _appOpenLoadFuture = null;
      }
    }
  }

  Future<bool> _loadAppOpenOnce() async {
    if (_appOpenAd != null) return true;
    if (_appOpenLoading) {
      while (_appOpenLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_appOpenAd != null) return true;
      }
      if (_appOpenAd != null) return true;
    }

    final completer = Completer<bool>();
    _appOpenLoading = true;

    AppOpenAd.load(
      adUnitId: AdRemoteConfig.instance.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _appOpenLoading = false;
          debugPrint('App open load failed: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  Future<void> handleResume({required SubscriptionTier tier}) async {
    if (takeMediaReturn()) {
      await showAppOpenOnDemand(
        tier: tier,
        placement: AdPlacement.appOpenMediaReturn,
        ignoreInterval: true,
      );
      return;
    }
    if (DateTime.now().isBefore(_suppressForegroundUntil) || _isShowingFullScreenAd) return;
    if (!AdManager.instance.leftBackgroundLongEnough()) return;
    await showAppOpenOnDemand(
      tier: tier,
      placement: AdPlacement.appOpenForeground,
    );
  }

  /// Loads an app-open ad at the moment it should appear, then waits until it closes.
  Future<bool> showAppOpenOnDemand({
    required SubscriptionTier tier,
    required AdPlacement placement,
    bool ignoreInterval = false,
  }) async {
    if (!AdConfig.isSupported || _isShowingFullScreenAd) return false;
    if (!tier.showAppOpenAds) return false;
    final decision = AdManager.instance.decideAppOpen(
      placement: placement,
      tier: tier,
      ignoreInterval: ignoreInterval,
    );
    if (!decision.allow) {
      debugPrint('App open ${placement.remoteKey} skipped: ${decision.reason}');
      return false;
    }
    _suppressForegroundUntil = DateTime.now().add(const Duration(seconds: 8));

    final loaded = await ensureAppOpenLoaded(timeout: const Duration(seconds: 3));
    final ad = _appOpenAd;
    if (!loaded || ad == null) return false;

    _appOpenAd = null;
    _appOpenLoadFuture = null;
    _isShowingFullScreenAd = true;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        AdManager.instance.recordAppOpenShown();
        _suppressForegroundUntil = DateTime.now().add(const Duration(seconds: 3));
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('App open show failed: $error');
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    try {
      await ad.show();
      return await closed.future.timeout(const Duration(minutes: 2), onTimeout: () => true);
    } catch (e) {
      debugPrint('App open show exception: $e');
      _isShowingFullScreenAd = false;
      return false;
    }
  }

  Future<bool> _waitForRewarded(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_rewarded != null) return true;
      if (!_rewardedLoading) return false;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return _rewarded != null;
  }

  Future<void> _loadRewardedOnce() async {
    if (!AdConfig.isSupported || _rewarded != null || _rewardedLoading) return;
    if (InvoiceProvider.adsHeldStatic || !_placementWanted(_rewardedPlacements)) return;
    if (!AdManager.instance.canShowRewarded()) return;
    if (!(await ensureMobileAdsReady(timeout: const Duration(seconds: 4)))) return;

    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdRemoteConfig.instance.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          debugPrint('Rewarded load failed: $error');
        },
      ),
    );
  }

  /// Loads a rewarded ad when the user asks for one, then shows it.
  ///
  /// True only when the user earns the reward.
  Future<bool> showRewarded({
    required String adUnitId,
    AdPlacement placement = AdPlacement.rewardedTemplate,
  }) async {
    if (!AdConfig.isSupported ||
        !AdRemoteConfig.instance.isPlacementEnabled(placement) ||
        !AdManager.instance.canShowRewarded() ||
        _isShowingFullScreenAd) {
      return false;
    }
    if (!(await ensureMobileAdsReady(timeout: const Duration(seconds: 4)))) {
      return false;
    }

    var ad = _rewarded;
    if (ad == null || ad.adUnitId != adUnitId) {
      if (ad != null) {
        ad.dispose();
        _rewarded = null;
      }
      await _loadRewardedOnce();
      final loaded = await _waitForRewarded(const Duration(seconds: 5));
      if (!loaded) return false;
      ad = _rewarded;
      if (ad == null) return false;
    }
    _rewarded = null;

    final finished = Completer<bool>();
    var earned = false;
    _isShowingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        if (!finished.isCompleted) finished.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('Rewarded show failed: $error');
        if (!finished.isCompleted) finished.complete(false);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('Rewarded show exception: $e');
      _isShowingFullScreenAd = false;
      return false;
    }
    final granted = await finished.future.timeout(const Duration(minutes: 2), onTimeout: () => earned);
    if (granted) await AdManager.instance.recordRewardedShown();
    return granted;
  }
}
