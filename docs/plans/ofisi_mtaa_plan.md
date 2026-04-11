# Ofisi ya Mtaa (Ward/Street Office) — Implementation Plan

## Overview
Digital interface for Tanzania's lowest urban government unit (Mtaa/street). Enables citizens to request services (reference letters, land verification), book appointments with Mtendaji, track applications, view fee schedules, report issues, and access community notices — replacing paper-based processes that currently require multiple visits.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/ofisi_mtaa/
├── ofisi_mtaa_module.dart
├── models/
│   ├── service_request_models.dart
│   ├── mtaa_official_models.dart
│   └── appointment_models.dart
├── services/
│   └── ofisi_mtaa_service.dart
├── pages/
│   ├── mtaa_home_page.dart
│   ├── service_catalog_page.dart
│   ├── apply_service_page.dart
│   ├── my_applications_page.dart
│   ├── book_appointment_page.dart
│   ├── community_board_page.dart
│   ├── issue_report_page.dart
│   ├── contacts_page.dart
│   └── fee_schedule_page.dart
└── widgets/
    ├── official_card.dart
    ├── service_tile.dart
    ├── application_timeline.dart
    └── appointment_slot.dart
```

### Data Models
- `MtaaOfficial` — id, name, role (mwenyekiti/mtendaji/mjumbe), phone, photo, availabilityStatus
- `ServiceRequest` — id, userId, serviceType, status (received/underReview/ready), documents, feeAmount, submittedAt, estimatedDate
- `ServiceCatalog` — id, name, description, requiredDocs, officialFee, processingTime
- `Appointment` — id, userId, officialId, dateTime, purpose, status
- `CommunityNotice` — id, title, body, authorId, type (announcement/alert/meeting), createdAt

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getServiceCatalog(mtaaId)` | GET | `/api/mtaa/{id}/services` | `PaginatedResult<ServiceCatalog>` |
| `submitRequest(data)` | POST | `/api/mtaa/requests` | `SingleResult<ServiceRequest>` |
| `getMyRequests()` | GET | `/api/mtaa/requests/mine` | `PaginatedResult<ServiceRequest>` |
| `bookAppointment(data)` | POST | `/api/mtaa/appointments` | `SingleResult<Appointment>` |
| `getAvailableSlots(officialId, date)` | GET | `/api/mtaa/appointments/slots` | `PaginatedResult<TimeSlot>` |
| `getNotices(mtaaId)` | GET | `/api/mtaa/{id}/notices` | `PaginatedResult<CommunityNotice>` |
| `reportIssue(data)` | POST | `/api/mtaa/issues` | `SingleResult<Issue>` |
| `getOfficials(mtaaId)` | GET | `/api/mtaa/{id}/officials` | `PaginatedResult<MtaaOfficial>` |

### Pages
- **MtaaHomePage** — Mtaa overview: chairperson, Mtendaji, quick actions, recent notices
- **ServiceCatalogPage** — Browsable list of services with fees, docs, processing time
- **ApplyServicePage** — Step-by-step form with document upload, fee display, submission
- **MyApplicationsPage** — All requests with status tracking timeline
- **BookAppointmentPage** — Calendar with available slots, confirmation flow
- **CommunityBoardPage** — Feed of notices from Mtaa leadership
- **IssueReportPage** — Photo + GPS + category + description form

