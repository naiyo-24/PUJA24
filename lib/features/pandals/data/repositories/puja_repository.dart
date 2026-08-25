import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../../../core/network/api_config.dart';

// Provides the repository instance
final pujaRepositoryProvider = Provider<PujaRepository>((ref) {
  return PujaRepository();
});

class PujaRepository {
  /// Fetches Puja details.
  /// 
  /// Currently simulates a network request since the backend is not fully ready.
  /// Once ready, replace this with an http.get call to [ApiConfig.baseUrl]/pandals/$id
  Future<PujaDetailModel> getPujaDetails(String id) async {
    // 1. Simulate network latency (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Simulate JSON response from backend
    final String mockJsonResponse = '''
    {
      "id": "$id",
      "name": "Ekdalia Evergreen",
      "area": "Ballygunge",
      "rating": "4.8",
      "distance": "1.2 km",
      "historySummary": "Established in 1943, Ekdalia Evergreen is renowned for its traditional and monumental pandal architecture. It holds a legacy of recreating world-famous temples and monuments.",
      "theme2026": "Echoes of the Chola Dynasty (Tribute to Brihadeeswara Temple)",
      "idolArtist": "Sanatan Dinda",
      "pandalDesigner": "Bhabatosh Sutar",
      "imageUrl": "assets/images/ad1.png",
      "totalPhotos": 42,
      "crowdStatus": "High",
      "queueTimeMins": 45,
      "amenities": ["Wheelchair", "Parking", "First Aid", "Washroom", "VIP Entry"],
      "nearestMetro": "Kalighat (1.5 km)",
      "nearestBusStop": "Ekdalia More (200m)",
      "nearestCafe": "6 Ballygunge Place (400m), Barista (500m)",
      "nearestHospital": "AMRI Hospital, Gariahat (1.2 km)",
      "payAndUseToilet": "Near Ekdalia Park Gate 2 (50m)"
    }
    ''';

    // 3. Parse JSON and return model
    final Map<String, dynamic> data = json.decode(mockJsonResponse);
    return PujaDetailModel.fromJson(data);
  }
}
