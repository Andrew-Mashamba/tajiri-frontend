// lib/fitness/models/fitness_models.dart
import 'package:flutter/material.dart';

// ─── Workout Types ──────────────────────────────────────────────

enum WorkoutType {
  strength,
  hiit,
  yoga,
  dance,
  pilates,
  kickboxing,
  cycling,
  running,
  swimming,
  meditation,
  stretching,
  bodyweight,
  football,
  crossfit;

  String get displayName {
    switch (this) {
      case WorkoutType.strength: return 'Nguvu';
      case WorkoutType.hiit: return 'HIIT';
      case WorkoutType.yoga: return 'Yoga';
      case WorkoutType.dance: return 'Dansi';
      case WorkoutType.pilates: return 'Pilates';
      case WorkoutType.kickboxing: return 'Kickboxing';
      case WorkoutType.cycling: return 'Baiskeli';
      case WorkoutType.running: return 'Kukimbia';
      case WorkoutType.swimming: return 'Kuogelea';
      case WorkoutType.meditation: return 'Kutafakari';
      case WorkoutType.stretching: return 'Kunyoosha';
      case WorkoutType.bodyweight: return 'Mwili';
      case WorkoutType.football: return 'Mpira';
      case WorkoutType.crossfit: return 'CrossFit';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutType.strength: return Icons.fitness_center_rounded;
      case WorkoutType.hiit: return Icons.bolt_rounded;
      case WorkoutType.yoga: return Icons.self_improvement_rounded;
      case WorkoutType.dance: return Icons.music_note_rounded;
      case WorkoutType.pilates: return Icons.accessibility_new_rounded;
      case WorkoutType.kickboxing: return Icons.sports_mma_rounded;
      case WorkoutType.cycling: return Icons.pedal_bike_rounded;
      case WorkoutType.running: return Icons.directions_run_rounded;
      case WorkoutType.swimming: return Icons.pool_rounded;
      case WorkoutType.meditation: return Icons.spa_rounded;
      case WorkoutType.stretching: return Icons.straighten_rounded;
      case WorkoutType.bodyweight: return Icons.person_rounded;
      case WorkoutType.football: return Icons.sports_soccer_rounded;
      case WorkoutType.crossfit: return Icons.sports_gymnastics_rounded;
    }
  }

  static WorkoutType fromString(String? s) {
    return WorkoutType.values.firstWhere((v) => v.name == s, orElse: () => WorkoutType.strength);
  }
}

enum Difficulty { beginner, intermediate, advanced }

// ─── Gym ────────────────────────────────────────────────────────

class Gym {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double rating;
  final int totalReviews;
  final int memberCount;
  final String? imageUrl;
  final List<String> photos;
  final List<String> facilities;
  final List<WorkoutType> workoutTypes;
  final String? openingHours;
  final bool isOpen;
  final bool hasLiveStreaming;
  final double monthlyPrice;
  final double? yearlyPrice;
  final String? description;
  final List<GymTrainer> trainers;

  Gym({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.rating = 0,
    this.totalReviews = 0,
    this.memberCount = 0,
    this.imageUrl,
    this.photos = const [],
    this.facilities = const [],
    this.workoutTypes = const [],
    this.openingHours,
    this.isOpen = false,
    this.hasLiveStreaming = false,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.description,
    this.trainers = const [],
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'],
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      facilities: (json['facilities'] as List?)?.cast<String>() ?? [],
      workoutTypes: (json['workout_types'] as List?)?.map((w) => WorkoutType.fromString(w)).toList() ?? [],
      openingHours: json['opening_hours'],
      isOpen: json['is_open'] ?? false,
      hasLiveStreaming: json['has_live_streaming'] ?? false,
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 0,
      yearlyPrice: (json['yearly_price'] as num?)?.toDouble(),
      description: json['description'],
      trainers: (json['trainers'] as List?)?.map((t) => GymTrainer.fromJson(t)).toList() ?? [],
    );
  }
}

class GymTrainer {
  final int id;
  final String name;
  final String? photoUrl;
  final String? specialty;
  final int experienceYears;

  GymTrainer({required this.id, required this.name, this.photoUrl, this.specialty, this.experienceYears = 0});

  factory GymTrainer.fromJson(Map<String, dynamic> json) => GymTrainer(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        photoUrl: json['photo_url'],
        specialty: json['specialty'],
        experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      );
}

// ─── Gym Membership ─────────────────────────────────────────────

enum MembershipStatus { active, expired, cancelled, paused }

class GymMembership {
  final int id;
  final int userId;
  final int gymId;
  final String gymName;
  final String? gymImageUrl;
  final MembershipStatus status;
  final String frequency; // monthly, yearly
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? nextPaymentDate;

  GymMembership({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.gymName,
    this.gymImageUrl,
    required this.status,
    required this.frequency,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.nextPaymentDate,
  });

