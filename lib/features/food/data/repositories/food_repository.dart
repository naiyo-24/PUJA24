import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant_model.dart';
import '../../../../core/network/graphql_service.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(GraphQLService());
});

class FoodRepository {
  final GraphQLService _graphQLService;

  FoodRepository(this._graphQLService);

  Future<List<RestaurantModel>> getRestaurants(double lat, double lng, {int limit = 10, int skip = 0, String? searchQuery, String? category}) async {
    const String query = '''
      query GetNearbyFood(\$lat: Float!, \$lng: Float!, \$limit: Int, \$skip: Int, \$searchQuery: String, \$category: String) {
        nearbyFood(lat: \$lat, lng: \$lng, limit: \$limit, skip: \$skip, searchQuery: \$searchQuery, category: \$category) {
          id
          name
          subCategory
          avgRating
          totalReviews
          distanceMeters
          latitude
          longitude
          isPopular
          imageUrl
          placeMetadata
          area
        }
      }
    ''';

    final variables = {
      'lat': lat,
      'lng': lng,
      'limit': limit,
      'skip': skip,
      'searchQuery': searchQuery,
      'category': category,
    };

    try {
      final response = await _graphQLService.query(query, variables: variables);
      
      if (response['nearbyFood'] != null) {
        final List<dynamic> data = response['nearbyFood'];
        return data.map((json) {
           int priceLevel = 2;
           String about = '';
           String timings = '24/7';
           String contactPhone = '';
           List<Map<String, dynamic>> topDishes = [];
           
           if (json['placeMetadata'] != null) {
             final metadata = json['placeMetadata'] is String ? jsonDecode(json['placeMetadata']) : json['placeMetadata'];
             if (metadata['price_level'] != null) {
               priceLevel = metadata['price_level'];
             }
             if (metadata['about'] != null) about = metadata['about'];
             if (metadata['timings'] != null) timings = metadata['timings'];
             if (metadata['contactPhone'] != null) contactPhone = metadata['contactPhone'];
             if (metadata['topDishes'] != null) {
               topDishes = List<Map<String, dynamic>>.from(metadata['topDishes']);
             }
           }
           String priceString = List.generate(priceLevel, (_) => '₹').join();

           return RestaurantModel(
             id: json['id'] ?? '',
             name: json['name'] ?? '',
             cuisine: json['subCategory'] ?? 'Food & Cafe',
             rating: (json['avgRating'] ?? 0.0).toString(),
             distance: '${((json['distanceMeters'] ?? 0) / 1000).toStringAsFixed(1)} km',
             priceRange: priceString,
             imageUrl: json['imageUrl'] ?? '', 
             isPujaSpecial: json['isPopular'] ?? false,
             latitude: (json['latitude'] ?? 0.0).toDouble(),
             longitude: (json['longitude'] ?? 0.0).toDouble(),
             area: json['area'] ?? 'Kolkata',
             contactPhone: contactPhone.isNotEmpty ? contactPhone : null,
             about: about.isNotEmpty ? about : null,
             topDishes: topDishes.isNotEmpty ? topDishes : null,
             totalReviews: json['totalReviews'] ?? 0,
             timings: timings,
           );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Food GraphQL Error: $e');
      return [];
    }
  }
}
