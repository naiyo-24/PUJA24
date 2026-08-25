class RestaurantModel {
  final String id;
  final String name;
  final String cuisine;
  final String rating;
  final String distance;
  final String priceRange; // e.g., "$$"
  final String imageUrl;
  final bool isPujaSpecial;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.distance,
    required this.priceRange,
    required this.imageUrl,
    required this.isPujaSpecial,
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
    );
  }
}
