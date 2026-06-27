import '../../my_baby/models/my_baby_models.dart' as baby;
import '../../my_children/models/my_children_models.dart';
import 'graphql_my_baby_service.dart';

/// GraphQL my children — reuses my_baby API (rev 209) with Child model mapping.
class GraphqlMyChildrenService {
  static baby.FeedingType _babyFeedingType(FeedingType type) =>
      baby.FeedingType.values.firstWhere((v) => v.name == type.name);

  static baby.BreastSide? _babySide(BreastSide? side) {
    if (side == null) return null;
    return baby.BreastSide.values.firstWhere((v) => v.name == side.name);
  }

  static Child _toChild(baby.Baby b) => Child(
        id: b.id,
        userId: b.userId,
        name: b.name,
        dateOfBirth: b.dateOfBirth,
        gender: b.gender,
        birthWeightGrams: b.birthWeightGrams,
        birthLengthCm: b.birthLengthCm,
      );

  static FeedingLog _toFeeding(baby.FeedingLog f) => FeedingLog.fromJson({
        'id': f.id,
        'baby_id': f.babyId,
        'type': f.type.name,
        if (f.side != null) 'side': f.side!.name,
        if (f.durationMinutes != null) 'duration_minutes': f.durationMinutes,
        if (f.amountMl != null) 'amount_ml': f.amountMl,
        if (f.foodDescription != null) 'food_description': f.foodDescription,
        'date': f.date.toIso8601String(),
        if (f.loggedBy != null) 'logged_by': f.loggedBy,
      });

  static SleepSession _toSleep(baby.SleepSession s) => SleepSession.fromJson({
        if (s.id != null) 'id': s.id,
        'baby_id': s.babyId,
        'start_time': s.startTime.toIso8601String(),
        if (s.endTime != null) 'end_time': s.endTime!.toIso8601String(),
        if (s.durationMinutes != null) 'duration_minutes': s.durationMinutes,
        'type': s.type,
        if (s.notes != null) 'notes': s.notes,
        if (s.loggedBy != null) 'logged_by': s.loggedBy,
      });

  static DiaperLog _toDiaper(baby.DiaperLog d) => DiaperLog.fromJson({
        if (d.id != null) 'id': d.id,
        'baby_id': d.babyId,
        'type': d.type,
        if (d.color != null) 'color': d.color,
        if (d.notes != null) 'notes': d.notes,
        'logged_at': d.loggedAt.toIso8601String(),
        if (d.loggedBy != null) 'logged_by': d.loggedBy,
      });

  static GrowthMeasurement _toGrowth(baby.GrowthMeasurement g) =>
      GrowthMeasurement.fromJson({
        if (g.id != null) 'id': g.id,
        'baby_id': g.babyId,
        if (g.weightKg != null) 'weight_kg': g.weightKg,
        if (g.heightCm != null) 'height_cm': g.heightCm,
        if (g.headCm != null) 'head_cm': g.headCm,
        'measured_at': g.measuredAt.toIso8601String(),
        if (g.notes != null) 'notes': g.notes,
      });

  static Future<MyBabyListResult<Baby>> getMyBabies() async {
    final result = await GraphqlMyBabyService.getMyBabies();
    if (!result.success) {
      return MyBabyListResult(success: false, message: result.message);
    }
    return MyBabyListResult(
      success: true,
      items: result.items.map(_toChild).toList(),
    );
  }

  static Future<MyBabyResult<Baby>> registerBaby({
    required String name,
    required DateTime dateOfBirth,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
  }) async {
    final result = await GraphqlMyBabyService.registerBaby(
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      birthWeightGrams: birthWeightGrams,
      birthLengthCm: birthLengthCm,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toChild(result.data!));
  }

  static Future<MyBabyResult<Baby>> updateBaby({
    required int babyId,
    String? name,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
  }) async {
    final result = await GraphqlMyBabyService.updateBaby(
      babyId: babyId,
      name: name,
      gender: gender,
      birthWeightGrams: birthWeightGrams,
      birthLengthCm: birthLengthCm,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toChild(result.data!));
  }

