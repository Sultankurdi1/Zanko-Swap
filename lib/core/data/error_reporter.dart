import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorReporter {
  ErrorReporter._();

  static const appVersion = '1.1.0+2';
  static const _maxPerSession = 20;
  static final _sent = <String>{};

  static void install() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true;
    };
  }

  static void report(Object error, StackTrace? stack) {
    if (kDebugMode) return;
    final message = error.toString();
    if (_sent.length >= _maxPerSession || !_sent.add(message)) return;
    unawaited(_send(message, stack?.toString() ?? ''));
  }

  static Future<void> _send(String message, String stack) async {
    try {
      await Supabase.instance.client.rpc(
        'log_app_error',
        params: {
          'message': message,
          'stack': stack,
          'platform': defaultTargetPlatform.name,
          'app_version': appVersion,
        },
      );
    } catch (_) {}
  }
}
