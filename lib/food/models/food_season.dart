enum FoodSeason {
  none,
  ramadhan,
  christmas,
  easter,
  sundayFunguLaKumi,
}

extension FoodSeasonX on FoodSeason {
  String get titleSwahili {
    switch (this) {
      case FoodSeason.ramadhan:
        return 'Iftari ya Leo';
      case FoodSeason.christmas:
        return 'Christmas Lunch';
      case FoodSeason.easter:
        return 'Pasaka ya Pamoja';
      case FoodSeason.sundayFunguLaKumi:
        return 'Fungu la Kumi Jumapili';
      case FoodSeason.none:
        return '';
    }
  }

  String get subtitleSwahili {
    switch (this) {
      case FoodSeason.ramadhan:
        return 'Misikiti karibu inahitaji chakula cha iftari usiku huu';
      case FoodSeason.christmas:
        return 'Makanisa yanawalisha watu Krismasi — changia chakula';
      case FoodSeason.easter:
        return 'Pasaka — makanisa yanawalisha watu. Changia mlo';
      case FoodSeason.sundayFunguLaKumi:
        return 'Kanisa lako linawalisha watu leo — changia mlo mmoja';
      case FoodSeason.none:
        return '';
    }
  }

  String get emoji {
    switch (this) {
      case FoodSeason.ramadhan:
        return '🌙';
      case FoodSeason.christmas:
        return '✝️';
      case FoodSeason.easter:
        return '✝️';
      case FoodSeason.sundayFunguLaKumi:
        return '⛪';
      case FoodSeason.none:
        return '';
    }
  }

  /// Which beneficiary type this season targets.
  /// Returns null for seasons with no type filter.
  String? get beneficiaryTypeFilter {
    switch (this) {
      case FoodSeason.ramadhan:
        return 'msikiti';
      case FoodSeason.christmas:
      case FoodSeason.easter:
      case FoodSeason.sundayFunguLaKumi:
        return 'kanisa';
      case FoodSeason.none:
        return null;
    }
  }
}

class FoodSeasonDetector {
  /// Detect the currently-active seasonal surface based on [now].
  /// Simple heuristic:
  ///   - Feb–Mar: Ramadhan (Islamic lunar calendar shifts yearly; month-based for MVP)
  ///   - April: Easter
  ///   - December: Christmas
  ///   - Otherwise Sunday: fungu la kumi
  ///   - Otherwise: no active seasonal surface
  static FoodSeason detect([DateTime? now]) {
    final n = now ?? DateTime.now();
    if (n.month == 2 || n.month == 3) return FoodSeason.ramadhan;
    if (n.month == 4) return FoodSeason.easter;
    if (n.month == 12) return FoodSeason.christmas;
    if (n.weekday == DateTime.sunday) return FoodSeason.sundayFunguLaKumi;
    return FoodSeason.none;
  }
}
