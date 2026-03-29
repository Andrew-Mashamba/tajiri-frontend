/// Registration state model for multi-step registration flow

class RegistrationState {
  // User ID from backend (after successful registration)
  int? userId;
  String? profilePhotoUrl;

  // Face photo (after Bio step)
  String? profilePhotoPath; // File path — survives Hive persistence
  Map<String, int>? faceBbox; // {x, y, width, height} from ML Kit

  // Step 1: Bio Information
  String? firstName;
  String? lastName;
  DateTime? dateOfBirth;
  Gender? gender;

  // Step 2: Phone Verification
  String? phoneNumber;
  bool isPhoneVerified;
  String? verificationId;

  // Step 2b: PIN
  String? pin;

  // Step 3: Location
  LocationSelection? location;

  // Step 4: Primary School
  EducationEntry? primarySchool;

  // Step 5: Secondary School (O-Level)
  EducationEntry? secondarySchool;

  /// Step 5 (Education Path): Whether user attended A-Level. Drives conditional Step 6.
  bool? didAttendAlevel;

  /// Education path selected during onboarding branching
  EducationPath? educationPath;

  // Step 6: A-Level (conditional on didAttendAlevel)
  AlevelEducation? alevelEducation;

  // Step 7: Post-Secondary (Optional)
  EducationEntry? postsecondaryEducation;

  // Step 8: University (Optional)
  UniversityEducation? universityEducation;

  // Step 9: Current Employer (Optional)
  EmployerEntry? currentEmployer;

  RegistrationState({
    this.userId,
    this.profilePhotoUrl,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.isPhoneVerified = false,
    this.verificationId,
    this.pin,
    this.location,
    this.primarySchool,
    this.secondarySchool,
    this.didAttendAlevel,
    this.educationPath,
    this.alevelEducation,
    this.postsecondaryEducation,
    this.universityEducation,
    this.currentEmployer,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  bool get isBioComplete =>
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty &&
      dateOfBirth != null &&
      gender != null;

  bool get isPhotoComplete => profilePhotoPath != null;

  bool get isPhoneComplete => phoneNumber != null && isPhoneVerified;

  bool get isLocationComplete => location != null && location!.isComplete;

  bool get isPrimaryComplete =>
      primarySchool != null && primarySchool!.isComplete;

  bool get isSecondaryComplete =>
      secondarySchool != null && secondarySchool!.isComplete;

  bool get isAlevelComplete =>
      alevelEducation == null || alevelEducation!.isComplete;

  /// Apply user id and profile data returned from POST /api/users/register.
  void applyServerProfile(Map<String, dynamic> data) {
    final id = data['id'];
    if (id != null) userId = id is int ? id : (id is num ? id.toInt() : null);
    if (data['profile_photo_url'] != null) {
      profilePhotoUrl = data['profile_photo_url'] as String?;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'profile_photo_url': profilePhotoUrl,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (faceBbox != null) 'face_bbox': faceBbox,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender?.name,
      'phone_number': phoneNumber,
      'is_phone_verified': isPhoneVerified,
      'pin': pin,
      'location': location?.toJson(),
      'primary_school': primarySchool?.toJson(),
      'secondary_school': secondarySchool?.toJson(),
      'did_attend_alevel': didAttendAlevel,
      'education_path': educationPath?.name,
      'alevel_education': alevelEducation?.toJson(),
      'postsecondary_education': postsecondaryEducation?.toJson(),
      'university_education': universityEducation?.toJson(),
      'current_employer': currentEmployer?.toJson(),
    };
  }

  factory RegistrationState.fromJson(Map<String, dynamic> json) {
    final state = RegistrationState(
      userId: json['user_id'],
      profilePhotoUrl: json['profile_photo_url'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (g) => g.name == json['gender'],
              orElse: () => Gender.male,
            )
          : null,
      phoneNumber: json['phone_number'],
      isPhoneVerified: json['is_phone_verified'] ?? false,
      pin: json['pin'] as String?,
      location: json['location'] != null
          ? LocationSelection.fromJson(json['location'])
          : null,
      primarySchool: json['primary_school'] != null
          ? EducationEntry.fromJson(json['primary_school'])
          : null,
      secondarySchool: json['secondary_school'] != null
          ? EducationEntry.fromJson(json['secondary_school'])
          : null,
      didAttendAlevel: json['did_attend_alevel'] as bool?,
      educationPath: json['education_path'] != null
          ? EducationPath.values.firstWhere(
              (e) => e.name == json['education_path'],
              orElse: () => EducationPath.primary,
            )
          : null,
      alevelEducation: json['alevel_education'] != null
          ? AlevelEducation.fromJson(json['alevel_education'])
          : null,
      postsecondaryEducation: json['postsecondary_education'] != null
          ? EducationEntry.fromJson(json['postsecondary_education'])
          : null,
      universityEducation: json['university_education'] != null
          ? UniversityEducation.fromJson(json['university_education'])
          : null,
      currentEmployer: json['current_employer'] != null
          ? EmployerEntry.fromJson(json['current_employer'])
          : null,
    );
    state.profilePhotoPath = json['profile_photo_path'] as String?;
    state.faceBbox = json['face_bbox'] != null ? Map<String, int>.from(json['face_bbox']) : null;
    return state;
  }
}

enum Gender { male, female }

/// Education level for onboarding branching logic
enum EducationPath {
  primary,       // Shule ya Msingi
  secondary,     // Sekondari (O-Level)
  alevel,        // Kidato cha 5-6
  postSecondary, // Chuo
  university,    // Chuo Kikuu
}

extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Me';
      case Gender.female:
        return 'Ke';
    }
  }

  String get fullLabel {
    switch (this) {
      case Gender.male:
        return 'Mwanaume';
      case Gender.female:
        return 'Mwanamke';
    }
  }
}

