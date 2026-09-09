import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/route_service.dart';
import '../../../../core/services/places_api_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../transport/domain/metro_data.dart';
import '../../food/data/repositories/food_repository.dart';
import '../../food/domain/models/restaurant_model.dart';
import '../domain/models/puja_detail_model.dart';
import 'widgets/live_update_bottom_sheet.dart';
import 'providers/puja_list_provider.dart';
import 'puja_detail_screen.dart';

final mapNavigatingProvider = StateProvider<bool>((ref) => false);
final navigationTargetProvider = StateProvider<PujaDetailModel?>((ref) => null);

class PujaMapScreen extends ConsumerStatefulWidget {
  final String initialFilter;
  const PujaMapScreen({super.key, this.initialFilter = 'Pandals'});

  @override
  ConsumerState<PujaMapScreen> createState() => _PujaMapScreenState();
}

class _PujaMapScreenState extends ConsumerState<PujaMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  bool _isLoadingFilterData = false;
  PujaDetailModel? _selectedPuja;
  late String _selectedFilter;
  
  List<LatLng> _routePoints = [];
  bool _isNavigating = false;
  bool _isFetchingRoute = false;
  final RouteService _routeService = RouteService();
  double? _distance;
  double? _duration;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final PlacesApiService _placesService = PlacesApiService();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;
  Marker? _customSearchMarker;
  BitmapDescriptor? _profileMarkerIcon;
  List<Map<String, dynamic>> _nearbyMetroStations = [];
  List<Map<String, dynamic>> _nearbyToilets = [];
  List<RestaurantModel> _offlineFood = [];
  List<Map<String, dynamic>> _nearbyParking = [];
  List<Map<String, dynamic>> _nearbyHospitals = [];
  List<Map<String, dynamic>> _nearbyNursingHomes = [];
  List<Map<String, dynamic>> _nearbyTrainStations = [];

  List<RouteStep> _routeSteps = [];
  DateTime? _lastRouteFetchTime;

  StreamSubscription<Position>? _positionStreamSubscription;

  final List<String> _filters = ['Pandals', 'Metro', 'Pay & Use', 'Food', 'Hospitals', 'Nursing Homes', 'Stations', 'Parking'];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _startLocationTracking();
    _loadProfileMarker();
    
    // Check if we need to navigate immediately on map open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialTarget = ref.read(navigationTargetProvider);
      if (initialTarget != null) {
        setState(() {
          _selectedPuja = initialTarget;
        });
        _startNavigation(initialTarget);
        ref.read(navigationTargetProvider.notifier).state = null;
      }
    });
  }

  Future<void> _loadProfileMarker() async {
    Uint8List? imageBytes;

    // 1. Try local image first (from ProfileScreen)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('local_profile_image_path');
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Failed to load local profile image: $e');
    }

    // 2. Try auth provider profileImageUrl
    if (imageBytes == null) {
      final authState = ref.read(authProvider);
      String? profileUrl;
      
      if (authState is Authenticated) {
        profileUrl = authState.user.profileImageUrl;
      }
      
      // Fallback to FirebaseAuth
      profileUrl ??= FirebaseAuth.instance.currentUser?.photoURL;

      if (profileUrl != null && profileUrl.isNotEmpty) {
        try {
          final request = await HttpClient().getUrl(Uri.parse(profileUrl));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = <int>[];
            await for (final chunk in response) {
              bytes.addAll(chunk);
            }
            imageBytes = Uint8List.fromList(bytes);
          }
        } catch (e) {
          debugPrint('Failed to download profile image: $e');
        }
      }
    }

    Future<void> createFallbackMarker() async {
      final int size = 120;
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      final Paint borderPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

      final Paint innerPaint = Paint()..color = AppColors.pujaRed;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, innerPaint);

      final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
      String initial = 'U';
      final name = FirebaseAuth.instance.currentUser?.displayName;
      if (name != null && name.isNotEmpty) {
        initial = name[0].toUpperCase();
      }

      textPainter.text = TextSpan(
        text: initial,
        style: const TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size, size);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null && mounted) {
        setState(() {
          _profileMarkerIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
        });
      }
    }

    if (imageBytes == null) {
      await createFallbackMarker();
      return;
    }

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final int size = 120; // 120px diameter
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      // Draw white border
      final Paint borderPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

      // Clip to inner circle
      final Path clipPath = Path()..addOval(Rect.fromLTWH(8, 8, size - 16, size - 16));
      canvas.clipPath(clipPath);

      final Paint paint = Paint()..isAntiAlias = true;
      // Fit crop
      final double scaleX = (size - 16) / image.width;
      final double scaleY = (size - 16) / image.height;
      final double scale = math.max(scaleX, scaleY);
      
      final Matrix4 matrix = Matrix4.identity()
        ..translate(size / 2, size / 2)
        ..scale(scale, scale)
        ..translate(-image.width / 2, -image.height / 2);
        
      canvas.transform(matrix.storage);
      canvas.drawImage(image, Offset.zero, paint);

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size, size);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null && mounted) {
        setState(() {
          _profileMarkerIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile image for map marker: $e');
      await createFallbackMarker();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      // Get initial position first to center the map quickly
      Position initialPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
          _isLoadingLocation = false;
        });
        _recenter();
        // Fetch data for the initial filter if needed
        _onFilterSelected(_selectedFilter);
      }

      // Start listening to the stream for live tracking
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // notify every 2 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
            });
            
            // Real-time camera movement when navigating
            if (_isNavigating && _userLocation != null) {
              _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation!));
              
              // Smart Step Tracking: check if we reached the end of the current step
              if (_routeSteps.isNotEmpty) {
                double distanceToStepEnd = Geolocator.distanceBetween(
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                  _routeSteps[0].endLocation.latitude,
                  _routeSteps[0].endLocation.longitude,
                );
                if (distanceToStepEnd < 15.0 && _routeSteps.length > 1) {
                  // Reached the turn! Move to the next step.
                  _routeSteps.removeAt(0);
                }
              }
              
              // Smart Recalculation: fetch new route every 2 minutes
              if (_selectedPuja != null && _lastRouteFetchTime != null) {
                if (DateTime.now().difference(_lastRouteFetchTime!).inMinutes >= 2) {
                  _lastRouteFetchTime = DateTime.now(); // Optimistic update to prevent spam
                  _recalculateRoute();
                }
              }
            }
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _recenter() {
    if (_userLocation != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14.0));
    }
  }

  Future<void> _onFilterSelected(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _selectedPuja = null;
    });

    if (filter == 'Metro' && _userLocation != null && _nearbyMetroStations.isEmpty) {
      setState(() => _isLoadingFilterData = true);
      final stations = await _placesService.getNearbyMetroStations(
        _userLocation!.latitude,
        _userLocation!.longitude,
      );
      if (mounted) {
        setState(() {
          _nearbyMetroStations = stations;
          _isLoadingFilterData = false;
        });
      }
    } else if (filter == 'Toilets' || filter == 'Pay & Use') {
      if (_userLocation != null && _nearbyToilets.isEmpty) {
        setState(() => _isLoadingFilterData = true);
        final toilets = await _placesService.getNearbyToilets(
          _userLocation!.latitude,
          _userLocation!.longitude,
        );
        if (mounted) {
          setState(() {
            _nearbyToilets = toilets;
            _isLoadingFilterData = false;
          });
        }
      }
    } else if (filter == 'Food' && _userLocation != null && _offlineFood.isEmpty) {
      setState(() => _isLoadingFilterData = true);
      try {
        final repository = ref.read(foodRepositoryProvider);
        final foodList = await repository.getRestaurants(
          _userLocation!.latitude,
          _userLocation!.longitude,
          limit: 60,
          skip: 0
        );
        if (mounted) {
          setState(() {
            _offlineFood = foodList;
            _isLoadingFilterData = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingFilterData = false);
      }
    } else if (filter == 'Parking' && _userLocation != null && _nearbyParking.isEmpty) {
        setState(() => _isLoadingFilterData = true);
        final parkingList = await _placesService.getNearbyParking(
            _userLocation!.latitude, _userLocation!.longitude);
        if (mounted) {
          setState(() {
              _nearbyParking = parkingList;
              _isLoadingFilterData = false;
          });
        }
    } else if (filter == 'Hospitals' && _userLocation != null && _nearbyHospitals.isEmpty) {
      setState(() => _isLoadingFilterData = true);
      final list = await _placesService.getNearbyHospitals(_userLocation!.latitude, _userLocation!.longitude);
      if (mounted) setState(() { _nearbyHospitals = list; _isLoadingFilterData = false; });
    } else if (filter == 'Nursing Homes' && _userLocation != null && _nearbyNursingHomes.isEmpty) {
      setState(() => _isLoadingFilterData = true);
      final list = await _placesService.getNearbyNursingHomes(_userLocation!.latitude, _userLocation!.longitude);
      if (mounted) setState(() { _nearbyNursingHomes = list; _isLoadingFilterData = false; });
    } else if (filter == 'Stations' && _userLocation != null && _nearbyTrainStations.isEmpty) {
      setState(() => _isLoadingFilterData = true);
      final list = await _placesService.getNearbyStations(_userLocation!.latitude, _userLocation!.longitude);
      if (mounted) setState(() { _nearbyTrainStations = list; _isLoadingFilterData = false; });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _selectedPuja = null; // hide bottom sheet
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (value.isEmpty) {
      setState(() {
        _searchResults = [];
        _customSearchMarker = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final googleResults = await _placesService.getAutocomplete(value);
      
      if (mounted) {
        // Also search local pandals
        final allPujas = ref.read(filteredPujasProvider('All')).value ?? [];
        final localMatches = allPujas
            .where((p) => p.name.toLowerCase().contains(value.toLowerCase()) || p.area.toLowerCase().contains(value.toLowerCase()))
            .take(3)
            .map((p) {
              return {
                'description': '${p.name}, ${p.area}',
                'is_pandal': true,
                'pandal': p,
              };
            }).toList();

        setState(() {
          _searchResults = [...localMatches, ...googleResults];
        });
      }
    });
  }

  Future<void> _onSearchResultSelected(Map<String, dynamic> result) async {
    final description = result['description'] as String;

    setState(() {
      _searchResults = [];
      _searchQuery = description;
      _searchController.text = description;
      _selectedPuja = null;
    });

    if (result['is_pandal'] == true) {
      // It's a real Pandal!
      final puja = result['pandal'] as PujaDetailModel;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(puja.latitude, puja.longitude), 16.0));
      _showPujaDetails(puja);
      return;
    }

    final placeId = result['place_id'] as String;

    // Fetch coordinates
    final latLng = await _placesService.getPlaceDetails(placeId);
    if (latLng != null && mounted) {
      final gLatLng = LatLng(latLng.latitude, latLng.longitude);

      // 1. Move camera
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(gLatLng, 16.0));
      
      // 2. Add custom marker
      setState(() {
        _customSearchMarker = Marker(
          markerId: MarkerId(placeId),
          position: gLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: description),
        );
      });

      // 3. Show a dummy PujaDetailModel so we can navigate to it
      final placePuja = PujaDetailModel(
        id: placeId,
        name: description.split(',').first,
        type: 'custom',
        area: description,
        rating: '0',
        distance: '',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        imageUrl: '',
        theme2026: '',
        crowdStatus: 'Normal',
        queueTimeMins: 0,
        historySummary: 'GOOGLE_PLACE',
        idolArtist: '',
        pandalDesigner: '',
        totalPhotos: 0,
        amenities: [],
        nearestMetro: '',
        nearestBusStop: '',
        nearestCafe: '',
        nearestParking: '',
        nearestHospital: '',
        payAndUseToilet: '',
        rainStatus: 'Clear',
      );
      _showPujaDetails(placePuja);
    }
  }

  void _shareLocation() {
    if (_userLocation != null) {
      final lat = _userLocation!.latitude;
      final lng = _userLocation!.longitude;
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      Share.share('Hey! I am currently exploring Puja Pandals here: $url');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching your location, please wait...')),
      );
    }
  }

  Future<void> _showPujaDetails(PujaDetailModel puja) async {
    setState(() {
      _selectedPuja = puja;
      _distance = null; // Reset while loading
      _duration = null;
    });
    
    if (_userLocation != null) {
      final routeData = await _routeService.getRouteData(
        _userLocation!,
        LatLng(puja.latitude, puja.longitude),
      );
      if (routeData != null && mounted) {
        setState(() {
          _distance = routeData.distanceMeters;
          _duration = routeData.durationSeconds;
          _routeSteps = routeData.steps;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for cross-screen navigation requests
    ref.listen<PujaDetailModel?>(navigationTargetProvider, (previous, next) {
      if (next != null) {
        Future.microtask(() {
          setState(() {
            _selectedPuja = next;
          });
          _startNavigation(next);
          ref.read(navigationTargetProvider.notifier).state = null;
        });
      }
    });

    final pujasAsync = ref.watch(filteredPujasProvider('All'));

    // Default center to Kolkata if user location is not available
    final center = _userLocation ?? const LatLng(22.5726, 88.3639);

    return Scaffold(
      body: Stack(
        children: [
          // The Map
          pujasAsync.when(
            data: (pujas) {
              var filteredPujas = pujas.where((p) {
                bool matchesSearch = _searchQuery.isEmpty || 
                                     p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     p.area.toLowerCase().contains(_searchQuery.toLowerCase());
                
                bool matchesFilter = true;
                if (_selectedFilter == 'famous') {
                  matchesFilter = ((double.tryParse(p.rating) ?? 0.0) >= 4.5); // Fallback since isFamous isn't on the model
                } else if (_selectedFilter == 'nearby' && _userLocation != null) {
                  double dist = Geolocator.distanceBetween(
                    _userLocation!.latitude, _userLocation!.longitude,
                    p.latitude, p.longitude,
                  );
                  matchesFilter = dist <= 5000; // within 5km
                }
                
                return matchesSearch && matchesFilter;
              }).toList();

              final Set<Marker> googleMarkers = {};
              
              if (_selectedFilter == 'Pandals') {
                googleMarkers.addAll(filteredPujas.map((puja) {
                  var lat = puja.latitude;
                  var lng = puja.longitude;
                  if (lat == 0.0 || lng == 0.0) {
                    final random = math.Random(puja.id.hashCode);
                    lat = 22.5726 + (random.nextDouble() - 0.5) * 0.05;
                    lng = 88.3639 + (random.nextDouble() - 0.5) * 0.05;
                  }
                  return Marker(
                    markerId: MarkerId(puja.id),
                    position: LatLng(lat, lng),
                    onTap: () => _showPujaDetails(puja),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  );
                }));
              }
              
              if (_selectedFilter == 'Metro') {
                for (var station in _nearbyMetroStations) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId(station['place_id']),
                    position: LatLng(station['lat'], station['lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(title: station['name']),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: station['place_id'],
                        name: station['name'],
                        type: 'metro',
                        area: 'Metro Station',
                        rating: '0',
                        distance: '',
                        latitude: station['lat'],
                        longitude: station['lng'],
                        imageUrl: '',
                        theme2026: '',
                        crowdStatus: 'Normal',
                        queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE',
                        idolArtist: '',
                        pandalDesigner: '',
                        totalPhotos: 0,
                        amenities: [],
                        nearestMetro: '',
                        nearestBusStop: '',
                        nearestCafe: '',
                        nearestParking: '',
                        nearestHospital: '',
                        payAndUseToilet: '',
                        rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }

              if (_selectedFilter == 'Pay & Use' || _selectedFilter == 'Toilets') {
                for (var toilet in _nearbyToilets) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId(toilet['place_id']),
                    position: LatLng(toilet['lat'], toilet['lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    infoWindow: InfoWindow(title: toilet['name']),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: toilet['place_id'],
                        name: toilet['name'],
                        type: 'toilet',
                        area: 'Public Toilet',
                        rating: '0',
                        distance: '',
                        latitude: toilet['lat'],
                        longitude: toilet['lng'],
                        imageUrl: '',
                        theme2026: '',
                        crowdStatus: 'Normal',
                        queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE',
                        idolArtist: '',
                        pandalDesigner: '',
                        totalPhotos: 0,
                        amenities: [],
                        nearestMetro: '',
                        nearestBusStop: '',
                        nearestCafe: '',
                        nearestParking: '',
                        nearestHospital: '',
                        payAndUseToilet: '',
                        rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }

              if (_selectedFilter == 'Parking') {
                for (var spot in _nearbyParking) {
                  googleMarkers.add(
                    Marker(
                      markerId: MarkerId(spot['place_id']),
                      position: LatLng(spot['lat'], spot['lng']),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue for Parking
                      infoWindow: InfoWindow(title: spot['name']),
                      onTap: () {
                        final placePuja = PujaDetailModel(
                          id: spot['place_id'],
                          name: spot['name'],
                          type: 'parking',
                          area: 'Parking Facility',
                          rating: '0',
                          distance: '',
                          latitude: spot['lat'],
                          longitude: spot['lng'],
                          imageUrl: '',
                          theme2026: '',
                          crowdStatus: 'Normal',
                          queueTimeMins: 0,
                          historySummary: 'GOOGLE_PLACE',
                          idolArtist: '',
                          pandalDesigner: '',
                          totalPhotos: 0,
                          amenities: [],
                          nearestMetro: '',
                          nearestBusStop: '',
                          nearestCafe: '',
                          nearestParking: '',
                          nearestHospital: '',
                          payAndUseToilet: '',
                          rainStatus: 'Clear',
                        );
                        _showPujaDetails(placePuja);
                      },
                    ),
                  );
                }
              }

              if (_selectedFilter == 'Food') {
                for (var food in _offlineFood) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId('food_${food.id}'),
                    position: LatLng(food.latitude, food.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(title: food.name, snippet: food.cuisine),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: 'food_\${food.id}',
                        name: food.name,
                        type: 'restaurant',
                        area: food.cuisine,
                        rating: food.rating,
                        distance: '',
                        latitude: food.latitude,
                        longitude: food.longitude,
                        imageUrl: '',
                        theme2026: '',
                        crowdStatus: 'Normal',
                        queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE',
                        idolArtist: '',
                        pandalDesigner: '',
                        totalPhotos: 0,
                        amenities: [],
                        nearestMetro: '',
                        nearestBusStop: '',
                        nearestCafe: '',
                        nearestParking: '',
                        nearestHospital: '',
                        payAndUseToilet: '',
                        rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }
              if (_selectedFilter == 'Hospitals') {
                for (var hospital in _nearbyHospitals) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId(hospital['place_id']),
                    position: LatLng(hospital['lat'], hospital['lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: hospital['name']),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: hospital['place_id'],
                        name: hospital['name'],
                        type: 'hospital',
                        area: 'Hospital',
                        rating: '0',
                        distance: '',
                        latitude: hospital['lat'],
                        longitude: hospital['lng'],
                        imageUrl: '', theme2026: '', crowdStatus: 'Normal', queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE', idolArtist: '', pandalDesigner: '',
                        totalPhotos: 0, amenities: [], nearestMetro: '', nearestBusStop: '',
                        nearestCafe: '', nearestParking: '', nearestHospital: '',
                        payAndUseToilet: '', rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }

              if (_selectedFilter == 'Nursing Homes') {
                for (var nh in _nearbyNursingHomes) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId(nh['place_id']),
                    position: LatLng(nh['lat'], nh['lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                    infoWindow: InfoWindow(title: nh['name']),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: nh['place_id'],
                        name: nh['name'],
                        type: 'nursing_home',
                        area: 'Nursing Home',
                        rating: '0',
                        distance: '',
                        latitude: nh['lat'],
                        longitude: nh['lng'],
                        imageUrl: '', theme2026: '', crowdStatus: 'Normal', queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE', idolArtist: '', pandalDesigner: '',
                        totalPhotos: 0, amenities: [], nearestMetro: '', nearestBusStop: '',
                        nearestCafe: '', nearestParking: '', nearestHospital: '',
                        payAndUseToilet: '', rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }

              if (_selectedFilter == 'Stations') {
                for (var station in _nearbyTrainStations) {
                  googleMarkers.add(Marker(
                    markerId: MarkerId(station['place_id']),
                    position: LatLng(station['lat'], station['lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(title: station['name']),
                    onTap: () {
                      final placePuja = PujaDetailModel(
                        id: station['place_id'],
                        name: station['name'],
                        type: 'station',
                        area: 'Railway Station',
                        rating: '0',
                        distance: '',
                        latitude: station['lat'],
                        longitude: station['lng'],
                        imageUrl: '', theme2026: '', crowdStatus: 'Normal', queueTimeMins: 0,
                        historySummary: 'GOOGLE_PLACE', idolArtist: '', pandalDesigner: '',
                        totalPhotos: 0, amenities: [], nearestMetro: '', nearestBusStop: '',
                        nearestCafe: '', nearestParking: '', nearestHospital: '',
                        payAndUseToilet: '', rainStatus: 'Clear',
                      );
                      _showPujaDetails(placePuja);
                    },
                  ));
                }
              }
              if (_customSearchMarker != null) {
                googleMarkers.add(_customSearchMarker!);
              }
              
              if (_isNavigating && _selectedPuja != null) {
                googleMarkers.add(
                  Marker(
                    markerId: const MarkerId('navigation_destination'),
                    position: LatLng(_selectedPuja!.latitude, _selectedPuja!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: _selectedPuja!.name, snippet: 'Destination'),
                  ),
                );
              }
              
              if (_userLocation != null) {
                googleMarkers.add(
                  Marker(
                    markerId: const MarkerId('user_location'),
                    position: _userLocation!,
                    icon: _profileMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                    zIndex: 999, // Ensure it's above other markers
                  ),
                );
              }

              final Set<Polyline> googlePolylines = {};
              if (_isNavigating && _routePoints.isNotEmpty) {
                 googlePolylines.add(Polyline(
                   polylineId: const PolylineId('route'),
                   points: _routePoints,
                   color: Colors.blueAccent,
                   width: 6,
                 ));
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: 13.0),
                onMapCreated: (controller) => _mapController = controller,
                markers: googleMarkers,
                polylines: googlePolylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(bottom: 90), // Offset for custom bottom nav bar
                onTap: _onMapTapped,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          // Global loading overlay for API calls
          if (_isLoadingFilterData || _isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.pujaRed),
                    SizedBox(height: 16),
                    Text(
                      'Fetching places around you...',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepMaroon),
                    ),
                  ],
                ),
              ),
            ),

          // Top Controls (Navigation Instructions)
          if (_isNavigating) _buildNavigationInstructionsCard(),

          // Top Controls (Search & Filters)
          if (!_isNavigating)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search pandals, metro, toilets',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: false,
                      ),
                      onTap: () {
                        if (_selectedPuja != null) {
                          setState(() {
                            _selectedPuja = null;
                          });
                        }
                      },
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  
                  // Search Results Dropdown
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            final isPandal = result['is_pandal'] == true;
                            
                            return ListTile(
                              leading: Icon(
                                isPandal ? Icons.festival : Icons.location_on, 
                                color: isPandal ? AppColors.saffron : AppColors.pujaRed
                              ),
                              title: Text(
                                result['description'] ?? '', 
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: isPandal ? FontWeight.bold : FontWeight.normal
                                )
                              ),
                              onTap: () => _onSearchResultSelected(result),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Filters (Hide when searching)
                  if (_searchResults.isEmpty)
                    SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              filter.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _onFilterSelected(filter);
                              } else {
                                _onFilterSelected('Pandals');
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.pujaRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.pujaRed : Colors.grey.shade300,
                              ),
                            ),
                            showCheckmark: false,
                            avatar: Icon(
                              _getFilterIcon(filter),
                              color: isSelected ? Colors.white : AppColors.pujaRed,
                              size: 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls (Recenter)
          if (!_isNavigating)
            Positioned(
              bottom: _selectedPuja != null ? 220 : 140, // Increased bottom padding to clear the custom bottom navbar
              right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'share_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _shareLocation,
                  child: const Icon(Icons.ios_share, color: AppColors.charcoal, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location, color: AppColors.charcoal),
                ),
              ],
            ),
          ),

          // Bottom Sheet for Selected Puja
          if (_selectedPuja != null && !_isNavigating)
            _buildPandalDetailsCard(context, _selectedPuja!),
            
          if (_isNavigating && _selectedPuja != null) ...[
            _buildNavigationBottomCard(context, _selectedPuja!),
          ],
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Pandals':
        return Icons.temple_hindu;
      case 'Metro':
        return Icons.directions_subway;
      case 'Toilets':
        return Icons.wc;
      default:
        return Icons.place;
    }
  }

  Future<void> _startNavigation(PujaDetailModel destination) async {
    setState(() {
      _isFetchingRoute = true;
    });

    if (_userLocation == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
        _userLocation = LatLng(pos.latitude, pos.longitude);
      } catch (e) {
        if (mounted) setState(() => _isFetchingRoute = false);
        return;
      }
    }
    
    if (_userLocation == null) {
      if (mounted) setState(() => _isFetchingRoute = false);
      return;
    }
    
    final routeData = await _routeService.getRouteData(
      LatLng(_userLocation!.latitude, _userLocation!.longitude),
      LatLng(destination.latitude, destination.longitude),
    );
    
    setState(() {
      if (routeData != null) {
        _routePoints = routeData.points;
        _routeSteps = routeData.steps;
        _distance = routeData.distanceMeters;
        _duration = routeData.durationSeconds;
      }
      _isNavigating = true;
      _isFetchingRoute = false;
      _lastRouteFetchTime = DateTime.now();
    });
    ref.read(mapNavigatingProvider.notifier).state = true;

    // Zoom into user's location to start tracking
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 17.5));
  }

  Future<void> _recalculateRoute() async {
    if (_userLocation == null || _selectedPuja == null) return;
    
    final routeData = await _routeService.getRouteData(
      _userLocation!,
      LatLng(_selectedPuja!.latitude, _selectedPuja!.longitude),
    );
    
    if (routeData != null && mounted) {
      setState(() {
        _routePoints = routeData.points;
        _distance = routeData.distanceMeters;
        _duration = routeData.durationSeconds;
        _routeSteps = routeData.steps;
      });
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedPuja = null;
    });

    try {
      final nearestPlace = await _placesService.getNearestPlace(position.latitude, position.longitude);
      if (nearestPlace != null) {
        String poiType = 'custom';
        final nameLower = (nearestPlace['name'] as String).toLowerCase();
        if (nameLower.contains('hospital') || nameLower.contains('clinic') || nameLower.contains('multispeciality')) {
          poiType = 'hospital';
        } else if (nameLower.contains('nursing home')) {
          poiType = 'nursing_home';
        } else if (nameLower.contains('station')) {
          poiType = 'station';
        } else if (nameLower.contains('restaurant') || nameLower.contains('cafe')) {
          poiType = 'restaurant';
        }

        final placePuja = PujaDetailModel(
          id: nearestPlace['place_id'],
          name: nearestPlace['name'],
          type: poiType,
          area: 'Map Location',
          rating: '0',
          distance: '',
          latitude: nearestPlace['lat'],
          longitude: nearestPlace['lng'],
          imageUrl: '', theme2026: '', crowdStatus: 'Normal', queueTimeMins: 0,
          historySummary: 'GOOGLE_PLACE', idolArtist: '', pandalDesigner: '',
          totalPhotos: 0, amenities: [], nearestMetro: '', nearestBusStop: '',
          nearestCafe: '', nearestParking: '', nearestHospital: '',
          payAndUseToilet: '', rainStatus: 'Clear',
        );
        _showPujaDetails(placePuja);
      }
    } catch (e) {
      debugPrint('Failed to resolve tapped map location: $e');
    }
  }

  void _endNavigation() {
    setState(() {
      _isNavigating = false;
      _routePoints = [];
      _routeSteps = [];
    });
    ref.read(mapNavigatingProvider.notifier).state = false;
  }

  IconData _getManeuverIcon(String maneuver) {
    if (maneuver.contains('right')) {
      if (maneuver.contains('sharp')) return Icons.turn_sharp_right;
      if (maneuver.contains('slight')) return Icons.turn_slight_right;
      if (maneuver.contains('uturn')) return Icons.u_turn_right;
      return Icons.turn_right;
    } else if (maneuver.contains('left')) {
      if (maneuver.contains('sharp')) return Icons.turn_sharp_left;
      if (maneuver.contains('slight')) return Icons.turn_slight_left;
      if (maneuver.contains('uturn')) return Icons.u_turn_left;
      return Icons.turn_left;
    }
    return Icons.straight;
  }

  String _getDynamicDistanceToStepEnd() {
    if (_routeSteps.isEmpty || _userLocation == null) return '';
    final currentStep = _routeSteps[0];
    double dist = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );
    if (dist > 1000) {
      return '${(dist / 1000).toStringAsFixed(1)} km';
    } else {
      // Snap to nearest 5 meters to prevent flickering numbers
      int roundedDist = (dist / 5).round() * 5;
      if (roundedDist < 5) roundedDist = 0;
      return '$roundedDist m';
    }
  }

  Widget _buildNavigationInstructionsCard() {
    if (_routeSteps.isEmpty) return const SizedBox.shrink();

    final currentStep = _routeSteps[0];
    final nextStep = _routeSteps.length > 1 ? _routeSteps[1] : null;
    final dynamicDistance = _getDynamicDistanceToStepEnd();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Instruction
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D5D56),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Icon(_getManeuverIcon(currentStep.maneuver), color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dynamicDistance.isNotEmpty ? dynamicDistance : currentStep.distanceText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(currentStep.instruction, style: const TextStyle(color: Colors.white, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPandalDetailsCard(BuildContext context, PujaDetailModel puja) {
    String walkTime = '--';
    String bikeTime = '--';
    String carTime = '--';
    String distanceText = puja.distance; // Fallback to backend distance if location unavailable
    bool isWithin500m = false;

    if (_userLocation != null && puja.latitude != 0.0 && puja.longitude != 0.0) {
      // 1. Calculate straight-line distance
      double straightLineMeters = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        puja.latitude,
        puja.longitude,
      );
      
      isWithin500m = straightLineMeters <= 500.0;
      
      // 2. Use real OSRM distance if available, else fallback to a standard 1.3x city block multiplier
      double roadDistanceMeters = _distance ?? (straightLineMeters * 1.3);
      
      distanceText = '${(roadDistanceMeters / 1000).toStringAsFixed(1)} km';
      
      // 3. Calibrated urban speeds (based on real Google Maps routing for Kolkata)
      // Walk: ~5.7 km/h = 95 meters/minute
      int wMins = (roadDistanceMeters / 95).ceil();
      // Bike/Motorcycle: ~17 km/h = 285 meters/minute
      int bMins = (roadDistanceMeters / 285).ceil();
      // Car: use real Google Maps duration if available, else estimate
      int cMins = _duration != null ? (_duration! / 60).ceil() : (roadDistanceMeters / 265).ceil();

      walkTime = _formatEta(wMins);
      bikeTime = _formatEta(bMins);
      carTime = _formatEta(cMins);
    }
    
    final bool isRealPandal = puja.historySummary != 'GOOGLE_PLACE';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 100, // keep it above the bottom nav bar
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepMaroon.withOpacity(0.08),
              blurRadius: 32,
              spreadRadius: 8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.pujaRed, AppColors.deepMaroon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.pujaRed.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(
                    puja.type == 'hospital' || puja.type == 'nursing_home' ? Icons.local_hospital :
                    puja.type == 'station' || puja.type == 'metro' ? Icons.directions_subway :
                    puja.type == 'restaurant' ? Icons.restaurant :
                    puja.type == 'toilet' ? Icons.wc :
                    puja.type == 'parking' ? Icons.local_parking :
                    puja.type == 'custom' ? Icons.place :
                    Icons.temple_hindu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puja.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.charcoal, letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${puja.area}  •  $distanceText',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPuja = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ETA Pills
            if (walkTime != '--') ...[
              Row(
                children: [
                  _buildEtaPill(Icons.directions_walk, walkTime),
                  const SizedBox(width: 8),
                  _buildEtaPill(Icons.pedal_bike, bikeTime),
                  const SizedBox(width: 8),
                  _buildEtaPill(Icons.directions_car, carTime),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            if (isRealPandal) ...[
              // Status Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.water_drop,
                      gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                      title: 'Rain Status',
                      value: puja.rainStatus,
                      subtitle: 'Updated just now',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.groups,
                      gradient: const LinearGradient(colors: [AppColors.pujaRed, AppColors.deepMaroon]),
                      title: 'Crowd Level',
                      value: puja.crowdStatus,
                      subtitle: 'Live reports',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Visited Recently Banner
              GestureDetector(
                onTap: isWithin500m ? () {
                  LiveUpdateBottomSheet.show(context, puja, onUpdate: (rain, crowd) {
                    setState(() {
                      _selectedPuja = PujaDetailModel(
                        id: puja.id, name: puja.name, type: puja.type, area: puja.area,
                        rating: puja.rating, distance: puja.distance, latitude: puja.latitude,
                        longitude: puja.longitude, historySummary: puja.historySummary,
                        theme2026: puja.theme2026, idolArtist: puja.idolArtist,
                        pandalDesigner: puja.pandalDesigner, imageUrl: puja.imageUrl,
                        totalPhotos: puja.totalPhotos, crowdStatus: crowd,
                        queueTimeMins: puja.queueTimeMins, amenities: puja.amenities,
                        nearestMetro: puja.nearestMetro, nearestBusStop: puja.nearestBusStop,
                        nearestCafe: puja.nearestCafe, nearestParking: puja.nearestParking,
                        nearestHospital: puja.nearestHospital, payAndUseToilet: puja.payAndUseToilet,
                        rainStatus: rain,
                      );
                    });
                  });
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isWithin500m ? AppColors.saffron.withOpacity(0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isWithin500m ? AppColors.saffron.withOpacity(0.3) : Colors.grey.shade200, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isWithin500m ? AppColors.saffron.withOpacity(0.2) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isWithin500m ? Icons.my_location : Icons.lock_outline, color: isWithin500m ? AppColors.deepMaroon : Colors.grey.shade500, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isWithin500m ? 'You are at the Pandal!' : 'Live Updates Locked', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.charcoal)),
                            const SizedBox(height: 2),
                            Text(isWithin500m ? 'Tap here to update live status.' : 'Only available within 500m.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isWithin500m)
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.saffron),
                    ],
                  ),
                ),
              ),
            ],
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1.5, color: Color(0xFFF2F2F2)),
            ),
            
            // Metro Row
            if (puja.nearestMetro.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.directions_subway, color: Colors.blue, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        children: [
                          TextSpan(text: puja.nearestMetro, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Bus Row
            if (puja.nearestBusStop.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.blue, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        children: [
                          const TextSpan(text: 'Board at '),
                          TextSpan(text: puja.nearestBusStop, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Navigation Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(puja),
                    icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                    label: const Text('Navigate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pujaRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppColors.pujaRed.withOpacity(0.4),
                    ),
                  ),
                ),
                if (isRealPandal) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PujaDetailScreen(id: puja.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, color: AppColors.deepMaroon, size: 20),
                      label: const Text('Details', style: TextStyle(color: AppColors.deepMaroon, fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ivory,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.antiqueGold, width: 1.5),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaPill(IconData icon, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required IconData icon, required LinearGradient gradient, required String title, required String value, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBusPill(String number) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatEta(int mins) {
    if (mins < 60) return '$mins min';
    int hrs = mins ~/ 60;
    int remainingMins = mins % 60;
    if (remainingMins == 0) return '$hrs hr';
    return '${hrs}h ${remainingMins}m';
  }

  Widget _buildNavigationBottomCard(BuildContext context, PujaDetailModel puja) {
    String walkTime = '--';
    String distanceText = '';
    
    if (_userLocation != null && puja.latitude != 0.0 && puja.longitude != 0.0) {
      double roadDistanceMeters = _distance ?? 0.0;
      
      // If we don't have the exact distance yet (should be rare in navigation mode), calculate a rough one
      if (roadDistanceMeters == 0.0) {
        double straightLineMeters = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          puja.latitude,
          puja.longitude,
        );
        roadDistanceMeters = straightLineMeters * 1.3;
      }
      
      distanceText = '${(roadDistanceMeters / 1000).toStringAsFixed(1)} km';
      int mins = _duration != null ? (_duration! / 60).ceil() : (roadDistanceMeters / 95).ceil();
      walkTime = _formatEta(mins);
    }

    return Positioned(
      bottom: 40, // Anchored near the bottom since navbar is hidden
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(walkTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Icon(Icons.directions_car, size: 20, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$distanceText · to ${puja.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            GestureDetector(
              onTap: _endNavigation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.pujaRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('End', style: TextStyle(color: AppColors.pujaRed, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
