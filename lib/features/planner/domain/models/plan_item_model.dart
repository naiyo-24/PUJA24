enum PlanItemType { pandal, restaurant }

class PlanItemModel {
  final String id;
  final PlanItemType type;
  final String title;
  final String subtitle;
  final String timeWindow;
  final String imageUrl;

  PlanItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeWindow,
    required this.imageUrl,
  });
}
