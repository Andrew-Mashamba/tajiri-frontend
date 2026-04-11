# Neighbourhood Watch (Ulinzi wa Mtaa) — Implementation Plan

## Overview
Community-based neighborhood security platform with emergency broadcasts, incident reporting, patrol coordination, night watchman check-ins, visitor management, safety mapping, and anonymous reporting. Built on Tanzania's Sungusungu and nyumba kumi traditions.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/neighbourhood_watch/
├── neighbourhood_watch_module.dart
├── models/
│   ├── neighbourhood_group.dart
│   ├── incident_report.dart
│   ├── patrol_shift.dart
│   ├── patrol_checkin.dart
│   ├── visitor_record.dart
│   └── safety_contact.dart
├── services/
│   └── neighbourhood_service.dart   — AuthenticatedDio.instance
├── pages/
│   ├── neighbourhood_home_page.dart
│   ├── alert_broadcast_page.dart
│   ├── incident_feed_page.dart
│   ├── report_incident_page.dart
│   ├── safety_map_page.dart
│   ├── patrol_schedule_page.dart
│   ├── group_members_page.dart
│   ├── emergency_contacts_page.dart
│   ├── visitor_log_page.dart
│   └── meeting_planner_page.dart
└── widgets/
    ├── alert_banner.dart
    ├── incident_card.dart
    ├── patrol_status.dart
    ├── member_role_badge.dart
    ├── panic_button.dart
    ├── incident_map_pin.dart
    └── visitor_card.dart
```

### Data Models
- **NeighbourhoodGroup** — `id`, `name`, `ward`, `district`, `memberCount`, `coordinatorId`, `lat`, `lng`, `radius`. `_parseInt`, `_parseDouble`.
- **IncidentReport** — `id`, `groupId`, `reporterId`, `type` (theft/breakin/suspicious/noise/fire/flood/road_hazard), `description`, `lat`, `lng`, `severity` (low/medium/high/critical), `photos` (List), `isAnonymous`, `isResolved`, `resolution`, `createdAt`. `_parseDouble`, `_parseBool`.
- **PatrolShift** — `id`, `groupId`, `patrollerId`, `patrollerName`, `startTime`, `endTime`, `date`, `checkpoints` (List), `isActive`. `_parseBool`.
- **PatrolCheckin** — `id`, `shiftId`, `lat`, `lng`, `timestamp`, `note`.
- **VisitorRecord** — `id`, `groupId`, `visitorName`, `hostResidentId`, `expectedTime`, `vehiclePlate`, `status` (expected/arrived/departed), `createdAt`.
- **SafetyContact** — `name`, `phone`, `role` (mjumbe/ocd/hospital/fire/security).

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getMyNeighbourhood()` — `GET /api/neighbourhood/my-group`
- `joinGroup(int groupId)` — `POST /api/neighbourhood/{id}/join`
- `broadcastAlert(Map data)` — `POST /api/neighbourhood/alerts`
- `reportIncident(Map data)` — `POST /api/neighbourhood/incidents`
- `getIncidentFeed(int groupId, {String? type})` — `GET /api/neighbourhood/{id}/incidents`
- `resolveIncident(int incidentId, String resolution)` — `PUT /api/neighbourhood/incidents/{id}/resolve`
- `getPatrolSchedule(int groupId)` — `GET /api/neighbourhood/{id}/patrols`
- `checkInPatrol(int shiftId, Map data)` — `POST /api/neighbourhood/patrols/{id}/checkin`
- `getMembers(int groupId)` — `GET /api/neighbourhood/{id}/members`
- `logVisitor(int groupId, Map data)` — `POST /api/neighbourhood/{id}/visitors`
- `getSafetyMap(int groupId)` — `GET /api/neighbourhood/{id}/safety-map`

### Pages
- **NeighbourhoodHomePage** — Active alerts banner, recent incidents, patrol status, quick report
- **AlertBroadcastPage** — Emergency alert creation with type, description, location
- **IncidentFeedPage** — Scrollable feed with filters (type, date, status)
- **ReportIncidentPage** — Type selector, description, location pin, time, photo/video
- **SafetyMapPage** — Map overlay with incident pins and density heat map
- **PatrolSchedulePage** — Weekly roster, check-in points, active patrol tracker
- **GroupMembersPage** — Member list with roles (coordinator, patrol, resident)
- **EmergencyContactsPage** — One-tap dial: mjumbe, police, hospital, fire, security
- **VisitorLogPage** — Expected visitors with approval status
- **MeetingPlannerPage** — Schedule security meetings with agenda and RSVP

