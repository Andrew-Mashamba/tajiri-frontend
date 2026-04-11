// lib/doctor/services/doctor_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/doctor_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class DoctorService {
  // ─── Find Doctors ──────────────────────────────────────────────

  Future<DoctorListResult<Doctor>> findDoctors({
    String? specialty,
    String? search,
    bool? onlineOnly,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (specialty != null) params['specialty'] = specialty;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (onlineOnly == true) params['online'] = '1';

      final uri = Uri.parse('$_baseUrl/doctors').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Doctor.fromJson(j))
              .toList();
          return DoctorListResult(success: true, items: items);
        }
      }
      return DoctorListResult(success: false, message: 'Imeshindwa kupakia madaktari');
    } catch (e) {
      return DoctorListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorResult<Doctor>> getDoctorProfile(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$doctorId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DoctorResult(success: true, data: Doctor.fromJson(data['data']));
        }
      }
      return DoctorResult(success: false, message: 'Imeshindwa kupakia daktari');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Doctor Registration (Doctor Tajiri Program) ───────────────

  Future<DoctorResult<Doctor>> registerAsDoctor({
    required int userId,
    required DoctorRegistrationRequest request,
    required File mctCertificate,
    required File medicalDegree,
    required File nationalId,
    File? specialistCertificate,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/doctors/register');
      final multipart = http.MultipartRequest('POST', uri);

      multipart.fields['user_id'] = '$userId';
      multipart.fields.addAll(
        request.toJson().map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );

      multipart.files.add(await http.MultipartFile.fromPath('mct_certificate', mctCertificate.path));
      multipart.files.add(await http.MultipartFile.fromPath('medical_degree', medicalDegree.path));
      multipart.files.add(await http.MultipartFile.fromPath('national_id', nationalId.path));
      if (specialistCertificate != null) {
        multipart.files.add(await http.MultipartFile.fromPath('specialist_certificate', specialistCertificate.path));
      }

      final streamedResponse = await multipart.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return DoctorResult(success: true, data: Doctor.fromJson(data['data']));
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa kusajili');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorResult<Doctor>> getMyDoctorProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/me?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DoctorResult(success: true, data: Doctor.fromJson(data['data']));
        }
      }
      return DoctorResult(success: false);
    } catch (e) {
      return DoctorResult(success: false);
    }
  }

  // ─── Appointments ──────────────────────────────────────────────

  Future<DoctorResult<Appointment>> bookAppointment({
    required int patientId,
    required int doctorId,
    required ConsultationType type,
    required DateTime scheduledAt,
    required String reason,
    String? symptoms,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'doctor_id': doctorId,
          'type': type.name,
          'scheduled_at': scheduledAt.toIso8601String(),
          'reason': reason,
          if (symptoms != null) 'symptoms': symptoms,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final appointment = Appointment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        if (appointment.fee > 0) {
          LocalStorageService.getInstance().then((storage) {
            final token = storage.getAuthToken();
            if (token != null) {
              ExpenditureService.recordExpenditure(
                token: token,
                amount: appointment.fee,
                category: 'afya',
                description: 'Daktari: ${appointment.doctor?.fullName ?? reason}',
                referenceId: 'doctor_appointment_${appointment.id}',
                sourceModule: 'doctor',
              ).catchError((_) => null);
            }
          }).catchError((_) {
            debugPrint('[DoctorService] expenditure tracking skipped');
          });
        }
        return DoctorResult(success: true, data: appointment);
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorListResult<Appointment>> getMyAppointments({
    required int userId,
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/doctors/appointments?user_id=$userId&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Appointment.fromJson(j))
              .toList();
          return DoctorListResult(success: true, items: items);
        }
      }
      return DoctorListResult(success: false, message: 'Imeshindwa kupakia miadi');
    } catch (e) {
      return DoctorListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorResult<void>> cancelAppointment(int appointmentId, {String? reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/appointments/$appointmentId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({if (reason != null) 'reason': reason}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return DoctorResult(success: true);
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorResult<Appointment>> giveConsent(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/appointments/$appointmentId/consent'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return DoctorResult(success: true, data: Appointment.fromJson(data['data']));
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Consultations (start call/chat for appointment) ───────────

  Future<DoctorResult<Map<String, dynamic>>> startConsultation(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/appointments/$appointmentId/start'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return DoctorResult(success: true, data: data['data']);
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa kuanza');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Prescriptions ─────────────────────────────────────────────

  Future<DoctorListResult<Prescription>> getMyPrescriptions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/prescriptions?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Prescription.fromJson(j))
              .toList();
          return DoctorListResult(success: true, items: items);
        }
      }
      return DoctorListResult(success: false, message: 'Imeshindwa kupakia dawa');
    } catch (e) {
      return DoctorListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Reviews ───────────────────────────────────────────────────

  Future<DoctorResult<ConsultationReview>> submitReview({
    required int appointmentId,
    required int patientId,
    required int doctorId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appointment_id': appointmentId,
          'patient_id': patientId,
          'doctor_id': doctorId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return DoctorResult(success: true, data: ConsultationReview.fromJson(data['data']));
      }
      return DoctorResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return DoctorResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<DoctorListResult<ConsultationReview>> getDoctorReviews(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$doctorId/reviews'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ConsultationReview.fromJson(j))
              .toList();
          return DoctorListResult(success: true, items: items);
        }
      }
      return DoctorListResult(success: false);
    } catch (e) {
      return DoctorListResult(success: false);
    }
  }
}
