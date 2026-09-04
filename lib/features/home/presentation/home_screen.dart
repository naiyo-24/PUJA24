import 'package:latlong2/latlong.dart' as ll;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../pandals/presentation/providers/puja_list_provider.dart';
import '../../pandals/presentation/widgets/pandal_card_skeleton.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../presentation/providers/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _currentLocationName = 'Kolkata';
  Position? _currentPosition;
  static bool _hasShownWelcomeModal = false;
  bool _isNavigating = false;
  bool _isPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
    _checkInstallReferrer();
    if (!_hasShownWelcomeModal) {
      _hasShownWelcomeModal = true;
      Future.delayed(Duration.zero, () {
        if (mounted) _showWelcomeModal(context);
      });
    }
  }

  Future<void> _checkInstallReferrer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_handled_referral') == true) return;

    try {
      final referrerDetails = await PlayInstallReferrer.installReferrer;
      final referrer = referrerDetails.installReferrer;
      if (referrer != null && referrer.contains('puja_id=')) {
        final uri = Uri.parse('?\$referrer'); // Parse as query string
        final pujaId = uri.queryParameters['puja_id'];
        if (pujaId != null && mounted) {
          await prefs.setBool('has_handled_referral', true);
          Future.delayed(Duration.zero, () {
            if (mounted) {
              context.push('/puja_detail/$pujaId');
            }
          });
        }
      }
    } catch (e) {
      // Ignore errors if API is unavailable or times out
    }
  }

  Future<void> _fetchLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentLocationName = place.locality ?? place.subLocality ?? place.name ?? 'Custom Location';
          });
        }
      }
    } catch (e) {
      // Ignore errors and keep default
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
                      Container(
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      Row(
                        children: [

                          GestureDetector(
                            onTap: () {
                              context.go('/profile');
                            },
                            child: FutureBuilder<SharedPreferences>(
                              future: SharedPreferences.getInstance(),
                              builder: (context, snapshot) {
                                String? localPath = snapshot.data?.getString('local_profile_image_path');
                                final authState = ref.watch(authProvider);
                                String? remotePath;
                                if (authState is Authenticated) {
                                  remotePath = authState.user.profileImageUrl;
                                }
                                
                                if (localPath != null && localPath.isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundImage: FileImage(File(localPath)),
                                  );
                                } else if (remotePath != null && remotePath.isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundImage: NetworkImage(remotePath),
                                  );
                                }
                                return const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.antiqueGold,
                                  child: Icon(Icons.person, color: AppColors.pureWhite),
                                );
                              },
                            ),
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

              // Dynamic Banners
              ref.watch(bannersProvider).when(
                data: (banners) {
                  final heroBanners = banners.where((b) => b.bannerType == 'HERO' || b.bannerType == 'PROMO').toList();
                  if (heroBanners.isEmpty) return const SizedBox.shrink();
                  
                  final banner = heroBanners.first;
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.antiqueGold.withOpacity(0.5), width: 1),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(banner.imageUrl),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
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
                          banner.subtitle ?? 'Special Offer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.antiqueGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banner.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (banner.actionType == 'NAVIGATE' && banner.actionPayload != null) {
                              context.push(banner.actionPayload!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3C77C),
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
                        if (heroBanners.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(heroBanners.length, (index) {
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.red : Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          )
                      ],
                    ),
                  );
                },
                loading: () => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => const SizedBox.shrink(),
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
              
              SizedBox(
                height: 220,
                child: ref.watch(popularPujasProvider).when(
                  data: (pandals) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pandals.map((pandal) {
                        return GestureDetector(
                          onTap: () {
                            context.push('/puja_detail/${pandal.id}');
                          },
                          child: _PandalCard(name: pandal.name, distance: pandal.distance, rating: pandal.rating),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(3, (index) => const PandalCardSkeleton()),
                  ),
                ),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
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
              ref.watch(bannersProvider).when(
                data: (banners) {
                  final eventBanners = banners.where((b) => b.bannerType == 'EVENT').toList();
                  if (eventBanners.isEmpty) return const SizedBox.shrink();
                  
                  final eventBanner = eventBanners.first;
                  
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3C77C), width: 1),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(eventBanner.imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eventBanner.subtitle ?? 'Upcoming Event',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFF3C77C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                eventBanner.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton(
                            onPressed: () {
                              if (eventBanner.actionType == 'NAVIGATE' && eventBanner.actionPayload != null) {
                                context.push(eventBanner.actionPayload!);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3C77C),
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
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 100), // Padding to allow scrolling past the floating navbar
            ],
          ),
        ),
      ),
    );
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
