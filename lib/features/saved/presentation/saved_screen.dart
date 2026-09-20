import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../food/domain/models/restaurant_model.dart';
import '../../pandals/domain/models/puja_detail_model.dart';
import '../../pandals/presentation/providers/save_pandal_provider.dart';
import 'providers/saved_provider.dart';
import '../../../core/widgets/native_ad_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final List<String> _filters = ['All', 'Pandals', 'Cafes'];

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(savedFilterProvider);
    final itemsAsync = ref.watch(savedItemsProvider);

    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.go('/explore'),
            ),
            titleSpacing: 0,
            toolbarHeight: 80.0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Saved Places',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'PlayfairDisplay',
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Your favorite pandals and restaurants.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            floating: true,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == activeFilter;
                      return GestureDetector(
                        onTap: () => ref.read(savedFilterProvider.notifier).state = filter,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? goldColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: goldColor.withOpacity(isSelected ? 1.0 : 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),



          // ── Saved Items List or Empty State ──────────────────────────────
          itemsAsync.when(
            data: (allItems) {
              // Apply filter locally
              List<PujaDetailModel> items = allItems;
              if (activeFilter == 'Pandals') {
                items = allItems.where((item) => item.type.toLowerCase() == 'pandal').toList();
              } else if (activeFilter == 'Cafes') {
                items = allItems.where((item) => item.type.toLowerCase() == 'restaurant' || item.type.toLowerCase() == 'cafe').toList();
              }

              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: goldColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No saved $activeFilter yet', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Tap the heart icon to save places here.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/explore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.search, size: 20),
                          label: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _buildSavedCard(item, goldColor, ref);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: goldColor)),
            ),
            error: (err, stack) => const SliverFillRemaining(
              child: Center(child: Text('Error loading saved items', style: TextStyle(color: Colors.red))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: BannerAdWidget(adUnitId: Platform.isAndroid ? dotenv.env['ADMOB_BANNER_SAVEDPLACES_ANDROID'] : dotenv.env['ADMOB_BANNER_SAVEDPLACES_IOS']),
            ),
          ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSavedCard(PujaDetailModel item, Color goldColor, WidgetRef ref) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 36),
      ),
      onDismissed: (direction) {
        ref.read(savedPandalIdsProvider.notifier).toggleSave(item.id);
      },
      child: GestureDetector(
        onTap: () {
          if (item.type.toLowerCase() == 'restaurant' || item.type.toLowerCase() == 'cafe') {
            final restaurant = RestaurantModel(
              id: item.id,
              name: item.name,
              cuisine: 'Food & Cafe',
              rating: item.rating,
              distance: item.distance,
              priceRange: '₹₹',
              imageUrl: item.imageUrl,
              isPujaSpecial: false,
              latitude: item.latitude,
              longitude: item.longitude,
              area: item.area,
              contactPhone: '',
              about: '',
              topDishes: [],
              totalReviews: 0,
              timings: '24/7',
            );
            context.push('/restaurant_detail/${item.id}', extra: restaurant);
          } else {
            context.push('/puja_detail/${item.id}');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: goldColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: goldColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image or Vibrant Placeholder
                item.imageUrl.startsWith('http')
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),

                // Cinematic Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Content Overlay
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Top Row (Heart Icon)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(savedPandalIdsProvider.notifier).toggleSave(item.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Title & Area
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: goldColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.area,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Bottom Row: Stats
                      Row(
                        children: [
                          _buildStatPill(Icons.directions_walk, '${item.distance ?? 0.0} km', goldColor, Colors.white.withOpacity(0.1)),
                          if (double.tryParse(item.rating) != null && double.parse(item.rating) > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatPill(Icons.star, item.rating, Colors.amber, Colors.amber.withOpacity(0.15)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Vibrant Purple/Deep Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.image, color: Colors.white.withOpacity(0.2), size: 60),
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        // Subtle blur for glassmorphism
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
