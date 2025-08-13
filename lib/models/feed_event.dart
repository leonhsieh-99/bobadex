import 'dart:convert';

import 'package:bobadex/models/user.dart';

class FeedEvent {
  User feedUser;
  final String id;
  final String objectId;
  final String eventType;
  final DateTime createdAt;
  final String? brandSlug;
  final Map<String, dynamic> payload;
  final bool isBackfill;
  final int seq;

  FeedEvent({
    required this.feedUser,
    required this.id,
    required this.objectId,
    required this.eventType,
    required this.createdAt,
    this.brandSlug,
    required this.payload,
    required this.isBackfill,
    this.seq = 0,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsePayload(dynamic raw) {
      if (raw == null) return {};
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
      }
      return {};
    }
    return FeedEvent(
      feedUser: (json['feed_user'] == null)
          ? User.empty()
          : User.fromJson(json['feed_user']),
      id: json['id'] as String,
      objectId: json['object_id'] as String,
      eventType: json['event_type'] as String,
      brandSlug: json['brand_slug'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      payload: parsePayload(json['payload']),
      isBackfill: json['is_backfill'] == true,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
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
      'seq': seq,
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
    int? seq,
  }) {
    return FeedEvent(
      feedUser: feedUser ?? User.empty(),
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      brandSlug: brandSlug ?? this.brandSlug,
      isBackfill: isBackfill ?? this.isBackfill,
      seq: seq ?? this.seq
    );
  }
}
