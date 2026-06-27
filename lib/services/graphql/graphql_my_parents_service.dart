import '../../my_parents/models/my_parents_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL elderly parent care (Phase 89). Financial support remains REST-only.
class GraphqlMyParentsService {
  static const _parentFields = r'''
    id
    name
    relationship
    dateOfBirth
    gender
    photoUrl
    phone
    whatsappAvailable
    locationName
    livingSituation
    bloodType
    mobilityStatus
    cognitiveStatus
    chronicConditions
    allergies
    nhifNumber
    nhifStatus
    emergencyContacts
  ''';

  static const _medicationFields = r'''
    id
    parentId
    name
    dosage
    frequency
    timeSlots
    startDate
    endDate
    prescribingDoctor
    pillsRemaining
    pillsPerDose
    refillThreshold
    isActive
  ''';

  static const _readingFields = r'''
    id
    parentId
    readingType
    value
    value2
    unit
    notes
    measuredAt
  ''';

  static const _appointmentFields = r'''
    id
    parentId
    title
    providerName
    location
    scheduledAt
    notes
    status
  ''';

  static const _wellnessFields = r'''
    id
    parentId
    mood
    appetite
    sleepQuality
    notes
    checkedAt
  ''';

  static const _careTaskFields = r'''
    id
    parentId
    title
    dueAt
    completed
  ''';

  static const _caregiverFields = r'''
    id
    parentId
    caregiverUserId
    email
    status
    invitedAt
    acceptedAt
  ''';

