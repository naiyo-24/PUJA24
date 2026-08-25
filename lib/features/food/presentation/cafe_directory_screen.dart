import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/food_provider.dart';
import '../domain/models/restaurant_model.dart';

class CafeDirectoryScreen extends ConsumerStatefulWidget {
  const CafeDirectoryScreen({super.key});

  @override
  ConsumerState<CafeDirectoryScreen> createState() => _CafeDirectoryScreenState();
}

class _CafeDirectoryScreenState extends ConsumerState<CafeDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;

  List<Map<String, dynamic>> get _categories => [
    {'icon': Icons.grid_view_rounded, 'label': 'All'},
    {'icon': Icons.rice_bowl, 'label': 'Bengali'},
    {'icon': Icons.local_cafe, 'label': 'Cafe'},
    {'icon': Icons.kebab_dining, 'label': 'Biryani'},
    {'icon': Icons.ramen_dining, 'label': 'Chinese'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodProvider);
    
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sticky Header / Hero Section ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            toolbarHeight: 0,
            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.6), bgColor],
                        stops: const [0.3, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.darken,
                    child: Image.asset(
                      'assets/images/cafe.png', 
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Open Now',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Text('  •  Pandal Hopping Eats', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dine & Chill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            fontFamily: 'PlayfairDisplay', 
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Find the best spots to eat near the pandals',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(130.0), 
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161210),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: goldColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search restaurants, cafes...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A1C0E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Text('🔥', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text('Hot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Pills
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedCategory == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF331700) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: goldColor.withOpacity(isSelected ? 0.8 : 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _categories[index]['icon'] as IconData,
                                    size: 16,
                                    color: isSelected ? goldColor : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _categories[index]['label'] as String,
                                    style: TextStyle(
                                      color: isSelected ? goldColor : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ── Data Sections ────────────────────────────────────────────────
          foodAsync.when(
            data: (restaurants) {
              final specials = restaurants.where((r) => r.isPujaSpecial).toList();
              // For demo purposes, we will pick the first restaurant as the Featured Today
              final featured = restaurants.isNotEmpty ? restaurants[0] : null;

              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Dining Stats Row (No Delivery!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161210),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: goldColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(Icons.restaurant, '142+', 'Dine-In', goldColor),
                            _buildDivider(),
                            _buildStatItem(Icons.nightlight_round, '24/7', 'Open Late', goldColor),
                            _buildDivider(),
                            _buildStatItem(Icons.directions_walk, '< 1km', 'Walkable', goldColor),
                            _buildDivider(),
                            _buildStatItem(Icons.currency_rupee, '₹ ₹', 'Avg Cost', goldColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Featured Today (Maha Ashtami Special) ──
                    if (featured != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: goldColor, size: 20),
                            const SizedBox(width: 8),
                            const Text('Maha Ashtami Featured', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () => context.push('/restaurant_detail/${featured.id}', extra: featured),
                          child: _buildFeaturedCard(featured, goldColor),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // ── Puja Specials Carousel ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.spa, color: goldColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Puja Specials', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('See all', style: TextStyle(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: goldColor, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 290,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: specials.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => context.push('/restaurant_detail/${specials[index].id}', extra: specials[index]),
                          child: _buildSpecialCard(specials[index], goldColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // ── All Nearby Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: goldColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Nearby Restaurants', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E160C),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: goldColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: goldColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.format_list_bulleted, color: goldColor, size: 14),
                                      const SizedBox(width: 4),
                                      Text('List', style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.map_outlined, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      const Text('Map', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // List Tiles
                    ...restaurants.map((r) => GestureDetector(
                          onTap: () => context.push('/restaurant_detail/${r.id}', extra: r),
                          child: _buildListTile(r, goldColor),
                        )).toList(),
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4A24C)))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: \$e', style: const TextStyle(color: Colors.red)))),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconButton(IconData icon, Color goldColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: goldColor.withOpacity(0.5)),
      ),
      child: Icon(icon, color: goldColor, size: 20),
    );
  }

  Widget _buildCircularIconButtonWithText(IconData icon, String text, Color goldColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: goldColor, size: 16),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: goldColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color goldColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: goldColor, size: 18),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildFeaturedCard(RestaurantModel r, Color goldColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  r.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF8B1D1D), borderRadius: BorderRadius.circular(8)),
                  child: const Text('🌟 Ashtami Special', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.black, size: 12),
                          const SizedBox(width: 4),
                          Text(r.rating, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${r.cuisine}  •  ${r.priceRange}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: goldColor, size: 16),
                          const SizedBox(width: 4),
                          Text('${r.distance} from Maddox Square', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Get Directions Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: goldColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions, color: goldColor, size: 16),
                          const SizedBox(width: 6),
                          Text('Directions', style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCard(RestaurantModel r, Color goldColor) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  r.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 12),
                      const SizedBox(width: 4),
                      Text(r.rating, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 16),
                ),
              ),
              if (r.isPujaSpecial)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF8B1D1D), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Puja Special', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text('Park Circus', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag(r.cuisine, goldColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: goldColor, size: 14),
                        const SizedBox(width: 4),
                        Text(r.distance, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('|', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                        Text(r.priceRange, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color goldColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: goldColor, fontSize: 11)),
    );
  }

  Widget _buildListTile(RestaurantModel r, Color goldColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.asset(
                  r.imageUrl,
                  width: 90,
                  height: 110,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Open', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text('Bhowanipore', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFD4A24C), size: 14),
                    const SizedBox(width: 4),
                    Text(r.rating, style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text(' (780)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.cuisine,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: goldColor, size: 14),
                        const SizedBox(width: 4),
                        Text(r.distance, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('|', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                        Text(r.priceRange, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Directions button
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: goldColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions, color: goldColor, size: 14),
                      const SizedBox(width: 6),
                      Text('Get Directions', style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
