import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../pandals/domain/models/puja_detail_model.dart';
import '../../pandals/presentation/puja_map_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pandals/presentation/providers/save_pandal_provider.dart';
import '../domain/models/restaurant_model.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            backgroundColor: bgColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    ref.read(savedPandalIdsProvider.notifier).toggleSave(restaurant.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ref.watch(savedPandalIdsProvider).contains(restaurant.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: ref.watch(savedPandalIdsProvider).contains(restaurant.id)
                          ? Colors.red
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Share.share('Check out ${restaurant.name} at ${restaurant.area} on PUJA24! \\nRating: ${restaurant.rating}⭐');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  restaurant.imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: restaurant.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Image.asset('assets/images/cafe.png', fit: BoxFit.cover),
                      )
                    : Image.asset(
                        restaurant.imageUrl.isNotEmpty ? restaurant.imageUrl : 'assets/images/cafe.png',
                        fit: BoxFit.cover,
                      ),
                  // Gradient for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          bgColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      if (restaurant.isPujaSpecial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1D1D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('🌟 Puja Special', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text('Open Now', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(restaurant.rating, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.black, size: 16),
                              ],
                            ),
                            Text('${restaurant.totalReviews ?? 0} Ratings', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    '${restaurant.cuisine}  •  ${restaurant.priceRange}',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Info Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: goldColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(Icons.location_on, restaurant.distance, 'Distance', goldColor),
                        _buildDivider(),
                        _buildInfoColumn(Icons.schedule, restaurant.timings ?? '24/7', 'Timings', goldColor),
                        _buildDivider(),
                        _buildInfoColumn(Icons.table_restaurant, 'Available', 'Dine-In', goldColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final mapTarget = PujaDetailModel(
                              id: restaurant.id,
                              name: restaurant.name,
                              area: restaurant.area,
                              rating: restaurant.rating,
                              distance: restaurant.distance,
                              latitude: restaurant.latitude,
                              longitude: restaurant.longitude,
                              historySummary: '',
                              theme2026: '',
                              idolArtist: '',
                              pandalDesigner: '',
                              imageUrl: restaurant.imageUrl,
                              totalPhotos: 0,
                              crowdStatus: 'Moderate',
                              queueTimeMins: 0,
                              amenities: [],
                              nearestMetro: '',
                              nearestBusStop: '',
                              nearestCafe: '',
                              nearestHospital: '',
                              payAndUseToilet: '',
                              rainStatus: 'Clear',
                            );
                            ref.read(navigationTargetProvider.notifier).state = mapTarget;
                            context.go('/map');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.directions, size: 20),
                          label: const Text('Get Directions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (restaurant.contactPhone != null && restaurant.contactPhone!.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('tel:\${restaurant.contactPhone}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: goldColor,
                              side: BorderSide(color: goldColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.call, size: 20),
                            label: const Text('Call Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // About Section
                  if (restaurant.about != null && restaurant.about!.isNotEmpty) ...[
                    const Text('About', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      restaurant.about!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // Top Menu Items
                  if (restaurant.topDishes != null && restaurant.topDishes!.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Top Dishes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Full Menu', style: TextStyle(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Menu List
                    ...restaurant.topDishes!.map((dish) => 
                      _buildMenuItem(
                        dish['name'] ?? 'Dish', 
                        dish['description'] ?? '', 
                        "₹\${dish['price'] ?? 0}", 
                        goldColor
                      )
                    ).toList(),
                    
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String value, String label, Color goldColor) {
    return Column(
      children: [
        Icon(icon, color: goldColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildMenuItem(String name, String desc, String price, Color goldColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(price, style: TextStyle(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
