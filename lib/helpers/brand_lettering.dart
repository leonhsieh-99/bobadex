const _stopWords = {
  'a',
  'an',
  'the',
  'of',
  'and',
  'at',
  'for',
  'to',
  'in',
};

/// One or two letters derived from a brand name. Same name always yields the same mark.
String brandLettering(String name) {
  final cleaned = name
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
      .trim();
  if (cleaned.isEmpty) return '?';

  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_stopWords.contains(w.toLowerCase()))
      .toList();
  final parts = words.isEmpty
      ? cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList()
      : words;

  if (parts.length == 1) {
    final word = parts.first;
    final take = word.length >= 2 ? 2 : 1;
    return word.substring(0, take).toUpperCase();
  }

  return (parts[0][0] + parts[1][0]).toUpperCase();
}

int brandLetteringSeed(String seed) {
  var hash = 0;
  for (final code in seed.toLowerCase().codeUnits) {
    hash = 0x1fffffff & ((hash << 5) + hash + code);
  }
  return hash;
}
