import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const analyticsEnabledKey = 'analytics_enabled';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> analyticsEnabled() async {
    return (await _prefs()).getBool(analyticsEnabledKey) ?? true;
  }

  static Future<void> setAnalyticsEnabled(bool value) async {
    await (await _prefs()).setBool(analyticsEnabledKey, value);
  }
}
