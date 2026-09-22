import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/rewards_api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/native_ad_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/providers/pass_provider.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  int _pujaPoints = 0;
  bool _isLoading = true;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadAd();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final rewardsApi = ref.read(rewardsApiServiceProvider);
      final data = await rewardsApi.getMyPasses();
      setState(() {
        _pujaPoints = data['puja_points'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.deepMaroon,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  void _loadAd() {
    setState(() => _isAdLoading = true);
    AdService().loadRewardedAd(
      onAdLoaded: (ad) {
        setState(() {
          _rewardedAd = ad;
          _isAdLoading = false;
        });
      },
      onAdFailedToLoad: (error) {
        setState(() => _isAdLoading = false);
      },
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;
    
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
      try {
        final rewardsApi = ref.read(rewardsApiServiceProvider);
        final response = await rewardsApi.watchAd();
        setState(() {
          _pujaPoints = response['puja_points'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You earned 2 Puja Points!')));
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.deepMaroon,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    });
    
    _rewardedAd = null;
    _loadAd(); // Load next ad
  }

  Future<void> _redeemVIPPass() async {
    try {
      final rewardsApi = ref.read(rewardsApiServiceProvider);
      final response = await rewardsApi.redeemPass();
      
      final user = ref.read(authProvider);
      final userName = user is Authenticated ? user.user.fullName : 'User';
      
      await ref.read(authProvider.notifier).setPujaPassPurchased();
      
      if (mounted) {
        setState(() {
          _pujaPoints = 0; // Reset points after redemption
        });
        _showPassDetailsSheet(context, AppColors.antiqueGold, response['pass_id'] ?? 'test_pass_id', userName);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFF141414),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.pujaRed, size: 48),
                  const SizedBox(height: 16),
                  const Text('Oops!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    errorMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pujaRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasPass = authState is Authenticated ? authState.user.hasPujaPass : false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puja Rewards'),
        backgroundColor: AppColors.pujaRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.pujaRed))
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.pujaRed,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPointsCard(),
                const SizedBox(height: 24),
                NativeAdWidget(height: 380, adUnitId: Platform.isAndroid ? dotenv.env['ADMOB_NATIVE_PUJAREWARDS_ANDROID'] : dotenv.env['ADMOB_NATIVE_PUJAREWARDS_IOS']),
                const SizedBox(height: 24),
                if (hasPass) ...[
                  _buildAlreadyGotPassSection(authState is Authenticated ? authState.user.id : ''),
                ] else ...[
                  _buildWatchAdSection(),
                  const SizedBox(height: 24),
                  _buildRedeemSection(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildAlreadyGotPassSection(String voucherCode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Pass Already Activated', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'You already have a VIP Pass! No need to earn points or watch ads anymore.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.antiqueGold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final authState = ref.read(authProvider);
                  final userName = authState is Authenticated ? authState.user.fullName : 'User';
                  _showPassDetailsSheet(context, AppColors.antiqueGold, voucherCode, userName);
                },
                child: const Text('View Digital Pass', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.deepMaroon,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Puja Points',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$_pujaPoints',
            style: const TextStyle(color: AppColors.antiqueGold, fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.play_circle_fill, color: AppColors.pujaRed, size: 28),
                SizedBox(width: 12),
                Text('Earn Points', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Watch a short video ad to earn 2 Puja Points.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _rewardedAd != null 
                    ? _showRewardedAd 
                    : (!_isAdLoading ? _loadAd : null),
                child: _isAdLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_rewardedAd != null ? 'Watch Ad (+2 Points)' : 'Ad Failed (Tap to Retry)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemSection() {
    final canRedeem = _pujaPoints >= 1000;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.card_membership, color: AppColors.antiqueGold, size: 28),
                SizedBox(width: 12),
                Text('Redeem VIP Pass', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Collect 1000 Puja Points to get a free VIP Pass for exclusive pandal access!',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? AppColors.antiqueGold : Colors.grey.shade300,
                  foregroundColor: canRedeem ? Colors.black87 : Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canRedeem ? _redeemVIPPass : null,
                child: Text(
                  canRedeem ? 'Redeem Now' : 'Need ${1000 - _pujaPoints} more points',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassDetailsSheet(BuildContext context, Color goldColor, String voucherCode, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            const Text('VIP DIGITAL PASS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Scan this QR code at the collection counter', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 40),
            
            // White QR Code Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: voucherCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Pass Info Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildDetailRow('Pass Holder', userName, goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Admit', '4 Persons', goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Pass ID', voucherCode.substring(0, 8).toUpperCase(), goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Status', 'NOT REDEEMED', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
