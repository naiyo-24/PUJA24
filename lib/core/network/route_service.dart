import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_config.dart';

class RouteStep {
  final String instruction;
  final String distanceText;
  final String maneuver;
  final LatLng endLocation;

  RouteStep({
    required this.instruction, 
    required this.distanceText, 
    required this.maneuver,
    required this.endLocation,
  });
}

class RouteData {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  RouteData({
    required this.points, 
    required this.distanceMeters, 
    required this.durationSeconds,
    this.steps = const [],
  });
}

class RouteService {
  /// Fetches a route using the Google Maps Directions API.
  Future<RouteData?> getRouteData(LatLng start, LatLng destination) async {
    final origin = '${start.latitude},${start.longitude}';
    final dest = '${destination.latitude},${destination.longitude}';
    final apiKey = ApiConfig.googleMapsApiKey;
    
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          final distance = (leg['distance']['value'] as num).toDouble();
          final duration = (leg['duration']['value'] as num).toDouble();
          final encodedPolyline = route['overview_polyline']['points'] as String;
          
          final points = _decodePolyline(encodedPolyline);
          
          final rawSteps = leg['steps'] as List?;
          List<RouteStep> parsedSteps = [];
          if (rawSteps != null) {
            for (var s in rawSteps) {
              final instructionHtml = s['html_instructions'] as String? ?? '';
              // Strip HTML tags using regex
              final instruction = instructionHtml.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
              final distText = s['distance']?['text'] as String? ?? '';
              final maneuver = s['maneuver'] as String? ?? 'straight';
              
              final endLoc = s['end_location'];
              LatLng endLatLng = const LatLng(0, 0);
              if (endLoc != null) {
                endLatLng = LatLng((endLoc['lat'] as num).toDouble(), (endLoc['lng'] as num).toDouble());
              }
              
              parsedSteps.add(RouteStep(
                instruction: instruction.trim(),
                distanceText: distText,
                maneuver: maneuver,
                endLocation: endLatLng,
              ));
            }
          }
          
          return RouteData(
            points: points, 
            distanceMeters: distance, 
            durationSeconds: duration,
            steps: parsedSteps,
          );
        } else {
          print('Google Maps API Error: ${data['status']} - ${data['error_message']}');
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route from Google Maps: $e');
      return null;
    }
  }

  /// Decodes Google's encoded polyline string into a list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
