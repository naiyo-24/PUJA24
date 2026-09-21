import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/pandal_api_service.dart';

final savedPandalIdsProvider = StateNotifierProvider<SavedPandalIdsNotifier, Set<String>>((ref) {
  final apiService = ref.watch(pandalApiServiceProvider);
  return SavedPandalIdsNotifier(apiService);
});

class SavedPandalIdsNotifier extends StateNotifier<Set<String>> {
  final PandalApiService _apiService;
  static const _prefsKey = 'saved_pandal_ids';

  SavedPandalIdsNotifier(this._apiService) : super({}) {
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. Load from local cache first for instant UI
    final ids = prefs.getStringList(_prefsKey) ?? [];
    state = ids.toSet();
    
    // 2. Fetch from backend and update
    final serverIds = await _apiService.fetchSavedPlaces();
    if (serverIds.isNotEmpty || state.isNotEmpty) {
      state = serverIds.toSet();
      _saveIdsToPrefs(state);
    }
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
      final isSaved = state.contains(placeId) 
          ? await _apiService.savePlace(placeId)
          : await _apiService.unsavePlace(placeId);
          
      // Re-sync if API call failed
      if (!isSaved) {
        state = previousState;
        _saveIdsToPrefs(state);
      }
    } catch (e) {
      // Revert on error
      state = previousState;
      _saveIdsToPrefs(state);
    }
  }
}
