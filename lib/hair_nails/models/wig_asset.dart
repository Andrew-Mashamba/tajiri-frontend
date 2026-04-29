/// Visual style category for a wig.
enum WigStyle {
  straight,
  wavy,
  curly,
}

/// Length category for a wig.
enum WigLength {
  short,
  medium,
  long,
}

/// Metadata for a single processed wig PNG asset.
class WigAsset {
  const WigAsset({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.assetPath,
    required this.style,
    required this.length,
  });

  /// Unique identifier (matches the filename stem after `wig_`).
  final String id;

  /// Display name in English.
  final String nameEn;

  /// Display name in Swahili.
  final String nameSw;

  /// Flutter asset path — e.g. `assets/filter_assets/wigs_processed/wig_black_curly.png`.
  final String assetPath;

  /// Visual style of this wig.
  final WigStyle style;

  /// Length category of this wig.
  final WigLength length;
}

/// Catalogue of all processed wig assets.
class WigAssets {
  WigAssets._();

  static const String _base = 'assets/filter_assets/wigs_processed';

  // --------------------------------------------------------------------------
  // Individual assets
  // --------------------------------------------------------------------------

  static const WigAsset blackWhiteWave = WigAsset(
    id: 'black_white_wave',
    nameEn: 'Black & White Wave',
    nameSw: 'Wimbi Nyeusi na Nyeupe',
    assetPath: '$_base/wig_black_white_wave.png',
    style: WigStyle.wavy,
    length: WigLength.long,
  );

  static const WigAsset honeyBrownStraight = WigAsset(
    id: 'honey_brown_straight',
    nameEn: 'Honey Brown Straight',
    nameSw: 'Kahawia Asali Nyofu',
    assetPath: '$_base/wig_honey_brown_straight.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  static const WigAsset chocolateWave = WigAsset(
    id: 'chocolate_wave',
    nameEn: 'Chocolate Wave',
    nameSw: 'Wimbi la Chokoleti',
    assetPath: '$_base/wig_chocolate_wave.png',
    style: WigStyle.wavy,
    length: WigLength.long,
  );

  static const WigAsset blackCurly = WigAsset(
    id: 'black_curly',
    nameEn: 'Black Curly',
    nameSw: 'Nyeusi Kupindapinda',
    assetPath: '$_base/wig_black_curly.png',
    style: WigStyle.curly,
    length: WigLength.medium,
  );

  static const WigAsset ashBlondeStraight = WigAsset(
    id: 'ash_blonde_straight',
    nameEn: 'Ash Blonde Straight',
    nameSw: 'Blonde Majivu Nyofu',
    assetPath: '$_base/wig_ash_blonde_straight.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  static const WigAsset blondeWavy = WigAsset(
    id: 'blonde_wavy',
    nameEn: 'Blonde Wavy',
    nameSw: 'Blonde Mawimbi',
    assetPath: '$_base/wig_blonde_wavy.png',
    style: WigStyle.wavy,
    length: WigLength.long,
  );

  static const WigAsset auburnBob = WigAsset(
    id: 'auburn_bob',
    nameEn: 'Auburn Bob',
    nameSw: 'Bob Kahawia-Nyekundu',
    assetPath: '$_base/wig_auburn_bob.png',
    style: WigStyle.straight,
    length: WigLength.medium,
  );

  static const WigAsset silverStraight = WigAsset(
    id: 'silver_straight',
    nameEn: 'Silver Straight',
    nameSw: 'Fedha Nyofu',
    assetPath: '$_base/wig_silver_straight.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  static const WigAsset platinumBlonde = WigAsset(
    id: 'platinum_blonde',
    nameEn: 'Platinum Blonde',
    nameSw: 'Platinamu Blonde',
    assetPath: '$_base/wig_platinum_blonde.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  static const WigAsset sandyBlondeWave = WigAsset(
    id: 'sandy_blonde_wave',
    nameEn: 'Sandy Blonde Wave',
    nameSw: 'Blonde Mchanga Wimbi',
    assetPath: '$_base/wig_sandy_blonde_wave.png',
    style: WigStyle.wavy,
    length: WigLength.long,
  );

  static const WigAsset jetBlackSleek = WigAsset(
    id: 'jet_black_sleek',
    nameEn: 'Jet Black Sleek',
    nameSw: 'Nyeusi Laini',
    assetPath: '$_base/wig_jet_black_sleek.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  static const WigAsset caramelBrown = WigAsset(
    id: 'caramel_brown',
    nameEn: 'Caramel Brown',
    nameSw: 'Kahawia Karameli',
    assetPath: '$_base/wig_caramel_brown.png',
    style: WigStyle.straight,
    length: WigLength.long,
  );

  // --------------------------------------------------------------------------
  // Master list
  // --------------------------------------------------------------------------

  /// All 12 wig assets in display order.
  static const List<WigAsset> all = <WigAsset>[
    blackWhiteWave,
    honeyBrownStraight,
    chocolateWave,
    blackCurly,
    ashBlondeStraight,
    blondeWavy,
    auburnBob,
    silverStraight,
    platinumBlonde,
    sandyBlondeWave,
    jetBlackSleek,
    caramelBrown,
  ];
}
