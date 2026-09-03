import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/puja_list_provider.dart';
import '../domain/models/puja_detail_model.dart';
import 'widgets/pandal_card_skeleton.dart';

class PujaDirectoryScreen extends ConsumerStatefulWidget {
  const PujaDirectoryScreen({super.key});

  @override
  ConsumerState<PujaDirectoryScreen> createState() => _PujaDirectoryScreenState();
}

class _PujaDirectoryScreenState extends ConsumerState<PujaDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Forced to light theme look as requested (Beige)
    final bgColor = AppColors.ivory;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeroHeader(context, theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                  _buildQuickStats(theme),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, _selectedFilter == 'All' ? '🔥 Popular Pujas' : '🔥 ${_selectedFilter} Pujas', 'View All'),
                  const SizedBox(height: 16),
                  _buildPopularPujasRow(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, '📍 Explore by Area', 'View All'),
                  const SizedBox(height: 16),
                  _buildAreaRow(context, theme),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, '🧭 Nearby Pujas', 'Map View'),
                  const SizedBox(height: 16),
                  _buildNearbyList(theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme) {
    return SliverPersistentHeader(
      pinned: false, // Don't pin the header, let it scroll away smoothly
      delegate: _HeroHeaderDelegate(
        expandedHeight: 340.0,
        searchController: _searchController,
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Popular', 'Nearby', 'North Kolkata', 'South Kolkata', 'Salt Lake'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(filter, style: AppTypography.chip(
                  color: isSelected ? Colors.white : AppColors.deepMaroon,
                  fontSize: 13,
                )),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.pujaRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.pujaRed : AppColors.antiqueGold.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final allPujasCount = ref.watch(filteredPujasProvider('All')).valueOrNull?.length ?? 0;
    final popularPujasCount = ref.watch(filteredPujasProvider('Popular')).valueOrNull?.length ?? 0;

    final stats = [
      {'icon': Icons.account_balance, 'value': allPujasCount > 0 ? '${allPujasCount}+' : '...', 'label': 'Pandals', 'color': AppColors.deepMaroon},
      {'icon': Icons.star, 'value': popularPujasCount > 0 ? '${popularPujasCount}+' : '...', 'label': 'Popular', 'color': AppColors.saffron},
      {'icon': Icons.people, 'value': 'Live', 'label': 'Crowd', 'color': AppColors.pujaRed},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.map((s) {
          final idx = stats.indexOf(s);
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(left: idx == 0 ? 0 : 8, right: idx == 2 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (s['color'] as Color).withOpacity(0.85),
                    (s['color'] as Color),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (s['color'] as Color).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(s['icon'] as IconData, color: Colors.white.withOpacity(0.9), size: 26),
                  const SizedBox(height: 8),
                  Text(
                    s['value'] as String,
                    style: AppTypography.statNumber(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    style: AppTypography.chip(color: Colors.white.withOpacity(0.85), fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.sectionHeading(color: AppColors.deepMaroon, fontSize: 20)),
          Row(
            children: [
              Text(actionText, style: AppTypography.button(color: AppColors.pujaRed, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, color: AppColors.pujaRed, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPujasRow(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ref.watch(filteredPujasProvider(_selectedFilter)).when(
        data: (pandals) {
          if (pandals.isEmpty) {
            return const Center(child: Text('No pandals found.'));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pandals.length,
            itemBuilder: (context, index) {
              final p = pandals[index];
              return _buildPandalCard(context, p.id, p.name, p.area, p.rating, p.distance);
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) => const PandalCardSkeleton(),
        ),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildPandalCard(BuildContext context, String id, String name, String area, String rating, String distance) {
    return GestureDetector(
      onTap: () {
        context.push('/puja_detail/$id');
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.antiqueGold.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.asset(
                    'assets/images/ad2.png',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Distance badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      distance,
                      style: const TextStyle(fontSize: 11, color: AppColors.deepMaroon, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Favourite heart
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 14, color: AppColors.pujaRed),
                  ),
                ),
                // Rating badge on image bottom
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.saffron),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: AppTypography.rating(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.cardTitle(color: AppColors.deepMaroon, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        area,
                        style: AppTypography.locationMeta(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/puja_detail/$id');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pujaRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('View Details', style: AppTypography.button(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaRow(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildAreaCard(context, 'Ballygunge', '12 Popular Pujas'),
          _buildAreaCard(context, 'Salt Lake', '18 Popular Pujas'),
          _buildAreaCard(context, 'North Kolkata', '25 Traditional Pujas'),
        ],
      ),
    );
  }

  Widget _buildAreaCard(BuildContext context, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/ad1.png'),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: AppColors.antiqueGold.withOpacity(0.2), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                AppColors.deepMaroon.withOpacity(0.88),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1.2),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.antiqueGold.withOpacity(0.5)),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.antiqueGold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ref.watch(nearbyPandalsProvider).when(
        data: (pandals) {
          if (pandals.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nearby pandals found.', style: TextStyle(color: Colors.grey)),
            );
          }
          return Column(
            children: pandals.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildNearbyListTile(p),
              );
            }).toList(),
          );
        },
        loading: () => ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: PandalCardSkeleton(),
            ),
          ),
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            error.toString().contains('permission') 
              ? 'Location permission is required to view nearby pandals.'
              : 'Error fetching location: \$error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyListTile(PujaDetailModel p) {
    return GestureDetector(
      onTap: () {
        context.push('/puja_detail/${p.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.antiqueGold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.imageUrl.startsWith('http') 
                ? Image.network(
                    p.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80, height: 80, color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF2A2A2A),
                    child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 40)),
                  ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepMaroon, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pujaRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.distance,
                          style: const TextStyle(color: AppColors.pujaRed, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.area,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.saffron),
                      const SizedBox(width: 4),
                      Text(p.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      // Actions
                      const Icon(Icons.directions, size: 18, color: AppColors.pujaRed),
                      const SizedBox(width: 12),
                      const Icon(Icons.bookmark_border, size: 18, color: AppColors.antiqueGold),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final TextEditingController searchController;

  _HeroHeaderDelegate({
    required this.expandedHeight,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Progress goes from 0.0 (fully expanded) to 1.0 (fully collapsed)
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    
    // Smoothly fade out text as we scroll up
    final textOpacity = (1 - progress * 2.5).clamp(0.0, 1.0);
    
    // Parallax the image up slightly
    final imageOffset = shrinkOffset * 0.4;
    
    // The curve smoothly flattens out to a straight line when pinned to the top
    final curveRadius = 40.0 * (1 - progress).clamp(0.0, 1.0);

    return Container(
      color: AppColors.ivory,
      height: maxExtent,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none, // Allow search bar shadow to overflow smoothly
        children: [
          // Clipped Background (Image + Gradient)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 40, // Stop before the bottom edge to prevent subpixel bleed
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Parallax Image
                  Positioned(
                    top: -imageOffset,
                    left: 0,
                    right: 0,
                    height: maxExtent + 60, // extra height to prevent bottom clipping during parallax
                    child: Image.asset(
                      'assets/images/ad1.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  
                  // Cinematic dark gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                            Colors.black.withOpacity((0.5 + progress * 0.5).clamp(0.0, 1.0)),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Animated Text Content
          Positioned(
            left: 24,
            right: 24,
            bottom: 145 + (progress * 80), // Translates upward smoothly while fading
            child: Opacity(
              opacity: textOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durga Puja',
                    style: AppTypography.heroHeading(color: Colors.white, fontSize: 38),
                  ),
                  Text(
                    'KOLKATA 2026',
                    style: AppTypography.sectionHeading(color: AppColors.antiqueGold, fontSize: 18).copyWith(letterSpacing: 4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Experience the Magic',
                          style: AppTypography.chip(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Animated Transition Curve (Flattens when pinned)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(curveRadius)),
              ),
            ),
          ),
          
          // Sticky Search Bar
          Positioned(
            bottom: 12,
            left: 24,
            right: 24,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepMaroon.withOpacity(0.12 * (1 - progress)), // Shadow softens when pinned
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.charcoal),
                decoration: InputDecoration(
                  hintText: 'Search puja, pandal, area...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                  filled: false,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.search, color: AppColors.antiqueGold, size: 26),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.pujaRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: Colors.white, size: 18),
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  // Pin the search bar area when collapsed
  @override
  double get minExtent => 120.0;

  @override
  bool shouldRebuild(covariant _HeroHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight;
  }
}
