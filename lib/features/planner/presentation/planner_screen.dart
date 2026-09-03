import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../pandals/domain/models/puja_detail_model.dart';
import 'providers/planner_provider.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final List<String> _days = ['Sashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami'];

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final plansAsync = ref.watch(plannerProvider);

    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220.0,
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
                      'assets/images/plan.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  const Positioned(
                    bottom: 90, // Positioned above the 70px bottom tabs
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Itinerary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Plan your pandal hopping flawlessly.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70.0),
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final isSelected = day == selectedDay;
                      return GestureDetector(
                        onTap: () => ref.read(selectedDayProvider.notifier).state = day,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF331700) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: goldColor.withOpacity(isSelected ? 0.8 : 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: isSelected ? goldColor : Colors.white,
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

          // ── Timeline or Empty State ──────────────────────────────────────
          plansAsync.when(
            data: (plansMap) {
              final dayPlan = plansMap[selectedDay] ?? [];
              if (dayPlan.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: goldColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No plans yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Start adding pandals and cafes to your itinerary.', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
                      final item = dayPlan[index];
                      final isLast = index == dayPlan.length - 1;
                      return _buildTimelineItem(item, isLast, goldColor);
                    },
                    childCount: dayPlan.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: goldColor)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error loading plans', style: TextStyle(color: Colors.red))),
            ),
          ),
            
          // Add some padding at bottom
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(PujaDetailModel item, bool isLast, Color goldColor) {
    final isRestaurant = false; // Add restaurant logic if you add cafes later
    final icon = Icons.temple_hindu;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline Line & Dot ──
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: goldColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 108, // 100 for card + 24 for padding - 16 for dot
                color: goldColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // ── Content Card ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: GestureDetector(
              onTap: () => context.push('/puja_detail/${item.id}'),
              child: Container(
                height: 100, // Fixed height avoids IntrinsicHeight
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: goldColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: item.imageUrl.startsWith('http')
                          ? Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 80,
                                height: 100,
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(Icons.image, color: Colors.white54),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 100,
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.image, color: Colors.white54),
                            ),
                    ),
                    // Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, color: goldColor, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Anytime',
                                      style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.more_vert, color: Colors.white54, size: 16),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
