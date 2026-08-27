import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesApiService {
  static const String _apiKey = 'AIzaSyBmc97dQWHVQCx6obwgI3Quw2_BCJTeAIg';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final Dio _dio = Dio();

  // 1. Autocomplete Search
  Future<List<Map<String, dynamic>>> getAutocomplete(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:in', // Restrict to India
          'location': '22.5726,88.3639', // Bias towards Kolkata
          'radius': '50000',
        },
      );

      if (response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => {
          'description': p['description'],
          'place_id': p['place_id'],
        }).toList();
      }
      return [];
    } catch (e) {
      print('Places API Autocomplete Error: $e');
      return [];
    }
  }

  // 2. Get Coordinates for a Place ID
  Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry',
        },
      );

      if (response.data['status'] == 'OK') {
        final location = response.data['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
      return null;
    } catch (e) {
      print('Places API Details Error: $e');
      return null;
    }
  }

  // 3. Find Nearby Metro Stations
  Future<List<Map<String, dynamic>>> getNearbyMetroStations(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': '3000', // 3km radius
          'type': 'subway_station', // Specifically look for metro/subway
          'keyword': 'metro',
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((r) {
          final loc = r['geometry']['location'];
          return {
            'name': r['name'],
            'lat': loc['lat'],
            'lng': loc['lng'],
            'place_id': r['place_id'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Places API Nearby Search Error: $e');
      return [];
    }
  }
}
