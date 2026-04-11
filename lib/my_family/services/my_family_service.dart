// lib/my_family/services/my_family_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_family_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MyFamilyService {
  // ─── Members ──────────────────────────────────────────────────

  Future<FamilyListResult<FamilyMember>> getMembers(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/members?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FamilyMember.fromJson(j))
              .toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false, message: 'Imeshindwa kupakia wanafamilia');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<FamilyMember>> addMember({
    required int userId,
    required String name,
    required String relationship,
    required String gender,
    String? dateOfBirth,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? nhifNumber,
    String? emergencyPhone,
    String? photoUrl,
    int? linkedUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'relationship': relationship,
          'gender': gender,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (bloodType != null) 'blood_type': bloodType,
          if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
          if (chronicConditions != null && chronicConditions.isNotEmpty)
            'chronic_conditions': chronicConditions,
          if (nhifNumber != null) 'nhif_number': nhifNumber,
          if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (linkedUserId != null) 'linked_user_id': linkedUserId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: FamilyMember.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuongeza mwanafamilia');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<FamilyMember>> updateMember({
    required int memberId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/family/members/$memberId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(fields),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: FamilyMember.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kubadilisha taarifa');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> removeMember(int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family/members/$memberId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuondoa mwanafamilia');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Calendar Events ─────────────────────────────────────────

  Future<FamilyListResult<FamilyEvent>> getEvents(
      int userId, int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/family/events?user_id=$userId&month=$month&year=$year'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FamilyEvent.fromJson(j))
              .toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false, message: 'Imeshindwa kupakia matukio');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<FamilyEvent>> createEvent({
    required int userId,
    required String title,
    required String date,
    String? time,
    List<int>? memberIds,
    bool isRecurring = false,
    String? recurrenceRule,
    String? notes,
    String? color,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'date': date,
          if (time != null) 'time': time,
          if (memberIds != null && memberIds.isNotEmpty)
            'member_ids': memberIds,
          'is_recurring': isRecurring,
          if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
          if (notes != null) 'notes': notes,
          if (color != null) 'color': color,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: FamilyEvent.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuunda tukio');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family/events/$eventId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kufuta tukio');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Shared Lists ────────────────────────────────────────────

  Future<FamilyListResult<SharedList>> getLists(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/lists?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => SharedList.fromJson(j))
              .toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false, message: 'Imeshindwa kupakia orodha');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<SharedList>> createList({
    required int userId,
    required String name,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/lists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'type': type,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: SharedList.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuunda orodha');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<SharedListItem>> addListItem({
    required int listId,
    required String title,
    int? assignedMemberId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/lists/$listId/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          if (assignedMemberId != null) 'assigned_member_id': assignedMemberId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: SharedListItem.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuongeza kipengele');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> toggleListItem(int itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/lists/items/$itemId/toggle'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(success: false, message: 'Imeshindwa kubadilisha');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> deleteList(int listId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family/lists/$listId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kufuta orodha');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Health Records ──────────────────────────────────────────

  Future<FamilyListResult<FamilyHealthRecord>> getHealthRecords(
      int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/health?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FamilyHealthRecord.fromJson(j))
              .toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false, message: 'Imeshindwa kupakia rekodi za afya');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<FamilyHealthRecord>> addHealthRecord({
    required int userId,
    required int memberId,
    required String memberName,
    required String type,
    required String title,
    String? details,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/health'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'member_id': memberId,
          'member_name': memberName,
          'type': type,
          'title': title,
          if (details != null) 'details': details,
          'date': date,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: FamilyHealthRecord.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuongeza rekodi');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> deleteHealthRecord(int recordId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family/health/$recordId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kufuta rekodi');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Emergency Contacts ──────────────────────────────────────

  Future<FamilyListResult<EmergencyContact>> getEmergencyContacts(
      int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/emergency?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => EmergencyContact.fromJson(j))
              .toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false,
          message: 'Imeshindwa kupakia mawasiliano ya dharura');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<EmergencyContact>> addEmergencyContact({
    required int userId,
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/emergency'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'phone': phone,
          if (relationship != null) 'relationship': relationship,
          'is_primary': isPrimary,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: EmergencyContact.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuongeza mawasiliano');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> deleteEmergencyContact(int contactId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family/emergency/$contactId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kufuta mawasiliano');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Chores ──────────────────────────────────────────────────

  Future<FamilyListResult<Chore>> getChores(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/chores?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items =
              (data['data'] as List).map((j) => Chore.fromJson(j)).toList();
          return FamilyListResult(success: true, items: items);
        }
      }
      return FamilyListResult(
          success: false, message: 'Imeshindwa kupakia kazi');
    } catch (e) {
      return FamilyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<Chore>> addChore({
    required int userId,
    required String title,
    int? assignedMemberId,
    String? assignedMemberName,
    String? dueDate,
    int points = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/chores'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          if (assignedMemberId != null) 'assigned_member_id': assignedMemberId,
          if (assignedMemberName != null)
            'assigned_member_name': assignedMemberName,
          if (dueDate != null) 'due_date': dueDate,
          'points': points,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(
            success: true, data: Chore.fromJson(data['data']));
      }
      return FamilyResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kuongeza kazi');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FamilyResult<void>> markChoreDone(int choreId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/chores/$choreId/done'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
          success: false, message: 'Imeshindwa kukamilisha kazi');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Search TAJIRI User (for linking) ────────────────────────

  Future<FamilyResult<Map<String, dynamic>>> searchUserByPhone(
      String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/search-user?phone=$phone'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return FamilyResult(
              success: true,
              data: data['data'] as Map<String, dynamic>);
        }
      }
      return FamilyResult(
          success: false, message: 'Mtumiaji hajapatikana');
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }
}