  static Map<String, dynamic> _parentToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'name': row['name'],
      'relationship': row['relationship'],
      'date_of_birth': row['dateOfBirth'],
      'gender': row['gender'],
      'photo_url': row['photoUrl'],
      'phone': row['phone'],
      'whatsapp_available': row['whatsappAvailable'] ?? false,
      'location_name': row['locationName'],
      'living_situation': row['livingSituation'],
      'blood_type': row['bloodType'],
      'mobility_status': row['mobilityStatus'],
      'cognitive_status': row['cognitiveStatus'],
      'chronic_conditions': row['chronicConditions'] ?? [],
      'allergies': row['allergies'] ?? [],
      'nhif_number': row['nhifNumber'],
      'nhif_status': row['nhifStatus'],
      'emergency_contacts': row['emergencyContacts'] ?? [],
    };
  }

  static Map<String, dynamic> _medicationToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'dosage': row['dosage'],
      'frequency': row['frequency'],
      'time_slots': row['timeSlots'] ?? [],
      'start_date': row['startDate'],
      'end_date': row['endDate'],
      'prescribing_doctor': row['prescribingDoctor'],
      'pills_remaining': row['pillsRemaining'],
      'pills_per_dose': row['pillsPerDose'],
      'refill_threshold': row['refillThreshold'],
      'is_active': row['isActive'] ?? true,
    };
  }

  static Map<String, dynamic> _readingToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'type': row['readingType'],
      'value': row['value'],
      'value2': row['value2'],
      'unit': row['unit'],
      'notes': row['notes'],
      'measured_at': row['measuredAt'],
    };
  }

  static Map<String, dynamic> _appointmentToLegacy(Map<String, dynamic> row) {
    final scheduledAt = row['scheduledAt']?.toString();
    DateTime? date;
    String? time;
    if (scheduledAt != null && scheduledAt.isNotEmpty) {
      final parsed = DateTime.tryParse(scheduledAt);
      if (parsed != null) {
        date = parsed;
        time =
            '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    }
    final gqlStatus = row['status']?.toString() ?? 'scheduled';
    final legacyStatus = gqlStatus == 'scheduled' ? 'upcoming' : gqlStatus;
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'doctor_name': row['providerName'],
      'facility': row['location'],
      'reason': row['title'],
      'date': date?.toIso8601String() ?? scheduledAt,
      'time': time,
      'notes': row['notes'],
      'status': legacyStatus,
    };
  }

  static Map<String, dynamic> _wellnessToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'date': row['checkedAt'],
      'mood': row['mood'],
      'ate_meals': row['appetite'] != null && row['appetite'] != 'poor',
      'took_medication': false,
      'exercised': false,
      'socialized': false,
      'notes': row['notes'],
    };
  }

  static Map<String, dynamic> _careTaskToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'due_date': row['dueAt'],
      'status': row['completed'] == true ? 'completed' : 'pending',
    };
  }

  static Map<String, dynamic> _caregiverToLegacy(Map<String, dynamic> row) {
    final id = int.tryParse(row['id']?.toString() ?? '');
    return {
      if (id != null) 'id': id,
      'parent_id': int.tryParse(row['parentId']?.toString() ?? '') ?? 0,
      'owner_user_id': 0,
      'caregiver_user_id': row['caregiverUserId'] != null
          ? int.tryParse(row['caregiverUserId'].toString())
          : null,
      'invite_code': row['id']?.toString() ?? '',
      'role': 'viewer',
      'status': row['status'] ?? 'pending',
      'caregiver_name': row['email'],
    };
  }

  static String _scheduledAt(DateTime date, String? time) {
    if (time != null && time.isNotEmpty) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, hour, minute)
            .toIso8601String();
      }
    }
    return date.toIso8601String();
  }

  // ─── Parent CRUD ──────────────────────────────────────────────────

  static Future<ParentResult<Parent>> registerParent({
    required int userId,
    required String name,
    required DateTime dateOfBirth,
    required String relationship,
    String? gender,
    String? phone,
    bool whatsappAvailable = false,
    String? locationName,
    String? livingSituation,
    String? bloodType,
    String? mobilityStatus,
    String? cognitiveStatus,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? nhifNumber,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateElderlyParent(\$input: CreateElderlyParentInput!) {
          createElderlyParent(input: \$input) {
            $_parentFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'relationship': relationship,
            'dateOfBirth': dateOfBirth.toIso8601String(),
            if (gender != null) 'gender': gender,
            if (phone != null) 'phone': phone,
            'whatsappAvailable': whatsappAvailable,
            if (locationName != null) 'locationName': locationName,
            if (livingSituation != null) 'livingSituation': livingSituation,
            if (bloodType != null) 'bloodType': bloodType,
            if (mobilityStatus != null) 'mobilityStatus': mobilityStatus,
            if (cognitiveStatus != null) 'cognitiveStatus': cognitiveStatus,
            if (chronicConditions != null && chronicConditions.isNotEmpty)
              'chronicConditions': chronicConditions,
            if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
            if (nhifNumber != null) 'nhifNumber': nhifNumber,
            if (emergencyContacts != null && emergencyContacts.isNotEmpty)
              'emergencyContacts': emergencyContacts,
          },
        },
        auth: true,
      );
      final row = data['createElderlyParent'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to register parent');
      }
      return ParentResult(
        success: true,
        data: Parent.fromJson(_parentToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<Parent>> getMyParents() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyParents {
          myParents {
            $_parentFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myParents'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Parent.fromJson(_parentToLegacy(row)))
          .toList();
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<Parent>> updateParent({
    required int parentId,
    String? name,
    String? gender,
    String? phone,
    bool? whatsappAvailable,
    String? photoUrl,
    String? locationName,
    String? livingSituation,
    String? bloodType,
    String? mobilityStatus,
    String? cognitiveStatus,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? nhifNumber,
    String? nhifStatus,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateElderlyParent(
          \$parentId: ID!
          \$name: String
          \$gender: String
          \$phone: String
          \$whatsappAvailable: Boolean
          \$photoUrl: String
          \$locationName: String
          \$livingSituation: String
          \$bloodType: String
          \$mobilityStatus: String
          \$cognitiveStatus: String
          \$chronicConditions: [String!]
          \$allergies: [String!]
          \$nhifNumber: String
          \$nhifStatus: String
          \$emergencyContacts: JSON
        ) {
          updateElderlyParent(
            parentId: \$parentId
            name: \$name
            gender: \$gender
            phone: \$phone
            whatsappAvailable: \$whatsappAvailable
            photoUrl: \$photoUrl
            locationName: \$locationName
            livingSituation: \$livingSituation
            bloodType: \$bloodType
            mobilityStatus: \$mobilityStatus
            cognitiveStatus: \$cognitiveStatus
            chronicConditions: \$chronicConditions
            allergies: \$allergies
            nhifNumber: \$nhifNumber
            nhifStatus: \$nhifStatus
            emergencyContacts: \$emergencyContacts
          ) {
            $_parentFields
          }
        }
        ''',
        variables: {
          'parentId': parentId.toString(),
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (phone != null) 'phone': phone,
          if (whatsappAvailable != null) 'whatsappAvailable': whatsappAvailable,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (locationName != null) 'locationName': locationName,
          if (livingSituation != null) 'livingSituation': livingSituation,
          if (bloodType != null) 'bloodType': bloodType,
          if (mobilityStatus != null) 'mobilityStatus': mobilityStatus,
          if (cognitiveStatus != null) 'cognitiveStatus': cognitiveStatus,
          if (chronicConditions != null) 'chronicConditions': chronicConditions,
          if (allergies != null) 'allergies': allergies,
          if (nhifNumber != null) 'nhifNumber': nhifNumber,
          if (nhifStatus != null) 'nhifStatus': nhifStatus,
          if (emergencyContacts != null) 'emergencyContacts': emergencyContacts,
        },
        auth: true,
      );
      final row = data['updateElderlyParent'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to update');
      }
      return ParentResult(
        success: true,
        data: Parent.fromJson(_parentToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> deleteParent({required int parentId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeleteElderlyParent($parentId: ID!) {
          deleteElderlyParent(parentId: $parentId)
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      if (data['deleteElderlyParent'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to delete');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Medications ──────────────────────────────────────────────────

  static Future<ParentResult<ParentMedication>> addMedication({
    required int parentId,
    required String name,
    required String dosage,
    required String frequency,
    List<String>? timeSlots,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribingDoctor,
    int? pillsRemaining,
    int? pillsPerDose,
    int? refillThreshold,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddParentMedication(\$input: AddParentMedicationInput!) {
          addParentMedication(input: \$input) {
            $_medicationFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'name': name,
            'dosage': dosage,
            'frequency': frequency,
            if (timeSlots != null && timeSlots.isNotEmpty) 'timeSlots': timeSlots,
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
            if (prescribingDoctor != null) 'prescribingDoctor': prescribingDoctor,
            if (pillsRemaining != null) 'pillsRemaining': pillsRemaining,
            if (pillsPerDose != null) 'pillsPerDose': pillsPerDose,
            if (refillThreshold != null) 'refillThreshold': refillThreshold,
          },
        },
        auth: true,
      );
      final row = data['addParentMedication'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to add medication');
      }
      return ParentResult(
        success: true,
        data: ParentMedication.fromJson(_medicationToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<ParentMedication>> getMedications(
    int parentId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentMedications(\$parentId: ID!) {
          parentMedications(parentId: \$parentId) {
            $_medicationFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      final rows = data['parentMedications'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => ParentMedication.fromJson(_medicationToLegacy(row)))
          .toList();
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<ParentMedication>> updateMedication({
    required int medicationId,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? timeSlots,
    DateTime? endDate,
    String? prescribingDoctor,
    int? pillsRemaining,
    int? pillsPerDose,
    int? refillThreshold,
    bool? isActive,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateParentMedication(
          \$medicationId: ID!
          \$name: String
          \$dosage: String
          \$frequency: String
          \$timeSlots: JSON
          \$endDate: String
          \$prescribingDoctor: String
          \$pillsRemaining: Int
          \$pillsPerDose: Int
          \$refillThreshold: Int
          \$isActive: Boolean
        ) {
          updateParentMedication(
            medicationId: \$medicationId
            name: \$name
            dosage: \$dosage
            frequency: \$frequency
            timeSlots: \$timeSlots
            endDate: \$endDate
            prescribingDoctor: \$prescribingDoctor
            pillsRemaining: \$pillsRemaining
            pillsPerDose: \$pillsPerDose
            refillThreshold: \$refillThreshold
            isActive: \$isActive
          ) {
            $_medicationFields
          }
        }
        ''',
        variables: {
          'medicationId': medicationId.toString(),
          if (name != null) 'name': name,
          if (dosage != null) 'dosage': dosage,
          if (frequency != null) 'frequency': frequency,
          if (timeSlots != null) 'timeSlots': timeSlots,
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (prescribingDoctor != null) 'prescribingDoctor': prescribingDoctor,
          if (pillsRemaining != null) 'pillsRemaining': pillsRemaining,
          if (pillsPerDose != null) 'pillsPerDose': pillsPerDose,
          if (refillThreshold != null) 'refillThreshold': refillThreshold,
          if (isActive != null) 'isActive': isActive,
        },
        auth: true,
      );
      final row = data['updateParentMedication'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to update medication');
      }
      return ParentResult(
        success: true,
        data: ParentMedication.fromJson(_medicationToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> deleteMedication({
    required int medicationId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeleteParentMedication($medicationId: ID!) {
          deleteParentMedication(medicationId: $medicationId)
        }
        ''',
        variables: {'medicationId': medicationId.toString()},
        auth: true,
      );
      if (data['deleteParentMedication'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to delete medication');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Health Readings ──────────────────────────────────────────────

  static Future<ParentResult<ParentHealthReading>> logHealthReading({
    required int parentId,
    required String type,
    required double value,
    double? value2,
    String? unit,
    String? notes,
    DateTime? measuredAt,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogParentHealthReading(\$input: LogParentHealthReadingInput!) {
          logParentHealthReading(input: \$input) {
            $_readingFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'readingType': type,
            'value': value,
            if (value2 != null) 'value2': value2,
            if (unit != null) 'unit': unit,
            if (notes != null) 'notes': notes,
            'measuredAt': (measuredAt ?? DateTime.now()).toIso8601String(),
          },
        },
        auth: true,
      );
      final row = data['logParentHealthReading'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to log reading');
      }
      return ParentResult(
        success: true,
        data: ParentHealthReading.fromJson(_readingToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<ParentHealthReading>> getHealthReadings(
    int parentId, {
    String? type,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentHealthReadings(\$parentId: ID!) {
          parentHealthReadings(parentId: \$parentId) {
            $_readingFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      var rows = (data['parentHealthReadings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => ParentHealthReading.fromJson(_readingToLegacy(row)))
          .toList();
      if (type != null) {
        rows = rows.where((r) => r.type == type).toList();
      }
      return ParentListResult(success: true, items: rows);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> deleteHealthReading({
    required int readingId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeleteParentHealthReading($readingId: ID!) {
          deleteParentHealthReading(readingId: $readingId)
        }
        ''',
        variables: {'readingId': readingId.toString()},
        auth: true,
      );
      if (data['deleteParentHealthReading'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to delete reading');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Appointments ─────────────────────────────────────────────────

  static Future<ParentResult<ParentAppointment>> addAppointment({
    required int parentId,
    String? doctorName,
    String? facility,
    String? reason,
    required DateTime date,
    String? time,
    String? notes,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddParentAppointment(\$input: AddParentAppointmentInput!) {
          addParentAppointment(input: \$input) {
            $_appointmentFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'title': reason ?? doctorName ?? 'Appointment',
            'scheduledAt': _scheduledAt(date, time),
            if (doctorName != null) 'providerName': doctorName,
            if (facility != null) 'location': facility,
            if (notes != null) 'notes': notes,
          },
        },
        auth: true,
      );
      final row = data['addParentAppointment'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to add appointment');
      }
      return ParentResult(
        success: true,
        data: ParentAppointment.fromJson(_appointmentToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<ParentAppointment>> getAppointments(
    int parentId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentAppointments(\$parentId: ID!) {
          parentAppointments(parentId: \$parentId) {
            $_appointmentFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      var items = (data['parentAppointments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => ParentAppointment.fromJson(_appointmentToLegacy(row)))
          .toList();
      if (status != null) {
        items = items.where((a) => a.status == status).toList();
      }
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<ParentAppointment>> updateAppointment({
    required int appointmentId,
    String? doctorName,
    String? facility,
    String? reason,
    DateTime? date,
    String? time,
    String? notes,
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateParentAppointment(
          \$appointmentId: ID!
          \$title: String
          \$providerName: String
          \$location: String
          \$scheduledAt: String
          \$notes: String
          \$status: String
        ) {
          updateParentAppointment(
            appointmentId: \$appointmentId
            title: \$title
            providerName: \$providerName
            location: \$location
            scheduledAt: \$scheduledAt
            notes: \$notes
            status: \$status
          ) {
            $_appointmentFields
          }
        }
        ''',
        variables: {
          'appointmentId': appointmentId.toString(),
          if (reason != null) 'title': reason,
          if (doctorName != null) 'providerName': doctorName,
          if (facility != null) 'location': facility,
          if (date != null) 'scheduledAt': _scheduledAt(date, time),
          if (notes != null) 'notes': notes,
          if (status != null)
            'status': status == 'upcoming' ? 'scheduled' : status,
        },
        auth: true,
      );
      final row = data['updateParentAppointment'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to update appointment');
      }
      return ParentResult(
        success: true,
        data: ParentAppointment.fromJson(_appointmentToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> deleteAppointment({
    required int appointmentId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeleteParentAppointment($appointmentId: ID!) {
          deleteParentAppointment(appointmentId: $appointmentId)
        }
        ''',
        variables: {'appointmentId': appointmentId.toString()},
        auth: true,
      );
      if (data['deleteParentAppointment'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
        success: false,
        message: 'Failed to delete appointment',
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Wellness ─────────────────────────────────────────────────────

  static Future<ParentResult<WellnessCheckIn>> saveWellnessCheckIn({
    required int parentId,
    String? mood,
    bool ateMeals = false,
    bool tookMedication = false,
    bool exercised = false,
    bool socialized = false,
    String? notes,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogParentWellnessCheckin(\$input: LogParentWellnessCheckinInput!) {
          logParentWellnessCheckin(input: \$input) {
            $_wellnessFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            if (mood != null) 'mood': mood,
            'appetite': ateMeals ? 'good' : 'poor',
            if (notes != null) 'notes': notes,
            'checkedAt': DateTime.now().toIso8601String(),
          },
        },
        auth: true,
      );
      final row = data['logParentWellnessCheckin'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to save check-in');
      }
      return ParentResult(
        success: true,
        data: WellnessCheckIn.fromJson(_wellnessToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<WellnessCheckIn>> getWellnessHistory(
    int parentId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentWellnessCheckins(\$parentId: ID!) {
          parentWellnessCheckins(parentId: \$parentId) {
            $_wellnessFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      final items = (data['parentWellnessCheckins'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => WellnessCheckIn.fromJson(_wellnessToLegacy(row)))
          .toList();
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Care Tasks ───────────────────────────────────────────────────

  static Future<ParentResult<CareTask>> addCareTask({
    required int parentId,
    required String title,
    String? description,
    int? assignedTo,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddParentCareTask(\$input: AddParentCareTaskInput!) {
          addParentCareTask(input: \$input) {
            $_careTaskFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'title': title,
            if (dueDate != null) 'dueAt': dueDate.toIso8601String(),
          },
        },
        auth: true,
      );
      final row = data['addParentCareTask'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to add care task');
      }
      return ParentResult(
        success: true,
        data: CareTask.fromJson(_careTaskToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<CareTask>> getCareTasks(
    int parentId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentCareTasks(\$parentId: ID!) {
          parentCareTasks(parentId: \$parentId) {
            $_careTaskFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      var items = (data['parentCareTasks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => CareTask.fromJson(_careTaskToLegacy(row)))
          .toList();
      if (status != null) {
        items = items.where((t) => t.status == status).toList();
      }
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<CareTask>> updateCareTask({
    required int taskId,
    String? title,
    DateTime? dueDate,
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateParentCareTask(
          \$taskId: ID!
          \$title: String
          \$dueAt: String
          \$completed: Boolean
        ) {
          updateParentCareTask(
            taskId: \$taskId
            title: \$title
            dueAt: \$dueAt
            completed: \$completed
          ) {
            $_careTaskFields
          }
        }
        ''',
        variables: {
          'taskId': taskId.toString(),
          if (title != null) 'title': title,
          if (dueDate != null) 'dueAt': dueDate.toIso8601String(),
          if (status != null) 'completed': status == 'completed',
        },
        auth: true,
      );
      final row = data['updateParentCareTask'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to update care task');
      }
      return ParentResult(
        success: true,
        data: CareTask.fromJson(_careTaskToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> deleteCareTask({required int taskId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeleteParentCareTask($taskId: ID!) {
          deleteParentCareTask(taskId: $taskId)
        }
        ''',
        variables: {'taskId': taskId.toString()},
        auth: true,
      );
      if (data['deleteParentCareTask'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to delete care task');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Caregivers ───────────────────────────────────────────────────

  static Future<ParentResult<ParentCaregiverShare>> inviteCaregiver({
    required int parentId,
    required String role,
  }) async {
    if (!role.contains('@')) {
      return ParentResult(
        success: false,
        message: 'GraphQL backend requires caregiver email address',
      );
    }
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation InviteParentCaregiver(\$input: InviteParentCaregiverInput!) {
          inviteParentCaregiver(input: \$input) {
            $_caregiverFields
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'email': role,
          },
        },
        auth: true,
      );
      final row = data['inviteParentCaregiver'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to invite caregiver');
      }
      return ParentResult(
        success: true,
        data: ParentCaregiverShare.fromJson(_caregiverToLegacy(row)),
      );
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentListResult<ParentCaregiverShare>> listCaregivers(
    int parentId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentCaregivers(\$parentId: ID!) {
          parentCaregivers(parentId: \$parentId) {
            $_caregiverFields
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      final items = (data['parentCaregivers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => ParentCaregiverShare.fromJson(_caregiverToLegacy(row)))
          .toList();
      return ParentListResult(success: true, items: items);
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> revokeCaregiver({required int shareId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RevokeParentCaregiver($caregiverId: ID!) {
          revokeParentCaregiver(caregiverId: $caregiverId)
        }
        ''',
        variables: {'caregiverId': shareId.toString()},
        auth: true,
      );
      if (data['revokeParentCaregiver'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to revoke caregiver');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> acceptInvite({
    required String inviteCode,
  }) async {
    final caregiverId = int.tryParse(inviteCode);
    if (caregiverId == null) {
      return ParentResult(
        success: false,
        message: 'Invalid invite code — expected caregiver ID',
      );
    }
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation AcceptParentCaregiverInvite($caregiverId: ID!) {
          acceptParentCaregiverInvite(caregiverId: $caregiverId) {
            id
          }
        }
        ''',
        variables: {'caregiverId': caregiverId.toString()},
        auth: true,
      );
      if (data['acceptParentCaregiverInvite'] != null) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to accept invite');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Emergency Card ───────────────────────────────────────────────

  static Future<ParentResult<Map<String, dynamic>>> getEmergencyCard(
    int parentId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ParentEmergencyCard(\$parentId: ID!) {
          parentEmergencyCard(parentId: \$parentId) {
            parentId
            cardJson
            updatedAt
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
        auth: true,
      );
      final row = data['parentEmergencyCard'] as Map<String, dynamic>?;
      if (row == null) {
        return ParentResult(success: false, message: 'Failed to load emergency card');
      }
      final cardJson = row['cardJson'];
      if (cardJson is Map<String, dynamic>) {
        return ParentResult(success: true, data: cardJson);
      }
      return ParentResult(success: true, data: {'card': cardJson});
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ParentResult<void>> saveEmergencyCard({
    required int parentId,
    required Map<String, dynamic> cardData,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SaveParentEmergencyCard(\$input: SaveParentEmergencyCardInput!) {
          saveParentEmergencyCard(input: \$input) {
            parentId
          }
        }
        ''',
        variables: {
          'input': {
            'parentId': parentId.toString(),
            'cardJson': cardData,
          },
        },
        auth: true,
      );
      if (data['saveParentEmergencyCard'] != null) {
        return ParentResult(success: true);
      }
      return ParentResult(success: false, message: 'Failed to save emergency card');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }
}
