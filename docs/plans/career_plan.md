# Career / Kazi — Implementation Plan

## Overview
Career development platform for Tanzanian students and graduates. Internship/job listings, CV builder with Tanzanian market templates, cover letter templates, portfolio showcase, interview prep, company profiles, alumni network, mentorship matching, application tracker, skill assessments with badges, professional body registration guides, government job alerts (ajira.go.tz), and entrepreneurship resources.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/career/
├── career_module.dart
├── models/
│   ├── job_listing.dart
│   ├── company.dart
│   ├── cv_data.dart
│   ├── application.dart
│   ├── skill_assessment.dart
│   └── alumni.dart
├── services/
│   └── career_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── career_home_page.dart
│   ├── job_listings_page.dart
│   ├── job_detail_page.dart
│   ├── cv_builder_page.dart
│   ├── application_tracker_page.dart
│   ├── company_profile_page.dart
│   ├── interview_prep_page.dart
│   ├── alumni_network_page.dart
│   ├── skill_assessments_page.dart
│   ├── career_events_page.dart
│   └── portfolio_page.dart
└── widgets/
    ├── job_card.dart
    ├── company_tile.dart
    ├── application_status_chip.dart
    ├── cv_section_card.dart
    ├── skill_badge.dart
    ├── alumni_card.dart
    └── career_event_card.dart
```

### Data Models
```dart
class JobListing {
  final int id;
  final String title, company, location, type;  // internship, full_time, part_time, attachment
  final String? salaryRange, description, requirements;
  final DateTime deadline;
  final String? companyLogoUrl;
  final String industry;
  final bool remote;
  factory JobListing.fromJson(Map<String, dynamic> j) => JobListing(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    company: j['company'] ?? '',
    location: j['location'] ?? '',
    type: j['type'] ?? 'full_time',
    industry: j['industry'] ?? '',
    deadline: DateTime.parse(j['deadline']),
  );
}