### Widgets
- `OfficialCard` — Photo, name, role, availability status, contact action
- `ServiceTile` — Service name, fee, processing time, apply button
- `ApplicationTimeline` — Received > Under Review > Ready for Collection
- `AppointmentSlot` — Time slot chip with availability indicator

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Ofisi ya Mtaa   🔔  │
├─────────────────────────┤
│ Mtaa: Sinza Kijiweni    │
│ ┌─────────────────────┐ │
│ │ Mwenyekiti: A. Juma │ │
│ │ Mtendaji: B. Saidi  │ │
│ │ Status: ● Available │ │
│ └─────────────────────┘ │
│                         │
│ [Apply Service] [Book]  │
│ [My Apps]    [Report]   │
│                         │
│ Community Notices       │
│ ├─ Mkutano wa Mtaa 10/4│
│ ├─ Water schedule update│
│ └─ Security alert...   │
│                         │
│ Fee Schedule ›          │
│ Contacts ›              │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE mtaa_services(id INTEGER PRIMARY KEY, mtaa_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_mtaa_services_mtaa ON mtaa_services(mtaa_id);

CREATE TABLE mtaa_requests(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_mtaa_requests_user ON mtaa_requests(user_id);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Service catalog 24h, notices 15min, officials 12h
- Offline read: YES — service catalog, fees, emergency contacts
- Offline write: pending_queue for service requests and issue reports

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE mtaa_officials (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    mtaa_id BIGINT NOT NULL, role TEXT NOT NULL, phone TEXT,
    availability_status TEXT DEFAULT 'available',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE mtaa_service_requests (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    mtaa_id BIGINT NOT NULL, service_type TEXT NOT NULL, status TEXT DEFAULT 'received',
    documents JSONB, fee_amount DECIMAL(12,2), estimated_date DATE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE mtaa_appointments (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    official_id BIGINT REFERENCES mtaa_officials(id),
    date_time TIMESTAMP NOT NULL, purpose TEXT, status TEXT DEFAULT 'booked',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/mtaa/{id}/services | Service catalog | Yes |
| POST | /api/mtaa/requests | Submit service request | Yes |
| GET | /api/mtaa/requests/mine | My applications | Yes |
| POST | /api/mtaa/appointments | Book appointment | Yes |
| GET | /api/mtaa/appointments/slots | Available time slots | Yes |
| GET | /api/mtaa/{id}/notices | Community notices | Yes |
| POST | /api/mtaa/issues | Report street issue | Yes |
| GET | /api/mtaa/{id}/officials | Mtaa officials | Yes |

### Controller
- `app/Http/Controllers/Api/MtaaController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — `deposit()` for official service fees (reference letters, land verification)
- **MessageService** — Direct chat with Mtendaji or Mwenyekiti
- **GroupService** — Auto-create Mtaa community group; resident directory
- **NotificationService + FCMService** — Application status changes, meeting reminders, emergency alerts
- **LiveUpdateService** — Real-time application tracking via Firestore
- **LocationService** — GPS-based Mtaa detection and automatic assignment
- **PhotoService** — Document uploads (ID copies, passport photos), issue attachments
- **CalendarService** — Mtaa meetings, appointment slots
- **Cross-module: barozi_wangu** — Escalation from Mtaa to Ward Councillor

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Officials directory and service catalog API

### Phase 2: Core UI (Week 2)
- Mtaa home, service catalog, application form with document upload
- Application tracking timeline, appointment booking calendar

### Phase 3: Integration (Week 3)
- WalletService fee payments, GroupService community group
- LiveUpdateService real-time tracking, FCM push notifications

### Phase 4: Polish (Week 4)
- Community board, fee transparency reporting, digital reference letters
- Offline support for catalogs and emergency contacts

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Tanzania Open Data Portal | Government of Tanzania / eGA | Open government data (health, water, education) | Free | CKAN API at opendata.go.tz for programmatic access |
| GePG (Government e-Payment Gateway) | Ministry of Finance, Tanzania | Government service fee payments, control number generation | Institutional access | SHA1withRSA digital signatures; docs at gepg.go.tz/documents |
| eGA mPortal | e-Government Agency, Tanzania | Citizen portal for government mobile services | Free to citizens | mportal.ega.go.tz — aggregates government apps |
| NBS Statistical Portal (TISP) | National Bureau of Statistics | Census data, DHS, SDG indicators by ward/district | Free | Multiple portals: TNADA, TASIS at nbs.go.tz |
| World Bank Open Data API | World Bank | Tanzania governance and development indicators | Free | REST API, no auth required |
| ClickPesa BillPay API | ClickPesa | GePG control number generation for government fees | Contact for pricing | docs.clickpesa.com — automates control number workflows |
| AzamPay API | AzamPay | Mobile money payments for government service fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| Selcom API | Selcom | Payment aggregation for government fees | Commission-based | REST API with PHP/Java/Shell SDKs at developers.selcommobile.com |

### Integration Priority
1. **Immediate** — Tanzania Open Data Portal (free CKAN API), World Bank API (free, no auth), NBS data portals (free)
2. **Short-term** — AzamPay for fee payments (has Dart SDK), ClickPesa for GePG control number integration, Selcom API
3. **Partnership** — GePG direct integration (institutional access required), eGA mPortal data feeds
