import 'package:supabase_flutter/supabase_flutter.dart';

class TeaRoom {
  final String id;
  String name;
  String? description;
  final String ownerId;
  String? roomImagePath;

  TeaRoom ({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.roomImagePath,
  });

    String get imageUrl => roomImagePath != null && roomImagePath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('media-uploads')
        .getPublicUrl(roomImagePath!.trim())
    : '';

  String get thumbUrl => roomImagePath != null && roomImagePath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('media-uploads')
        .getPublicUrl('thumbs/${roomImagePath!.trim()}')
    : '';

  TeaRoom copyWith ({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? roomImagePath,
  }) {
    return TeaRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      roomImagePath: roomImagePath ?? this.roomImagePath,
    );
  }

  factory TeaRoom.fromJson(Map<String, dynamic> json) {
    return TeaRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ownerId: json['owner_id'],
      roomImagePath: json['room_image_path'],
    );
  }
}