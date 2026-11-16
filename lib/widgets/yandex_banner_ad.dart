import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// A reusable Yandex Mobile Ads sticky banner widget.
///
/// Dynamically sizes itself based on the logical screen width,
/// loads the ad asynchronously, and collapses gracefully using
/// [SizedBox.shrink] while loading or upon failure.
class YandexBannerAd extends StatefulWidget {
  /// The Yandex Ad Unit ID for the banner ad.
  final String adUnitId;

  /// Optional callback invoked when the ad finishes loading successfully.
  final VoidCallback? onAdLoaded;

  /// Optional callback invoked when the ad fails to load.
  final void Function(dynamic error)? onAdFailedToLoad;

  const YandexBannerAd({
    super.key,
    this.adUnitId = 'R-M-20435489-1',
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  @override
  State<YandexBannerAd> createState() => _YandexBannerAdState();
}

class _YandexBannerAdState extends State<YandexBannerAd> {
  BannerAd? _bannerAd;
  StreamSubscription<BannerAdLoadState>? _loadSubscription;
  bool _isLoaded = false;
  double? _lastWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidth = MediaQuery.sizeOf(context).width;
    if (_bannerAd == null || _lastWidth != currentWidth) {
      _lastWidth = currentWidth;
      _initAndLoadAd(currentWidth);
    }
  }

  void _initAndLoadAd(double screenWidth) {
    _loadSubscription?.cancel();
    _bannerAd?.destroy();
    _isLoaded = false;

    final width = screenWidth.round();
    if (width <= 0) return;

    try {
      final bannerAd = BannerAd(
        adSize: BannerAdSize.sticky(width: width),
      );

      _bannerAd = bannerAd;

      _loadSubscription = bannerAd.loadStateStream.listen((state) {
        if (!mounted) return;
        if (state is BannerAdLoadStateLoaded) {
          setState(() {
            _isLoaded = true;
          });
          widget.onAdLoaded?.call();
        } else if (state is BannerAdLoadStateError) {
          setState(() {
            _isLoaded = false;
          });
          widget.onAdFailedToLoad?.call(state.error);
        }
      });

      bannerAd.load(AdRequest(adUnitId: widget.adUnitId));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('YandexBannerAd initialization error: $error');
      }
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
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return AdWidget(bannerAd: _bannerAd!);
  }
}
