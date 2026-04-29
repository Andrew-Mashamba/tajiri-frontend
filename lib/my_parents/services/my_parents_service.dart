// lib/my_parents/services/my_parents_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_parents_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MyParentsService {
  // ─── Parent CRUD ──────────────────────────────────────────────────

  Future<ParentResult<Parent>> registerParent({
    required String token,
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
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/parents'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'date_of_birth': dateOfBirth.toIso8601String(),
          'relationship': relationship,
          if (gender != null) 'gender': gender,
          if (phone != null) 'phone': phone,
          'whatsapp_available': whatsappAvailable,
          if (locationName != null) 'location_name': locationName,
          if (livingSituation != null) 'living_situation': livingSituation,
          if (bloodType != null) 'blood_type': bloodType,
          if (mobilityStatus != null) 'mobility_status': mobilityStatus,
          if (cognitiveStatus != null) 'cognitive_status': cognitiveStatus,
          if (chronicConditions != null && chronicConditions.isNotEmpty)
            'chronic_conditions': chronicConditions,
          if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
          if (nhifNumber != null) 'nhif_number': nhifNumber,
          if (emergencyContacts != null && emergencyContacts.isNotEmpty)
            'emergency_contacts': emergencyContacts,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true, data: Parent.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to register parent');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<Parent>> getMyParents(
      String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-parents/parents?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items =
              (data['data'] as List).map((j) => Parent.fromJson(j)).toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load parents');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<Parent>> updateParent({
    required String token,
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
      final response = await http.put(
        Uri.parse('$_baseUrl/my-parents/parents/$parentId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (phone != null) 'phone': phone,
          if (whatsappAvailable != null)
            'whatsapp_available': whatsappAvailable,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (locationName != null) 'location_name': locationName,
          if (livingSituation != null) 'living_situation': livingSituation,
          if (bloodType != null) 'blood_type': bloodType,
          if (mobilityStatus != null) 'mobility_status': mobilityStatus,
          if (cognitiveStatus != null) 'cognitive_status': cognitiveStatus,
          if (chronicConditions != null) 'chronic_conditions': chronicConditions,
          if (allergies != null) 'allergies': allergies,
          if (nhifNumber != null) 'nhif_number': nhifNumber,
          if (nhifStatus != null) 'nhif_status': nhifStatus,
          if (emergencyContacts != null)
            'emergency_contacts': emergencyContacts,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true, data: Parent.fromJson(data['data']));
      }
      return ParentResult(
          success: false, message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteParent({
    required String token,
    required int parentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/parents/$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false, message: data['message'] ?? 'Failed to delete');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Medications ──────────────────────────────────────────────────

  Future<ParentResult<ParentMedication>> addMedication({
    required String token,
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
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/medications'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'name': name,
          'dosage': dosage,
          'frequency': frequency,
          if (timeSlots != null && timeSlots.isNotEmpty) 'time_slots': timeSlots,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          if (prescribingDoctor != null)
            'prescribing_doctor': prescribingDoctor,
          if (pillsRemaining != null) 'pills_remaining': pillsRemaining,
          if (pillsPerDose != null) 'pills_per_dose': pillsPerDose,
          if (refillThreshold != null) 'refill_threshold': refillThreshold,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: ParentMedication.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to add medication');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<ParentMedication>> getMedications(
      String token, int parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-parents/medications?parent_id=$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ParentMedication.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load medications');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<ParentMedication>> updateMedication({
    required String token,
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
      final response = await http.put(
        Uri.parse('$_baseUrl/my-parents/medications/$medicationId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (dosage != null) 'dosage': dosage,
          if (frequency != null) 'frequency': frequency,
          if (timeSlots != null) 'time_slots': timeSlots,
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          if (prescribingDoctor != null)
            'prescribing_doctor': prescribingDoctor,
          if (pillsRemaining != null) 'pills_remaining': pillsRemaining,
          if (pillsPerDose != null) 'pills_per_dose': pillsPerDose,
          if (refillThreshold != null) 'refill_threshold': refillThreshold,
          if (isActive != null) 'is_active': isActive,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: ParentMedication.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to update medication');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteMedication({
    required String token,
    required int medicationId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/medications/$medicationId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to delete medication');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Health Readings ──────────────────────────────────────────────

  Future<ParentResult<ParentHealthReading>> logHealthReading({
    required String token,
    required int parentId,
    required String type,
    required double value,
    double? value2,
    String? unit,
    String? notes,
    DateTime? measuredAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/readings'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'type': type,
          'value': value,
          if (value2 != null) 'value2': value2,
          if (unit != null) 'unit': unit,
          if (notes != null) 'notes': notes,
          'measured_at':
              (measuredAt ?? DateTime.now()).toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: ParentHealthReading.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to log reading');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<ParentHealthReading>> getHealthReadings(
      String token, int parentId,
      {String? type}) async {
    try {
      String url =
          '$_baseUrl/my-parents/readings?parent_id=$parentId';
      if (type != null) url += '&type=$type';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ParentHealthReading.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load health readings');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteHealthReading({
    required String token,
    required int readingId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/readings/$readingId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to delete reading');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Appointments ─────────────────────────────────────────────────

  Future<ParentResult<ParentAppointment>> addAppointment({
    required String token,
    required int parentId,
    String? doctorName,
    String? facility,
    String? reason,
    required DateTime date,
    String? time,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/appointments'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          if (doctorName != null) 'doctor_name': doctorName,
          if (facility != null) 'facility': facility,
          if (reason != null) 'reason': reason,
          'date': date.toIso8601String(),
          if (time != null) 'time': time,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: ParentAppointment.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to add appointment');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<ParentAppointment>> getAppointments(
      String token, int parentId,
      {String? status}) async {
    try {
      String url =
          '$_baseUrl/my-parents/appointments?parent_id=$parentId';
      if (status != null) url += '&status=$status';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ParentAppointment.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load appointments');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<ParentAppointment>> updateAppointment({
    required String token,
    required int appointmentId,
    String? doctorName,
    String? facility,
    String? reason,
    DateTime? date,
    String? time,
    String? diagnosis,
    String? prescription,
    double? cost,
    DateTime? followUpDate,
    String? notes,
    String? status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-parents/appointments/$appointmentId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (doctorName != null) 'doctor_name': doctorName,
          if (facility != null) 'facility': facility,
          if (reason != null) 'reason': reason,
          if (date != null) 'date': date.toIso8601String(),
          if (time != null) 'time': time,
          if (diagnosis != null) 'diagnosis': diagnosis,
          if (prescription != null) 'prescription': prescription,
          if (cost != null) 'cost': cost,
          if (followUpDate != null)
            'follow_up_date': followUpDate.toIso8601String(),
          if (notes != null) 'notes': notes,
          if (status != null) 'status': status,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: ParentAppointment.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to update appointment');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteAppointment({
    required String token,
    required int appointmentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/appointments/$appointmentId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to delete appointment');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Financial Support ────────────────────────────────────────────

  Future<ParentResult<FinancialSupport>> logSupport({
    required String token,
    required int parentId,
    required double amount,
    required String type,
    String? description,
    DateTime? date,
    String? paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/support'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'amount': amount,
          'type': type,
          if (description != null) 'description': description,
          'date': (date ?? DateTime.now()).toIso8601String(),
          if (paymentMethod != null) 'payment_method': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: FinancialSupport.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to log support');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<FinancialSupport>> getSupportHistory(
      String token, int parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-parents/support?parent_id=$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FinancialSupport.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load support history');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<FinancialSupport>> updateSupport({
    required String token,
    required int supportId,
    double? amount,
    String? type,
    String? description,
    String? paymentMethod,
    DateTime? date,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-parents/support/$supportId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (amount != null) 'amount': amount,
          if (type != null) 'type': type,
          if (description != null) 'description': description,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (date != null) 'date': date.toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: FinancialSupport.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to update support');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteSupport({
    required String token,
    required int supportId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/support/$supportId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to delete support record');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Wellness Check-In ────────────────────────────────────────────

  Future<ParentResult<WellnessCheckIn>> saveWellnessCheckIn({
    required String token,
    required int parentId,
    String? mood,
    bool ateMeals = false,
    bool tookMedication = false,
    bool exercised = false,
    bool socialized = false,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/wellness'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'date': DateTime.now().toIso8601String(),
          if (mood != null) 'mood': mood,
          'ate_meals': ateMeals,
          'took_medication': tookMedication,
          'exercised': exercised,
          'socialized': socialized,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: WellnessCheckIn.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to save check-in');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<WellnessCheckIn>> getWellnessHistory(
      String token, int parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-parents/wellness?parent_id=$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => WellnessCheckIn.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load wellness history');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Care Tasks ───────────────────────────────────────────────────

  Future<ParentResult<CareTask>> addCareTask({
    required String token,
    required int parentId,
    required String title,
    String? description,
    int? assignedTo,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/tasks'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'title': title,
          if (description != null) 'description': description,
          if (assignedTo != null) 'assigned_to': assignedTo,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: CareTask.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to add care task');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<CareTask>> getCareTasks(
      String token, int parentId,
      {String? status}) async {
    try {
      String url =
          '$_baseUrl/my-parents/tasks?parent_id=$parentId';
      if (status != null) url += '&status=$status';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => CareTask.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load care tasks');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<CareTask>> updateCareTask({
    required String token,
    required int taskId,
    String? title,
    String? description,
    int? assignedTo,
    DateTime? dueDate,
    String? status,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-parents/tasks/$taskId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (assignedTo != null) 'assigned_to': assignedTo,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true, data: CareTask.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to update care task');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> deleteCareTask({
    required String token,
    required int taskId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/tasks/$taskId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to delete care task');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Caregivers ───────────────────────────────────────────────────

  Future<ParentResult<ParentCaregiverShare>> inviteCaregiver({
    required String token,
    required int parentId,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/caregivers/invite'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'parent_id': parentId,
          'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(
            success: true,
            data: ParentCaregiverShare.fromJson(data['data']));
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to invite caregiver');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentListResult<ParentCaregiverShare>> listCaregivers(
      String token, int parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-parents/caregivers?parent_id=$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ParentCaregiverShare.fromJson(j))
              .toList();
          return ParentListResult(success: true, items: items);
        }
      }
      return ParentListResult(
          success: false, message: 'Failed to load caregivers');
    } catch (e) {
      return ParentListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> revokeCaregiver({
    required String token,
    required int shareId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-parents/caregivers/$shareId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to revoke caregiver');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> acceptInvite({
    required String token,
    required String inviteCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/caregivers/accept'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'invite_code': inviteCode,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to accept invite');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Emergency Card ───────────────────────────────────────────────

  Future<ParentResult<Map<String, dynamic>>> getEmergencyCard(
      String token, int parentId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/my-parents/emergency-card?parent_id=$parentId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ParentResult(
              success: true,
              data: data['data'] as Map<String, dynamic>);
        }
      }
      return ParentResult(
          success: false, message: 'Failed to load emergency card');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  Future<ParentResult<void>> saveEmergencyCard({
    required String token,
    required int parentId,
    required Map<String, dynamic> cardData,
  }) async {
    try {
      final body = Map<String, dynamic>.from(cardData);
      body['parent_id'] = parentId;
      final response = await http.post(
        Uri.parse('$_baseUrl/my-parents/emergency-card'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ParentResult(success: true);
      }
      return ParentResult(
          success: false,
          message: data['message'] ?? 'Failed to save emergency card');
    } catch (e) {
      return ParentResult(success: false, message: 'Error: $e');
    }
  }

  // ─── AI Summary (local aggregation for Shangazi) ──────────────────

  /// Aggregates parent data locally into a summary map for Shangazi AI context.
  /// Does NOT call any external AI endpoint — just collects and structures
  /// existing data into a digestible format.
  Future<Map<String, dynamic>> getParentSummaryForAI({
    required String token,
    required int parentId,
    required int userId,
  }) async {
    final summary = <String, dynamic>{
      'parent_id': parentId,
      'generated_at': DateTime.now().toIso8601String(),
    };

    // Fetch parent profile
    final parentsResult = await getMyParents(token, userId);
    Parent? parent;
    if (parentsResult.success) {
      parent = parentsResult.items
          .where((p) => p.id == parentId)
          .firstOrNull;
    }

    if (parent != null) {
      summary['name'] = parent.name;
      summary['age'] = parent.ageInYears;
      summary['relationship'] = parent.relationship;
      summary['living_situation'] = parent.livingSituation;
      summary['mobility'] = parent.mobilityStatus;
      summary['cognitive'] = parent.cognitiveStatus;
      summary['chronic_conditions'] = parent.chronicConditions;
      summary['allergies'] = parent.allergies;
      summary['blood_type'] = parent.bloodType;
    }

    // Medications
    final medsResult = await getMedications(token, parentId);
    if (medsResult.success) {
      summary['active_medications'] = medsResult.items
          .where((m) => m.isActive)
          .map((m) => {
                'name': m.name,
                'dosage': m.dosage,
                'frequency': m.frequency,
                'pills_remaining': m.pillsRemaining,
              })
          .toList();
    }

    // Recent health readings (last 10)
    final readingsResult = await getHealthReadings(token, parentId);
    if (readingsResult.success) {
      final recent = readingsResult.items.take(10).toList();
      summary['recent_health_readings'] = recent
          .map((r) => {
                'type': r.type,
                'value': r.value,
                if (r.value2 != null) 'value2': r.value2,
                'unit': r.unit,
                'measured_at': r.measuredAt.toIso8601String(),
              })
          .toList();
    }

    // Upcoming appointments
    final apptResult =
        await getAppointments(token, parentId, status: 'upcoming');
    if (apptResult.success) {
      summary['upcoming_appointments'] = apptResult.items
          .map((a) => {
                'doctor': a.doctorName,
                'facility': a.facility,
                'reason': a.reason,
                'date': a.date.toIso8601String(),
              })
          .toList();
    }

    // Recent wellness
    final wellnessResult = await getWellnessHistory(token, parentId);
    if (wellnessResult.success && wellnessResult.items.isNotEmpty) {
      final latest = wellnessResult.items.first;
      summary['latest_wellness'] = {
        'date': latest.date.toIso8601String(),
        'mood': latest.mood,
        'ate_meals': latest.ateMeals,
        'took_medication': latest.tookMedication,
        'exercised': latest.exercised,
        'socialized': latest.socialized,
      };
    }

    // Pending care tasks
    final tasksResult =
        await getCareTasks(token, parentId, status: 'pending');
    if (tasksResult.success) {
      summary['pending_tasks'] = tasksResult.items
          .map((t) => {
                'title': t.title,
                'due_date': t.dueDate?.toIso8601String(),
              })
          .toList();
    }

    return summary;
  }
}
