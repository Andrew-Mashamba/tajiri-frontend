# Tajirika (Partner Program) — Implementation Plan

## Overview

Tajirika is TAJIRI's partner program for mafundi (skilled artisans) and madalali (brokers) in Tanzania. It provides registration, skill verification, job matching, earnings management, and training for service professionals. Customers post jobs, receive quotes from verified fundis, pay through escrow, and rate completed work. The platform replaces word-of-mouth hiring with a structured, trust-building marketplace.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tajirika/
├── tajirika_module.dart              — Entry point & route registration
├── models/
│   ├── partner_models.dart           — Partner, PartnerTier, SkillCategory
│   ├── job_models.dart               — Job, JobBid, JobStatus, Quote
│   └── earnings_models.dart          — Earnings, Payout, Commission
├── services/
│   └── tajirika_service.dart         — API service using AuthenticatedDio
├── pages/
│   ├── partner_dashboard_page.dart   — Earnings, active jobs, ratings
│   ├── registration_flow_page.dart   — Multi-step onboarding
│   ├── job_feed_page.dart            — Available jobs listing
│   ├── job_detail_page.dart          — Job info, quote submission
│   ├── booking_calendar_page.dart    — Schedule management
│   ├── earnings_page.dart            — Payouts, withdrawals
│   ├── portfolio_page.dart           — Work samples, certifications
│   ├── training_hub_page.dart        — Courses, progress
│   ├── quote_builder_page.dart       — Itemized quote creation
│   └── referral_center_page.dart     — Referral tracking
└── widgets/
    ├── tier_badge_widget.dart        — Apprentice/Verified/Master badge
    ├── job_card_widget.dart          — Job listing card
    ├── earnings_chart_widget.dart    — Earnings breakdown chart
    └── rating_summary_widget.dart    — Star rating with categories
```

### Data Models
- **Partner**: id, userId, name, skills[], tier (apprentice/verified/master), rating, serviceArea, nidaVerified, tinVerified, vetaCertified, isActive, createdAt. `factory Partner.fromJson()` with `_parseDouble` for rating.
- **Job**: id, customerId, title, description, photos[], location, budget, category, status (open/assigned/in_progress/completed), urgency, createdAt. `factory Job.fromJson()` with `_parseInt` for budget.
- **JobBid**: id, jobId, partnerId, amount, estimatedDays, description, createdAt.
- **Earnings**: totalEarnings, weeklyEarnings, pendingPayout, commission, tips, payouts[].

### Service Layer
- `getPartnerProfile(int partnerId)` — GET `/api/tajirika/partners/{id}`
- `registerPartner(Map data)` — POST `/api/tajirika/partners`
- `getAvailableJobs({String? category, String? location})` — GET `/api/tajirika/jobs`
- `submitBid(int jobId, Map bid)` — POST `/api/tajirika/jobs/{id}/bids`
- `getEarnings({String period})` — GET `/api/tajirika/earnings`
- `requestPayout(double amount)` — POST `/api/tajirika/payouts`
- `getTrainingCourses()` — GET `/api/tajirika/training`
- `updateAvailability(Map schedule)` — PUT `/api/tajirika/availability`
- `getReferrals()` — GET `/api/tajirika/referrals`

### Pages & Screens
- **Partner Dashboard**: Earnings summary, active jobs count, upcoming bookings, rating. Loads partner profile + earnings.
- **Job Feed**: Filterable list of open jobs by skill/location/budget. Pull-to-refresh, infinite scroll.
- **Job Detail**: Full description, customer info, map, submit quote form.
- **Quote Builder**: Itemized line items (labor, materials, transport), total calculation.
- **Earnings Page**: Daily/weekly/monthly toggle, payout history, withdrawal button.
- **Training Hub**: Course cards with progress bars, certificates earned.

### Widgets
- `TierBadgeWidget` — Colored badge for Apprentice (grey), Verified (blue), Master (gold)
- `JobCardWidget` — Title, category icon, budget range, location, urgency indicator
- `EarningsChartWidget` — Bar chart with period selector
- `RatingSummaryWidget` — 5-star display with quality/timeliness/communication/value breakdown

---

## 2. UI Design

- Palette: #1A1A1A primary, #666666 secondary, #FAFAFA background, #FFFFFF cards
- Cards: BorderRadius.circular(12), subtle elevation shadow
- Touch targets: 48dp minimum on all interactive elements
- Text: maxLines + TextOverflow.ellipsis on job titles, descriptions
- Icons: Material _rounded variants (work_rounded, star_rounded, account_circle_rounded)
- Loading: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))
- Empty states: 64px icon + "No jobs available" centered

### Key Screen Mockup — Partner Dashboard
```
┌─────────────────────────────┐
│  SafeArea                   │
│  ┌───────────────────────┐  │
│  │ ★ 4.8  Master Fundi   │  │
│  │ Earnings: TZS 2.4M    │  │
│  └───────────────────────┘  │
│  ┌─────┐ ┌─────┐ ┌─────┐  │
│  │Active│ │Pend.│ │Done │  │
│  │  3   │ │  2  │ │ 47  │  │
│  └─────┘ └─────┘ └─────┘  │
│  ── Upcoming Bookings ───   │
│  [JobCard] Tomorrow 9am     │
│  [JobCard] Wed 2pm          │
│  ── Recent Earnings ────    │
│  [EarningsChart weekly]     │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: tajirika_jobs
// Columns: id INTEGER PRIMARY KEY, category TEXT, location TEXT, status TEXT, json_data TEXT, synced_at TEXT
// Indexes: category, status, location
```

### Stale-While-Revalidate
- Load jobs from SQLite instantly (<5ms)
- API fetch in background, diff and merge
- Cache TTL: 5 minutes for job feed, 15 minutes for earnings

### Offline Support
- Read: Job feed, earnings history, training content
- Write: Quote submissions, availability updates queued in pending_queue
- Sync: Delta sync on reconnect, conflict resolution by server timestamp

### Media Caching
- Images: MediaCacheService (30-day TTL) for portfolio photos
- BlurHash placeholders for job photos and partner avatars

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE tajirika_partners (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    tier VARCHAR(20) DEFAULT 'apprentice',
    skills TEXT[],
    service_area JSONB,
    nida_verified BOOLEAN DEFAULT FALSE,
    tin_number VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0,
    jobs_completed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tajirika_jobs (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES users(id),
    title VARCHAR(255),
    description TEXT,
    category VARCHAR(100),
    budget_min INTEGER,
    budget_max INTEGER,
    location JSONB,
    status VARCHAR(20) DEFAULT 'open',
    urgency VARCHAR(20) DEFAULT 'normal',
    assigned_partner_id BIGINT REFERENCES tajirika_partners(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tajirika_bids (
    id BIGSERIAL PRIMARY KEY,
    job_id BIGINT REFERENCES tajirika_jobs(id),
    partner_id BIGINT REFERENCES tajirika_partners(id),
    amount INTEGER,
    estimated_days INTEGER,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/tajirika/partners/{id} | Get partner profile | Yes |
| POST | /api/tajirika/partners | Register as partner | Yes |
| GET | /api/tajirika/jobs | List available jobs | Yes |
| POST | /api/tajirika/jobs | Create job posting | Yes |
| POST | /api/tajirika/jobs/{id}/bids | Submit bid on job | Yes |
| PUT | /api/tajirika/jobs/{id}/status | Update job status | Yes |
| GET | /api/tajirika/earnings | Get earnings summary | Yes |
| POST | /api/tajirika/payouts | Request payout | Yes |
| GET | /api/tajirika/training | List training courses | Yes |

### Controller
- File: `app/Http/Controllers/Api/TajirikaController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Validation: `$request->validate([...])` at start of POST/PUT

