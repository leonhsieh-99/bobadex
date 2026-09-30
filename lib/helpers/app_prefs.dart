import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const analyticsEnabledKey = 'analytics_enabled';
  static const locationPromptedKey = 'county_location_prompted';
  static const dismissedCountySuggestionKey = 'dismissed_county_suggestion';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> analyticsEnabled() async {
    return (await _prefs()).getBool(analyticsEnabledKey) ?? true;
  }

  static Future<void> setAnalyticsEnabled(bool value) async {
    await (await _prefs()).setBool(analyticsEnabledKey, value);
  }

  static Future<bool> locationPrompted() async {
    return (await _prefs()).getBool(locationPromptedKey) ?? false;
  }

  static Future<void> setLocationPrompted() async {
    await (await _prefs()).setBool(locationPromptedKey, true);
  }

  static Future<String?> dismissedCountySuggestion() async {
    return (await _prefs()).getString(dismissedCountySuggestionKey);
  }

  static Future<void> dismissCountySuggestion(String placeId) async {
    await (await _prefs()).setString(dismissedCountySuggestionKey, placeId);
  }
}
