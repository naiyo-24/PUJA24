import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const MapLocationPicker({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _selectedLocation;
  String _address = 'Tap anywhere to select your location';
  bool _isLoading = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Default to Kolkata if no initial location is provided
    _selectedLocation = widget.initialLocation ?? const LatLng(22.5726, 88.3639);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _address = 'Fetching current location...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _address = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
      await _getAddressFromLatLng(latLng);
    } catch (e) {
      setState(() {
        _address = 'Failed to get current location';
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Construct a readable address
          final List<String> addressParts = [];
          if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
          if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
          if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
          if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
          
          _address = addressParts.join(', ');
          if (_address.isEmpty) _address = 'Unknown Address';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Could not find address for this location';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
        foregroundColor: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 13.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (latLng) {
              _getAddressFromLatLng(latLng);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
          ),
          
          // Current Location FAB
          Positioned(
            right: 16,
            bottom: 220, // positioned above the bottom panel
            child: FloatingActionButton(
              heroTag: 'current_location_fab',
              backgroundColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
              foregroundColor: AppColors.antiqueGold,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          
          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.pureWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Address',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.antiqueGold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoading 
                            ? const Text('Fetching address...')
                            : Text(
                                _address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.antiqueGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading || _address.isEmpty || _address.startsWith('Tap anywhere')
                            ? null
                            : () {
                                Navigator.pop(context, _address);
                              },
                        child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
