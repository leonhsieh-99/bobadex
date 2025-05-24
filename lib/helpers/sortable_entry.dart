abstract class SortableEntry {
  String get name;
  double get rating;
  bool get isFavorite;
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
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      default:
        return 0;
    }
  });
}