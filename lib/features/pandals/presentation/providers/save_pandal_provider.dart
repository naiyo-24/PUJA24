import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/puja_repository.dart';

final savedPandalIdsProvider = StateNotifierProvider<SavedPandalIdsNotifier, Set<String>>((ref) {
  final repository = ref.watch(pujaRepositoryProvider);
  return SavedPandalIdsNotifier(repository);
});

class SavedPandalIdsNotifier extends StateNotifier<Set<String>> {
  final PujaRepository _repository;
  static const _prefsKey = 'saved_pandal_ids';

  SavedPandalIdsNotifier(this._repository) : super({}) {
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    state = ids.toSet();
  }

  Future<void> _saveIdsToPrefs(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  void toggleSave(String placeId) async {
    final previousState = state;
    // Optimistic UI update
    if (state.contains(placeId)) {
      state = {...state}..remove(placeId);
    } else {
      state = {...state, placeId};
    }
    _saveIdsToPrefs(state);

    try {
      final isSaved = await _repository.toggleSavedPandal(placeId);
      // Re-sync with backend response
      if (isSaved) {
        state = {...state, placeId};
      } else {
        state = {...state}..remove(placeId);
      }
      _saveIdsToPrefs(state);
    } catch (e) {
      // Revert on error
      state = previousState;
      _saveIdsToPrefs(state);
    }
  }
}
