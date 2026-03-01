class SchoolRegion {
  final String region;
  final String regionCode;
  final int schoolCount;

  SchoolRegion({
    required this.region,
    required this.regionCode,
    required this.schoolCount,
  });

  factory SchoolRegion.fromJson(Map<String, dynamic> json) {
    return SchoolRegion(
      region: json['region'] ?? '',
      regionCode: json['region_code'] ?? '',
      schoolCount: json['school_count'] ?? 0,
    );
  }
}

class SchoolDistrict {
  final String district;
  final String districtCode;
  final int schoolCount;

  SchoolDistrict({
    required this.district,
    required this.districtCode,
    required this.schoolCount,
  });

  factory SchoolDistrict.fromJson(Map<String, dynamic> json) {
    return SchoolDistrict(
      district: json['district'] ?? '',
      districtCode: json['district_code'] ?? '',
      schoolCount: json['school_count'] ?? 0,
    );
  }
}

class School {
  final int id;
  final String code;
  final String name;
  final String type;
  final String? region;
  final String? district;

  School({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.region,
    this.district,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
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

class SchoolStats {
  final int totalSchools;
  final int governmentSchools;
  final int privateSchools;
  final int regionsCount;
  final int districtsCount;

  SchoolStats({
    required this.totalSchools,
    required this.governmentSchools,
    required this.privateSchools,
    required this.regionsCount,
    required this.districtsCount,
  });

  factory SchoolStats.fromJson(Map<String, dynamic> json) {
    return SchoolStats(
      totalSchools: json['total_schools'] ?? 0,
      governmentSchools: json['government_schools'] ?? 0,
      privateSchools: json['private_schools'] ?? 0,
      regionsCount: json['regions_count'] ?? 0,
      districtsCount: json['districts_count'] ?? 0,
    );
  }
}

class SelectedSchool {
  final SchoolRegion? region;
  final SchoolDistrict? district;
  final School? school;

  SelectedSchool({
    this.region,
    this.district,
    this.school,
  });

  bool get isComplete => school != null;

  Map<String, dynamic> toJson() {
    return {
      'school_id': school?.id,
      'school_code': school?.code,
      'school_name': school?.name,
      'school_type': school?.type,
      'region': region?.region,
      'region_code': region?.regionCode,
      'district': district?.district,
      'district_code': district?.districtCode,
    };
  }

  String get displayText {
    if (school == null) return '';
    return '${school!.name}\n${district?.district ?? ''}, ${region?.region ?? ''}';
  }
}
