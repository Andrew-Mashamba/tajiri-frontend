import 'package:flutter/services.dart';

/// Platform-channel wrapper to block / allow screenshots on sensitive screens.
/// Android uses FLAG_SECURE; iOS uses UITextField secureTextEntry workaround
/// or a dedicated plugin. Web/desktop are NO-OP.
class ScreenshotBlocker {
  static const MethodChannel _channel = MethodChannel('tajiri/screenshot');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<void>('block');
    } catch (_) {
      // NO-OP on unsupported platforms
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('unblock');
    } catch (_) {
      // NO-OP on unsupported platforms
    }
  }
}
