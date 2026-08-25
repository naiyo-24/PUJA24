import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/plan_item_model.dart';

final selectedDayProvider = StateProvider<String>((ref) => 'Sashthi');

final plannerProvider = Provider<Map<String, List<PlanItemModel>>>((ref) {
  // Mock itinerary for each day of the Puja
  return {
    'Sashthi': [
      PlanItemModel(
        id: '1',
        type: PlanItemType.pandal,
        title: 'Bosepukur Sitala Mandir',
        subtitle: 'Theme: Rural Bengal',
        timeWindow: '18:00 - 19:30',
        imageUrl: 'assets/images/ad1.png',
      ),
      PlanItemModel(
        id: '2',
        type: PlanItemType.restaurant,
        title: '6 Ballygunge Place',
        subtitle: 'Dinner  •  Authentic Bengali',
        timeWindow: '20:00 - 21:30',
        imageUrl: 'assets/images/cafe.png',
      ),
    ],
    'Saptami': [
      PlanItemModel(
        id: '3',
        type: PlanItemType.pandal,
        title: 'Maddox Square',
        subtitle: 'Traditional Puja & Adda',
        timeWindow: '16:00 - 18:00',
        imageUrl: 'assets/images/ad2.png',
      ),
      PlanItemModel(
        id: '4',
        type: PlanItemType.pandal,
        title: 'Badamtala Ashar Sangha',
        subtitle: 'Theme: Sustainability',
        timeWindow: '18:30 - 20:00',
        imageUrl: 'assets/images/ad1.png',
      ),
      PlanItemModel(
        id: '5',
        type: PlanItemType.restaurant,
        title: 'The Daily Cafe',
        subtitle: 'Late Night Snacks',
        timeWindow: '20:30 - 22:00',
        imageUrl: 'assets/images/cafe.png',
      ),
    ],
    'Ashtami': [
      PlanItemModel(
        id: '6',
        type: PlanItemType.pandal,
        title: 'Bagbazar Sarbojanin',
        subtitle: 'Maha Ashtami Anjali',
        timeWindow: '08:00 - 11:00',
        imageUrl: 'assets/images/ad2.png',
      ),
      PlanItemModel(
        id: '7',
        type: PlanItemType.restaurant,
        title: 'Bhojohori Manna',
        subtitle: 'Bhog & Lunch Thali',
        timeWindow: '13:00 - 14:30',
        imageUrl: 'assets/images/cafe.png',
      ),
    ],
    'Navami': [],
    'Dashami': [],
  };
});
