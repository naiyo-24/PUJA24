import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant_model.dart';
import '../../../../core/network/api_config.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

class FoodRepository {
  Future<List<RestaurantModel>> getRestaurants() async {
    // 1. Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1200));

    // 2. Simulate JSON response from backend
    final String mockJsonResponse = '''
    [
      {
        "id": "1",
        "name": "6 Ballygunge Place",
        "cuisine": "Authentic Bengali",
        "rating": "4.9",
        "distance": "400m",
        "priceRange": "\$\$\$",
        "imageUrl": "assets/images/cafe.png",
        "isPujaSpecial": true
      },
      {
        "id": "2",
        "name": "Bhojohori Manna",
        "cuisine": "Bengali Thali",
        "rating": "4.7",
        "distance": "800m",
        "priceRange": "\$\$",
        "imageUrl": "assets/images/cafe.png",
        "isPujaSpecial": true
      },
      {
        "id": "3",
        "name": "Arsalan",
        "cuisine": "Mughlai & Biryani",
        "rating": "4.8",
        "distance": "1.2km",
        "priceRange": "\$\$",
        "imageUrl": "assets/images/cafe.png",
        "isPujaSpecial": false
      },
      {
        "id": "4",
        "name": "The Daily Cafe",
        "cuisine": "Cafe & Continental",
        "rating": "4.6",
        "distance": "1.5km",
        "priceRange": "\$\$",
        "imageUrl": "assets/images/cafe.png",
        "isPujaSpecial": false
      },
      {
        "id": "5",
        "name": "Kasturi",
        "cuisine": "Dhakai Bangladeshi",
        "rating": "4.5",
        "distance": "2.0km",
        "priceRange": "\$\$",
        "imageUrl": "assets/images/cafe.png",
        "isPujaSpecial": true
      }
    ]
    ''';

    // 3. Parse JSON and return model
    final List<dynamic> data = json.decode(mockJsonResponse);
    return data.map((json) => RestaurantModel.fromJson(json)).toList();
  }
}
