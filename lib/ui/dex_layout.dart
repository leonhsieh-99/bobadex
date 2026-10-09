import 'package:bobadex/ui/theme/boba_tokens.dart';

/// How many dex cards fit across [width].
///
/// [preference] is the saved density: 2 is the comfortable card, 3 is compact.
/// Wider screens add columns so a card stays near that size instead of stretching.
int dexColumnCount(double width, {required int preference}) {
  final compact = preference >= 3;
  final target = compact ? 128.0 : 196.0;
  const spacing = BobaSpace.x2;
  final available = width - BobaSpace.x2 * 2;
  if (available <= 0) return compact ? 3 : 2;
  final count = ((available + spacing) / (target + spacing)).round();
  final minimum = compact ? 3 : 2;
  if (available < target * minimum) return minimum;
  return count.clamp(minimum, 8);
}
