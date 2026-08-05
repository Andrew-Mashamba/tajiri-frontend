// API Configuration — switch between local and remote backend

class ApiConfig {
  // Remote backend (production/UAT) — legacy Laravel REST
  static const String baseUrl = 'https://tajiri.zimasystems.com/api';
  static const String storageUrl = 'https://tajiri.zimasystems.com/storage';

  // Greenfield GraphQL backend (TAJIRI-BACKEND). Enable via:
  //   flutter run --dart-define=USE_GRAPHQL=true
  //   flutter run --dart-define=USE_GRAPHQL=true --dart-define=GRAPHQL_URL=http://10.0.2.2:8000/graphql
  static const bool useGraphqlBackend =
      bool.fromEnvironment('USE_GRAPHQL', defaultValue: false);
  static const String graphqlUrl = String.fromEnvironment(
    'GRAPHQL_URL',
    defaultValue: 'http://127.0.0.1:8000/graphql',
  );

  /// Media base when using the greenfield backend (FastAPI storage_url).
  static const String graphqlStorageUrl = String.fromEnvironment(
    'GRAPHQL_STORAGE_URL',
    defaultValue: 'http://127.0.0.1:8000/media/files',
  );

  /// Multipart media upload endpoint on greenfield backend (not GraphQL).
  static String get graphqlMediaUploadUrl {
    final base = graphqlUrl.replaceFirst(RegExp(r'/graphql/?$'), '');
    return '$base/media/upload';
  }

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

  // Same as [authHeaders] but skips any X-Trace-Id we'd otherwise inject;
  // used by digest/summary endpoints where trace propagation isn't desired.
  static Map<String, String> authHeadersWithoutTrace(String token) =>
      authHeaders(token);

  /// WebSocket URL for Laravel Reverb (call signaling). If null, derived from [baseUrl] (same host, /app/{reverbAppKey}).
  /// Set explicitly if Reverb runs on a different host/port.
  static String? reverbWsUrl;

  /// Reverb WebSocket port (external). Nginx proxies 6001 → internal 6002.
  static const int reverbPort = 6001;

  /// Resolved WebSocket URL for Reverb. Uses [reverbWsUrl] if set; otherwise builds from [baseUrl].
  static String? get reverbWsUrlResolved {
    if (reverbWsUrl != null && reverbWsUrl!.isNotEmpty) return reverbWsUrl;
    try {
      final uri = Uri.parse(baseUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${uri.host}:$reverbPort/app/$reverbAppKey';
    } catch (_) {
      return null;
    }
  }

  /// Reverb app key (used in connection path). Must match backend REVERB_APP_KEY.
  static String get reverbAppKey => 'tajiri-reverb-key-2026';

  /// Base URL for broadcasting auth (private channel subscription). Derived from baseUrl if not set.
  static String get broadcastAuthBaseUrl {
    if (baseUrl.startsWith('http')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme == 'https' ? 'https' : 'http'}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
    return baseUrl.replaceFirst(RegExp(r'/api$'), '');
  }

  /// Sanitize URLs from backend to ensure HTTPS
  /// Normalizes URLs from backend responses
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Convert HTTP to HTTPS for our backend URLs
    if (url.startsWith('http://tajiri.zimasystems.com')) {
      return url; // Already correct
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
