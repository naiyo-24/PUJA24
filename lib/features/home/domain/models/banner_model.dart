class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String bannerType;
  final String imageUrl;
  final String actionType;
  final String? actionPayload;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.bannerType,
    required this.imageUrl,
    required this.actionType,
    this.actionPayload,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      bannerType: json['bannerType'] ?? 'HERO',
      imageUrl: json['imageUrl'] ?? '',
      actionType: json['actionType'] ?? 'NONE',
      actionPayload: json['actionPayload'],
    );
  }
}