### Background Jobs
- Weekly payout processing (cron: every Monday)
- Rating recalculation after each review
- Tier upgrade check after job completion milestones

---

## 5. Integration Wiring

- **Wallet**: Escrow holds via WalletService for milestone payments. Weekly payouts. Tips via transfer. Commission auto-deducted.
- **Messaging**: Auto-create conversation on booking. Job coordination chat with photo sharing.
- **Groups**: Trade-specific communities (Mafundi wa Umeme, Maseremala). Knowledge sharing.
- **Profile**: Fundi verification badge, tier level, certifications on social profile.
- **Location**: GPS-based job matching using Tanzania hierarchy. Service area definition.
- **Notifications**: New job matches, booking confirmations, payment received, rating alerts.
- **Calendar**: Booking calendar sync, recurring job scheduling.
- **Insurance**: Professional liability insurance for partners.
- **Loans**: Micro-loans for tool purchases based on earnings history.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and tajirika_module.dart
- [ ] Partner, Job, Bid, Earnings models with fromJson/toJson
- [ ] TajirikaService with AuthenticatedDio
- [ ] Backend: migrations + CRUD endpoints
- [ ] SQLite table for offline job cache

### Phase 2: Core UI (Week 2)
- [ ] Partner Dashboard with earnings summary
- [ ] Job Feed with filters and infinite scroll
- [ ] Job Detail with quote submission
- [ ] Quote Builder with itemized line items
- [ ] Registration flow (multi-step)

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for escrow and payouts
- [ ] Wire to MessageService for booking chats
- [ ] Wire to NotificationService for job alerts
- [ ] Wire to CalendarService for booking sync

### Phase 4: Polish (Week 4)
- [ ] Offline support with pending queue for bids
- [ ] BlurHash placeholders for portfolio photos
- [ ] Pull-to-refresh on all list screens
- [ ] Empty states for no jobs, no earnings
- [ ] Error handling with retry logic
- [ ] Analytics tracking for job funnel

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Worker payments, escrow, disbursements (C2B, B2C, B2B) | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev. Fintech 2.0 platform, 1,000+ TPS |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for mobile money + cards | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev. mobileCheckout + bankCheckout |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection + bulk worker payouts | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa. Best for bulk payouts to multiple mobile money wallets |
| [Verified.Africa](https://docs.verified.africa/) | Verified Africa | Identity verification, KYC for gig workers | Paid (per-verification) | API-first digital identity verification across Africa |
| [VerifyMe](https://verifyme.ng/) | VerifyMe Nigeria | Background checks, ID verification, facial recognition | Paid (per-check) | KYC + facial recognition via "Pluto" product. Expanding beyond Nigeria |
| [Checkr API](https://checkr.com/our-technology/background-check-api) | Checkr | Background checks, employment verification | Paid (per-check) | International criminal search, education + employment verification. 196 countries |
| [Authenticate](https://authenticate.com/) | Authenticate.com | ID authentication, background verification | Paid | 7,500+ ID types from 196 countries. Facial recognition + liveness detection |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS/USSD notifications to workers | Pay-as-you-go | Supports Vodacom, Tigo, Airtel in TZ. Great for USSD payment flows |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Push notifications for job alerts | Free | Already integrated in TAJIRI app |
