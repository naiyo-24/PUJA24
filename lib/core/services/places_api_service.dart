import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

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

  // 4. Find Nearby Toilets
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
}
