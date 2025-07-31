import 'package:flutter/material.dart';

class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() action, {
    int retries = 3,
    Duration delay = const Duration(milliseconds: 500),
    bool exponentialBackoff = true,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action(); // success
      } catch (e) {
        attempt++;
        debugPrint('Retry attempt $attempt failed: $e');

        if (attempt >= retries) rethrow;

        final wait = exponentialBackoff
            ? delay * (1 << (attempt - 1))
            : delay;
        await Future.delayed(wait);
      }
    }
  }
}