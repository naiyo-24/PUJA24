import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/pandals/domain/models/puja_detail_model.dart';
import '../../../../features/pandals/data/repositories/puja_repository.dart';
import '../../../../features/pandals/presentation/providers/save_pandal_provider.dart';

final savedFilterProvider = StateProvider<String>((ref) => 'All');

final savedItemsProvider = FutureProvider<List<PujaDetailModel>>((ref) async {
  final savedIds = ref.watch(savedPandalIdsProvider);
  final repository = ref.read(pujaRepositoryProvider);
  
  final futures = savedIds.map((id) async {
    try {
      final detail = await repository.getPujaDetails(id);
      return detail;
    } catch (e) {
      return null;
    }
  }).toList();

  final results = await Future.wait(futures);
  
  return results.where((item) => item != null).cast<PujaDetailModel>().toList();
});
