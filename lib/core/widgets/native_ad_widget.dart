import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class NativeAdWidget extends StatefulWidget {
  final double height;
  final String? adUnitId;
  
  const NativeAdWidget({
    super.key,
    this.height = 300,
    this.adUnitId,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = AdService().createNativeAd(
      adUnitId: widget.adUnitId,
      onAdLoaded: (ad) {
        setState(() {
          _isAdLoaded = true;
          _isAdError = false;
        });
      },
      onAdFailedToLoad: (error) {
        setState(() {
          _isAdLoaded = false;
          _isAdError = true;
        });
      },
    );
    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdError) {
      return const SizedBox.shrink(); // Don't show anything if ad fails to load
    }
    
    if (!_isAdLoaded || _nativeAd == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: widget.height,
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
