import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/metro_data.dart';

class MetroLiveMapScreen extends StatefulWidget {
  const MetroLiveMapScreen({super.key});

  @override
  State<MetroLiveMapScreen> createState() => _MetroLiveMapScreenState();
}

class _MetroLiveMapScreenState extends State<MetroLiveMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  // Center of Kolkata
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(22.5726, 88.3639),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    _loadAllMetroStations();
  }

  void _loadAllMetroStations() {
    for (var line in MetroData.lines) {
      for (var station in line.stations) {
        _markers.add(
          Marker(
            markerId: MarkerId('${line.id}_${station.name}'),
            position: LatLng(station.lat, station.lng),
            infoWindow: InfoWindow(
              title: station.name,
              snippet: station.isInterchange ? 'Interchange Station' : '${line.name} Station',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(line.color)),
          ),
        );
      }
    }
    setState(() {});
  }

  double _getHueFromColor(Color color) {
    if (color == Colors.blue) return BitmapDescriptor.hueAzure;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? AppColors.charcoal.withOpacity(0.8) : AppColors.pureWhite.withOpacity(0.8),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.pureWhite : AppColors.charcoal, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
