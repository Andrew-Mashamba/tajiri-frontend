/// Models for Post-secondary, University, and Business/Employer

class PostsecondaryInstitution {
  final int id;
  final String code;
  final String name;
  final String? acronym;
  final String type;
  final String category;
  final String? region;

  PostsecondaryInstitution({
    required this.id,
    required this.code,
    required this.name,
    this.acronym,
    required this.type,
    required this.category,
    this.region,
  });

  factory PostsecondaryInstitution.fromJson(Map<String, dynamic> json) {
    return PostsecondaryInstitution(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      acronym: json['acronym'],
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      region: json['region'],
    );
  }

  String get displayName => acronym != null ? '$name ($acronym)' : name;

  String get categoryLabel {
    switch (category) {
      case 'vocational_training':
        return 'VETA';
      case 'teacher_training':
        return 'Ualimu';
      case 'health_medical':
        return 'Afya';
      case 'technical_polytechnic':
        return 'Ufundi';
      case 'agricultural':
        return 'Kilimo';
      default:
        return category;
    }
  }
}

class PostsecondaryDepartment {
  final int id;
  final String code;
  final String name;
  final int institutionId;

  PostsecondaryDepartment({
    required this.id,
    required this.code,
    required this.name,
    required this.institutionId,
  });

  factory PostsecondaryDepartment.fromJson(Map<String, dynamic> json) {
    return PostsecondaryDepartment(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      institutionId: json['institution_id'] ?? 0,
    );
  }
}

class PostsecondaryProgramme {
  final int id;
  final String code;
  final String name;
  final String levelCode;
  final int duration;
  final int? departmentId;
  final int institutionId;

  PostsecondaryProgramme({
    required this.id,
    required this.code,
    required this.name,
    required this.levelCode,
    required this.duration,
    this.departmentId,
    required this.institutionId,
  });

  factory PostsecondaryProgramme.fromJson(Map<String, dynamic> json) {
    return PostsecondaryProgramme(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      levelCode: json['level_code'] ?? '',
      duration: json['duration'] ?? 0,
      departmentId: json['department_id'],
      institutionId: json['institution_id'] ?? 0,
    );
  }

  String get levelLabel {
    switch (levelCode) {
      case 'NVA1':
        return 'NVA Level 1';
      case 'NVA2':
        return 'NVA Level 2';
      case 'NVA3':
        return 'NVA Level 3';
      case 'NTA4':
        return 'NTA Level 4';
      case 'NTA5':
        return 'NTA Level 5';
      case 'NTA6':
        return 'NTA Level 6 (Diploma)';
      case 'CERT':
        return 'Certificate';
      case 'DIP':
        return 'Diploma';
      default:
        return levelCode;
    }
  }
}

class University {
  final int id;
  final String code;
  final String name;
  final String? acronym;
  final String type;
  final String? ownership;
  final String? region;

  University({
    required this.id,
    required this.code,
    required this.name,
    this.acronym,
    required this.type,
    this.ownership,
    this.region,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      acronym: json['acronym'],
      type: json['type'] ?? '',
      ownership: json['ownership'],
      region: json['region'],
    );
  }

  String get displayName => acronym != null ? '$acronym - $name' : name;

  String get typeLabel {
    switch (type) {
      case 'public_university':
        return 'Chuo Kikuu cha Serikali';
      case 'private_university':
        return 'Chuo Kikuu cha Binafsi';
      case 'public_college':
        return 'Chuo cha Serikali';
      case 'private_college':
        return 'Chuo cha Binafsi';
      default:
        return type;
    }
  }

  bool get isPublic => ownership == 'public' || type.startsWith('public_');
}

class UniversityDetailed {
  final int id;
  final String code;
  final String name;
  final String? acronym;
  final String type;
  final String? region;
  final int? established;
  final String? website;

  UniversityDetailed({
    required this.id,
    required this.code,
    required this.name,
    this.acronym,
    required this.type,
    this.region,
    this.established,
    this.website,
  });

  factory UniversityDetailed.fromJson(Map<String, dynamic> json) {
    return UniversityDetailed(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      acronym: json['acronym'],
      type: json['type'] ?? '',
      region: json['region'],
      established: json['established'],
      website: json['website'],
    );
  }

  String get displayName => acronym != null ? '$acronym - $name' : name;

