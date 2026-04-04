import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

/// Utility class for launching the native SMS app with pre-filled content
class SmsLauncher {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Opens the native SMS app with pre-filled recipient and message
  ///
  /// [phoneNumber] - The recipient's phone number (e.g., "+255754111112")
  /// [message] - The message body to pre-fill
  ///
  /// Returns true if SMS app was launched successfully, false otherwise
  static Future<bool> openSmsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      _logger.i('Opening SMS app for: $phoneNumber');

      // Encode the message body properly
      final encodedMessage = Uri.encodeComponent(message);

      // iOS uses '&' separator, Android uses '?'
      final separator = Platform.isIOS ? '&' : '?';

      // Construct the SMS URI
      final smsUri = Uri.parse('sms:$phoneNumber${separator}body=$encodedMessage');

      _logger.d('SMS URI: $smsUri');

      // Check if we can launch this URI
      if (await canLaunchUrl(smsUri)) {
        final launched = await launchUrl(smsUri);
        _logger.i('SMS app launched: $launched');
        return launched;
      } else {
        _logger.w('Cannot launch SMS app');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error opening SMS app', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