### Widgets
- `PanicButton` — Large emergency broadcast button with confirmation
- `AlertBanner` — Persistent red/orange banner for active alerts

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch (panic button 72dp), maxLines+ellipsis, _rounded icons
- Dark stat cards for active alerts and patrol status
- Cards: radius 12-16, subtle shadow
- Alert banners use severity-appropriate visual weight

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Ulinzi wa Mtaa        ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ ⚠️ ACTIVE ALERT          │ │
│ │ Suspicious vehicle      │ │
│ │ reported near Block C   │ │
│ │ 15 min ago              │ │
│ └─────────────────────────┘ │
│                             │
│  [🚨 BROADCAST ALERT]      │
│                             │
│  Patrol Status              │
│ ┌─────────────────────────┐ │
│ │ ✅ Askari on duty        │ │
│ │ Last check-in: 22:30    │ │
│ │ Next: Checkpoint 3      │ │
│ └─────────────────────────┘ │
│                             │
│  Recent Incidents           │
│ ┌─────────────────────────┐ │
│ │ 🔴 Theft • Block A      │ │
│ │ 🟡 Noise • Block D      │ │
│ │ 🟢 Resolved • Block B   │ │
│ └─────────────────────────┘ │
│                             │
│ [Report][Map][Patrol][Visit]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE neighbourhood_groups(id INTEGER PRIMARY KEY, name TEXT, ward TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE incidents(id INTEGER PRIMARY KEY, group_id INTEGER, type TEXT, severity TEXT, is_resolved INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE patrol_shifts(id INTEGER PRIMARY KEY, group_id INTEGER, date TEXT, is_active INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_incidents_group ON incidents(group_id, is_resolved);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: alerts — 1 minute (near real-time), incidents — 10 minutes, patrols — 15 minutes
- Offline: read YES, write reports/checkins via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE neighbourhood_groups(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), ward VARCHAR(100), district VARCHAR(100), coordinator_id BIGINT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, radius DOUBLE PRECISION, member_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE neighbourhood_members(id BIGSERIAL PRIMARY KEY, group_id BIGINT, user_id BIGINT, role VARCHAR(30) DEFAULT 'resident', joined_at TIMESTAMP DEFAULT NOW());

CREATE TABLE neighbourhood_incidents(id BIGSERIAL PRIMARY KEY, group_id BIGINT, reporter_id BIGINT, type VARCHAR(30), description TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, severity VARCHAR(10), photos JSONB, is_anonymous BOOLEAN DEFAULT FALSE, is_resolved BOOLEAN DEFAULT FALSE, resolution TEXT, created_at TIMESTAMP DEFAULT NOW(), resolved_at TIMESTAMP);

CREATE TABLE neighbourhood_alerts(id BIGSERIAL PRIMARY KEY, group_id BIGINT, broadcaster_id BIGINT, type VARCHAR(30), description TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT NOW(), resolved_at TIMESTAMP);

CREATE TABLE patrol_shifts(id BIGSERIAL PRIMARY KEY, group_id BIGINT, patroller_id BIGINT, shift_date DATE, start_time TIME, end_time TIME, checkpoints JSONB, is_active BOOLEAN DEFAULT FALSE);

CREATE TABLE patrol_checkins(id BIGSERIAL PRIMARY KEY, shift_id BIGINT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, checked_at TIMESTAMP DEFAULT NOW(), note TEXT);

CREATE TABLE visitor_records(id BIGSERIAL PRIMARY KEY, group_id BIGINT, visitor_name VARCHAR(200), host_resident_id BIGINT, expected_time TIMESTAMP, vehicle_plate VARCHAR(20), status VARCHAR(20) DEFAULT 'expected', created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/neighbourhood/my-group | My neighbourhood | Bearer |
| POST | /api/neighbourhood/{id}/join | Join group | Bearer |
| POST | /api/neighbourhood/alerts | Broadcast alert | Bearer |
| POST | /api/neighbourhood/incidents | Report incident | Bearer |
| GET | /api/neighbourhood/{id}/incidents | Incident feed | Bearer |
| PUT | /api/neighbourhood/incidents/{id}/resolve | Resolve incident | Bearer |
| GET | /api/neighbourhood/{id}/patrols | Patrol schedule | Bearer |
| POST | /api/neighbourhood/patrols/{id}/checkin | Patrol check-in | Bearer |
| GET | /api/neighbourhood/{id}/members | Group members | Bearer |
| POST | /api/neighbourhood/{id}/visitors | Log visitor | Bearer |
| GET | /api/neighbourhood/{id}/safety-map | Safety heat map | Bearer |

### Controller
`app/Http/Controllers/Api/NeighbourhoodController.php` — DB facade with priority push for alerts and ward-based group management.

---

## 5. Integration Wiring
- **GroupService** — neighbourhood watch as specialized TAJIRI group
- **LocationService** — ward boundaries, incident locations, patrol routes
- **MessageService** — group chat, alert broadcast to all members
- **NotificationService** — emergency priority push with sound override
- **CalendarService** — patrol schedules and security meetings
- **PhotoService** — photo/video evidence on incident reports
- **police** — escalate serious incidents to police
- **alerts** — feed into broader emergency alert system
- **my_family** — family check-in during emergencies
- **housing** — safety ratings in property listings

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and group CRUD
- Ward-based group creation

### Phase 2: Core UI (Week 2)
- Incident reporting with photos
- Alert broadcast with priority push
- Incident feed with filters

### Phase 3: Integration (Week 3)
- Patrol schedule and GPS check-ins
- Safety map with heat visualization
- Group member management

### Phase 4: Polish (Week 4)
- Visitor log system
- Meeting planner
- Anonymous reporting, resolution tracking

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Firebase Cloud Messaging | Google | Push notifications for safety alerts | Free (with Firebase) | Topic-based messaging; ideal for real-time community alerts |
| CrimeoMeter API | CrimeoMeter | Crime data around specific locations | Freemium | Safety scores, crime types, radius search; crimeometer.com |
| OneSignal | OneSignal | Push notifications for safety broadcasts | Free (up to 10k subscribers) | Segmented push; onesignal.com; great for community alerts |
| Twilio API | Twilio | SMS/voice alerts for emergency notifications | $0.0079/SMS | Mass SMS alerts; reliable delivery |
| OpenStreetMap Overpass | OpenStreetMap | Map data for neighborhood boundaries | Free, open source | Community boundary data; global coverage |

**Note:** No dedicated "neighborhood watch" APIs exist. Best approach: build custom incident reporting with Firebase/Firestore for real-time data, CrimeoMeter for crime context, and push notifications (FCM/OneSignal) for alerts.

### Integration Priority
1. **Immediate** — Free APIs (Firebase Cloud Messaging for alerts, OpenStreetMap for maps)
2. **Short-term** — Freemium APIs (CrimeoMeter for crime context, OneSignal for push)
3. **Partnership** — Twilio (SMS alerts), local law enforcement integration
