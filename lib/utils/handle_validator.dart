/// Client-side handle (username) validation, suggestion, and blocklist logic.
///
/// Backend `/users/check-handle` is the source of truth for uniqueness.
/// This util performs cheap format/reserved/profanity rejection so the
/// network call only fires for plausible candidates.
class HandleValidationResult {
  final bool isValid;

  /// One of: too_short, too_long, starts_with_number, invalid_chars,
  /// consecutive_underscores, ends_with_underscore, reserved, profanity.
  final String? errorKey;

  const HandleValidationResult({required this.isValid, this.errorKey});
}

class HandleValidator {
  /// Reserved system handles. Lowercase only.
  static const Set<String> _reserved = {
    'admin', 'administrator', 'root', 'system', 'support', 'help', 'helpdesk',
    'tajiri', 'tajirihq', 'official', 'staff', 'team', 'mod', 'moderator',
    'api', 'www', 'web', 'mobile', 'app',
    'null', 'undefined', 'anonymous', 'guest', 'user', 'me', 'i',
    'login', 'signup', 'register', 'auth', 'security', 'privacy', 'terms',
    'tos', 'about', 'contact', 'home', 'feed', 'profile', 'settings',
    'shop', 'store', 'market', 'shangazi', 'mzee', 'baba', 'mama',
  };

  /// Minimal profanity blocklist (English + Swahili).
  /// Server-side moderation is authoritative; this only catches obvious cases.
  static const Set<String> _profanity = {
    'shit', 'fuck', 'bitch', 'asshole', 'bastard', 'cunt', 'nigger', 'nigga',
    'mboo', 'kuma', 'malaya', 'mshenzi', 'umbwa',
  };

  static final RegExp _formatRegex = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  static HandleValidationResult validate(String raw) {
    final h = raw.trim().toLowerCase();
    if (h.length < 3) {
      return const HandleValidationResult(isValid: false, errorKey: 'too_short');
    }
    if (h.length > 20) {
      return const HandleValidationResult(isValid: false, errorKey: 'too_long');
    }
    if (RegExp(r'^[0-9_]').hasMatch(h)) {
      return const HandleValidationResult(
        isValid: false,
        errorKey: 'starts_with_number',
      );
    }
    if (h.endsWith('_')) {
      return const HandleValidationResult(
        isValid: false,
        errorKey: 'ends_with_underscore',
      );
    }
    if (!_formatRegex.hasMatch(h)) {
      return const HandleValidationResult(
        isValid: false,
        errorKey: 'invalid_chars',
      );
    }
    if (h.contains('__')) {
      return const HandleValidationResult(
        isValid: false,
        errorKey: 'consecutive_underscores',
      );
    }
    if (_reserved.contains(h)) {
      return const HandleValidationResult(isValid: false, errorKey: 'reserved');
    }
    if (_profanity.any((bad) => h.contains(bad))) {
      return const HandleValidationResult(isValid: false, errorKey: 'profanity');
    }
    return const HandleValidationResult(isValid: true);
  }

  static String errorSwahili(String? key) {
    switch (key) {
      case 'too_short':
        return 'Lazima iwe na herufi 3 au zaidi';
      case 'too_long':
        return 'Isizidi herufi 20';
      case 'starts_with_number':
        return 'Anza na herufi (a-z)';
      case 'invalid_chars':
        return 'Tumia herufi ndogo (a-z), namba (0-9), na _ pekee';
      case 'consecutive_underscores':
        return 'Usiweke _ mbili mfululizo';
      case 'ends_with_underscore':
        return 'Usimalize na _';
      case 'reserved':
        return 'Jina hili limehifadhiwa';
      case 'profanity':
        return 'Jina hili silitumiki, chagua lingine';
      default:
        return 'Jina si halali';
    }
  }

  /// Generates up to 4 plausible handle candidates that already pass
  /// [validate]. Caller should still confirm uniqueness via the API.
  static List<String> suggest({
    required String firstName,
    String? middleName,
    required String lastName,
    DateTime? dob,
  }) {
    String slug(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final first = slug(firstName);
    final last = slug(lastName);
    final mid = (middleName != null && middleName.isNotEmpty)
        ? slug(middleName)
        : '';
    final yy = dob != null ? (dob.year % 100).toString().padLeft(2, '0') : '';

    String cap(String s, int n) => s.length > n ? s.substring(0, n) : s;

    final raw = <String>[
      if (first.isNotEmpty && last.isNotEmpty)
        cap('${first}_$last', 20),
      if (first.isNotEmpty && last.isNotEmpty) cap('$first$last', 20),
      if (first.isNotEmpty && yy.isNotEmpty) cap('$first$yy', 20),
      if (first.isNotEmpty && last.isNotEmpty && yy.isNotEmpty)
        cap('${first}_${last}_$yy', 20),
      if (first.isNotEmpty && last.isNotEmpty)
        cap('${first.substring(0, 1)}$last', 20),
      if (first.isNotEmpty && mid.isNotEmpty && last.isNotEmpty)
        cap('$first${mid.substring(0, 1)}$last', 20),
    ];

    final seen = <String>{};
    final out = <String>[];
    for (final s in raw) {
      if (seen.contains(s)) continue;
      seen.add(s);
      if (validate(s).isValid) out.add(s);
      if (out.length >= 4) break;
    }
    return out;
  }
}
