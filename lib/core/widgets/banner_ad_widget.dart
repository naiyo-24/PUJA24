import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  const BannerAdWidget({super.key, this.adUnitId});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdError = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdLoaded && !_isAdError && _bannerAd == null && !_isLoading) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    _isLoading = true;
    final adSize = AdSize.banner;
    
    if (!mounted) return;

    _bannerAd = AdService().createBannerAd(
      adUnitId: widget.adUnitId,
      size: adSize,
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
            _isAdError = false;
            _isLoading = false;
          });
        }
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _isAdError = true;
            _isLoading = false;
          });
        }
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdError) {
      return const SizedBox.shrink();
    }
    
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(
        height: AdSize.banner.height.toDouble(),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
