class Brand {
  final String slug;
  final String display;
  final List<String> aliases;
  final String urlText;

  Brand({
    required this.slug,
    required this.display,
    required this.aliases,
    required this.urlText,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      slug: json['slug'],
      display: json['display'],
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      urlText: json['urlText'] ?? '',
    );
  }
}
