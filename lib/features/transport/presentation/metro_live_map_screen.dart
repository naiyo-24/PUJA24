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
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Center of Kolkata
  final LatLng _initialCenter = const LatLng(22.5726, 88.3639);

  @override
  void initState() {
    super.initState();
    _loadAllMetroStations();
  }

  void _loadAllMetroStations() {
    for (var line in MetroData.lines) {
      List<LatLng> linePoints = [];
      for (var station in line.stations) {
        final point = LatLng(station.lat, station.lng);
        linePoints.add(point);
        
        _markers.add(
          Marker(
            markerId: MarkerId(station.name),
            position: point,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${station.name} (${station.isInterchange ? 'Interchange' : line.name})'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Simplified for now
          ),
        );
      }
      
      if (linePoints.length > 1) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId(line.name),
            points: linePoints,
            color: line.color.withOpacity(0.7),
            width: 4,
          ),
        );
      }
    }
    setState(() {});
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
        initialCameraPosition: CameraPosition(
          target: _initialCenter,
          zoom: 11.5,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