  static Future<MyBabyResult<FeedingLog>> logFeeding({
    required int babyId,
    required FeedingType type,
    BreastSide? side,
    int? durationMinutes,
    double? amountMl,
    String? foodDescription,
  }) async {
    final result = await GraphqlMyBabyService.logFeeding(
      babyId: babyId,
      type: _babyFeedingType(type),
      side: _babySide(side),
      durationMinutes: durationMinutes,
      amountMl: amountMl,
      foodDescription: foodDescription,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toFeeding(result.data!));
  }

  static Future<MyBabyListResult<FeedingLog>> getFeedingHistory(
    int babyId,
    DateTime date,
  ) async {
    final result =
        await GraphqlMyBabyService.getFeedingHistory(babyId, date);
    if (!result.success) {
      return MyBabyListResult(success: false, message: result.message);
    }
    return MyBabyListResult(
      success: true,
      items: result.items.map(_toFeeding).toList(),
    );
  }

  static Future<MyBabyResult<SleepSession>> logSleep({
    required int babyId,
    required DateTime startTime,
    DateTime? endTime,
    String type = 'nap',
    String? notes,
  }) async {
    final result = await GraphqlMyBabyService.logSleep(
      babyId: babyId,
      startTime: startTime,
      endTime: endTime,
      type: type,
      notes: notes,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toSleep(result.data!));
  }

  static Future<MyBabyResult<SleepSession>> updateSleep({
    required int sessionId,
    required DateTime endTime,
  }) async {
    final result = await GraphqlMyBabyService.updateSleep(
      sessionId: sessionId,
      endTime: endTime,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toSleep(result.data!));
  }

  static Future<MyBabyListResult<SleepSession>> getSleepHistory(
    int babyId, {
    DateTime? date,
  }) async {
    final result =
        await GraphqlMyBabyService.getSleepHistory(babyId, date: date);
    if (!result.success) {
      return MyBabyListResult(success: false, message: result.message);
    }
    return MyBabyListResult(
      success: true,
      items: result.items.map(_toSleep).toList(),
    );
  }

  static Future<MyBabyResult<DiaperLog>> logDiaper({
    required int babyId,
    required String type,
    String? color,
    String? notes,
  }) async {
    final result = await GraphqlMyBabyService.logDiaper(
      babyId: babyId,
      type: type,
      color: color,
      notes: notes,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toDiaper(result.data!));
  }

  static Future<MyBabyListResult<DiaperLog>> getDiaperHistory(
    int babyId, {
    DateTime? date,
  }) async {
    final result =
        await GraphqlMyBabyService.getDiaperHistory(babyId, date: date);
    if (!result.success) {
      return MyBabyListResult(success: false, message: result.message);
    }
    return MyBabyListResult(
      success: true,
      items: result.items.map(_toDiaper).toList(),
    );
  }

  static Future<MyBabyResult<GrowthMeasurement>> logGrowth({
    required int babyId,
    double? weightKg,
    double? heightCm,
    double? headCm,
    required DateTime measuredAt,
    String? notes,
  }) async {
    final result = await GraphqlMyBabyService.logGrowth(
      babyId: babyId,
      weightKg: weightKg,
      heightCm: heightCm,
      headCm: headCm,
      measuredAt: measuredAt,
      notes: notes,
    );
    if (!result.success || result.data == null) {
      return MyBabyResult(success: false, message: result.message);
    }
    return MyBabyResult(success: true, data: _toGrowth(result.data!));
  }

  static Future<MyBabyListResult<GrowthMeasurement>> getGrowthHistory(
    int babyId,
  ) async {
    final result = await GraphqlMyBabyService.getGrowthHistory(babyId);
    if (!result.success) {
      return MyBabyListResult(success: false, message: result.message);
    }
    return MyBabyListResult(
      success: true,
      items: result.items.map(_toGrowth).toList(),
    );
  }
}