class LocationSelection {
  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;
  final int? wardId;
  final String? wardName;
  final int? streetId;
  final String? streetName;

  LocationSelection({
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.wardId,
    this.wardName,
    this.streetId,
    this.streetName,
  });

  bool get isComplete =>
      regionId != null &&
      districtId != null &&
      wardId != null &&
      streetId != null;

  String get displayAddress {
    final parts = <String>[];
    if (streetName != null) parts.add(streetName!);
    if (wardName != null) parts.add(wardName!);
    if (districtName != null) parts.add(districtName!);
    if (regionName != null) parts.add(regionName!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'region_id': regionId,
      'region_name': regionName,
      'district_id': districtId,
      'district_name': districtName,
      'ward_id': wardId,
      'ward_name': wardName,
      'street_id': streetId,
      'street_name': streetName,
    };
  }

  factory LocationSelection.fromJson(Map<String, dynamic> json) {
    return LocationSelection(
      regionId: json['region_id'],
      regionName: json['region_name'],
      districtId: json['district_id'],
      districtName: json['district_name'],
      wardId: json['ward_id'],
      wardName: json['ward_name'],
      streetId: json['street_id'],
      streetName: json['street_name'],
    );
  }
}

class EducationEntry {
  final int? schoolId;
  final String? schoolCode;
  final String? schoolName;
  final String? schoolType;
  final int? startYear;
  final int? graduationYear;
  final String? regionName;
  final String? districtName;

  EducationEntry({
    this.schoolId,
    this.schoolCode,
    this.schoolName,
    this.schoolType,
    this.startYear,
    this.graduationYear,
    this.regionName,
    this.districtName,
  });

  bool get isComplete => schoolId != null && graduationYear != null;

  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'school_code': schoolCode,
      'school_name': schoolName,
      'school_type': schoolType,
      'start_year': startYear,
      'graduation_year': graduationYear,
      'region_name': regionName,
      'district_name': districtName,
    };
  }

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      schoolId: json['school_id'],
      schoolCode: json['school_code'],
      schoolName: json['school_name'],
      schoolType: json['school_type'],
      startYear: json['start_year'],
      graduationYear: json['graduation_year'],
      regionName: json['region_name'],
      districtName: json['district_name'],
    );
  }
}

