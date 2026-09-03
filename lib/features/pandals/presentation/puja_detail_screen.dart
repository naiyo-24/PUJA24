import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/puja_basic_info.dart';
import 'widgets/puja_theme_section.dart';
import 'widgets/puja_live_status.dart';
import 'widgets/puja_facilities.dart';
import 'widgets/puja_transit.dart';
import 'widgets/puja_nearby_places.dart';
import '../../../../core/theme/app_typography.dart';
import 'providers/puja_detail_provider.dart';
import 'providers/save_pandal_provider.dart';
import 'providers/plan_pandal_provider.dart';
import '../domain/models/puja_detail_model.dart';
import 'widgets/puja_detail_skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PujaDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const PujaDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PujaDetailScreen> createState() => _PujaDetailScreenState();
}

class _PujaDetailScreenState extends ConsumerState<PujaDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pujaAsyncValue = ref.watch(pujaDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
      body: pujaAsyncValue.when(
        data: (puja) => CustomScrollView(
          slivers: [
            _buildHeroGallery(context, puja),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PujaBasicInfo(puja: puja),
                  _buildDivider(),
                  PujaLiveStatus(puja: puja),
                  _buildDivider(),
                  PujaThemeSection(puja: puja),
                  _buildDivider(),
                  PujaFacilities(puja: puja),
                  _buildDivider(),
                  PujaNearbyPlaces(puja: puja),
                  _buildDivider(),
                  PujaTransit(puja: puja),
                  _buildDivider(),
                  // More sections will go here
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ],
        ),
        loading: () => const PujaDetailSkeleton(),
        error: (error, stack) => Center(
          child: Text('Error loading details: $error', style: const TextStyle(color: AppColors.pujaRed)),
        ),
      ),
      bottomNavigationBar: pujaAsyncValue.hasValue ? _buildBottomActionBar(pujaAsyncValue.value!) : null,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildHeroGallery(BuildContext context, PujaDetailModel puja) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.pujaRed,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            ref.watch(savedPandalIdsProvider).contains(puja.id)
                ? Icons.favorite
                : Icons.favorite_border,
            color: ref.watch(savedPandalIdsProvider).contains(puja.id)
                ? Colors.red
                : Colors.white,
          ),
          onPressed: () {
            ref.read(savedPandalIdsProvider.notifier).toggleSave(puja.id);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            final playStoreLink = 'https://play.google.com/store/apps/details?id=com.naiyo24.puja24&referrer=puja_id%3D${puja.id}';
            Share.share('Check out ${puja.name} at PUJA24! It has a rating of ${puja.rating}.\n\nDownload the app to see more: $playStoreLink');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            puja.imageUrl.startsWith('http') 
              ? Image.network(
                  puja.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 48)),
                  ),
                )
              : Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 48)),
                ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '1/${puja.totalPhotos} Photos',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(PujaDetailModel puja) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (puja.latitude == 0.0 && puja.longitude == 0.0) return;
                  final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${puja.latitude},${puja.longitude}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
                    }
                  }
                },
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final isPlanned = ref.read(planPandalIdsProvider).containsKey(puja.id);
                  if (isPlanned) {
                    ref.read(planPandalIdsProvider.notifier).removePlan(puja.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from Plan!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    _showDaySelectionBottomSheet(context, ref, puja.id);
                  }
                },
                icon: Icon(
                  ref.watch(planPandalIdsProvider).containsKey(puja.id) ? Icons.check : Icons.add
                ),
                label: Text(
                  ref.watch(planPandalIdsProvider).containsKey(puja.id) ? 'Planned' : 'Add to Plan'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.antiqueGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaySelectionBottomSheet(BuildContext context, WidgetRef ref, String pujaId) {
    final days = ['Sashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Day to Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...days.map((day) => ListTile(
                    title: Text(day, style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    onTap: () {
                      ref.read(planPandalIdsProvider.notifier).addPlan(pujaId, day);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to $day Plan!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
