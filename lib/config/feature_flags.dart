abstract final class FeatureFlags {
  /// County collection RPCs live on the dev project. Prod builds stay off
  /// until those functions are merged.
  static const collection =
      String.fromEnvironment('SUPABASE_URL') ==
      'https://xnkpatktudnycpkbmvsf.supabase.co';
}
