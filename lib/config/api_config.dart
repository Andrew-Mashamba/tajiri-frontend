// API Configuration — switch between local and remote backend

class ApiConfig {
  // Remote backend (production/UAT)
  static const String baseUrl = 'https://zima-uat.site:8003/api';
  static const String storageUrl = 'https://zima-uat.site:8003/storage';

  // Local backend (for development)
  // static const String baseUrl = 'http://127.0.0.1:1617/api';
  // static const String storageUrl = 'http://127.0.0.1:1617/storage';

  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers with auth token
  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  /// WebSocket URL for Laravel Reverb (call signaling). If null, derived from [baseUrl] (same host, /app/{reverbAppKey}).
  /// Set explicitly if Reverb runs on a different host/port.
  static String? reverbWsUrl;

  /// Resolved WebSocket URL for Reverb. Uses [reverbWsUrl] if set; otherwise builds from [baseUrl].
  static String? get reverbWsUrlResolved {
    if (reverbWsUrl != null && reverbWsUrl!.isNotEmpty) return reverbWsUrl;
    try {
      final uri = Uri.parse(baseUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final port = uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '';
      return '$scheme://${uri.host}$port/app/$reverbAppKey';
    } catch (_) {
      return null;
    }
  }

  /// Reverb app key (used in connection path). Default for Laravel Reverb.
  static String get reverbAppKey => 'reverb-key';

  /// Base URL for broadcasting auth (private channel subscription). Derived from baseUrl if not set.
  static String get broadcastAuthBaseUrl {
    if (baseUrl.startsWith('http')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme == 'https' ? 'https' : 'http'}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
    return baseUrl.replaceFirst(RegExp(r'/api$'), '');
  }

  /// Sanitize URLs from backend to ensure HTTPS
  /// Converts http:// to https:// for zima-uat.site URLs
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Convert HTTP to HTTPS for our backend URLs
    if (url.startsWith('http://zima-uat.site')) {
      return url.replaceFirst('http://', 'https://');
    }

    // Handle localhost URLs - convert to storage URL
    if (url.startsWith('http://localhost:8000/storage/') ||
        url.startsWith('http://127.0.0.1:8000/storage/')) {
      final path = url.split('/storage/').last;
      return '$storageUrl/$path';
    }

    return url;
  }
}
