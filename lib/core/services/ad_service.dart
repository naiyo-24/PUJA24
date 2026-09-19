import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712467313';
    }
    return '';
  }

  BannerAd createBannerAd({required VoidCallback onAdLoaded, required void Function(LoadAdError) onAdFailedToLoad}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    );
  }
  
  void loadRewardedAd({
    required void Function(RewardedAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('RewardedAd failed to show: $error');
              ad.dispose();
            },
          );
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          onAdFailedToLoad(error);
        },
      ),
    );
  }

  NativeAd createNativeAd({required void Function(NativeAd ad) onAdLoaded, required void Function(LoadAdError) onAdFailedToLoad}) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
      ),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onAdLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    );
  }
}
