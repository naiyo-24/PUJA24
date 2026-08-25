enum SavedItemType { pandal, restaurant }

class SavedItemModel {
  final String id;
  final SavedItemType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String distance;
  final String? rating;

  SavedItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.distance,
    this.rating,
  });
}
