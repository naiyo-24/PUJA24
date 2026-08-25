import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant_model.dart';
import '../../data/repositories/food_repository.dart';

final foodProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getRestaurants();
});
