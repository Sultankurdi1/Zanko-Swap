import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;
  static String? _registeredToken;
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await _registerCurrentDevice();
    FirebaseMessaging.onMessage.listen((message) {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final title = message.notification?.title ?? 'ZankoSwap';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
        );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      navigatorKey.currentState?.pushNamed('/services');
    });
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed('/services');
      });
    }
    messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) unawaited(_registerCurrentDevice());
    });
    _initialized = true;
  }

  static Future<void> _registerCurrentDevice() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _saveToken(token);
    } catch (_) {}
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final previousToken = _registeredToken;
      if (previousToken != null && previousToken != token) {
        await Supabase.instance.client
            .from('user_devices')
            .delete()
            .eq('user_id', user.id)
            .eq('fcm_token', previousToken);
      }

      await Supabase.instance.client.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');
      _registeredToken = token;
    } catch (_) {}
  }

  static Future<void> unregisterCurrentDevice() async {
    if (!_initialized) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await Supabase.instance.client
          .from('user_devices')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', token);
      _registeredToken = null;
    } catch (_) {}
  }
}
