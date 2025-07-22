import 'package:bobadex/models/user.dart';

class FeedEvent {
  User feedUser;
  final String id;
  final String objectId;
  final String eventType;
  final DateTime? createdAt;
  final String? brandSlug;
  final Map<String, dynamic> payload;
  final bool isBackfill;

  FeedEvent({
    required this.feedUser,
    required this.id,
    required this.objectId,
    required this.eventType,
    this.createdAt,
    this.brandSlug,
    required this.payload,
    required this.isBackfill,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    return FeedEvent(
      feedUser: json['feed_user'] == null ? User.empty() : User.fromJson(json['feed_user']),
      id: json['id'] as String,
      objectId: json['object_id'] as String,
      eventType: json['event_type'] as String,
      brandSlug: json['brand_slug'] as String?,
      createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'])
          : {},
      isBackfill: json['is_backfill'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedUser': feedUser.toJson(),
      'id': id,
      'object_id': objectId,
      'event_type': eventType,
      'brand_slug': brandSlug,
      'created_at': createdAt,
      'is_backfill': isBackfill,
      'payload': payload,
    };
  }

  FeedEvent copyWith({
    User? feedUser,
    String? id,
    String? objectId,
    String? eventType,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
    String? brandSlug,
    bool? isBackfill,
  }) {
    return FeedEvent(
      feedUser: feedUser ?? User.empty(),
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      brandSlug: brandSlug ?? this.brandSlug,
      isBackfill: isBackfill ?? this.isBackfill
    );
  }
}
