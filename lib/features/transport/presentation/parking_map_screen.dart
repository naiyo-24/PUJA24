import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/places_api_service.dart';
import '../../../core/theme/app_colors.dart';

class ParkingMapScreen extends ConsumerStatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  ConsumerState<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends ConsumerState<ParkingMapScreen> {
  GoogleMapController? _mapController;
  final PlacesApiService _placesApiService = PlacesApiService();
  
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
      
      _fetchParking(position.latitude, position.longitude);

    } catch (e) {
      debugPrint("Error getting location: \$e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchParking(double lat, double lng) async {
    try {
      final parkingLots = await _placesApiService.getNearbyParking(lat, lng);
      final newMarkers = <Marker>{};

      for (var p in parkingLots) {
        newMarkers.add(Marker(
          markerId: MarkerId(p['place_id']),
          position: LatLng(p['lat'], p['lng']),
          infoWindow: InfoWindow(
            title: p['name'],
            snippet: 'Parking',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      }

      // Add user location marker
      newMarkers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
        
        if (parkingLots.isNotEmpty) {
          double minLat = lat;
          double maxLat = lat;
          double minLng = lng;
          double maxLng = lng;

          for (var p in parkingLots) {
            if (p['lat'] < minLat) minLat = p['lat'];
            if (p['lat'] > maxLat) maxLat = p['lat'];
            if (p['lng'] < minLng) minLng = p['lng'];
            if (p['lng'] > maxLng) maxLng = p['lng'];
          }

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              50.0, // padding
            ),
          );
        } else {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(lat, lng),
                zoom: 14,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching parking: \$e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Find Parking',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.charcoal : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pujaRed))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(22.5726, 88.3639),
                zoom: 13,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),
    );
  }
}