class Company { int id; String name, industry, description; String? logoUrl, website; int openPositions; }
class CvData { String name, email, phone; List<Education> education; List<Experience> experience; List<String> skills; List<Reference> references; }
class Application { int id, jobId; String jobTitle, company, status; DateTime appliedAt; } // status: applied, under_review, interview, offer, rejected
class SkillAssessment { int id; String skill; int? score; String? badge; int durationMinutes; }
class Alumni { int id; String name, company, position, institution; int graduationYear; }
```

### Service Layer
```dart
class CareerService {
  static Future<List<JobListing>> getListings(String token, {String? type, String? industry, String? location}); // GET /api/career/listings
  static Future<JobListing> getListingDetail(String token, int id);            // GET /api/career/listings/{id}
  static Future<void> applyToJob(String token, int id, Map body);              // POST /api/career/listings/{id}/apply
  static Future<List<Application>> getApplications(String token);              // GET /api/career/applications
  static Future<CvData> getCvData(String token);                               // GET /api/career/cv
  static Future<void> saveCvData(String token, Map body);                      // PUT /api/career/cv
  static Future<String> generateCvPdf(String token, String template);          // GET /api/career/cv/pdf?template=
  static Future<List<Company>> getCompanies(String token, {String? industry}); // GET /api/career/companies
  static Future<Company> getCompanyDetail(String token, int id);               // GET /api/career/companies/{id}
  static Future<List<Alumni>> getAlumni(String token, {String? institution, String? company}); // GET /api/career/alumni
  static Future<List<SkillAssessment>> getAssessments(String token);           // GET /api/career/assessments
  static Future<Map> takeAssessment(String token, int id, Map answers);        // POST /api/career/assessments/{id}/submit
  static Future<List<Map>> getInterviewQuestions(String token, String category); // GET /api/career/interview-prep?category=
  static Future<List<Map>> getCareerEvents(String token);                      // GET /api/career/events
}
```

### Pages & Widgets
- **CareerHomePage**: featured opportunities, recent listings, application stats, career events
- **JobListingsPage**: filterable list with company logo, title, location, deadline, salary
- **JobDetailPage**: full description, requirements, company info, apply button, save, share
- **CvBuilderPage**: multi-step — personal info, education, experience, skills, references, preview
- **ApplicationTrackerPage**: kanban or list of all applications with status indicators
- **CompanyProfilePage**: company info, open positions, reviews, alumni connections
- **InterviewPrepPage**: question bank by category (behavioral, technical, HR), practice mode
- **AlumniNetworkPage**: browse alumni by institution, year, company, industry
- **SkillAssessmentsPage**: available tests with difficulty, time estimate, badge reward
- **PortfolioPage**: showcase projects, code, designs, certifications

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Job cards: company logo, title (1-line), company name, location, deadline countdown
- Dark hero card: "3 active applications" with latest status updates

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Career              [🔍 ⋮] │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 3 Active Applications    │ │
│ │ 1 Interview scheduled    │ │
│ │ CV: 85% complete         │ │
│ └──────────────────────────┘ │
│                              │
│ [Jobs] [CV] [Track] [Prep]   │
│                              │
│ FEATURED                     │
│ ┌──────────────────────────┐ │
│ │ [logo] Software Intern   │ │
│ │ Vodacom Tanzania         │ │
│ │ Dar es Salaam · 5d left  │ │
│ ├──────────────────────────┤ │
│ │ [logo] Graduate Trainee  │ │
│ │ CRDB Bank                │ │
│ │ Multiple · 12d left      │ │
│ └──────────────────────────┘ │
│                              │
│ CAREER EVENTS                │
│ ┌──────────────────────────┐ │
│ │ UDSM Career Fair 2026    │ │
│ │ Apr 20 · Main Hall       │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE job_listings(id INTEGER PRIMARY KEY, type TEXT, industry TEXT, location TEXT, deadline TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_jobs_type ON job_listings(type);
CREATE INDEX idx_jobs_deadline ON job_listings(deadline);

CREATE TABLE applications(id INTEGER PRIMARY KEY, job_id INTEGER, status TEXT, applied_at TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE cv_data(id INTEGER PRIMARY KEY, json_data TEXT, synced_at TEXT);
CREATE TABLE companies(id INTEGER PRIMARY KEY, industry TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE skill_badges(id INTEGER PRIMARY KEY, skill TEXT, score INTEGER, json_data TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — listings, CV data, applications, interview questions cached
- Offline write: pending_queue for applications, CV updates

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE job_listings(
  id SERIAL PRIMARY KEY, company_id INT REFERENCES companies(id),
  title VARCHAR(255), type VARCHAR(30),  -- internship, full_time, part_time, attachment
  location VARCHAR(255), industry VARCHAR(100),
  salary_range VARCHAR(100), description TEXT, requirements TEXT,
  deadline TIMESTAMP, remote BOOLEAN DEFAULT FALSE,
  posted_by INT REFERENCES users(id), created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE companies(
  id SERIAL PRIMARY KEY, name VARCHAR(255), industry VARCHAR(100),
  description TEXT, logo_url TEXT, website VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE job_applications(
  id SERIAL PRIMARY KEY, listing_id INT REFERENCES job_listings(id),
  user_id INT REFERENCES users(id), status VARCHAR(30) DEFAULT 'applied',
  cover_letter TEXT, cv_url TEXT, applied_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(listing_id, user_id)
);
CREATE TABLE user_cvs(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  personal_info JSONB, education JSONB, experience JSONB,
  skills JSONB, references JSONB, updated_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE skill_assessments(
  id SERIAL PRIMARY KEY, skill VARCHAR(100), description TEXT,
  questions JSONB, duration_minutes INT, badge_name VARCHAR(50)
);
CREATE TABLE user_skill_badges(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  assessment_id INT REFERENCES skill_assessments(id),
  score INT, completed_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, assessment_id)
);
CREATE TABLE alumni_profiles(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  institution VARCHAR(255), graduation_year SMALLINT,
  company VARCHAR(255), position VARCHAR(255),
  open_to_mentor BOOLEAN DEFAULT FALSE
);
CREATE TABLE career_events(
  id SERIAL PRIMARY KEY, title VARCHAR(255), description TEXT,
  venue VARCHAR(255), event_date TIMESTAMP,
  organizer VARCHAR(255), created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/career/listings | Job/internship listings | Bearer |
| GET | /api/career/listings/{id} | Listing detail | Bearer |
| POST | /api/career/listings/{id}/apply | Apply to job | Bearer |
| GET | /api/career/applications | My applications | Bearer |
| GET | /api/career/cv | Get CV data | Bearer |
| PUT | /api/career/cv | Save CV data | Bearer |
| GET | /api/career/cv/pdf | Generate CV PDF | Bearer |
| GET | /api/career/companies | Browse companies | Bearer |
| GET | /api/career/companies/{id} | Company detail | Bearer |
| GET | /api/career/alumni | Alumni network | Bearer |
| GET | /api/career/assessments | Skill tests | Bearer |
| POST | /api/career/assessments/{id}/submit | Submit test | Bearer |
| GET | /api/career/interview-prep | Interview questions | Bearer |
| GET | /api/career/events | Career events | Bearer |

### Controller
`app/Http/Controllers/Api/CareerController.php`

---

## 5. Integration Wiring
- ProfileService — CV data extends TAJIRI profile; education, skills, experience
- PostService — share job postings and achievements to feed
- MessageService — DM recruiters or alumni through TAJIRI messaging
- WalletService — pay for premium features (CV review, skill courses)
- NotificationService + FCM — job alerts, application status, deadline reminders
- CalendarService — career fairs, interview schedules, deadlines synced
- FriendService — mutual connections at target companies for referrals
- results module — GPA and transcript for applications
- newton module — AI helps with CV writing, cover letters, interview prep
- events/ module — career fairs integrate with TAJIRI events
- business/ module — entrepreneurship resources link to business tools

---

## 6. Implementation Phases

### Phase 1 — Listings & Browsing (Week 1-2)
- [ ] JobListing, Company models, service, SQLite cache
- [ ] Career home with featured listings
- [ ] Job listings page with filters (type, industry, location)
- [ ] Job detail page with apply button

### Phase 2 — CV & Applications (Week 3-4)
- [ ] CV builder (multi-step wizard)
- [ ] CV PDF generation with templates
- [ ] Job application submission
- [ ] Application tracker with status updates

### Phase 3 — Network & Prep (Week 5)
- [ ] Company profiles with open positions
- [ ] Alumni network browsing
- [ ] Interview prep question bank
- [ ] Skill assessments with badges

### Phase 4 — Advanced (Week 6)
- [ ] Portfolio page for projects/work samples
- [ ] Mentorship matching
- [ ] Government job alerts (ajira.go.tz)
- [ ] Career events calendar with RSVP
- [ ] Professional body registration guides
- [ ] Entrepreneurship resources section

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| JSearch API (RapidAPI) | OpenWeb Ninja | Aggregated job search (Indeed, LinkedIn, etc.) | Free: 200 req/mo; Paid from $30/mo | Aggregates from multiple job boards. Good for MVP job search feature. |
| RemoteOK API | RemoteOK | Remote job listings | Free (JSON feed) | Remote jobs only. No API key needed. Good for tech/remote roles. |
| Arbeitnow API | Arbeitnow | Remote/flexible job listings | Free (JSON feed) | Simple JSON endpoint. No authentication required. |
| Adzuna API | Adzuna | Job search aggregation, salary data | Free tier available (API key required) | 12 countries supported. Tanzania NOT currently covered. Good for international job search. |
| BrighterMonday | BrighterMonday Tanzania | Tanzania's #1 job board | No public API | 276+ job offers. Part of Ringier One Africa Media. **Would need partnership or web scraping.** |
| Ajira Portal | PSRS Tanzania | Government/public sector jobs | No public API | Portal at ajira.go.tz. Managed by Public Service Recruitment Secretariat. **Scraping possible.** |
| LinkedIn API | LinkedIn/Microsoft | Job postings, professional profiles | Paid (Talent Solutions license) | Requires LinkedIn Talent Solutions subscription. Limited to partners. |

**Tanzania context:** BrighterMonday Tanzania and Ajira Portal have NO public APIs. For Tanzania-specific jobs, build a backend scraper for BrighterMonday, Ajira, Mabumbe, and Zoom Tanzania. For international/remote jobs, use JSearch or RemoteOK APIs.

### Integration Priority
1. **Immediate** -- RemoteOK API (free JSON feed, no key), Arbeitnow API (free JSON feed, no key), JSearch API (200 free req/mo for aggregated search)
2. **Short-term** -- Adzuna API (free tier with key, international jobs), custom backend scraper for BrighterMonday and Ajira Portal
3. **Partnership** -- BrighterMonday official API access, LinkedIn Talent Solutions (formal partnership required), Ajira Portal data feed
