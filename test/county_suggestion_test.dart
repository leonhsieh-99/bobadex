import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

CountySummary _county({
  required String id,
  required bool tracked,
  String name = 'Santa Clara County',
}) {
  return CountySummary(
    countyPlaceId: id,
    countyName: name,
    stateName: 'California',
    eligibleTotal: 38,
    discoveredTotal: 0,
    isTracked: tracked,
  );
}

void main() {
  test('nearby suggestion is the untracked county at that place', () {
    final counties = [
      _county(id: 'tracked', tracked: true, name: 'Alameda County'),
      _county(id: 'here', tracked: false),
    ];

    expect(
      untrackedCountyById(counties, 'here')?.countyName,
      'Santa Clara County',
    );
    expect(untrackedCountyById(counties, 'tracked'), isNull);
    expect(untrackedCountyById(counties, 'missing'), isNull);
    expect(untrackedCountyById(counties, null), isNull);
  });

  test('suggestion statuses stay explanatory and hide database errors', () {
    expect(
      messageForCollectionSuggestion('pending'),
      contains('A person reviews it'),
    );
    expect(
      messageForCollectionSuggestion('already_in_collection'),
      'That brand is already in this collection.',
    );
    expect(
      messageForCollectionSuggestion('not_in_collection'),
      'That brand is not in this collection.',
    );
    expect(
      messageForCollectionSuggestion('recently_reviewed'),
      contains('reviewed recently'),
    );
    expect(
      messageForCollectionSuggestion('collection_suggestion_daily_limit'),
      contains('10 suggestions'),
    );
    expect(
      collectionSuggestionErrorCode('ERROR: authentication_required', '42501'),
      'authentication_required',
    );
    expect(
      collectionSuggestionErrorCode('duplicate key value', '23505'),
      'unknown',
    );
    expect(
      messageForCollectionSuggestion('unknown'),
      'Could not send that suggestion. Please try again.',
    );
    expect(collectionSuggestionIsError('pending'), isFalse);
    expect(collectionSuggestionIsError('collection_not_active'), isTrue);
  });

  test(
    'pending suggestions are recognized without changing the collection',
    () {
      final pending = CollectionSuggestionResult.parse({
        'status': 'pending',
        'suggestion_id': 'sug-1',
      });
      expect(pending.isPending, isTrue);
      expect(pending.suggestionId, 'sug-1');

      final suggestions = [
        CollectionSuggestion(
          id: 'sug-1',
          countyPlaceId: 'county',
          brandSlug: 'boba-loca',
          action: 'remove',
          status: 'pending',
        ),
        CollectionSuggestion(
          id: 'sug-2',
          countyPlaceId: 'county',
          brandSlug: 'sweetea',
          action: 'add',
          status: 'accepted',
        ),
      ];
      expect(hasPendingSuggestion(suggestions, 'boba-loca', 'remove'), isTrue);
      expect(hasPendingSuggestion(suggestions, 'boba-loca', 'add'), isFalse);
      expect(hasPendingSuggestion(suggestions, 'sweetea', 'add'), isFalse);
      expect(normalizeSuggestionNote('  near the mall  '), 'near the mall');
      expect(normalizeSuggestionNote('   '), isNull);
      expect(suggestionNoteTooLong('a' * 501), isTrue);
    },
  );
}
