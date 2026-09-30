import 'package:bobadex/collection/collection_models.dart';
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
}
