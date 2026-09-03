import 'dart:convert';

class PujaDetailModel {
  final String id;
  final String name;
  final String area;
  final String rating;
  final String distance;
  final double latitude;
  final double longitude;
  final String historySummary;
  final String theme2026;
  final String idolArtist;
  final String pandalDesigner;
  final String imageUrl;
  final int totalPhotos;
  final String crowdStatus; // "High", "Moderate", "Low"
  final int queueTimeMins;
  final List<String> amenities;
  final String nearestMetro;
  final String nearestBusStop;
  final String nearestCafe;
  final String nearestHospital;
  final String payAndUseToilet;
  final String rainStatus; // e.g. "Clear", "Drizzle", "Raining", "Heavy rain"

  PujaDetailModel({
    required this.id,
    required this.name,
    required this.area,
    required this.rating,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.historySummary,
    required this.theme2026,
    required this.idolArtist,
    required this.pandalDesigner,
    required this.imageUrl,
    required this.totalPhotos,
    required this.crowdStatus,
    required this.queueTimeMins,
    required this.amenities,
    required this.nearestMetro,
    required this.nearestBusStop,
    required this.nearestCafe,
    required this.nearestHospital,
    required this.payAndUseToilet,
    required this.rainStatus,
  });

  factory PujaDetailModel.fromJson(Map<String, dynamic> json) {
    // Backend may send placeMetadata string/map or individual fields via resolvers
    Map<String, dynamic> metadata = {};
    if (json['placeMetadata'] != null) {
      if (json['placeMetadata'] is String) {
        try {
          metadata = Map<String, dynamic>.from(jsonDecode(json['placeMetadata']));
        } catch (e) {
          // ignore
        }
      } else {
        metadata = Map<String, dynamic>.from(json['placeMetadata']);
      }
    }

    return PujaDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      area: json['area'] ?? json['zone'] ?? '',
      rating: (json['rating'] ?? json['avgRating'] ?? 0.0).toString(),
      distance: (json['distance'] ?? json['distanceMeters'] ?? 0.0).toString(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 0.0,
      historySummary: metadata['historySummary'] ?? '',
      theme2026: json['theme2026'] ?? metadata['theme2026'] ?? '',
      idolArtist: metadata['idolArtist'] ?? '',
      pandalDesigner: metadata['pandalDesigner'] ?? '',
      imageUrl: json['imageUrl'] ?? metadata['imageUrl'] ?? '',
      totalPhotos: json['totalPhotos'] ?? metadata['totalPhotos'] ?? 0,
      crowdStatus: json['crowdStatus'] ?? metadata['crowdStatus'] ?? 'Moderate',
      queueTimeMins: json['queueTimeMins'] ?? metadata['queueTimeMins'] ?? 30,
      amenities: List<String>.from(metadata['amenities'] ?? []),
      nearestMetro: metadata['nearestMetro'] ?? '',
      nearestBusStop: metadata['nearestBusStop'] ?? '',
      nearestCafe: metadata['nearestCafe'] ?? '',
      nearestHospital: metadata['nearestHospital'] ?? '',
      payAndUseToilet: metadata['payAndUseToilet'] ?? '',
      rainStatus: json['rainStatus'] ?? metadata['rainStatus'] ?? 'Clear',
    );
  }
}
