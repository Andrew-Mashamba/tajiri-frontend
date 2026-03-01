/// Models for Secondary Schools (O-Level) and A-Level Schools

class SecondarySchool {
  final int id;
  final String code;
  final String name;
  final String type;
  final String? regionCode;
  final String? districtCode;
  final String? region;
  final String? district;

  SecondarySchool({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.regionCode,
    this.districtCode,
    this.region,
    this.district,
  });

  factory SecondarySchool.fromJson(Map<String, dynamic> json) {
    return SecondarySchool(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
      regionCode: json['region_code'],
      districtCode: json['district_code'],
      region: json['region'],
      district: json['district'],
    );
  }

  String get displayName => '$name ($code)';

  String get typeLabel {
    switch (type) {
      case 'government':
        return 'Serikali';
      case 'private':
        return 'Binafsi';
      default:
        return 'Haijulikani';
    }
  }
}

class AlevelSchool {
  final int id;
  final String code;
  final String name;
  final String type;
  final String? regionCode;
  final String? districtCode;
  final String? region;
  final String? district;
  final List<String>? combinationCodes;

  AlevelSchool({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.regionCode,
    this.districtCode,
    this.region,
    this.district,
    this.combinationCodes,
  });

  factory AlevelSchool.fromJson(Map<String, dynamic> json) {
    return AlevelSchool(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
      regionCode: json['region_code'],
      districtCode: json['district_code'],
      region: json['region'],
      district: json['district'],
      combinationCodes: json['combinations'] != null
          ? List<String>.from(json['combinations'])
          : null,
    );
  }

  String get displayName => '$name ($code)';

  String get typeLabel {
    switch (type) {
      case 'government':
        return 'Serikali';
      case 'private':
        return 'Binafsi';
      default:
        return 'Haijulikani';
    }
  }
}

class AlevelCombination {
  final int id;
  final String code;
  final String name;
  final String category;
  final String popularity;
  final List<String> subjects;
  final List<String>? careers;

  AlevelCombination({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.popularity,
    required this.subjects,
    this.careers,
  });

  factory AlevelCombination.fromJson(Map<String, dynamic> json) {
    return AlevelCombination(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      popularity: json['popularity'] ?? 'medium',
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'])
          : [],
      careers:
          json['careers'] != null ? List<String>.from(json['careers']) : null,
    );
  }

  String get displayName => '$code - $name';

  String get categoryLabel {
    switch (category) {
      case 'science':
        return 'Sayansi';
      case 'business':
        return 'Biashara';
      case 'arts':
        return 'Sanaa';
      case 'language':
        return 'Lugha';
      case 'religious':
        return 'Dini';
      default:
        return category;
    }
  }

  bool get isPopular => popularity == 'high';
}

class AlevelSubject {
  final int id;
  final String code;
  final String name;
  final String category;

  AlevelSubject({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
  });

  factory AlevelSubject.fromJson(Map<String, dynamic> json) {
    return AlevelSubject(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class SecondaryRegion {
  final String region;
  final String regionCode;
  final int schoolCount;

  SecondaryRegion({
    required this.region,
    required this.regionCode,
    required this.schoolCount,
  });

  factory SecondaryRegion.fromJson(Map<String, dynamic> json) {
    return SecondaryRegion(
      region: json['region'] ?? '',
      regionCode: json['region_code'] ?? '',
      schoolCount: json['school_count'] ?? 0,
    );
  }
}

class SecondaryDistrict {
  final String district;
  final String districtCode;
  final int schoolCount;

  SecondaryDistrict({
    required this.district,
    required this.districtCode,
    required this.schoolCount,
  });

  factory SecondaryDistrict.fromJson(Map<String, dynamic> json) {
    return SecondaryDistrict(
      district: json['district'] ?? '',
      districtCode: json['district_code'] ?? '',
      schoolCount: json['school_count'] ?? 0,
    );
  }
}
