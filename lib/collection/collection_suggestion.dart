class CollectionSuggestion {
  const CollectionSuggestion({
    required this.id,
    required this.countyPlaceId,
    required this.brandSlug,
    required this.action,
    required this.status,
    this.note,
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String countyPlaceId;
  final String brandSlug;
  final String action;
  final String status;
  final String? note;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';

  factory CollectionSuggestion.fromJson(Map<String, dynamic> json) {
    return CollectionSuggestion(
      id: (json['id'] as String?) ?? '',
      countyPlaceId: (json['county_place_id'] as String?) ?? '',
      brandSlug: (json['brand_slug'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      note: json['note'] as String?,
      submittedAt: _time(json['submitted_at']),
      reviewedAt: _time(json['reviewed_at']),
    );
  }
}

class CollectionSuggestionResult {
  const CollectionSuggestionResult({required this.status, this.suggestionId});

  final String status;
  final String? suggestionId;

  bool get isPending => status == 'pending';

  factory CollectionSuggestionResult.parse(dynamic raw) {
    if (raw is! Map) {
      return const CollectionSuggestionResult(status: 'unknown');
    }
    final json = Map<String, dynamic>.from(raw);
    final id = json['suggestion_id'];
    return CollectionSuggestionResult(
      status: (json['status'] as String?) ?? 'unknown',
      suggestionId: id is String && id.isNotEmpty ? id : null,
    );
  }
}

const collectionSuggestionCodes = {
  'authentication_required',
  'collection_suggestion_daily_limit',
  'collection_not_active',
  'brand_not_active',
  'invalid_collection_suggestion_input',
  'invalid_collection_suggestion_action',
};

String collectionSuggestionErrorCode(String? message, [String? code]) {
  final text = '${message ?? ''} ${code ?? ''}'.toLowerCase();
  for (final known in collectionSuggestionCodes) {
    if (text.contains(known)) return known;
  }
  return 'unknown';
}

String? normalizeSuggestionNote(String raw) {
  final note = raw.trim();
  if (note.isEmpty) return null;
  return note;
}

bool suggestionNoteTooLong(String raw) => raw.trim().length > 500;

String messageForCollectionSuggestion(String status) {
  return switch (status) {
    'pending' =>
      'Suggestion sent. A person reviews it before the collection changes.',
    'already_in_collection' => 'That brand is already in this collection.',
    'not_in_collection' => 'That brand is not in this collection.',
    'recently_reviewed' =>
      'This suggestion was reviewed recently. Try again in a few days.',
    'authentication_required' => 'Sign in to suggest a change.',
    'collection_suggestion_daily_limit' =>
      'You can send 10 suggestions a day. Try again tomorrow.',
    'collection_not_active' => 'This collection is not taking suggestions.',
    'brand_not_active' => 'That brand is not available to suggest.',
    'invalid_collection_suggestion_input' =>
      'Keep the reason under 500 characters.',
    _ => 'Could not send that suggestion. Please try again.',
  };
}

bool collectionSuggestionIsError(String status) {
  return status != 'pending' &&
      status != 'already_in_collection' &&
      status != 'not_in_collection' &&
      status != 'recently_reviewed';
}

String collectionSuggestionStatusLabel(String status) {
  return switch (status) {
    'pending' => 'Suggestion sent',
    'accepted' => 'Accepted',
    'dismissed' => 'Dismissed',
    _ => 'Reviewed',
  };
}

bool hasPendingSuggestion(
  List<CollectionSuggestion> suggestions,
  String brandSlug,
  String action,
) {
  return suggestions.any(
    (suggestion) =>
        suggestion.brandSlug == brandSlug &&
        suggestion.action == action &&
        suggestion.isPending,
  );
}

DateTime? _time(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
