import 'dart:io';

import 'package:bobadex/navigation.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/friend_requests_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Friend-request pushes. The system shows the banner; a tap opens Friends.
class PushRegistration {
  static bool _listening = false;

  static Future<void> sync() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return;

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        final apns = await messaging.getAPNSToken();
        if (apns == null) return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _save(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  static void listen() {
    if (_listening) return;
    _listening = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _save(token);
    });
    FirebaseMessaging.onMessage.listen((message) {
      if (!Platform.isAndroid) return;
      final body = message.notification?.body;
      if (body == null || body.isEmpty) return;
      notify(body, SnackType.info);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _open(message);
    });
  }

  static Future<void> removeCurrent() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final token = await FirebaseMessaging.instance.getToken();
      if (userId == null || token == null || token.isEmpty) return;
      await Supabase.instance.client
          .from('device_push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', token);
    } catch (e) {
      debugPrint('Push token removal failed: $e');
    }
  }

  static Future<void> _save(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || token.isEmpty) return;
    await Supabase.instance.client.rpc(
      'register_push_token',
      params: {
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }

  static Future<void> _open(RemoteMessage message) async {
    final kind = message.data['kind'];
    await goRoot('/friends');
    if (kind != 'friend_request') return;
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const FriendRequestsPage()));
  }
}
