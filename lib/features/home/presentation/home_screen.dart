import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocationName = 'Kolkata';
  static bool _hasShownWelcomeModal = false;

  @override
  void initState() {
    super.initState();
    if (!_hasShownWelcomeModal) {
      _hasShownWelcomeModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeModal(context);
      });
    }
  }

  void _showWelcomeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/puja-pass');
                },
                child: Image.asset(
                  'assets/images/pujapass.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: AppColors.pujaRed),
            const SizedBox(width: 8),
            Text(
              'Exit App',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to exit PUJA24?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.ivory : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'No',
              style: TextStyle(
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pujaRed,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.deepMaroon : AppColors.ivory,
        body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header Row
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await context.push<LatLng>('/map_picker');
                          if (result != null) {
                            setState(() {
                              _currentLocationName = 'Locating...';
                            });
                            try {
                              final Geocoding geocoding = Geocoding();
                              List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(result.latitude, result.longitude);
                              if (placemarks.isNotEmpty) {
                                final place = placemarks.first;
                                setState(() {
                                  _currentLocationName = place.locality ?? place.subLocality ?? place.name ?? 'Custom Location';
                                });
                              } else {
                                setState(() {
                                  _currentLocationName = 'Custom Location';
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _currentLocationName = 'Custom Location';
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.charcoal : AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _currentLocationName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      
                      // Actions
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.notifications_outlined, size: 20),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.pujaRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.antiqueGold,
                            child: Icon(Icons.person, color: AppColors.pureWhite),
                          )
                        ],
                      ),
                    ],
                  ),
                  // Perfectly Centered Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => 
                      Text('PUJA24', style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.antiqueGold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search pandal, restaurant, cafe...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.pujaRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: AppColors.pureWhite, size: 20),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Banner
              GestureDetector(
                onTap: () => context.push('/puja-pass'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/banner.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryItem(
                      icon: Icons.temple_hindu,
                      label: 'Pandals',
                      isSelected: true,
                      onTap: () => context.go('/puja'),
                    ),
                    _CategoryItem(
                      icon: Icons.restaurant,
                      label: 'Food & Cafés',
                      onTap: () => context.push('/cafe'),
                    ),
                    _CategoryItem(
                      icon: Icons.map,
                      label: 'Plan',
                      onTap: () => context.push('/plan'),
                    ),
                    _CategoryItem(
                      icon: Icons.train,
                      label: 'Metro',
                      onTap: () => context.push('/metro'),
                    ),
                    _CategoryItem(icon: Icons.local_parking, label: 'Parking'),
                    _CategoryItem(icon: Icons.wc, label: 'Toilets'),
                    _CategoryItem(icon: Icons.event, label: 'Events'),
                    _CategoryItem(icon: Icons.grid_view, label: 'More'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.antiqueGold.withOpacity(0.5), width: 1),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/ad1.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Container(width: 20, height: 1, color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joy Maa Durga!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Celebrate Puja\nLike Never Before',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        'Explore pandals, plan your route,\nfind the best food & more.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ivory.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3C77C), // Matching the gold in the image
                        foregroundColor: AppColors.deepMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Explore Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.deepMaroon,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Explore Near You
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Explore Near You', style: theme.textTheme.titleLarge),
                  Text('View All >', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.pujaRed, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/puja_detail/ekdalia_evergreen');
                      },
                      child: const _PandalCard(name: 'Ekdalia Evergreen', distance: '1.2 km', rating: '4.8'),
                    ),
                    _PandalCard(name: 'Maddox Square', distance: '2.1 km', rating: '4.7'),
                    _PandalCard(name: 'Sreebhumi Sporting Club', distance: '2.8 km', rating: '4.6'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Map Preview
              Text('Puja Around You', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey.withOpacity(0.2),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      // Gradient overlay for better button visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to full map screen
                          },
                          icon: const Icon(Icons.map, color: Colors.white),
                          label: const Text('View All on Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pujaRed,
                            elevation: 8,
                            shadowColor: AppColors.pujaRed.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickAction(icon: Icons.route, title: 'Plan Your Route', subtitle: 'Smart Route Planner'),
                    _QuickAction(icon: Icons.calendar_today, title: 'Puja Planner', subtitle: 'Plan Your Schedule'),
                    _QuickAction(icon: Icons.favorite_border, title: 'Saved Places', subtitle: 'Your Favourites'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming Event
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3C77C), width: 1), // Gold border
                  image: const DecorationImage(
                    image: AssetImage('assets/images/ad2.png'),
                    fit: BoxFit.fill, // Stretches the image so left and right art is fully visible
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 110, top: 16, bottom: 16, right: 16), // Padding to avoid the man on the left
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Event',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFF3C77C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cultural Program at Maddox Square',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 14, color: AppColors.ivory),
                              const SizedBox(width: 4),
                              Text(
                                '10 Oct, 8:00 PM Onwards',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ivory),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3C77C), // Gold button
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Padding to allow scrolling past the floating navbar
            ],
          ),
        ),
      ),
    ));
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.pureWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.pujaRed : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.pujaRed : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PandalCard extends StatelessWidget {
  final String name;
  final String distance;
  final String rating;

  const _PandalCard({
    required this.name,
    required this.distance,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: AppColors.border,
                ),
                child: const Center(child: Icon(Icons.image, color: AppColors.mutedGray)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.favorite_border, color: AppColors.pureWhite, size: 20),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(distance, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.saffron, size: 14),
                        const SizedBox(width: 4),
                        Text(rating, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.pujaRed),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
