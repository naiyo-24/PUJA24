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
                _buildRegionSection('West Kolkata & Behala', [
                  'Barisha Club', 'S B Park Sarbojanin', 'Behala Nutan Dal', 'Behala Friends', 'Behala Club'
                ]),
                _buildRegionSection('North Kolkata', [
                  'Kidderpore 25 Pally Club', 'Dum Dum Park Bharat Chakra', 'Dum Dum Park Tarun Dal', 'Dum Dum Park Tarun Sangha', 'Ahiritola Sarbojanin', 'Ahiritola Yubak Brinda', 'Jagat Mukherjee Park', 'Chorebagan Sarbojanin', 'Chaltabagan Sarbajanin', 'Sikdar Bagan', 'Tala Barowari', 'Mitali Sangha Kankurgachi', 'Prafulla Kanan Paschim Adhibasi Brinda', 'Aswininagar Bandhu Mahal', 'Hatibagan Sarbojanin', 'Hatibagan Nabin Pally', 'Kashi Bose Lane', 'Nalin Sarkar Street'
                ]),
                _buildRegionSection('Central Kolkata', [
                  'Beliaghata 33 Palli', 'Santosh Mitra Square'
                ]),
                _buildRegionSection('Salt Lake & Rajarhat', [
                  'New Town Sarbojanin', 'AK Block Salt Lake'
                ]),
                _buildRegionSection('South Kolkata', [
                  'Ajeya Sanghati', 'Vivekananda Park Athletic Club', '41 Pally Club', 'Badam Tala Ashar Sangha', 'Pratapaditya Road – Tricon Park', 'Alipur Sarbojanin', 'Bakul Bagan Sarbojanin', 'Chakraberia Sarbojanin', 'Abasar', 'Netaji Jatiyo Seva Dal', 'Kendua Shanti Sangha', 'Purbachal Shakti Sangha', 'Santoshpur Lake Pally', 'Santoshpur Trikon Park', '95 Pally', 'Hindusthan Park Sarbojanin', 'Rajdanga Naba Uday Sangha', 'Bosepukur Sitala Mandir'
                ]),
                
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