class AlevelEducation {
  final int? schoolId;
  final String? schoolCode;
  final String? schoolName;
  final String? schoolType;
  final int? startYear;
  final int? graduationYear;
  final String? combinationCode;
  final String? combinationName;
  final List<String>? subjects;
  final String? regionName;
  final String? districtName;

  AlevelEducation({
    this.schoolId,
    this.schoolCode,
    this.schoolName,
    this.schoolType,
    this.startYear,
    this.graduationYear,
    this.combinationCode,
    this.combinationName,
    this.subjects,
    this.regionName,
    this.districtName,
  });

  bool get isComplete =>
      schoolId != null && graduationYear != null && combinationCode != null;

  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'school_code': schoolCode,
      'school_name': schoolName,
      'school_type': schoolType,
      'start_year': startYear,
      'graduation_year': graduationYear,
      'combination_code': combinationCode,
      'combination_name': combinationName,
      'subjects': subjects,
      'region_name': regionName,
      'district_name': districtName,
    };
  }

  factory AlevelEducation.fromJson(Map<String, dynamic> json) {
    return AlevelEducation(
      schoolId: json['school_id'],
      schoolCode: json['school_code'],
      schoolName: json['school_name'],
      schoolType: json['school_type'],
      startYear: json['start_year'],
      graduationYear: json['graduation_year'],
      combinationCode: json['combination_code'],
      combinationName: json['combination_name'],
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'])
          : null,
      regionName: json['region_name'],
      districtName: json['district_name'],
    );
  }
}

class UniversityEducation {
  final int? universityId;
  final String? universityCode;
  final String? universityName;
  final int? programmeId;
  final String? programmeName;
  final String? degreeLevel;
  final int? startYear;
  final int? graduationYear;
  final bool isCurrentStudent;

  UniversityEducation({
    this.universityId,
    this.universityCode,
    this.universityName,
    this.programmeId,
    this.programmeName,
    this.degreeLevel,
    this.startYear,
    this.graduationYear,
    this.isCurrentStudent = false,
  });

  bool get isComplete =>
      universityId != null &&
      programmeId != null &&
      (graduationYear != null || isCurrentStudent);

  Map<String, dynamic> toJson() {
    return {
      'university_id': universityId,
      'university_code': universityCode,
      'university_name': universityName,
      'programme_id': programmeId,
      'programme_name': programmeName,
      'degree_level': degreeLevel,
      'start_year': startYear,
      'graduation_year': graduationYear,
      'is_current_student': isCurrentStudent,
    };
  }

  factory UniversityEducation.fromJson(Map<String, dynamic> json) {
    return UniversityEducation(
      universityId: json['university_id'],
      universityCode: json['university_code'],
      universityName: json['university_name'],
      programmeId: json['programme_id'],
      programmeName: json['programme_name'],
      degreeLevel: json['degree_level'],
      startYear: json['start_year'],
      graduationYear: json['graduation_year'],
      isCurrentStudent: json['is_current_student'] ?? false,
    );
  }
}

class EmployerEntry {
  final int? employerId;
  final String? employerCode;
  final String? employerName;
  final String? sector;
  final String? ownership;
  final bool isCustomEmployer;

  EmployerEntry({
    this.employerId,
    this.employerCode,
    this.employerName,
    this.sector,
    this.ownership,
    this.isCustomEmployer = false,
  });

  bool get isComplete => employerName != null && employerName!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'employer_id': employerId,
      'employer_code': employerCode,
      'employer_name': employerName,
      'sector': sector,
      'ownership': ownership,
      'is_custom_employer': isCustomEmployer,
    };
  }

  factory EmployerEntry.fromJson(Map<String, dynamic> json) {
    return EmployerEntry(
      employerId: json['employer_id'],
      employerCode: json['employer_code'],
      employerName: json['employer_name'],
      sector: json['sector'],
      ownership: json['ownership'],
      isCustomEmployer: json['is_custom_employer'] ?? false,
    );
  }
}
