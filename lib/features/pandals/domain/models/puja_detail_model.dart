class PujaDetailModel {
  final String id;
  final String name;
  final String area;
  final String rating;
  final String distance;
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

  PujaDetailModel({
    required this.id,
    required this.name,
    required this.area,
    required this.rating,
    required this.distance,
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
  });

  factory PujaDetailModel.fromJson(Map<String, dynamic> json) {
    return PujaDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      area: json['area'] ?? '',
      rating: json['rating'] ?? '',
      distance: json['distance'] ?? '',
      historySummary: json['historySummary'] ?? '',
      theme2026: json['theme2026'] ?? '',
      idolArtist: json['idolArtist'] ?? '',
      pandalDesigner: json['pandalDesigner'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      totalPhotos: json['totalPhotos'] ?? 0,
      crowdStatus: json['crowdStatus'] ?? 'Moderate',
      queueTimeMins: json['queueTimeMins'] ?? 30,
      amenities: List<String>.from(json['amenities'] ?? []),
      nearestMetro: json['nearestMetro'] ?? '',
      nearestBusStop: json['nearestBusStop'] ?? '',
      nearestCafe: json['nearestCafe'] ?? '',
      nearestHospital: json['nearestHospital'] ?? '',
      payAndUseToilet: json['payAndUseToilet'] ?? '',
    );
  }
}
