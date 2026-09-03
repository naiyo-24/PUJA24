import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/pandals/domain/models/puja_detail_model.dart';
import '../../../../features/pandals/data/repositories/puja_repository.dart';
import '../../../../features/pandals/presentation/providers/plan_pandal_provider.dart';

final selectedDayProvider = StateProvider<String>((ref) => 'Sashthi');

final plannerProvider = FutureProvider<Map<String, List<PujaDetailModel>>>((ref) async {
  final plannedMap = ref.watch(planPandalIdsProvider); // Map<String, String> (ID -> Day)
  final repository = ref.read(pujaRepositoryProvider);
  
  final Map<String, List<PujaDetailModel>> dayMap = {
    'Sashthi': [],
    'Saptami': [],
    'Ashtami': [],
    'Navami': [],
    'Dashami': [],
  };

  // Fetch all pandals concurrently
  final futures = plannedMap.keys.map((id) async {
    try {
      final detail = await repository.getPujaDetails(id);
      return detail;
    } catch (e) {
      return null;
    }
  }).toList();

  final results = await Future.wait(futures);

  for (final detail in results) {
    if (detail != null) {
      final day = plannedMap[detail.id];
      if (day != null && dayMap.containsKey(day)) {
        dayMap[day]!.add(detail);
      }
    }
  }

  return dayMap;
});
