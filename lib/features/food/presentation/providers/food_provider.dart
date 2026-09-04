import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant_model.dart';
import '../../data/repositories/food_repository.dart';

class FoodState {
  final List<RestaurantModel> restaurants;
  final bool isLoadingMore;
  final bool hasMore;

  FoodState({
    this.restaurants = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  FoodState copyWith({
    List<RestaurantModel>? restaurants,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return FoodState(
      restaurants: restaurants ?? this.restaurants,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FoodNotifier extends FamilyAsyncNotifier<FoodState, ({double lat, double lng, String? searchQuery, String? category})> {
  static const int _limit = 10;
  
  @override
  Future<FoodState> build(({double lat, double lng, String? searchQuery, String? category}) arg) async {
    final repository = ref.watch(foodRepositoryProvider);
    print("FoodNotifier build called with \$arg"); 
    final initialData = await repository.getRestaurants(
      arg.lat, 
      arg.lng, 
      limit: _limit, 
      skip: 0,
      searchQuery: arg.searchQuery,
      category: arg.category,
    );
    return FoodState(
      restaurants: initialData,
      hasMore: initialData.length == _limit,
    );
  }

  Future<void> loadMore() async {
    final stateVal = state.value;
    if (stateVal == null || stateVal.isLoadingMore || !stateVal.hasMore) return;

    state = AsyncData(stateVal.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(foodRepositoryProvider);
      final newItems = await repository.getRestaurants(
        arg.lat,
        arg.lng,
        limit: _limit,
        skip: stateVal.restaurants.length,
        searchQuery: arg.searchQuery,
        category: arg.category,
      );

      state = AsyncData(stateVal.copyWith(
        restaurants: [...stateVal.restaurants, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length == _limit,
      ));
    } catch (e) {
      state = AsyncData(stateVal.copyWith(isLoadingMore: false));
    }
  }
}

final foodProvider = AsyncNotifierProvider.family<FoodNotifier, FoodState, ({double lat, double lng, String? searchQuery, String? category})>(FoodNotifier.new);
