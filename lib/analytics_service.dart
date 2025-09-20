import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _fa;
  AnalyticsService(this._fa);

  Future<void> setUser(String? userId) async {
    await _fa.setUserId(id: userId);
  }

  Future<void> setUserProps({required String theme, required int gridCols}) async {
    await _fa.setUserProperty(name: 'theme_slug', value: theme);
    await _fa.setUserProperty(name: 'grid_columns', value: '$gridCols');
  }

  Future<void> shopAdded({required double rating, String? brandSlug}) {
    return _fa.logEvent(
      name: 'shop_added',
      parameters: {
        'rating': rating,
        if (brandSlug != null) 'brand_slug': brandSlug,
      },
    );
  }

  Future<void> drinkAdded({required double rating, required String name}) {
    return _fa.logEvent(
      name: 'drink_added',
      parameters: {
        'name': name,
        'rating': rating,
      }
    );
  }

  Future<void> mediaUploaded({required String shopId, required int count}) {
    return _fa.logEvent(
      name: 'media_upload',
      parameters: {
        'shop_id': shopId,
        'count': count, // log once per submit
      },
    );
  }

  Future<void> friendRequestSent() => _fa.logEvent(name: 'friend_request_sent');
  Future<void> friendRequestAccepted() => _fa.logEvent(name: 'friend_request_accepted');
}
