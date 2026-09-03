class PassPackageModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final int personCapacity;
  final String collectionVenue;
  final bool isActive;
  final List<String> includedPandalIds;

  PassPackageModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.personCapacity,
    required this.collectionVenue,
    required this.isActive,
    required this.includedPandalIds,
  });

  factory PassPackageModel.fromJson(Map<String, dynamic> json) {
    return PassPackageModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      personCapacity: json['person_capacity'] ?? 3,
      collectionVenue: json['collection_venue'] ?? '',
      isActive: json['is_active'] ?? true,
      includedPandalIds: List<String>.from(json['included_pandal_ids'] ?? []),
    );
  }
}
