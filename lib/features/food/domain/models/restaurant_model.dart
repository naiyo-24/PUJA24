class RestaurantModel {
  final String id;
  final String name;
  final String cuisine;
  final String rating;
  final String distance;
  final String priceRange; // e.g., "$$"
  final String imageUrl;
  final bool isPujaSpecial;
  final double latitude;
  final double longitude;
  final String area;

  final String? contactPhone;
  final String? about;
  final List<Map<String, dynamic>>? topDishes;
  final int? totalReviews;
  final String? timings;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.distance,
    required this.priceRange,
    required this.imageUrl,
    required this.isPujaSpecial,
    required this.latitude,
    required this.longitude,
    this.area = 'Kolkata',
    this.contactPhone,
    this.about,
    this.topDishes,
    this.totalReviews,
    this.timings,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cuisine: json['cuisine'] ?? '',
      rating: json['rating'] ?? '',
      distance: json['distance'] ?? '',
      priceRange: json['priceRange'] ?? '\$\$',
      imageUrl: json['imageUrl'] ?? '',
      isPujaSpecial: json['isPujaSpecial'] ?? false,
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      area: json['area'] ?? 'Kolkata',
      contactPhone: json['contactPhone'],
      about: json['about'],
      topDishes: json['topDishes'] != null ? List<Map<String, dynamic>>.from(json['topDishes']) : null,
      totalReviews: json['totalReviews'],
      timings: json['timings'],
    );
  }
}
