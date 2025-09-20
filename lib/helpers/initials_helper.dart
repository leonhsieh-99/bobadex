String initialFrom({
  String? firstName,
  String? displayName,
  String? username,
  String fallback = '?',
}) {
  final cand = (firstName ?? '').trim().isNotEmpty
      ? firstName!
      : (displayName ?? '').trim().isNotEmpty
          ? displayName!
          : (username ?? '').trim();

  if (cand.isEmpty) return fallback;

  // Use grapheme cluster so emoji/combined chars are 1 char
  final first = cand[0];
  return first.toUpperCase();
}