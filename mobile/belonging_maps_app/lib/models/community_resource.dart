/// A community resource (food pantry, tutoring, etc.) stored in the backend
/// CommunityResources table (P1-220 / P1-225).
class CommunityResource {
  /// Database id. 0 means "not saved yet".
  final int id;
  final String title;
  final String category;
  final String description;

  /// One of: food, health, housing, education, financial, career,
  /// transportation, family.
  final String iconKey;

  /// Optional uploaded photo (P1-319). Null means no image.
  final int? imageId;

  const CommunityResource({
    this.id = 0,
    required this.title,
    required this.category,
    required this.description,
    this.iconKey = 'food',
    this.imageId,
  });

  factory CommunityResource.fromJson(Map<String, dynamic> json) {
    return CommunityResource(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'food',
      imageId: json['imageId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'description': description,
        'iconKey': iconKey,
        'imageId': imageId,
      };
}
