import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Wraps [child] in a screen that blocks system screen-capture.
///
/// Tanzania's Personal Data Protection Act 2022 requires sensitive personal
/// data (medical records, legal NDAs, ID uploads, prescriptions) be protected
/// against incidental disclosure. On Android we set [FLAG_SECURE] on the
/// window for the duration of this screen; on iOS the protection is a
/// best-effort no-op for now (iOS doesn't expose a system-level screenshot
/// block — a snapshot-overlay implementation is tracked as follow-up work).
///
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return SecureScreen(child: Scaffold(...));
/// }
/// ```
class SecureScreen extends StatefulWidget {
  final Widget child;

  const SecureScreen({super.key, required this.child});

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const _channel = MethodChannel('tajiri/secure_screen');

  @override
  void initState() {
    super.initState();
    _setSecure(true);
  }

  @override
  void dispose() {
    _setSecure(false);
    super.dispose();
  }

  Future<void> _setSecure(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecure', {'enabled': enabled});
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureScreen] setSecure($enabled) failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
