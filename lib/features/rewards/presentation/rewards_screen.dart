import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/rewards_api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/native_ad_widget.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  int _pujaPoints = 0;
  bool _isLoading = true;
  List<dynamic> _myPasses = [];
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
        _myPasses = data['passes'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    });
    
    _rewardedAd = null;
    _loadAd(); // Load next ad
  }

  Future<void> _redeemVIPPass() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final rewardsApi = ref.read(rewardsApiServiceProvider);
      final response = await rewardsApi.redeemPass();
      
      if (mounted) Navigator.pop(context); // Close loading
      
      setState(() {
        _pujaPoints = response['puja_points'];
      });
      _fetchData(); // Refresh passes list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VIP Pass redeemed successfully!')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const NativeAdWidget(height: 380),
                const SizedBox(height: 24),
                _buildWatchAdSection(),
                const SizedBox(height: 24),
                _buildRedeemSection(),
                const SizedBox(height: 24),
                _buildMyPassesSection(),
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

  Widget _buildMyPassesSection() {
    if (_myPasses.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('My Redeemed Passes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _myPasses.length,
          itemBuilder: (context, index) {
            final pass = _myPasses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () => context.push('/rewards/pass/${pass['id']}'),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.antiqueGold,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                title: Text('${pass['type'].toString().toUpperCase()} PASS', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Redeemed on: ${pass['created_at'].toString().split('T')[0]}'),
                trailing: const Icon(Icons.qr_code, color: AppColors.pujaRed),
              ),
            );
          },
        ),
      ],
    );
  }
}
