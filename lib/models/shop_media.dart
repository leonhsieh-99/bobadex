import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ShopMedia {
  final String id;
  final String shopId;
  final String userId;
  final String? drinkId;
  final String imagePath;
  bool isBanner;
  final String? visibility;
  final String? comment;
  final File? localFile;
  final bool isPending;
  // for feeds
  final String? userDisplayName;
  final String? profileImagePath;

  ShopMedia({
    required this.id,
    required this.shopId,
    required this.userId,
    this.drinkId,
    required this.imagePath,
    this.isBanner = false,
    this.visibility = 'public', // change to private after testing
    this.comment,
    this.localFile,
    this.isPending = false,
    this.userDisplayName,
    this.profileImagePath,
  });

  String get imageUrl => imagePath.isNotEmpty
    ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl(imagePath.trim())
    : '';

  String get thumbUrl => imagePath.isNotEmpty
    ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl('thumbs/${imagePath.trim()}')
    : '';

  String get userThumbUrl => (profileImagePath != null && profileImagePath!.isNotEmpty)
    ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl('thumbs/${profileImagePath!.trim()}')
    : '';


  factory ShopMedia.fromJson(Map<String, dynamic> json) {
    return ShopMedia(
      id: json['id'],
      shopId: json['shop_id'] ?? '',
      userId: json['user_id'],
      drinkId: json['drink_id'] ?? '',
      imagePath: json['image_path'],
      isBanner: json['is_banner'] ?? false,
      visibility: json['visibility'] ?? 'public', // change to private after testing
      comment: json['comment'] ?? '',
      isPending: json['is_pending'] ?? false,
      userDisplayName: json['user_display_name'],
      profileImagePath: json['profile_image_path']
    );
  }

  static ShopMedia galleryViewMedia({
    required String imagePath,
    required String comment,
  }) {
    return ShopMedia(
      id: '',
      shopId: '',
      userId: '',
      imagePath: imagePath,
      comment: comment
    );
  }

  ShopMedia copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? drinkId,
    String? imagePath,
    bool? isBanner,
    String? visibility,
    String? comment,
    File? localFile,
    bool? isPending,
  }) {
    return ShopMedia(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      drinkId: drinkId ?? this.drinkId,
      imagePath: imagePath ?? this.imagePath,
      isBanner: isBanner ?? this.isBanner,
      visibility: visibility ?? this.visibility,
      comment: comment ?? this.comment,
      localFile: localFile ?? this.localFile,
      isPending: isPending ?? this.isPending,
    );
  }
}