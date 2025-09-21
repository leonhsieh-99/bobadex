import 'package:supabase_flutter/supabase_flutter.dart';

enum BrandStatus { active, retired }

extension BrandStatusX on BrandStatus {
  String get db => this == BrandStatus.retired ? 'retired' : 'active';
  String get label => this == BrandStatus.retired ? 'Closed' : 'Open';
}

BrandStatus _brandStatusFromDb(String? s) =>
    s == 'retired' ? BrandStatus.retired : BrandStatus.active;

class Brand {
  final String slug;
  final String display;
  final List<String> aliases;
  final String? iconPath;
  BrandStatus status;

  Brand({
    required this.slug,
    required this.display,
    List<String>? aliases,
    this.iconPath,
    this.status = BrandStatus.active,
  }) : aliases = aliases ?? [];

  String get imageUrl => iconPath != null && iconPath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('shop-media')
        .getPublicUrl(iconPath!.trim())
    : '';

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      slug: json['slug'],
      display: json['display'],
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      iconPath: json['icon_path'],
      status: _brandStatusFromDb(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return ({
      'slug': slug,
      'display': display,
      'aliases': aliases,
      'icon_path': iconPath,
      'status': status.db,
    });
  }
}