  String get typeLabel {
    switch (type) {
      case 'public_university':
        return 'Chuo Kikuu cha Serikali';
      case 'private_university':
        return 'Chuo Kikuu Binafsi';
      case 'public_college':
        return 'Chuo cha Serikali';
      case 'private_college':
        return 'Chuo Binafsi';
      case 'public_institute':
        return 'Taasisi ya Serikali';
      case 'private_institute':
        return 'Taasisi Binafsi';
      default:
        return type;
    }
  }

  bool get isPublic => type.startsWith('public_');
}

class UniversityCollege {
  final int id;
  final String code;
  final String name;
  final String? type;
  final int universityId;

  UniversityCollege({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    required this.universityId,
  });

  factory UniversityCollege.fromJson(Map<String, dynamic> json) {
    return UniversityCollege(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'],
      universityId: json['university_id'] ?? 0,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'college':
        return 'College';
      case 'school':
        return 'School';
      case 'faculty':
        return 'Faculty';
      case 'institute':
        return 'Institute';
      default:
        return type ?? '';
    }
  }
}

class UniversityDepartment {
  final int id;
  final String code;
  final String name;
  final int collegeId;

  UniversityDepartment({
    required this.id,
    required this.code,
    required this.name,
    required this.collegeId,
  });

  factory UniversityDepartment.fromJson(Map<String, dynamic> json) {
    return UniversityDepartment(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      collegeId: json['college_id'] ?? 0,
    );
  }
}

class UniversityProgramme {
  final int id;
  final String code;
  final String name;
  final String levelCode;
  final int duration;
  final int? collegeId;
  final int? departmentId;
  final int universityId;
  final String? department;
  final String? college;
  final String? university;

  UniversityProgramme({
    required this.id,
    required this.code,
    required this.name,
    required this.levelCode,
    required this.duration,
    this.collegeId,
    this.departmentId,
    required this.universityId,
    this.department,
    this.college,
    this.university,
  });

  factory UniversityProgramme.fromJson(Map<String, dynamic> json) {
    return UniversityProgramme(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      levelCode: json['level_code'] ?? json['degree_level'] ?? '',
      duration: json['duration'] ?? 0,
      collegeId: json['college_id'],
      departmentId: json['department_id'],
      universityId: json['university_id'] ?? 0,
      department: json['department'],
      college: json['college'],
      university: json['university'],
    );
  }

  String get levelLabel {
    switch (levelCode) {
      case 'CERT':
        return 'Certificate';
      case 'DIP':
        return 'Diploma';
      case 'ADV_DIP':
        return 'Advanced Diploma';
      case 'BSC':
        return "Bachelor's Degree";
      case 'BENG':
        return 'Bachelor of Engineering';
      case 'MD':
        return 'Doctor of Medicine';
      case 'PGD':
        return 'Postgraduate Diploma';
      case 'MSC':
        return "Master's Degree";
      case 'PHD':
        return 'Doctorate (PhD)';
      default:
        return levelCode;
    }
  }

  String get displayWithLevel => '$name ($levelLabel)';
}

class Business {
  final int id;
  final String code;
  final String name;
  final String? acronym;
  final String? sector;
  final String? ownership;
  final String? category;
  final String? region;

  Business({
    required this.id,
    required this.code,
    required this.name,
    this.acronym,
    this.sector,
    this.ownership,
    this.category,
    this.region,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      acronym: json['acronym'],
      sector: json['sector'],
      ownership: json['ownership'],
      category: json['category'],
      region: json['region'],
    );
  }

  String get displayName => acronym != null ? '$name ($acronym)' : name;

  String get ownershipLabel {
    switch (ownership) {
      case 'government':
        return 'Serikali';
      case 'private':
        return 'Binafsi';
      case 'public_listed':
        return 'DSE';
      case 'foreign':
        return 'Kimataifa';
      default:
        return ownership ?? 'Unknown';
    }
  }
}

class PostsecondaryCategory {
  final String code;
  final String name;

  PostsecondaryCategory({required this.code, required this.name});

  factory PostsecondaryCategory.fromMapEntry(MapEntry<String, dynamic> entry) {
    return PostsecondaryCategory(
      code: entry.key,
      name: entry.value.toString(),
    );
  }
}
