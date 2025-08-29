abstract class SortableEntry {
  String get name;
  double get rating;
  bool get isFavorite;
  DateTime get createdAt;
}

void sortEntries<T extends SortableEntry>(
  List<T> entries, {
    required String by,
    required bool ascending,
}) {
  entries.sort((a, b) {
    switch (by) {
      case 'rating':
        return ascending
          ? a.rating.compareTo(b.rating)
          : b.rating.compareTo(a.rating);
      case 'name':
        return ascending
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case 'favorite':
        // always show favorites first
        final favCmp =
            (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
        if (favCmp != 0) return favCmp;

        // within groups, respect ascending for rating
        final ratingCmp = ascending
            ? a.rating.compareTo(b.rating)
            : b.rating.compareTo(a.rating);
        if (ratingCmp != 0) return ratingCmp;

        // final tie-breaker: name
        return ascending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case 'createdAt':
        return ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
      default:
        return 0;
    }
  });
}

List<T> filterEntries<T extends SortableEntry>(
List<T> entries, {
  required String searchQuery,
}) {
  return entries = entries.where((entry) => 
    entry.name.toLowerCase().contains(searchQuery.toLowerCase())
  ).toList();
}