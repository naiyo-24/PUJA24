import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/pass_provider.dart';

class PujaPassDetailsScreen extends ConsumerWidget {
  const PujaPassDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);
    
    final passesState = ref.watch(availablePassesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'PUJA PASS DETAILS',
          style: TextStyle(
            color: goldColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: passesState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
        data: (passes) {
          if (passes.isEmpty) {
            return const Center(child: Text('No VIP Passes available currently.', style: TextStyle(color: Colors.white)));
          }
          
          final package = passes.first;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/banner.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Details Header
                Text(
                  package.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  package.description ?? 'Purchase your pass directly from our platform. Get exclusive access to the biggest pandals in Kolkata with completely skipping the lines!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Features
                _buildFeatureRow(Icons.group, 'Exclusive ${package.personCapacity}-Person Entry', 'Bring up to ${package.personCapacity - 1} friends or family members on a single pass', goldColor),
                const SizedBox(height: 20),
                _buildFeatureRow(Icons.fast_forward, 'Zero Waiting Time', 'Walk straight in without standing in any queues', goldColor),
                const SizedBox(height: 20),
                _buildFeatureRow(Icons.temple_hindu, 'Universal Access', 'Valid at every partnered puja pandal across the city', goldColor),
                const SizedBox(height: 20),
                _buildFeatureRow(Icons.location_on, 'Physical Pass Collection', package.collectionVenue.isNotEmpty ? 'Collect from: ${package.collectionVenue}' : 'Show digital proof at HQ to collect passes', goldColor),
                
                const SizedBox(height: 32),
                const Text(
                  'Included Pandals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPandalCard('Bosepukur Sitala Mandir', 'assets/images/ad1.png'),
                      const SizedBox(width: 16),
                      _buildPandalCard('Maddox Square', 'assets/images/ad2.png'),
                      const SizedBox(width: 16),
                      _buildPandalCard('Suruchi Sangha', 'assets/images/ad1.png'),
                      const SizedBox(width: 16),
                      _buildPandalCard('Sreebhumi', 'assets/images/ad2.png'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/pass-purchase', extra: package.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buy Pass Now (₹${package.price.toStringAsFixed(0)})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, Color goldColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: goldColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: goldColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPandalCard(String name, String imagePath) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Center(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
