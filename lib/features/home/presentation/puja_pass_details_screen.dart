import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/pass_provider.dart';
import '../../pandals/presentation/providers/puja_list_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                Consumer(
                  builder: (context, ref, child) {
                    final detailsState = ref.watch(packageDetailsProvider(package.id));
                    
                    return detailsState.when(
                      data: (fullPackage) {
                        if (fullPackage.includedPandalsByZone.isEmpty) {
                          return const Text('No pandals available.', style: TextStyle(color: Colors.white54));
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: fullPackage.includedPandalsByZone.entries.map((entry) {
                            return _buildRegionSection(entry.key, entry.value);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
                      error: (err, _) => Text('Failed to load details: $err', style: const TextStyle(color: Colors.red)),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Action Button
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final hasPurchased = authState is Authenticated ? authState.user.hasPujaPass : false;

                    if (hasPurchased) {
                      return Column(
                        children: [
                          const Text(
                            'You already have the VIP pass!',
                            style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: goldColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: authState is Authenticated ? authState.user.id : '',
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return SizedBox(
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
                      );
                    }
                  }
                ),
                const SizedBox(height: 64), // Ensure the button fully clears the bottom of the screen
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

  Widget _buildRegionSection(String region, List<String> pandals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(region, style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pandals.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13)),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
