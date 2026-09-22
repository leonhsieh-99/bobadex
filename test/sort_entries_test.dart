import 'package:bobadex/helpers/sortable_entry.dart';
import 'package:bobadex/models/shop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Shop shop({
    required String name,
    required bool favorite,
    double rating = 3,
  }) {
    return Shop(
      id: name,
      userId: 'u',
      name: name,
      rating: rating,
      isFavorite: favorite,
      createdAt: DateTime(2024),
    );
  }

  test('favorite-desc keeps favorites first', () {
    final entries = [
      shop(name: 'a', favorite: false, rating: 5),
      shop(name: 'b', favorite: true, rating: 2),
      shop(name: 'c', favorite: true, rating: 4),
    ];
    sortEntries(entries, by: 'favorite', ascending: false);
    expect(entries.map((e) => e.name).toList(), ['c', 'b', 'a']);
  });

  test('favorite-asc puts favorites last', () {
    final entries = [
      shop(name: 'a', favorite: false, rating: 5),
      shop(name: 'b', favorite: true, rating: 2),
    ];
    sortEntries(entries, by: 'favorite', ascending: true);
    expect(entries.map((e) => e.name).toList(), ['a', 'b']);
  });
}
