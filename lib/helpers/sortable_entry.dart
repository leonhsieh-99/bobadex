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
        int favComp = (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0);
        if (favComp != 0) return favComp;
        return b.rating.compareTo(a.rating);
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