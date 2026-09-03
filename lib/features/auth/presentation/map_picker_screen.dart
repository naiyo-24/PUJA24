import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:durga_puja_explorer/core/theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  
  // Default to Kolkata
  LatLng _currentCenter = const LatLng(22.5726, 88.3639);
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      } 

      Position? position = await Geolocator.getLastKnownPosition();
      
      try {
        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        position ??= Position(
          longitude: 88.3639,
          latitude: 22.5726,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = latLng;
        _isLoadingLocation = false;
      });
      
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
      
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Location', style: TextStyle(color: AppColors.charcoal, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.charcoal, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentCenter, zoom: 16.0),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() {
                _currentCenter = position.target;
              });
            },
          ),
          
          // Center Marker Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Adjust to make the tip of the pin sit on the center
              child: Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.pujaRed,
              ),
            ),
          ),
          
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pujaRed)),
                      SizedBox(width: 12),
                      Text('Locating...', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            
          if (!_isLoadingLocation && _locationError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _locationError = null;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pujaRed.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoadingLocation
                      ? null
                      : () {
                          context.pop(_currentCenter);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pujaRed,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 110,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'recenter_btn',
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.my_location, color: AppColors.charcoal),
              onPressed: () {
                _determinePosition();
              },
            ),
          )
        ],
      ),
    );
  }
}
