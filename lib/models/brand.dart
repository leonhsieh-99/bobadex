class Brand {
  final String slug;
  final String display;
  final List<String> aliases;
  final String? urlText;
  final String? iconPath;

  Brand({
    required this.slug,
    required this.display,
    List<String>? aliases,
    this.urlText = '',
    this.iconPath,
  }) : aliases = aliases ?? [];

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      slug: json['slug'],
      display: json['display'],
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      urlText: json['urlText'] ?? '',
      iconPath: json['icon_path'],
    );
  }
}
