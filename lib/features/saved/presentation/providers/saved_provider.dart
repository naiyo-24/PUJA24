import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/saved_item_model.dart';

final savedFilterProvider = StateProvider<String>((ref) => 'All');

final savedItemsProvider = Provider<List<SavedItemModel>>((ref) {
  // Mock saved items
  return [
    SavedItemModel(
      id: '1',
      type: SavedItemType.pandal,
      title: 'Bosepukur Sitala Mandir',
      subtitle: 'Theme: Rural Bengal',
      imageUrl: 'assets/images/ad1.png',
      distance: '2.5 km',
    ),
    SavedItemModel(
      id: '2',
      type: SavedItemType.restaurant,
      title: '6 Ballygunge Place',
      subtitle: 'Authentic Bengali',
      imageUrl: 'assets/images/cafe.png',
      distance: '400m',
      rating: '4.9',
    ),
    SavedItemModel(
      id: '3',
      type: SavedItemType.pandal,
      title: 'Maddox Square',
      subtitle: 'Traditional Puja & Adda',
      imageUrl: 'assets/images/ad2.png',
      distance: '1.2 km',
    ),
    SavedItemModel(
      id: '4',
      type: SavedItemType.restaurant,
      title: 'The Daily Cafe',
      subtitle: 'Cafe & Continental',
      imageUrl: 'assets/images/cafe.png',
      distance: '1.5km',
      rating: '4.6',
    ),
  ];
});

final filteredSavedItemsProvider = Provider<List<SavedItemModel>>((ref) {
  final filter = ref.watch(savedFilterProvider);
  final items = ref.watch(savedItemsProvider);
  
  if (filter == 'Pandals') {
    return items.where((i) => i.type == SavedItemType.pandal).toList();
  } else if (filter == 'Cafes') {
    return items.where((i) => i.type == SavedItemType.restaurant).toList();
  }
  
  return items;
});
