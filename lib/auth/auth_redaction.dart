bool containsAuthSecrets(String? value) {
  if (value == null || value.isEmpty) return false;
  final lower = value.toLowerCase();
  return lower.contains('access_token') ||
      lower.contains('refresh_token') ||
      lower.contains('id_token') ||
      lower.contains('provider_token') ||
      RegExp(r'"code"\s*:\s*"\d{6,8}"').hasMatch(lower);
}
