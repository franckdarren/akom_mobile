class RestaurantModel {
  const RestaurantModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.slug,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? slug;

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logoUrl'] as String?,
        slug: json['slug'] as String?,
      );
}
