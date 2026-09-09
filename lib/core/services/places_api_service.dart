import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesApiService {
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
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
    List<Map<String, dynamic>> allStations = [];
    String? nextPageToken;

    try {
      do {
        final queryParams = <String, dynamic>{
          'key': _apiKey,
        };

        if (nextPageToken == null) {
          queryParams['location'] = '$lat,$lng';
          queryParams['radius'] = '50000'; // 50km radius
          queryParams['type'] = 'subway_station';
          queryParams['keyword'] = 'metro';
        } else {
          queryParams['pagetoken'] = nextPageToken;
          // Places API requires a short delay before next_page_token becomes valid
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await _dio.get(
          '$_baseUrl/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          allStations.addAll(results.map((r) {
            final loc = r['geometry']['location'];
            return {
              'name': r['name'],
              'lat': loc['lat'],
              'lng': loc['lng'],
              'place_id': r['place_id'],
            };
          }).toList());
          
          nextPageToken = response.data['next_page_token'];
        } else if (response.data['status'] == 'INVALID_REQUEST' && nextPageToken != null) {
           // Token might not be ready yet, try once more
           await Future.delayed(const Duration(seconds: 2));
           final retryResponse = await _dio.get('$_baseUrl/nearbysearch/json', queryParameters: queryParams);
           if (retryResponse.data['status'] == 'OK') {
             final results = retryResponse.data['results'] as List;
             allStations.addAll(results.map((r) {
               final loc = r['geometry']['location'];
               return {
                 'name': r['name'],
                 'lat': loc['lat'],
                 'lng': loc['lng'],
                 'place_id': r['place_id'],
               };
             }).toList());
             nextPageToken = retryResponse.data['next_page_token'];
           } else {
             nextPageToken = null;
           }
        } else {
          nextPageToken = null;
        }
      } while (nextPageToken != null && allStations.length < 60);

      return allStations;
    } catch (e) {
      print('Places API Nearby Search Error: $e');
      return allStations;
    }
  }

  // 4. Find Nearby Parking
  Future<List<Map<String, dynamic>>> getNearbyParking(double lat, double lng) async {
    List<Map<String, dynamic>> allParking = [];
    String? nextPageToken;

    try {
      do {
        final queryParams = <String, dynamic>{
          'key': _apiKey,
        };

        if (nextPageToken == null) {
          queryParams['location'] = '$lat,$lng';
          queryParams['radius'] = '15000'; // 15km radius
          queryParams['keyword'] = 'parking';
        } else {
          queryParams['pagetoken'] = nextPageToken;
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await _dio.get(
          '$_baseUrl/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          allParking.addAll(results.map((r) {
            final loc = r['geometry']['location'];
            return {
              'name': r['name'],
              'lat': loc['lat'],
              'lng': loc['lng'],
              'place_id': r['place_id'],
            };
          }).toList());
          
          nextPageToken = response.data['next_page_token'];
        } else if (response.data['status'] == 'INVALID_REQUEST' && nextPageToken != null) {
           await Future.delayed(const Duration(seconds: 2));
           final retryResponse = await _dio.get('$_baseUrl/nearbysearch/json', queryParameters: queryParams);
           if (retryResponse.data['status'] == 'OK') {
             final results = retryResponse.data['results'] as List;
             allParking.addAll(results.map((r) {
               final loc = r['geometry']['location'];
               return {
                 'name': r['name'],
                 'lat': loc['lat'],
                 'lng': loc['lng'],
                 'place_id': r['place_id'],
               };
             }).toList());
             nextPageToken = retryResponse.data['next_page_token'];
           } else {
             nextPageToken = null;
           }
        } else {
          nextPageToken = null;
        }
      } while (nextPageToken != null && allParking.length < 60);

      return allParking;
    } catch (e) {
      print('Places API Nearby Search Error: \$e');
      return allParking;
    }
  }

  // 5. Find Nearby Toilets
  Future<List<Map<String, dynamic>>> getNearbyToilets(double lat, double lng) async {
    List<Map<String, dynamic>> allToilets = [];
    String? nextPageToken;

    try {
      do {
        final queryParams = <String, dynamic>{
          'key': _apiKey,
        };

        if (nextPageToken == null) {
          queryParams['location'] = '$lat,$lng';
          queryParams['radius'] = '50000'; // 50km radius
          queryParams['keyword'] = 'public toilet';
        } else {
          queryParams['pagetoken'] = nextPageToken;
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await _dio.get(
          '$_baseUrl/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          allToilets.addAll(results.map((r) {
            final loc = r['geometry']['location'];
            return {
              'name': r['name'],
              'lat': loc['lat'],
              'lng': loc['lng'],
              'place_id': r['place_id'],
            };
          }).toList());
          
          nextPageToken = response.data['next_page_token'];
        } else if (response.data['status'] == 'INVALID_REQUEST' && nextPageToken != null) {
           await Future.delayed(const Duration(seconds: 2));
           final retryResponse = await _dio.get('$_baseUrl/nearbysearch/json', queryParameters: queryParams);
           if (retryResponse.data['status'] == 'OK') {
             final results = retryResponse.data['results'] as List;
             allToilets.addAll(results.map((r) {
               final loc = r['geometry']['location'];
               return {
                 'name': r['name'],
                 'lat': loc['lat'],
                 'lng': loc['lng'],
                 'place_id': r['place_id'],
               };
             }).toList());
             nextPageToken = retryResponse.data['next_page_token'];
           } else {
             nextPageToken = null;
           }
        } else {
          nextPageToken = null;
        }
      } while (nextPageToken != null && allToilets.length < 60);

      return allToilets;
    } catch (e) {
      print('Places API Nearby Toilets Error: $e');
      return allToilets;
    }
  }

  // 5. Find Nearby Food & Cafes
  Future<List<Map<String, dynamic>>> getNearbyFood(double lat, double lng) async {
    List<Map<String, dynamic>> allFood = [];
    String? nextPageToken;

    try {
      do {
        final queryParams = <String, dynamic>{
          'key': _apiKey,
        };

        if (nextPageToken == null) {
          queryParams['location'] = '$lat,$lng';
          queryParams['radius'] = '50000'; // 50km radius
          queryParams['type'] = 'restaurant';
        } else {
          queryParams['pagetoken'] = nextPageToken;
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await _dio.get(
          '$_baseUrl/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          allFood.addAll(results.map((r) {
            final loc = r['geometry']['location'];
            return {
              'name': r['name'],
              'lat': loc['lat'],
              'lng': loc['lng'],
              'place_id': r['place_id'],
            };
          }).toList());
          
          nextPageToken = response.data['next_page_token'];
        } else if (response.data['status'] == 'INVALID_REQUEST' && nextPageToken != null) {
           await Future.delayed(const Duration(seconds: 2));
           final retryResponse = await _dio.get('$_baseUrl/nearbysearch/json', queryParameters: queryParams);
           if (retryResponse.data['status'] == 'OK') {
             final results = retryResponse.data['results'] as List;
             allFood.addAll(results.map((r) {
               final loc = r['geometry']['location'];
               return {
                 'name': r['name'],
                 'lat': loc['lat'],
                 'lng': loc['lng'],
                 'place_id': r['place_id'],
               };
             }).toList());
             nextPageToken = retryResponse.data['next_page_token'];
           } else {
             nextPageToken = null;
           }
        } else {
          nextPageToken = null;
        }
      } while (nextPageToken != null && allFood.length < 60);

      return allFood;
    } catch (e) {
      print('Places API Nearby Food Error: $e');
      return allFood;
    }
  }

  // Find Nearby Hospitals
  Future<List<Map<String, dynamic>>> getNearbyHospitals(double lat, double lng) async {
    return _fetchNearby(lat, lng, 'hospital', '5000');
  }

  // Find Nearby Nursing Homes
  Future<List<Map<String, dynamic>>> getNearbyNursingHomes(double lat, double lng) async {
    return _fetchNearby(lat, lng, 'health', '5000', keyword: 'nursing home');
  }

  // Find Nearby Train Stations
  Future<List<Map<String, dynamic>>> getNearbyStations(double lat, double lng) async {
    return _fetchNearby(lat, lng, 'train_station', '50000');
  }

  // Find nearest place (for map taps)
  Future<Map<String, dynamic>?> getNearestPlace(double lat, double lng) async {
    final results = await _fetchNearby(lat, lng, '', '50');
    if (results.isEmpty) return null;
    
    // Filter out streets, localities, and generic regions to prioritize actual businesses/POIs
    final validPlaces = results.where((place) {
      final types = (place['types'] as List<dynamic>?)?.cast<String>() ?? [];
      return !types.contains('route') && 
             !types.contains('street_address') && 
             !types.contains('political') && 
             !types.contains('locality') &&
             !types.contains('sublocality');
    }).toList();
    
    if (validPlaces.isNotEmpty) {
      return validPlaces.first;
    }
    
    return results.first; // Fallback if only the street is found
  }

  // Helper method for nearby searches
  Future<List<Map<String, dynamic>>> _fetchNearby(double lat, double lng, String type, String radius, {String? keyword}) async {
    List<Map<String, dynamic>> allPlaces = [];
    String? nextPageToken;

    try {
      do {
        final queryParams = <String, dynamic>{
          'key': _apiKey,
        };

        if (nextPageToken == null) {
          queryParams['location'] = '${lat},${lng}';
          queryParams['radius'] = radius;
          if (type.isNotEmpty) queryParams['type'] = type;
          if (keyword != null) queryParams['keyword'] = keyword;
        } else {
          queryParams['pagetoken'] = nextPageToken;
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await _dio.get(
          '$_baseUrl/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          allPlaces.addAll(results.map((r) {
            final loc = r['geometry']['location'];
            return {
              'name': r['name'],
              'lat': loc['lat'],
              'lng': loc['lng'],
              'place_id': r['place_id'],
              'types': r['types'],
            };
          }).toList());
          
          nextPageToken = response.data['next_page_token'];
        } else if (response.data['status'] == 'INVALID_REQUEST' && nextPageToken != null) {
           await Future.delayed(const Duration(seconds: 2));
           final retryResponse = await _dio.get('$_baseUrl/nearbysearch/json', queryParameters: queryParams);
           if (retryResponse.data['status'] == 'OK') {
             final results = retryResponse.data['results'] as List;
             allPlaces.addAll(results.map((r) {
               final loc = r['geometry']['location'];
               return {
                 'name': r['name'],
                 'lat': loc['lat'],
                 'lng': loc['lng'],
                 'place_id': r['place_id'],
                 'types': r['types'],
               };
             }).toList());
             nextPageToken = retryResponse.data['next_page_token'];
           } else {
             nextPageToken = null;
           }
        } else {
          nextPageToken = null;
        }
      } while (nextPageToken != null && allPlaces.length < 60);

      return allPlaces;
    } catch (e) {
      print('Places API Nearby Error ($type): $e');
      return allPlaces;
    }
  }
}
