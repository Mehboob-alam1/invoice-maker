import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import 'ad_config.dart';
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
  bool _awaitingMediaReturn = false;
  DateTime _suppressForegroundUntil = DateTime.fromMillisecondsSinceEpoch(0);

  RewardedAd? _rewarded;
  bool _rewardedLoading = false;

  /// Bumped after [MobileAds.initialize] so on-screen slots can request.
  final ValueNotifier<int> sdkReady = ValueNotifier<int>(0);

  bool get isSdkReady => sdkReady.value > 0;

  Future<void> initialize() async {
    if (!AdConfig.isSupported) return;
    await AdRemoteConfig.instance.load();
    await AdManager.instance.loadCounters();
    sdkReady.value++;
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

  /// Starts rewarded and interstitial loads in the background.
  ///
  /// The bottom banner is requested when its slot is on screen so the
  /// collapsible overlay can open over the page. This does not wait for a fill.
  Future<void> waitForStartupPreloads({
    required SubscriptionTier tier,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (timeout < Duration.zero) return;
    if (InvoiceProvider.adsHeldStatic || tier == SubscriptionTier.pro) return;
    if (tier.showInterstitialAds) preloadInterstitial();
    preloadRewarded();
  }

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
          Future<void>.delayed(const Duration(seconds: 20), () {
            if (_interstitial == null && !_interstitialLoading) preloadInterstitial();
          });
        },
      ),
    );

    return completer.future;
  }

  /// Fills the interstitial cache. Showing never waits on a new request.
  void preloadInterstitial() {
    if (!AdConfig.isSupported) return;
    if (_interstitial != null || _interstitialLoading || _interstitialLoadFuture != null) return;
    if (InvoiceProvider.adsHeldStatic || !_placementWanted(_interstitialPlacements)) return;
    _interstitialLoadFuture = _loadInterstitialOnce().whenComplete(() {
      _interstitialLoadFuture = null;
    });
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
      if (config.isPlacementEnabled(placement)) return true;
    }
    return false;
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
        AdManager.instance.recordInterstitialShown();
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

  Future<bool> ensureAppOpenLoaded({Duration timeout = const Duration(seconds: 14)}) async {
    if (!AdConfig.isSupported) return false;
    if (_appOpenAd != null) return true;

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

  void preloadAppOpen() {
    // On demand: the next show loads a fresh app-open ad.
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

    final loaded = await ensureAppOpenLoaded(timeout: const Duration(seconds: 8));
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

  Future<void> showAppOpenIfAvailable({SubscriptionTier tier = SubscriptionTier.free}) async {
    final decision = AdManager.instance.decideAppOpen(
      placement: AdPlacement.appOpenForeground,
      tier: tier,
    );
    if (!AdConfig.isSupported || _isShowingFullScreenAd || !decision.allow) return;
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
        AdManager.instance.recordAppOpenShown();
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

  /// Fills the rewarded cache. The reward button only shows an ad that is already loaded.
  void preloadRewarded() {
    if (!AdConfig.isSupported || _rewarded != null || _rewardedLoading) return;
    if (InvoiceProvider.adsHeldStatic || !_placementWanted(_rewardedPlacements)) return;
    if (!AdManager.instance.canShowRewarded()) return;

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
          Future<void>.delayed(const Duration(seconds: 20), () {
            if (_rewarded == null && !_rewardedLoading) preloadRewarded();
          });
        },
      ),
    );
  }

  /// Shows the preloaded rewarded ad. True only when the user earns the reward.
  ///
  /// A missing ad returns immediately and keeps loading in the background.
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

    final ad = _rewarded;
    if (ad == null || ad.adUnitId != adUnitId) {
      if (ad != null) {
        ad.dispose();
        _rewarded = null;
      }
      preloadRewarded();
      return false;
    }
    _rewarded = null;

    final finished = Completer<bool>();
    var earned = false;
    _isShowingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        preloadRewarded();
        if (!finished.isCompleted) finished.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('Rewarded show failed: $error');
        preloadRewarded();
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
      preloadRewarded();
      return false;
    }
    final granted = await finished.future.timeout(const Duration(minutes: 2), onTimeout: () => earned);
    if (granted) await AdManager.instance.recordRewardedShown();
    return granted;
  }
}
