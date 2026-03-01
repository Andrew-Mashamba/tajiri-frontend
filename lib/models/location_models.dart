class Region {
  final int id;
  final String name;
  final String? postCode;

  Region({
    required this.id,
    required this.name,
    this.postCode,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'],
      name: json['name'],
      postCode: json['post_code'],
    );
  }

  @override
  String toString() => name;
}

class District {
  final int id;
  final int regionId;
  final String name;
  final String? postCode;

  District({
    required this.id,
    required this.regionId,
    required this.name,
    this.postCode,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      regionId: json['region_id'],
      name: json['name'],
      postCode: json['post_code'],
    );
  }

  @override
  String toString() => name;
}

class Ward {
  final int id;
  final int districtId;
  final String name;
  final String? postCode;

  Ward({
    required this.id,
    required this.districtId,
    required this.name,
    this.postCode,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'],
      districtId: json['district_id'],
      name: json['name'],
      postCode: json['post_code'],
    );
  }

  @override
  String toString() => name;
}

class Street {
  final int id;
  final int wardId;
  final String name;

  Street({
    required this.id,
    required this.wardId,
    required this.name,
  });

  factory Street.fromJson(Map<String, dynamic> json) {
    return Street(
      id: json['id'],
      wardId: json['ward_id'],
      name: json['name'],
    );
  }

  @override
  String toString() => name;
}

class UserLocation {
  final Region? region;
  final District? district;
  final Ward? ward;
  final Street? street;

  UserLocation({
    this.region,
    this.district,
    this.ward,
    this.street,
  });

  bool get isComplete =>
      region != null && district != null && ward != null && street != null;

  String get fullAddress {
    final parts = <String>[];
    if (street != null) parts.add(street!.name);
    if (ward != null) parts.add(ward!.name);
    if (district != null) parts.add(district!.name);
    if (region != null) parts.add(region!.name);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'region_id': region?.id,
      'district_id': district?.id,
      'ward_id': ward?.id,
      'street_id': street?.id,
    };
  }
}
