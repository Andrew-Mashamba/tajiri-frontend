# TAJIRI Fitness Module - Gym Marketplace & Fitness Streaming Design

> Research-backed design for a fitness module combining gym marketplace, fitness streaming, and health tracking, adapted for the Tanzanian market.

---

## Table of Contents

1. [Competitor Analysis](#1-competitor-analysis)
2. [Recommended Feature Set](#2-recommended-feature-set)
3. [Gym Marketplace](#3-gym-marketplace)
4. [Fitness Streaming Architecture](#4-fitness-streaming-architecture)
5. [Fitness Tracking](#5-fitness-tracking)
6. [Social Fitness Features](#6-social-fitness-features)
7. [Data Models](#7-data-models)
8. [API Endpoints](#8-api-endpoints)
9. [Screen Architecture](#9-screen-architecture)
10. [Monetization](#10-monetization)
11. [Tanzania-Specific Adaptations](#11-tanzania-specific-adaptations)

---

## 1. Competitor Analysis

### 1.1 Apple Fitness+ (Premium Streaming - $9.99/mo)

**Workout Types (12):** Strength, HIIT, Kickboxing, Yoga, Rowing, Pilates, Cycling, Treadmill Run, Dance, Core, Mindful Cooldown, Meditation. Sessions 5-45 minutes, new content weekly.

**Personalization:**
- Custom Plans auto-generated from user preferences (Get Started / Stay Consistent / Push Further tiers)
- "For You" tab with recommendations based on favorite activities, trainers, durations, music
- Audio Focus toggle (prioritize trainer voice vs. music volume)
- Stacks feature: queue multiple workouts/meditations back-to-back

**Metrics & Watch Integration:**
- Real-time heart rate, calories burned, activity ring progress
- Burn Bar: compares your effort to others who did the same workout
- Post-workout summary with insights
- AirPods Pro integration for stats display during workout

**Social:**
- SharePlay for group workouts over FaceTime
- Family Sharing (up to 5 members)
- Awards/badges for accomplishments and streaks

**Content:**
- 30+ certified trainers with profiles
- Artist Spotlight series (Taylor Swift, Bad Bunny, Karol G, etc.)
- Time to Walk: audio walking workouts with celebrity stories
- Multi-week structured Programs (e.g., "Build a Yoga Habit in 4 Weeks", "Strength Basics in 3 Weeks")
- Video-first with audio-only options for walks/runs/meditations

**What to adopt:** Custom Plans, workout stacking, Burn Bar concept, structured programs, trainer profiles, awards/streaks. **What to skip:** Apple Watch dependency, SharePlay (use TAJIRI's own social layer).

### 1.2 ClassPass (Gym Marketplace - $19-$159/mo)

**Credit-Based System:** Members buy monthly credit plans. Credit costs vary by class type, studio demand, time of day, and location. Dynamic pricing via ML (SmartRate).

**Gym Onboarding:** No upfront fee. Gyms create profile, add class descriptions/photos/amenities, connect existing booking system. Integrates with 100+ booking systems.

**SmartTools (ML-powered):**
- SmartSpot: identifies spots predicted to go unfilled, protects direct bookings
- SmartRate: dynamically adjusts credit costs to optimize payouts (20% higher payouts for partners)

**Revenue Model:** Gyms paid per booking as percentage of their lowest package rate. Monetizes "perishable inventory" (unfilled spots).

**Scale:** 88,000+ venues, 30+ countries, merged with EGYM at $7.5B valuation (March 2026).

**What to adopt:** Credit-based booking, dynamic class pricing, gym profile system, SmartSpot concept for fill-rate optimization. **What to adapt:** Simpler credit system for Tanzania (fewer tiers).

### 1.3 Wellhub/Gympass (Corporate Wellness)

**Model:** Employer-sponsored benefit. Companies buy annual subscriptions; employees get flexible monthly plans at 30-50% less than retail gym memberships.

**Network:** 50,000+ gyms, studios, and wellness apps. Plans include gym access + digital wellness apps (meditation, nutrition, sleep).

**What to adopt:** The B2B corporate wellness angle is valuable for Tanzania's growing corporate sector (banks, telecoms, NGOs). **What to adapt:** Start B2C first, add B2B employer tier later.

### 1.4 Peloton (Streaming + Equipment - $12.99-$28.99/mo)

**Features:**
- Peloton IQ: AI-powered personalized workout plans + performance insights
- Club Peloton: loyalty program (Bronze to Legend tiers, earn points for showing up)
- Official Teams: community groups for motivation
- Live + on-demand classes, 5-90 minutes
- Multi-device streaming (phone, tablet, TV, web)

**What to adopt:** AI workout recommendations, loyalty tier system, live + on-demand hybrid model. **What to skip:** Equipment lock-in model.

### 1.5 Les Mills+ (Group Fitness Streaming - $14.99/mo)

**Features:**
- 20 programs, 2,000+ workouts (strength, cardio, yoga, martial arts, cycling, dance, HIIT, wellness)
- 3-12 week structured workout plans, bootcamps, challenges
- Offline downloads (never expire)
- Stream on 3 devices simultaneously
- Scientifically designed programs with proven results

**What to adopt:** Offline downloads (critical for Tanzania's connectivity), multi-device streaming, structured multi-week plans, scientific program design.

---

## 2. Recommended Feature Set for TAJIRI Fitness

### Phase 1 (MVP)
- Gym directory and profiles
- Class scheduling and booking (credit-based)
- QR code check-in at gyms
- Basic fitness tracking (steps, manual workout log, weight)
- Workout sharing to TAJIRI feed
- Live fitness class streaming (reuse existing livestream infra)

### Phase 2
- On-demand workout video library
- Structured multi-week programs
- Trainer profiles and follow system
- Goals, streaks, and badges
- Challenges between friends
- Leaderboards

### Phase 3
- AI-powered workout recommendations
- Offline workout downloads
- Corporate/employer wellness tier (B2B)
- Nutrition tracking
- Progress photos with body composition estimation
- Gym owner analytics dashboard

---

## 3. Gym Marketplace

### 3.1 Gym Registration Flow

```
1. Gym owner opens TAJIRI app -> Profile -> "Register Your Gym"
2. Business verification:
   - Business name, TIN (Tax ID), business license photo
   - Owner name, phone, email
   - Physical address + GPS pin on map
3. Gym profile setup:
   - Logo, cover photos (min 3, max 10)
   - Facilities list (checkboxes): weights, cardio machines, pool, sauna,
     group class studio, parking, showers, lockers, wifi, AC, juice bar
   - Operating hours (per day of week)
   - Description (Swahili + English)
4. Class/service setup:
   - Add classes: name, type, description, trainer, capacity, duration,
     schedule (recurring/one-time), credit cost
   - Add memberships: daily pass, weekly, monthly, annual (prices in TZS)
5. Payment setup:
   - M-Pesa business number (Vodacom/Airtel)
   - Bank account (optional)
6. Admin review & approval (24-48 hours)
7. Gym goes live on marketplace
```

### 3.2 Gym Profile Features

```
GymProfile
├── Header: cover photo carousel + logo overlay
├── Info Bar: rating (stars), review count, distance from user
├── Quick Actions: [Book Class] [Get Pass] [Follow] [Share]
├── Tabs:
│   ├── About: description, facilities grid, hours, location map
│   ├── Classes: filterable schedule (by day, type, trainer)
│   ├── Trainers: trainer cards with bio, specialties, rating
│   ├── Reviews: star ratings + text reviews + photos
│   └── Gallery: photos and videos of the gym
├── Membership Plans: horizontal scroll cards with pricing
└── Similar Gyms: recommendation row
```

### 3.3 Subscription Models

| Model | Description | Tanzania Price Range |
|-------|-------------|---------------------|
| **Day Pass** | Single-day access to one gym | TZS 5,000 - 15,000 |
| **Class Credit Pack** | Buy 5/10/20 credits, use at any partner gym | TZS 25,000 - 80,000 |
| **Single Gym Monthly** | Unlimited access to one gym | TZS 50,000 - 150,000 |
| **Multi-Gym Pass** | Access to all partner gyms (ClassPass model) | TZS 80,000 - 200,000/mo |
| **Corporate Plan** | Employer-sponsored, per-employee pricing | TZS 30,000 - 60,000/employee/mo |

Credit system: 1 credit = ~TZS 5,000. Classes cost 1-5 credits depending on demand, time, and gym tier.

### 3.4 Class Scheduling & Booking

```
Booking Flow:
1. Browse classes (filter by: type, date, time, gym, trainer, credits)
2. Tap class -> see details (trainer, description, spots left, credit cost)
3. Confirm booking -> credits deducted
4. Receive booking confirmation with QR code
5. Reminder notification 1 hour before class
6. Check-in at gym via:
   a. QR code scan (gym has TAJIRI scanner)
   b. GPS proximity check (within 50m of gym)
   c. Manual check-in by gym staff (fallback)
7. Post-class: rate class, rate trainer, optional review
8. No-show penalty: credits forfeited, 3 no-shows = 24hr booking freeze
```

### 3.5 Check-in Verification

**Primary: QR Code**
- User shows QR code from booking confirmation
- Gym staff scans with TAJIRI app (gym mode)
- Validates booking, marks attendance
- Works offline (QR contains signed JWT with booking data)

**Secondary: GPS Geofencing**
- User taps "Check In" when within 50m of gym GPS coordinates
- Validates against booking time window (30 min before to 15 min after)
- Fallback when QR scanner unavailable

**Tertiary: Manual**
- Gym staff manually confirms attendance in gym dashboard
- Used for walk-ins and technical issues

### 3.6 Ratings & Reviews

- 5-star rating for gym overall
- 5-star rating per class attended
- 5-star rating per trainer
- Text review (min 20 chars, max 500 chars)
- Photo attachments (max 3 per review)
- Verified badge on reviews from users who actually attended
- Gym owner can respond to reviews
- Report/flag system for inappropriate reviews

---

## 4. Fitness Streaming Architecture

### 4.1 Integration with TAJIRI Livestream Infrastructure

TAJIRI already has a mature livestream system with:
- `TajiriStreamingSDK` - custom RTMP streaming with adaptive bitrate (360p/720p/1080p)
- `LiveStreamService` - REST API for stream CRUD, comments, gifts
- `LiveStream` model - supports categories, tags, recording, scheduled streams
- Real-time chat during streams
- Viewer count tracking, likes, comments

**Fitness streams are a specialized category** within the existing livestream system. No new streaming infrastructure needed.

### 4.2 Fitness Live Class Streaming

```
Gym/Trainer goes live:
1. Open TAJIRI -> Fitness tab -> "Go Live" (fitness-specific)
2. Select: class type, difficulty, duration estimate, equipment needed
3. Camera setup: front-facing (trainer view) or mounted (room view)
4. Optional: connect heart rate monitor via Bluetooth
5. Start streaming -> viewers join
6. During stream:
   - Real-time chat (encouragement, questions)
   - Viewer count and engagement metrics
   - Timer display (elapsed / remaining)
   - Exercise cue overlay (current exercise name, reps, sets)
   - Trainer can pin exercise instructions
7. Stream auto-records for on-demand replay
8. Post-stream: summary (duration, peak viewers, engagement)
```

### 4.3 On-Demand Replay

```
Recording Pipeline:
1. Live stream auto-recorded via TajiriStreamingSDK (isRecorded: true)
2. Post-stream processing:
   - Transcode to multiple qualities (360p, 720p, 1080p)
   - Generate thumbnail from key frame
   - Extract audio track for audio-only mode
   - Add chapter markers (if trainer tagged exercises during stream)
3. Published to on-demand library with metadata:
   - Workout type, difficulty, duration, equipment, trainer
   - Calorie estimate, muscle groups targeted
   - Chapter markers for skip-to-exercise
4. Users can:
   - Browse by category, trainer, difficulty, duration
   - Download for offline viewing (Phase 2)
   - Rate and review
   - Share to feed
```

### 4.4 Streaming Data Model Extension

Extend the existing `LiveStream` model with fitness-specific fields:

```dart
// Additional fields for fitness streams (sent via category='fitness' + metadata JSON)
{
  "workout_type": "hiit",           // strength, hiit, yoga, dance, cycling, etc.
  "difficulty": "intermediate",      // beginner, intermediate, advanced
  "duration_planned": 30,            // planned duration in minutes
  "equipment_needed": ["dumbbells", "mat"],
  "muscle_groups": ["chest", "triceps", "shoulders"],
  "calories_estimate": 250,
  "trainer_id": 42,                  // links to trainer profile
  "gym_id": 7,                       // links to gym (if gym-hosted)
  "is_fitness_class": true,
  "exercise_cues": [                 // timestamped exercise markers
    {"time": 120, "exercise": "Burpees", "reps": "12", "sets": "3"},
    {"time": 240, "exercise": "Mountain Climbers", "reps": "20", "sets": "3"}
  ]
}
```

### 4.5 Multiple Camera Angles (Phase 3)

- Primary camera: trainer front view (default)
- Secondary camera: wide room view (shows full movement)
- Optional: close-up cam for form detail
- Implementation: multiple RTMP streams to same room, viewer toggles angle
- Leverages existing co-host infrastructure from `LiveStream.cohosts`

---

## 5. Fitness Tracking (Tanzania-Adapted)

### 5.1 Design Philosophy

Most Tanzanian users will NOT have smartwatches. All tracking features must work with:
1. Phone sensors only (accelerometer, GPS)
2. Manual input as primary method
3. Optional Bluetooth device pairing as enhancement

### 5.2 Phone-Based Step Counting

```dart
// Use pedometer_2 package (or health package on iOS/Android)
// Implementation:
// - Background step counting via platform health APIs
// - Daily step goal (default 10,000, adjustable)
// - Weekly/monthly step history charts
// - Step count shared to TAJIRI feed (opt-in)
```

**Packages:** `pedometer_2` for cross-platform step counting, `health` package for deeper OS health integration.

### 5.3 Manual Workout Logging

```
Log Workout Screen:
├── Workout Type picker (Gym, Running, Walking, Cycling, Swimming, Yoga, Football, etc.)
├── Duration (hours:minutes)
├── Intensity: Light / Moderate / Vigorous
├── Auto-calculate estimated calories (based on type + duration + intensity + user weight)
├── Optional fields:
│   ├── Distance (km) - for running/cycling/walking
│   ├── Exercises performed (from exercise database)
│   │   ├── Exercise name
│   │   ├── Sets x Reps x Weight (kg)
│   │   └── Rest time
│   ├── Notes (free text)
│   └── Photos (gym selfie, etc.)
├── Location (auto-detect or manual)
└── Share to feed toggle
```

### 5.4 Weight Tracking

```
Weight Log:
- Enter weight in kg (Tanzania uses metric)
- Optional: body fat % (manual or from smart scale)
- Date auto-filled (can backdate)
- Chart: line graph showing weight over time
- Goal weight setting with projected timeline
- BMI auto-calculated and displayed
```

### 5.5 Water Intake Tracking

```
Water Tracker:
- Quick-add buttons: 250ml glass, 500ml bottle, 1L bottle, custom
- Daily goal: default 2.5L (adjustable)
- Visual progress: water glass filling animation
- Reminder notifications (configurable intervals)
- Daily/weekly history
```

### 5.6 Sleep Tracking (Manual)

```
Sleep Log:
- Bedtime and wake time (manual entry)
- Sleep quality rating: 1-5 stars
- Optional: notes (e.g., "woke up twice", "felt rested")
- Sleep duration auto-calculated
- Weekly sleep pattern chart
- Average sleep duration stat
- Goal: 7-9 hours (adjustable)
```

### 5.7 Goals, Streaks & Badges

**Goals:**
- Daily step goal
- Weekly workout frequency goal (e.g., 4 workouts/week)
- Weight goal (lose/gain/maintain)
- Water intake goal
- Sleep duration goal

**Streaks:**
- Workout streak (consecutive days with a logged workout)
- Step goal streak (consecutive days hitting step target)
- Check-in streak (consecutive gym visits)
- Longest streak displayed on profile

**Badges/Awards:**
| Badge | Criteria |
|-------|----------|
| First Step | Complete first workout |
| Week Warrior | 7-day workout streak |
| Month Monster | 30-day workout streak |
| Century | 100 workouts logged |
| Early Bird | 10 workouts before 7 AM |
| Night Owl | 10 workouts after 8 PM |
| Social Butterfly | Share 10 workouts to feed |
| Gym Explorer | Visit 5 different gyms |
| Class Act | Attend 20 group classes |
| Hydration Hero | Hit water goal 30 days in a row |
| Iron Will | Lift total 10,000 kg |
| Marathon | Log 42.2 km running total |
| Community Champion | Win 5 challenges |
| Trainer's Pet | Rate 10 classes |

### 5.8 Progress Photos

```
Progress Photo Feature:
- Take/upload photo with guided pose overlay (front, side, back)
- Photos stored privately (not shared unless user chooses)
- Side-by-side comparison slider (before/after)
- Timeline view of all progress photos
- Optional: share transformation to feed
- Photos tagged with date, weight, and body measurements
```

### 5.9 BMI Calculator

```
BMI Screen:
- Input: height (cm), weight (kg)
- Output: BMI value + category (Underweight/Normal/Overweight/Obese)
- Visual gauge showing where user falls
- History chart tracking BMI over time
- Educational info about healthy BMI range
```

---

## 6. Social Fitness Features

### 6.1 Workout Sharing to Feed

When a user completes a workout (manual log, class attendance, or fitness stream), they can share to the TAJIRI feed:

```
Workout Post Card:
┌─────────────────────────────────┐
│ [Avatar] Username                │
│ completed a workout              │
│                                  │
│ ┌─ Workout Summary Card ───────┐│
│ │ 🏋️ Strength Training          ││
│ │ 45 min · 320 cal · Gym Name  ││
│ │                               ││
│ │ Exercises:                    ││
│ │ Bench Press: 4x12 @ 60kg     ││
│ │ Squats: 4x10 @ 80kg          ││
│ │ + 3 more                      ││
│ │                               ││
│ │ 🔥 12-day streak              ││
│ └───────────────────────────────┘│
│                                  │
│ [Like] [Comment] [Share] [Save]  │
└─────────────────────────────────┘
```

This integrates with the existing `PostService` by adding a `workout` post type alongside existing types (text, image, video, audio, poll, etc.).

### 6.2 Fitness Challenges

```
Challenge System:
1. Create Challenge:
   - Challenge type: steps, workouts, calories, gym visits, specific exercise
   - Duration: 7 days, 14 days, 30 days, custom
   - Participants: invite friends, open to followers, gym community
   - Stake (optional): each participant puts in TZS X, winner takes pot
     (via TAJIRI Wallet)
   - Rules: most steps wins, most workouts wins, etc.

2. During Challenge:
   - Live leaderboard (updated from workout logs + step data)
   - Daily progress notifications
   - Trash talk / encouragement in challenge chat
   - Mid-challenge milestones ("You're halfway there!")

3. Challenge End:
   - Final leaderboard
   - Winner announced with celebratory animation
   - Badge awarded to winner
   - If staked: automatic payout via TAJIRI Wallet
   - Challenge summary shareable to feed
```

### 6.3 Leaderboards

```
Leaderboard Types:
├── Global (all TAJIRI Fitness users)
│   ├── Weekly steps
│   ├── Monthly workouts
│   └── Total calories burned
├── Friends
│   ├── Same categories as global
│   └── Filtered to people you follow
├── Gym-specific
│   ├── Most check-ins this month
│   ├── Most classes attended
│   └── Top-rated gym-goer
└── City/Region
    ├── Dar es Salaam, Arusha, Dodoma, Mwanza, etc.
    └── Same categories as global
```

### 6.4 Gym Community Groups

Extends TAJIRI's existing groups feature:
- Each gym auto-gets a community group
- Members who check in are auto-suggested to join
- Gym owner/staff are admins
- Used for: announcements, class updates, member discussions, trainer tips
- Integrates with existing `GroupService` and group screens

---

## 7. Data Models

### 7.1 Core Models

```dart
// lib/models/fitness_models.dart

class Gym {
  final int id;
  final int ownerId;
  final String name;
  final String? nameSwahili;
  final String? description;
  final String? descriptionSwahili;
  final String? logoPath;
  final List<String> coverPhotos;
  final String address;
  final String city;
  final String? region;
  final double latitude;
  final double longitude;
  final String phone;
  final String? email;
  final String? website;
  final List<String> facilities;     // ['weights', 'pool', 'sauna', ...]
  final Map<String, GymHours> hours; // {'monday': GymHours(...), ...}
  final double rating;
  final int reviewCount;
  final int memberCount;
  final int classCount;
  final bool isVerified;
  final String status;               // 'pending', 'active', 'suspended'
  final String? tinNumber;
  final DateTime createdAt;
  // Computed
  final double? distanceKm;          // from user's current location
  final bool? isFollowing;
}

class GymHours {
  final String openTime;  // "06:00"
  final String closeTime; // "22:00"
  final bool isClosed;
}

class GymClass {
  final int id;
  final int gymId;
  final int trainerId;
  final String name;
  final String? description;
  final String type;        // 'yoga', 'hiit', 'strength', 'dance', ...
  final String difficulty;  // 'beginner', 'intermediate', 'advanced'
  final int durationMinutes;
  final int capacity;
  final int bookedCount;
  final int creditCost;
  final List<String> equipmentNeeded;
  final List<String> muscleGroups;
  final int caloriesEstimate;
  final String? thumbnailPath;
  final DateTime scheduledAt;
  final bool isRecurring;
  final String? recurringPattern; // 'daily', 'weekly', 'MWF', 'TTh'
  final Trainer? trainer;
  final Gym? gym;
}

class Trainer {
  final int id;
  final int userId;
  final int? gymId;
  final String name;
  final String? bio;
  final String? avatarPath;
  final List<String> specialties;   // ['yoga', 'hiit', 'strength']
  final List<String> certifications;
  final int yearsExperience;
  final double rating;
  final int reviewCount;
  final int classCount;
  final int followerCount;
  final bool isVerified;
}

class ClassBooking {
  final int id;
  final int userId;
  final int classId;
  final int gymId;
  final String status;     // 'confirmed', 'checked_in', 'completed', 'no_show', 'cancelled'
  final int creditsSpent;
  final String? qrCode;    // JWT-signed QR data
  final DateTime bookedAt;
  final DateTime? checkedInAt;
  final DateTime? cancelledAt;
  final GymClass? gymClass;
  final Gym? gym;
}

class GymMembership {
  final int id;
  final int userId;
  final int gymId;
  final String type;       // 'day_pass', 'weekly', 'monthly', 'annual'
  final double priceTzs;
  final DateTime startDate;
  final DateTime endDate;
  final String status;     // 'active', 'expired', 'cancelled'
  final Gym? gym;
}

class CreditPack {
  final int id;
  final String name;
  final int credits;
  final double priceTzs;
  final bool isPopular;
}

class WorkoutLog {
  final int id;
  final int userId;
  final String type;       // 'gym', 'running', 'walking', 'cycling', 'swimming', 'yoga', 'football', 'other'
  final int durationMinutes;
  final String intensity;  // 'light', 'moderate', 'vigorous'
  final int caloriesBurned;
  final double? distanceKm;
  final List<ExerciseSet>? exercises;
  final String? notes;
  final List<String>? photos;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? gymId;
  final int? classBookingId;
  final int? fitnessStreamId;
  final bool sharedToFeed;
  final DateTime loggedAt;
  final DateTime createdAt;
}

class ExerciseSet {
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;
  final int? restSeconds;
}

class WeightLog {
  final int id;
  final int userId;
  final double weightKg;
  final double? bodyFatPercent;
  final double? bmi;
  final DateTime loggedAt;
}

class WaterLog {
  final int id;
  final int userId;
  final int amountMl;
  final DateTime loggedAt;
}

class SleepLog {
  final int id;
  final int userId;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int durationMinutes;
  final int qualityRating;   // 1-5
  final String? notes;
  final DateTime loggedAt;
}

class FitnessGoal {
  final int id;
  final int userId;
  final String type;         // 'steps', 'workouts_per_week', 'weight', 'water', 'sleep'
  final double targetValue;
  final double currentValue;
  final String? unit;
  final DateTime? deadline;
  final bool isActive;
}

class FitnessStreak {
  final int userId;
  final String type;         // 'workout', 'steps', 'checkin'
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
}

class FitnessBadge {
  final int id;
  final String slug;         // 'first_step', 'week_warrior', etc.
  final String name;
  final String? nameSwahili;
  final String description;
  final String? descriptionSwahili;
  final String iconPath;
  final DateTime? earnedAt;
}

class FitnessChallenge {
  final int id;
  final int creatorId;
  final String title;
  final String? description;
  final String type;          // 'steps', 'workouts', 'calories', 'gym_visits'
  final String metric;        // 'total', 'streak'
  final int durationDays;
  final double? stakeTzs;
  final int participantCount;
  final String status;        // 'upcoming', 'active', 'completed'
  final DateTime startDate;
  final DateTime endDate;
  final List<ChallengeParticipant>? participants;
  final ChallengeParticipant? winner;
}

class ChallengeParticipant {
  final int userId;
  final String userName;
  final String? avatarPath;
  final double score;
  final int rank;
}

class ProgressPhoto {
  final int id;
  final int userId;
  final String photoPath;
  final String pose;          // 'front', 'side', 'back'
  final double? weightKg;
  final Map<String, double>? measurements; // {'chest': 100, 'waist': 80, ...}
  final DateTime takenAt;
}

class GymReview {
  final int id;
  final int userId;
  final int gymId;
  final int? classId;
  final int? trainerId;
  final int rating;           // 1-5
  final String? text;
  final List<String>? photos;
  final bool isVerified;      // user actually attended
  final String? ownerReply;
  final DateTime createdAt;
  final ReviewUser? user;
}
```

### 7.2 Fitness Stream Extension

No new model needed. Use existing `LiveStream` with:
- `category = 'fitness'`
- Fitness metadata stored in a JSON field (workout_type, difficulty, equipment, exercise_cues)

---

## 8. API Endpoints

### 8.1 Gym Marketplace

```
# Gym Discovery
GET    /api/fitness/gyms                    # List gyms (filter: city, facilities, rating, distance)
GET    /api/fitness/gyms/{id}               # Gym detail
GET    /api/fitness/gyms/nearby             # Nearby gyms (lat, lng, radius_km)
GET    /api/fitness/gyms/{id}/classes       # Gym class schedule
GET    /api/fitness/gyms/{id}/trainers      # Gym trainers
GET    /api/fitness/gyms/{id}/reviews       # Gym reviews
GET    /api/fitness/gyms/{id}/gallery       # Gym photos/videos

# Gym Registration (owner)
POST   /api/fitness/gyms                    # Register new gym
PUT    /api/fitness/gyms/{id}               # Update gym profile
POST   /api/fitness/gyms/{id}/photos        # Upload gym photos
DELETE /api/fitness/gyms/{id}/photos/{photoId}

# Classes
GET    /api/fitness/classes                 # Browse all classes (filter: type, date, gym, trainer)
GET    /api/fitness/classes/{id}            # Class detail
POST   /api/fitness/gyms/{id}/classes       # Create class (gym owner/trainer)
PUT    /api/fitness/classes/{id}            # Update class
DELETE /api/fitness/classes/{id}            # Cancel class

# Bookings
POST   /api/fitness/bookings               # Book a class
GET    /api/fitness/bookings                # My bookings
GET    /api/fitness/bookings/{id}           # Booking detail with QR
PUT    /api/fitness/bookings/{id}/cancel    # Cancel booking
POST   /api/fitness/bookings/{id}/checkin   # Check in (QR or GPS)

# Memberships & Credits
GET    /api/fitness/credit-packs            # Available credit packs
POST   /api/fitness/credits/purchase        # Buy credits (via TAJIRI Wallet / M-Pesa)
GET    /api/fitness/credits/balance         # My credit balance
GET    /api/fitness/credits/history         # Credit transaction history
POST   /api/fitness/memberships             # Purchase gym membership
GET    /api/fitness/memberships             # My memberships

# Reviews
POST   /api/fitness/reviews                 # Submit review (gym, class, or trainer)
PUT    /api/fitness/reviews/{id}            # Edit review
DELETE /api/fitness/reviews/{id}            # Delete review
POST   /api/fitness/reviews/{id}/reply      # Gym owner reply

# Trainers
GET    /api/fitness/trainers                # Browse trainers
GET    /api/fitness/trainers/{id}           # Trainer profile
POST   /api/fitness/trainers               # Register as trainer
PUT    /api/fitness/trainers/{id}           # Update trainer profile
```

### 8.2 Fitness Tracking

```
# Workout Logs
POST   /api/fitness/workouts                # Log workout
GET    /api/fitness/workouts                # My workout history
GET    /api/fitness/workouts/{id}           # Workout detail
PUT    /api/fitness/workouts/{id}           # Edit workout log
DELETE /api/fitness/workouts/{id}           # Delete workout log
GET    /api/fitness/workouts/stats          # Workout statistics (weekly/monthly/yearly)

# Weight Tracking
POST   /api/fitness/weight                  # Log weight
GET    /api/fitness/weight                  # Weight history
DELETE /api/fitness/weight/{id}

# Water Tracking
POST   /api/fitness/water                   # Log water intake
GET    /api/fitness/water                   # Today's water log
GET    /api/fitness/water/history           # Water history

# Sleep Tracking
POST   /api/fitness/sleep                   # Log sleep
GET    /api/fitness/sleep                   # Sleep history

# Steps
GET    /api/fitness/steps                   # Step history (synced from device)
POST   /api/fitness/steps/sync              # Sync step data from device

# Goals
POST   /api/fitness/goals                   # Set goal
GET    /api/fitness/goals                   # My goals
PUT    /api/fitness/goals/{id}              # Update goal
DELETE /api/fitness/goals/{id}

# Streaks & Badges
GET    /api/fitness/streaks                 # My streaks
GET    /api/fitness/badges                  # All badges (earned + locked)
GET    /api/fitness/badges/earned           # My earned badges

# Progress Photos
POST   /api/fitness/progress-photos         # Upload progress photo
GET    /api/fitness/progress-photos         # My progress photos
DELETE /api/fitness/progress-photos/{id}
```

### 8.3 Social Fitness

```
# Challenges
POST   /api/fitness/challenges              # Create challenge
GET    /api/fitness/challenges              # Browse challenges
GET    /api/fitness/challenges/{id}         # Challenge detail + leaderboard
POST   /api/fitness/challenges/{id}/join    # Join challenge
POST   /api/fitness/challenges/{id}/leave   # Leave challenge
GET    /api/fitness/challenges/mine         # My challenges (active + past)

# Leaderboards
GET    /api/fitness/leaderboards/global     # Global leaderboard
GET    /api/fitness/leaderboards/friends    # Friends leaderboard
GET    /api/fitness/leaderboards/gym/{id}   # Gym leaderboard
GET    /api/fitness/leaderboards/city/{city}# City leaderboard

# Fitness Streams (uses existing /api/streams with category=fitness)
GET    /api/fitness/streams/live            # Live fitness classes
GET    /api/fitness/streams/ondemand        # On-demand fitness videos
GET    /api/fitness/streams/programs        # Multi-week structured programs
```

---

## 9. Screen Architecture

### 9.1 Navigation

Add a "Fitness" tab to TAJIRI's bottom navigation or as a top-level section accessible from the home screen.

```
lib/screens/fitness/
├── fitness_home_screen.dart          # Main fitness hub
├── gym/
│   ├── gym_discovery_screen.dart     # Browse/search gyms with map
│   ├── gym_detail_screen.dart        # Full gym profile
│   ├── gym_class_detail_screen.dart  # Class detail + booking
│   ├── gym_booking_screen.dart       # Booking confirmation
│   ├── gym_checkin_screen.dart       # QR code display + check-in
│   ├── gym_review_screen.dart        # Write review
│   ├── gym_registration_screen.dart  # Register new gym (owner flow)
│   └── gym_dashboard_screen.dart     # Gym owner management
├── tracking/
│   ├── fitness_dashboard_screen.dart # Overview: steps, calories, streaks, goals
│   ├── workout_log_screen.dart       # Log a workout
│   ├── workout_history_screen.dart   # Past workouts
│   ├── weight_tracker_screen.dart    # Weight log + chart
│   ├── water_tracker_screen.dart     # Water intake
│   ├── sleep_tracker_screen.dart     # Sleep log
│   ├── progress_photos_screen.dart   # Progress photo timeline
│   ├── bmi_calculator_screen.dart    # BMI tool
│   └── goals_screen.dart            # Manage fitness goals
├── social/
│   ├── challenges_screen.dart        # Browse/create challenges
│   ├── challenge_detail_screen.dart  # Challenge leaderboard
│   ├── leaderboard_screen.dart       # Global/friends/gym leaderboards
│   └── badges_screen.dart            # Badge collection
├── streaming/
│   ├── fitness_live_screen.dart      # Browse live fitness classes
│   ├── fitness_ondemand_screen.dart  # On-demand video library
│   ├── fitness_program_screen.dart   # Multi-week programs
│   ├── fitness_player_screen.dart    # Video player with exercise cues
│   └── go_live_fitness_screen.dart   # Trainer: start fitness livestream
├── trainers/
│   ├── trainer_directory_screen.dart # Browse trainers
│   └── trainer_profile_screen.dart   # Trainer detail
└── widgets/
    ├── gym_card.dart                 # Gym preview card
    ├── class_card.dart               # Class schedule card
    ├── trainer_card.dart             # Trainer preview card
    ├── workout_summary_card.dart     # Post-workout summary
    ├── streak_widget.dart            # Streak flame display
    ├── badge_widget.dart             # Badge icon with lock state
    ├── step_counter_widget.dart      # Circular step progress
    ├── water_progress_widget.dart    # Water glass animation
    ├── fitness_chart_widget.dart     # Reusable chart (weight, steps, etc.)
    └── exercise_cue_overlay.dart     # Exercise name overlay for streams
```

### 9.2 Fitness Home Screen Layout

```
FitnessHomeScreen
├── AppBar: "Fitness" + search icon + notification bell
├── Today's Summary Card (steps, calories, water, streak count)
├── Section: "Live Classes Now" (horizontal scroll of live fitness streams)
├── Section: "Upcoming Classes" (your booked classes, chronological)
├── Section: "Gyms Near You" (horizontal scroll of gym cards with distance)
├── Section: "Active Challenges" (challenge cards with your rank)
├── Section: "On-Demand Workouts" (categorized: HIIT, Yoga, Strength, etc.)
├── Section: "Trending Trainers" (trainer cards)
└── FAB: Quick actions (Log Workout, Find Gym, Start Challenge)
```

### 9.3 Routes

```dart
// Add to main.dart onGenerateRoute
'/fitness': (context) => FitnessHomeScreen(currentUserId: userId),
'/fitness/gyms': (context) => GymDiscoveryScreen(currentUserId: userId),
'/fitness/gym/:id': (context) => GymDetailScreen(gymId: id, currentUserId: userId),
'/fitness/class/:id': (context) => GymClassDetailScreen(classId: id, currentUserId: userId),
'/fitness/booking/:id': (context) => GymBookingScreen(bookingId: id, currentUserId: userId),
'/fitness/checkin/:id': (context) => GymCheckinScreen(bookingId: id),
'/fitness/dashboard': (context) => FitnessDashboardScreen(currentUserId: userId),
'/fitness/log-workout': (context) => WorkoutLogScreen(currentUserId: userId),
'/fitness/workouts': (context) => WorkoutHistoryScreen(currentUserId: userId),
'/fitness/weight': (context) => WeightTrackerScreen(currentUserId: userId),
'/fitness/water': (context) => WaterTrackerScreen(currentUserId: userId),
'/fitness/sleep': (context) => SleepTrackerScreen(currentUserId: userId),
'/fitness/progress-photos': (context) => ProgressPhotosScreen(currentUserId: userId),
'/fitness/bmi': (context) => BmiCalculatorScreen(),
'/fitness/goals': (context) => GoalsScreen(currentUserId: userId),
'/fitness/challenges': (context) => ChallengesScreen(currentUserId: userId),
'/fitness/challenge/:id': (context) => ChallengeDetailScreen(challengeId: id, currentUserId: userId),
'/fitness/leaderboard': (context) => LeaderboardScreen(currentUserId: userId),
'/fitness/badges': (context) => BadgesScreen(currentUserId: userId),
'/fitness/trainers': (context) => TrainerDirectoryScreen(currentUserId: userId),
'/fitness/trainer/:id': (context) => TrainerProfileScreen(trainerId: id, currentUserId: userId),
'/fitness/streams/live': (context) => FitnessLiveScreen(currentUserId: userId),
'/fitness/streams/ondemand': (context) => FitnessOnDemandScreen(currentUserId: userId),
'/fitness/streams/programs': (context) => FitnessProgramScreen(currentUserId: userId),
'/fitness/register-gym': (context) => GymRegistrationScreen(currentUserId: userId),
'/fitness/gym-dashboard/:id': (context) => GymDashboardScreen(gymId: id, currentUserId: userId),
```

---

## 10. Monetization

### 10.1 Revenue Streams

| Stream | Model | TAJIRI Cut |
|--------|-------|-----------|
| **Class Bookings** | Credit purchases via M-Pesa/TAJIRI Wallet | 15-20% commission |
| **Gym Memberships** | Pass-through with markup | 10% commission |
| **Day Passes** | Single-use purchase | 15% commission |
| **Premium Fitness Content** | Monthly subscription for on-demand library | TZS 10,000-20,000/mo |
| **Featured Gym Placement** | Gyms pay to appear at top of search | TZS 50,000-200,000/mo |
| **Trainer Tips** | Viewers tip trainers during live classes (existing gift system) | 30% cut (same as livestream gifts) |
| **Corporate Wellness** | B2B employer contracts | Custom pricing |
| **Challenge Stakes** | Users stake money on challenges | 5% platform fee |
| **Sponsored Challenges** | Brands sponsor fitness challenges | Per-campaign pricing |

### 10.2 Payment Integration

Reuse TAJIRI's existing `WalletService` and M-Pesa integration:
- Credit purchases processed through TAJIRI Wallet
- Gym payouts via M-Pesa disbursement (same as shop seller payouts)
- Challenge stakes held in escrow (wallet hold) until challenge completes
- Subscription billing via recurring M-Pesa debit

---

## 11. Tanzania-Specific Adaptations

### 11.1 Connectivity

- **Offline-first tracking:** Steps, workout logs, weight, water, sleep stored locally in Hive, synced when online
- **Low-bandwidth streaming:** Default to 360p for fitness streams, user can upgrade
- **Downloadable workouts:** On-demand videos downloadable for offline use
- **Lightweight class cards:** Minimal data transfer for class browsing (thumbnails lazy-loaded)

### 11.2 Payment

- **M-Pesa first:** All payments default to M-Pesa (Vodacom Tanzania, Airtel Money)
- **TZS pricing:** All prices in Tanzanian Shillings
- **Affordable tiers:** Credit packs start at TZS 5,000 (~$2 USD) to maximize accessibility
- **Pay-per-class:** No forced monthly subscription; users can buy individual credits

### 11.3 Localization

- All UI strings bilingual (Swahili + English) via existing `AppStrings` pattern
- Gym descriptions support both languages
- Exercise names in English with Swahili descriptions where applicable
- Workout types include local activities: "Football", "Bao" (traditional game), "Ngoma" (traditional dance)

### 11.4 Local Fitness Culture

- **Football/Soccer:** Include as workout type (hugely popular in Tanzania)
- **Walking/Running:** Emphasis on outdoor activities (many users don't have gym access)
- **Bodyweight Workouts:** Featured category for users without equipment
- **Community Groups:** Leverage TAJIRI's social layer for gym communities and running groups
- **Trainer Marketplace:** Independent trainers (not gym-affiliated) can offer services, common in Tanzania's informal fitness market

### 11.5 Hardware Considerations

- **No smartwatch required:** All features work with phone only
- **Phone sensor limits:** Step counting via accelerometer (less accurate than watch, but functional)
- **Manual-first approach:** Manual logging is the primary input method, not passive sensor data
- **Low-end device support:** Minimal animations on fitness tracker screens, lazy-load images, paginated lists

---

## Summary of Recommendations

### Must-Build (Phase 1 MVP)
1. **Gym Directory + Profiles** - searchable, filterable, with map view
2. **Credit-Based Class Booking** - ClassPass-inspired, pay-per-class
3. **QR Check-In** - simple, works offline
4. **Manual Workout Logging** - type, duration, intensity, exercises
5. **Step Counter** - phone-based, daily goal
6. **Weight Tracker** - simple log + chart
7. **Workout Sharing to Feed** - new post type
8. **Live Fitness Streaming** - reuse existing livestream with fitness metadata

### High-Value (Phase 2)
9. **On-Demand Video Library** - recorded fitness classes
10. **Structured Programs** - multi-week plans (like Apple Fitness+)
11. **Goals, Streaks, Badges** - gamification for retention
12. **Friend Challenges** - social competition with optional stakes
13. **Leaderboards** - global, friends, gym, city
14. **Trainer Profiles** - follow, rate, book

### Future (Phase 3)
15. **AI Workout Recommendations** - personalized plans
16. **Offline Downloads** - video workouts for no-connectivity areas
17. **Corporate Wellness** - B2B employer tier
18. **Nutrition Tracking** - food logging (complex, defer)
19. **Progress Photos** - before/after with body composition
20. **Gym Owner Analytics** - booking trends, revenue, member retention
