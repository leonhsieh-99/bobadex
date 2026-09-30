import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/helpers/app_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class CountyLocator {
  Future<String?> currentCountyPlaceId(CollectionRepository repo) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (await AppPrefs.locationPrompted()) return null;
        permission = await Geolocator.requestPermission();
        await AppPrefs.setLocationPrompted();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return await repo.countyPlaceIdAt(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (e) {
      debugPrint('county location failed: $e');
      return null;
    }
  }
}
