// lib/ambulance/services/ambulance_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/ambulance_models.dart';

class AmbulanceService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Emergency SOS ────────────────────────────────────────────

  Future<SingleResult<Emergency>> triggerSOS({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final resp = await _dio.post('/ambulance/sos', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Emergency.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Emergency>> getDispatchStatus(int emergencyId) async {
    try {
      final resp = await _dio.get('/ambulance/dispatch/$emergencyId');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Emergency.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Ambulance Tracking ──────────────────────────────────────

  Future<SingleResult<AmbulanceTracking>> trackAmbulance(
      int emergencyId) async {
    try {
      final resp = await _dio.get('/ambulance/track/$emergencyId');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: AmbulanceTracking.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<String>> shareTrackingLink(int emergencyId) async {
    try {
      final resp =
          await _dio.get('/ambulance/track/$emergencyId/share');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: data['data']['url']?.toString());
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Medical Profile ─────────────────────────────────────────

  Future<SingleResult<MedicalProfile>> getMedicalProfile() async {
    try {
      final resp = await _dio.get('/ambulance/medical-profile');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: MedicalProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<MedicalProfile>> updateMedicalProfile(
      MedicalProfile profile) async {
    try {
      final resp =
          await _dio.put('/ambulance/medical-profile', data: profile.toJson());
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: MedicalProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Emergency Contacts ──────────────────────────────────────

  Future<PaginatedResult<EmergencyContact>> getEmergencyContacts() async {
    try {
      final resp = await _dio.get('/ambulance/emergency-contacts');
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => EmergencyContact.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EmergencyContact>> addEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    try {
      final resp = await _dio.post('/ambulance/emergency-contacts', data: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: EmergencyContact.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<bool>> removeEmergencyContact(int contactId) async {
    try {
      final resp =
          await _dio.delete('/ambulance/emergency-contacts/$contactId');
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Insurance ────────────────────────────────────────────────

  Future<PaginatedResult<InsuranceInfo>> getInsuranceInfo() async {
    try {
      final resp = await _dio.get('/ambulance/insurance');
      final data = resp.data;
      if (data['success'] == true) {
        final raw = data['data'];
        final list = raw is List
            ? raw.map((j) => InsuranceInfo.fromJson(j)).toList()
            : [InsuranceInfo.fromJson(raw)];
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<InsuranceInfo>> saveInsuranceInfo({
    required String provider,
    required String policyNumber,
    String? memberId,
    String? coverageType,
    String? cardPhotoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'provider': provider,
        'policy_number': policyNumber,
        if (memberId != null) 'member_id': memberId,
        if (coverageType != null) 'coverage_type': coverageType,
        if (cardPhotoPath != null)
          'card_photo': await MultipartFile.fromFile(cardPhotoPath),
      });
      final resp = await _dio.post('/ambulance/insurance', data: formData);
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsuranceInfo.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<InsuranceInfo>> verifyInsurance(
      String policyNumber) async {
    try {
      final resp = await _dio.get('/ambulance/insurance/verify',
          queryParameters: {'policy_number': policyNumber});
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsuranceInfo.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Family Profiles ─────────────────────────────────────────

  Future<PaginatedResult<FamilyProfile>> getFamilyProfiles() async {
    try {
      final resp = await _dio.get('/ambulance/family');
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => FamilyProfile.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<FamilyProfile>> addFamilyProfile(
      FamilyProfile profile) async {
    try {
      final resp =
          await _dio.post('/ambulance/family', data: profile.toJson());
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FamilyProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<FamilyProfile>> updateFamilyProfile(
      int profileId, FamilyProfile profile) async {
    try {
      final resp = await _dio.put('/ambulance/family/$profileId',
          data: profile.toJson());
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FamilyProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<bool>> deleteFamilyProfile(int profileId) async {
    try {
      final resp = await _dio.delete('/ambulance/family/$profileId');
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Hospitals ────────────────────────────────────────────────

  Future<PaginatedResult<Hospital>> getHospitals({
    double? lat,
    double? lng,
    String? capability,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      if (capability != null) params['capability'] = capability;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final resp =
          await _dio.get('/ambulance/hospitals', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => Hospital.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── First Aid Guides ────────────────────────────────────────

  Future<PaginatedResult<FirstAidGuide>> getFirstAidGuides(
      {String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;

      final resp =
          await _dio.get('/ambulance/first-aid', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => FirstAidGuide.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Emergency History ────────────────────────────────────────

  Future<PaginatedResult<Emergency>> getEmergencyHistory(
      {int page = 1}) async {
    try {
      final resp = await _dio
          .get('/ambulance/history', queryParameters: {'page': page});
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => Emergency.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Subscription Plans ──────────────────────────────────────

  Future<PaginatedResult<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final resp = await _dio.get('/ambulance/plans');
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => SubscriptionPlan.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Subscription>> getCurrentSubscription() async {
    try {
      final resp = await _dio.get('/ambulance/plans/current');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Subscription.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Subscription>> subscribePlan({
    required int planId,
    required String paymentMethod,
  }) async {
    try {
      final resp = await _dio.post('/ambulance/plans/subscribe', data: {
        'plan_id': planId,
        'payment_method': paymentMethod,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Subscription.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Accident Reporting ───────────────────────────────────────

  Future<SingleResult<AccidentReport>> reportAccident({
    required double latitude,
    required double longitude,
    String? address,
    required String description,
    required String severity,
    List<String> photoPaths = const [],
  }) async {
    try {
      final formMap = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        'description': description,
        'severity': severity,
      };
      for (int i = 0; i < photoPaths.length; i++) {
        formMap['photos[$i]'] = await MultipartFile.fromFile(photoPaths[i]);
      }
      final formData = FormData.fromMap(formMap);
      final resp =
          await _dio.post('/ambulance/accidents/report', data: formData);
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: AccidentReport.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Insurance Pre-Auth ───────────────────────────────────────

  Future<SingleResult<InsurancePreAuth>> preAuthorizeInsurance({
    required String policyNumber,
    required String emergencyType,
  }) async {
    try {
      final resp = await _dio.post('/ambulance/insurance/pre-auth', data: {
        'policy_number': policyNumber,
        'emergency_type': emergencyType,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsurancePreAuth.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Payment ─────────────────────────────────────────────────

  Future<SingleResult<bool>> payEmergency({
    required int emergencyId,
    required String paymentMethod,
    required String phone,
  }) async {
    try {
      final resp = await _dio.post('/ambulance/payments', data: {
        'emergency_id': emergencyId,
        'payment_method': paymentMethod,
        'phone': phone,
      });
      final data = resp.data;
      return SingleResult(
        success: data['success'] == true,
        message: data['message'],
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── AED Locations ──────────────────────────────────────────

  Future<PaginatedResult<AedLocation>> getAedLocations({
    double? lat,
    double? lng,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      final resp =
          await _dio.get('/ambulance/aed-locations', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => AedLocation.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Community Responders ─────────────────────────────────────

  Future<SingleResult<bool>> registerResponder(
      Map<String, dynamic> data_) async {
    try {
      final resp = await _dio.post('/ambulance/responders', data: data_);
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<FirstResponder>> getNearbyResponders({
    double? lat,
    double? lng,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      final resp =
          await _dio.get('/ambulance/responders/nearby', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => FirstResponder.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<FirstResponder>> getBloodDonors(
      String bloodType) async {
    try {
      final resp = await _dio.get('/ambulance/blood-donors',
          queryParameters: {'blood_type': bloodType});
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => FirstResponder.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