  factory GymMembership.fromJson(Map<String, dynamic> json) => GymMembership(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        gymId: json['gym_id'] ?? 0,
        gymName: json['gym_name'] ?? '',
        gymImageUrl: json['gym_image_url'],
        status: MembershipStatus.values.firstWhere((v) => v.name == json['status'], orElse: () => MembershipStatus.active),
        frequency: json['frequency'] ?? 'monthly',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
        nextPaymentDate: json['next_payment_date'] != null ? DateTime.tryParse(json['next_payment_date']) : null,
      );

  bool get isActive => status == MembershipStatus.active;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}

// ─── Live Class / On-Demand ─────────────────────────────────────

class FitnessClass {
  final int id;
  final String title;
  final int gymId;
  final String gymName;
  final String? trainerName;
  final String? trainerPhotoUrl;
  final WorkoutType workoutType;
  final String difficulty; // beginner, intermediate, advanced
  final int durationMinutes;
  final DateTime scheduledAt;
  final bool isLive;
  final bool isRecorded;
  final String? streamUrl;
  final String? thumbnailUrl;
  final int viewerCount;
  final int? calorieEstimate;
  final List<String> equipment;
  final String? description;

  FitnessClass({
    required this.id,
    required this.title,
    required this.gymId,
    required this.gymName,
    this.trainerName,
    this.trainerPhotoUrl,
    required this.workoutType,
    required this.difficulty,
    required this.durationMinutes,
    required this.scheduledAt,
    this.isLive = false,
    this.isRecorded = false,
    this.streamUrl,
    this.thumbnailUrl,
    this.viewerCount = 0,
    this.calorieEstimate,
    this.equipment = const [],
    this.description,
  });

  factory FitnessClass.fromJson(Map<String, dynamic> json) => FitnessClass(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        gymId: json['gym_id'] ?? 0,
        gymName: json['gym_name'] ?? '',
        trainerName: json['trainer_name'],
        trainerPhotoUrl: json['trainer_photo_url'],
        workoutType: WorkoutType.fromString(json['workout_type']),
        difficulty: json['difficulty'] ?? 'beginner',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
        scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
        isLive: json['is_live'] ?? false,
        isRecorded: json['is_recorded'] ?? false,
        streamUrl: json['stream_url'],
        thumbnailUrl: json['thumbnail_url'],
        viewerCount: (json['viewer_count'] as num?)?.toInt() ?? 0,
        calorieEstimate: (json['calorie_estimate'] as num?)?.toInt(),
        equipment: (json['equipment'] as List?)?.cast<String>() ?? [],
        description: json['description'],
      );

  String get difficultyLabel {
    switch (difficulty) {
      case 'beginner': return 'Mwanzo';
      case 'intermediate': return 'Wastani';
      case 'advanced': return 'Ngumu';
      default: return difficulty;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'beginner': return const Color(0xFF4CAF50);
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ─── Workout Log (Tracking) ─────────────────────────────────────

class WorkoutLog {
  final int id;
  final int userId;
  final WorkoutType type;
  final int durationMinutes;
  final int? caloriesBurned;
  final String? notes;
  final DateTime date;
  final int? gymId;
  final int? classId;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    this.caloriesBurned,
    this.notes,
    required this.date,
    this.gymId,
    this.classId,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        type: WorkoutType.fromString(json['type']),
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        caloriesBurned: (json['calories_burned'] as num?)?.toInt(),
        notes: json['notes'],
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        gymId: (json['gym_id'] as num?)?.toInt(),
        classId: (json['class_id'] as num?)?.toInt(),
      );
}

// ─── Fitness Stats ──────────────────────────────────────────────

class FitnessStats {
  final int totalWorkouts;
  final int totalMinutes;
  final int totalCalories;
  final int currentStreak;
  final int bestStreak;
  final double? currentWeight;
  final double? goalWeight;
  final int thisWeekWorkouts;
  final int thisWeekMinutes;
  final int weeklyGoalMinutes;

  FitnessStats({
    this.totalWorkouts = 0,
    this.totalMinutes = 0,
    this.totalCalories = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.currentWeight,
    this.goalWeight,
    this.thisWeekWorkouts = 0,
    this.thisWeekMinutes = 0,
    this.weeklyGoalMinutes = 150,
  });

  factory FitnessStats.fromJson(Map<String, dynamic> json) => FitnessStats(
        totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
        totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
        totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
        bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
        currentWeight: (json['current_weight'] as num?)?.toDouble(),
        goalWeight: (json['goal_weight'] as num?)?.toDouble(),
        thisWeekWorkouts: (json['this_week_workouts'] as num?)?.toInt() ?? 0,
        thisWeekMinutes: (json['this_week_minutes'] as num?)?.toInt() ?? 0,
        weeklyGoalMinutes: (json['weekly_goal_minutes'] as num?)?.toInt() ?? 150,
      );

  double get weeklyProgress => weeklyGoalMinutes > 0 ? (thisWeekMinutes / weeklyGoalMinutes).clamp(0.0, 1.0) : 0;
}

// ─── Result wrappers ────────────────────────────────────────────

class FitnessResult<T> {
  final bool success;
  final T? data;
  final String? message;
  FitnessResult({required this.success, this.data, this.message});
}

class FitnessListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  FitnessListResult({required this.success, this.items = const [], this.message});
}
