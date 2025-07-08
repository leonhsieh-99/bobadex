class FeedEvent {
  final String id;
  final String userId;
  final String objectId;
  final String eventType;
  final DateTime? createdAt;
  final Map<String, dynamic> payload;
  final bool isBackfill;

  FeedEvent({
    required this.id,
    required this.userId,
    required this.objectId,
    required this.eventType,
    this.createdAt,
    required this.payload,
    required this.isBackfill,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    return FeedEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      objectId: json['object_id'] as String,
      eventType: json['event_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'])
          : {},
      isBackfill: json['is_backfill'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'object_id': objectId,
      'event_type': eventType,
      'created_at': createdAt,
      'payload': payload,
      'is_backfill': isBackfill,
    };
  }

  FeedEvent copyWith({
    String? id,
    String? userId,
    String? objectId,
    String? eventType,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
    bool? isBackfill,
  }) {
    return FeedEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      objectId: objectId ?? this.objectId,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      isBackfill: isBackfill ?? this.isBackfill
    );
  }
}
