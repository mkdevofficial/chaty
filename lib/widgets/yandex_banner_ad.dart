import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// A reusable Yandex Mobile Ads sticky banner widget.
///
/// Dynamically sizes itself based on the logical screen width,
/// loads the ad asynchronously, and collapses gracefully using
/// [SizedBox.shrink] if the ad fails to load or initialization fails.
class YandexBannerAd extends StatefulWidget {
  /// The primary Yandex Ad Unit ID for the banner ad.
  final String adUnitId;

  /// Whether to fallback to Yandex's official test ad unit ('demo-banner-yandex')
  /// if the primary ad unit fails to load (e.g. no fill or pending moderation).
  final bool fallbackToDemoOnFailure;

  /// Optional callback invoked when the ad finishes loading successfully.
  final VoidCallback? onAdLoaded;

  /// Optional callback invoked when the ad fails to load.
  final void Function(dynamic error)? onAdFailedToLoad;

  const YandexBannerAd({
    super.key,
    this.adUnitId = 'R-M-20435489-1',
    this.fallbackToDemoOnFailure = true,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  @override
  State<YandexBannerAd> createState() => _YandexBannerAdState();
}

class _YandexBannerAdState extends State<YandexBannerAd> {
  BannerAd? _bannerAd;
  StreamSubscription<BannerAdLoadState>? _loadSubscription;
  bool _hasError = false;
  double? _lastWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidth = MediaQuery.sizeOf(context).width;
    if (_bannerAd == null || _lastWidth != currentWidth) {
      _lastWidth = currentWidth;
      _initAndLoadAd(currentWidth, isFallback: false);
    }
  }

  void _initAndLoadAd(double screenWidth, {required bool isFallback}) {
    _loadSubscription?.cancel();
    _bannerAd?.destroy();

    final width = screenWidth.round();
    if (width <= 0) return;

    try {
      final bannerAd = BannerAd(
        adSize: BannerAdSize.sticky(width: width),
      );

      final targetAdUnitId = isFallback ? 'demo-banner-yandex' : widget.adUnitId;

      setState(() {
        _bannerAd = bannerAd;
        _hasError = false;
      });

      _loadSubscription = bannerAd.loadStateStream.listen((state) {
        if (!mounted) return;
        if (state is BannerAdLoadStateLoaded) {
          if (kDebugMode) {
            debugPrint(
              'YandexBannerAd loaded successfully: unit=$targetAdUnitId, size=${state.width}x${state.height}',
            );
          }
          setState(() {
            _hasError = false;
          });
          widget.onAdLoaded?.call();
        } else if (state is BannerAdLoadStateError) {
          if (kDebugMode) {
            debugPrint(
              'YandexBannerAd load error: unit=$targetAdUnitId, error=${state.error.description} (code: ${state.error.code})',
            );
          }

          // Fallback to official demo banner if primary unit has NO_FILL or pending moderation
          if (!isFallback && widget.fallbackToDemoOnFailure) {
            if (kDebugMode) {
              debugPrint('YandexBannerAd: falling back to demo-banner-yandex...');
            }
            _initAndLoadAd(screenWidth, isFallback: true);
            return;
          }

          setState(() {
            _hasError = true;
          });
          widget.onAdFailedToLoad?.call(state.error);
        }
      });

      bannerAd.load(AdRequest(adUnitId: targetAdUnitId));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('YandexBannerAd initialization exception: $error');
      }
      setState(() {
        _hasError = true;
      });
      widget.onAdFailedToLoad?.call(error);
    }
  }

  @override
  void dispose() {
    _loadSubscription?.cancel();
    _bannerAd?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the ad encountered an unrecoverable error or initialization failed,
    // take zero space.
    if (_bannerAd == null || _hasError) {
      return const SizedBox.shrink();
    }

    // AdWidget handles dynamic resizing on ad load and manages the platform view.
    // Mounting AdWidget immediately is REQUIRED so that Flutter creates the
    // native PlatformView and invokes onPlatformViewCreated to trigger the ad load.
    return AdWidget(bannerAd: _bannerAd!);
  }
}
