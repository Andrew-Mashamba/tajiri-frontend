/// Lightweight client-side check for banned / risky terms in product text (diary, etc.).
class SkincareIngredientSafety {
  SkincareIngredientSafety._();

  static const Set<String> _bannedSubstrings = {
    'mercury',
    'mercurous chloride',
    'mercuric chloride',
    'ammoniated mercury',
    'hydroquinone',
    'clobetasol',
    'clobetasol propionate',
    'betamethasone',
    'lead',
    'lead acetate',
    'tretinoin',
  };

  /// Returns true if any banned substring appears in [text] (case-insensitive).
  static bool textMayContainBanned(String text) {
    final lower = text.toLowerCase();
    for (final b in _bannedSubstrings) {
      if (lower.contains(b)) return true;
    }
    return false;
  }
}
