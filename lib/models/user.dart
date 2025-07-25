import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final String id;
  String username;
  String displayName;
  String themeSlug = 'grey';
  String? profileImagePath;
  String? bio;
  int gridColumns;
  bool useIcons;
  bool onboarded;

  User ({
    required this.id,
    required this.username,
    required this.displayName,
    this.themeSlug = 'grey',
    this.profileImagePath,
    this.bio,
    this.gridColumns = 2,
    this.useIcons = false,
    this.onboarded = false,
  });

  String get firstName => displayName.split(' ').first;

  String get imageUrl => profileImagePath != null && profileImagePath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('media-uploads')
        .getPublicUrl(profileImagePath!.trim())
    : '';

  String get thumbUrl => profileImagePath != null && profileImagePath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('media-uploads')
        .getPublicUrl('thumbs/${profileImagePath!.trim()}')
    : '';

  factory User.fromMap(Map<String, dynamic> profile, Map<String, dynamic>? settings) {
    return User(
      id: profile['id'],
      username: profile['username'],
      displayName: profile['display_name'],
      profileImagePath: profile['profile_image_path'],
      bio: profile['bio'],
      themeSlug: settings?['theme_slug'] ?? 'grey',
      gridColumns: settings?['grid_columns'] ?? 2,
      useIcons: settings?['use_icons'] ?? false,
      onboarded: settings?['onboarded'] ?? false,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      profileImagePath: json['profile_image_path'] ?? '',
      bio: json['bio'] ?? '',
    );
  }

  factory User.empty() => User(
    id: '',
    username: '',
    profileImagePath: '',
    themeSlug: 'grey',
    displayName: '',
    bio: '',
    gridColumns: 2,
    useIcons: false,
    onboarded: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profileImagePath': profileImagePath,
      'themeSlug': themeSlug,
      'displayName': displayName,
      'bio': bio,
      'gridColumns': gridColumns,
      'useIcons': useIcons,
      'onboarded': onboarded
    };
  }

  User copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? profileImagePath,
    String? themeSlug,
    int? gridColumns,
    bool? useIcons,
    bool? onboarded,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio:  bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      themeSlug: themeSlug ?? this.themeSlug,
      gridColumns: gridColumns ?? this.gridColumns,
      useIcons: useIcons ?? this.useIcons,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}