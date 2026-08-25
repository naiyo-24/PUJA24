import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/puja_basic_info.dart';
import 'widgets/puja_theme_section.dart';
import 'widgets/puja_live_status.dart';
import 'widgets/puja_facilities.dart';
import 'widgets/puja_transit.dart';
import 'widgets/puja_nearby_places.dart';
import 'providers/puja_detail_provider.dart';
import '../domain/models/puja_detail_model.dart';

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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pujaRed)),
        error: (error, stack) => Center(
          child: Text('Error loading details: $error', style: const TextStyle(color: AppColors.pujaRed)),
        ),
      ),
      bottomNavigationBar: pujaAsyncValue.hasValue ? _buildBottomActionBar() : null,
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
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              puja.imageUrl,
              fit: BoxFit.cover,
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

  Widget _buildBottomActionBar() {
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
                onPressed: () {},
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
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add to Plan'),
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
}
