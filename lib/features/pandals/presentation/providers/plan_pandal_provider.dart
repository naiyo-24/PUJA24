import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final planPandalIdsProvider = StateNotifierProvider<PlanPandalIdsNotifier, Map<String, String>>((ref) {
  return PlanPandalIdsNotifier();
});

class PlanPandalIdsNotifier extends StateNotifier<Map<String, String>> {
  static const _prefsKey = 'plan_pandal_map';

  PlanPandalIdsNotifier() : super({}) {
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
  }

  Future<void> _saveMapToPrefs(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  void addPlan(String placeId, String day) {
    state = {...state, placeId: day};
    _saveMapToPrefs(state);
  }

  void removePlan(String placeId) {
    if (state.containsKey(placeId)) {
      final newState = Map<String, String>.from(state)..remove(placeId);
      state = newState;
      _saveMapToPrefs(state);
    }
  }
}
