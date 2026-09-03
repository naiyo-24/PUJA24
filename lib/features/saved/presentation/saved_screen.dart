import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../pandals/domain/models/puja_detail_model.dart';
import 'providers/saved_provider.dart';

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
            expandedHeight: 180.0,
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
                    child: Container(color: const Color(0xFF1A0F05)), // Subtle dark background
                  ),
                  const Positioned(
                    bottom: 74,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Places',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your favorite pandals and restaurants.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              if (activeFilter == 'Cafes') {
                items = []; // We don't have cafe data yet
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
                      return _buildSavedCard(item, goldColor);
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
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSavedCard(PujaDetailModel item, Color goldColor) {
    return GestureDetector(
      onTap: () => context.push('/puja_detail/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: goldColor.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      width: 100,
                      height: 120, // Fixed height
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 120,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.image, color: Colors.white54),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 120,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
            ),
            // Details
            Expanded(
              child: SizedBox(
                height: 120, // Match image height
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.area,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                        ],
                      ),
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: goldColor, size: 14),
                              const SizedBox(width: 4),
                              Text('${item.distance} km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          if (double.tryParse(item.rating) != null && double.parse(item.rating) > 0) ...[
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(item.rating, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
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
