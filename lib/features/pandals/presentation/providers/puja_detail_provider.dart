import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../data/repositories/puja_repository.dart';

/// A FutureProvider that takes a String `id` and fetches the Puja details.
/// By using family, we can cache requests for different puja IDs independently.
final pujaDetailProvider = FutureProvider.family<PujaDetailModel, String>((ref, id) async {
  final repository = ref.watch(pujaRepositoryProvider);
  return repository.getPujaDetails(id);
});
