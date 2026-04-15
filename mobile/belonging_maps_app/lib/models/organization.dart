class Organization {
  final String id;
  final String name;
  final String description;
  final Map<String, String>
  socialLinks; // {"instagram": "url", "facebook": "url", etc}
  final String? imageUrl;
  final String category; // "Campus" or "Community"

  Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.socialLinks,
    this.imageUrl,
    required this.category,
  });
}
