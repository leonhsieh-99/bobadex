import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final String id;
  String username;
  String? displayName;
  String themeSlug = 'grey';
  String? profileImagePath;
  String? bio;
  int gridColumns;

  User ({
    required this.id,
    required this.username,
    this.displayName,
    this.themeSlug = 'grey',
    this.profileImagePath,
    this.bio,
    this.gridColumns = 3,
  });

  String get firstName => displayName!.split(' ').first;

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
      gridColumns: settings?['grid_columns'] ?? 3,
    );
  }

  factory User.empty() => User(
    id: '',
    username: '',
    profileImagePath: '',
    themeSlug: 'grey',
  );

  User copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? profileImagePath,
    String? themeSlug,
    int? gridColumns,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio:  bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      themeSlug: themeSlug ?? this.themeSlug,
      gridColumns: gridColumns ?? this.gridColumns,
    );
  }
}