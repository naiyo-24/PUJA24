import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/pandal_api_service.dart';

final planPandalIdsProvider = StateNotifierProvider<PlanPandalIdsNotifier, Map<String, String>>((ref) {
  final apiService = ref.watch(pandalApiServiceProvider);
  return PlanPandalIdsNotifier(apiService);
});

class PlanPandalIdsNotifier extends StateNotifier<Map<String, String>> {
  final PandalApiService _apiService;
  static const _prefsKey = 'plan_pandal_map';

  PlanPandalIdsNotifier(this._apiService) : super({}) {
    _loadPlanMap();
  }

  Future<void> _loadPlanMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        state = decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        state = {};
      }
    }
    
    // Fetch from backend
    final serverMap = await _apiService.fetchPujaPlans();
    if (serverMap.isNotEmpty || state.isNotEmpty) {
      state = serverMap;
      _saveMapToPrefs(state);
    }
  }

  Future<void> _saveMapToPrefs(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  void addPlan(String placeId, String day) async {
    final previousState = state;
    state = {...state, placeId: day};
    _saveMapToPrefs(state);
    
    final success = await _apiService.addToPlan(placeId, day);
    if (!success) {
      state = previousState;
      _saveMapToPrefs(state);
    }
  }

  void removePlan(String placeId) async {
    if (state.containsKey(placeId)) {
      final previousState = state;
      final newState = Map<String, String>.from(state)..remove(placeId);
      state = newState;
      _saveMapToPrefs(state);
      
      final success = await _apiService.removeFromPlan(placeId);
      if (!success) {
        state = previousState;
        _saveMapToPrefs(state);
      }
    }
  }
}
