# DC (District Commissioner) — Feature Description

## Tanzania Context

The District Commissioner (Mkuu wa Wilaya) is the chief representative of the central government at district level. Tanzania has 169 districts, each headed by a DC appointed by the President. The DC oversees security, law and order, development coordination, and government policy implementation within the district.

**DC office responsibilities:**
- Coordinating district security (chairs District Security Committee)
- Supervising government departments at district level (education, health, agriculture, water)
- Overseeing implementation of national policies and directives
- Coordinating disaster response and emergency management
- Mediating inter-ward disputes and escalated community issues
- Supervising District Administrative Secretary (DAS) and government staff
- Approving certain permits and licenses
- Monitoring development projects funded by central government

**Current reality:**
- DCs are powerful but inaccessible — citizens rarely interact directly
- District development projects lack transparency; budgets and progress not publicly tracked
- Emergency information (floods, disease outbreaks) disseminated slowly through radio and word-of-mouth
- District-level statistics (education, health, economy) not easily available to citizens
- Citizens don't know which services fall under DC vs District Council vs Regional level
- Complaints to DC office go through slow bureaucratic channels with no tracking
- District government websites, where they exist, are outdated and non-functional

**Pain points:**
- No direct channel for citizens to raise urgent district-level concerns
- Development project information opaque — contractors, budgets, timelines unknown
- Emergency response coordination slow and fragmented
- Inter-district services (e.g., transferring records) cumbersome
- Citizens travel to district HQ for information available digitally elsewhere

## International Reference Apps

1. **USAspending.gov** — Federal spending transparency portal showing contracts, grants, and budgets by region with visualization tools.
2. **Citizen Budget (Canada)** — Interactive budget simulator letting citizens see how public funds are allocated and propose changes.
3. **GovDelivery (US)** — Government communications platform for sending targeted alerts, updates, and notifications to citizens.
4. **Snap Send Solve (Australia)** — Report issues to local councils with automatic routing based on location and issue type.
5. **Huduma Kenya** — Integrated government services platform aggregating multiple department services in one interface.

## Feature List

1. **DC Profile** — Current DC photo, bio, appointment date, previous positions, contact information, office location
2. **District Overview** — Key statistics: population, wards, schools, health facilities, economic indicators, maps
3. **Government Departments** — Directory of all district-level departments (Education, Health, Water, Agriculture, Lands) with heads and contacts
4. **Development Projects** — List of ongoing and completed projects: name, budget, funder (central govt, donor, TASAF), contractor, timeline, progress photos
5. **Project Budget Tracker** — Visualize allocated vs disbursed vs spent funds per project, per sector
6. **District News & Announcements** — Official communications from DC office: directives, policy changes, event announcements
7. **Report to DC** — Submit formal complaints or suggestions to DC office with category, description, attachments, and tracking number
8. **Complaint Tracking** — Follow submitted reports through stages: Received > Assigned > Under Investigation > Resolved, with timeline
9. **Emergency Alerts** — Push notifications for district emergencies: floods, disease outbreaks, security threats, weather warnings
10. **Emergency Contacts** — Police (OCD), fire, hospitals, Red Cross, district disaster committee contacts
11. **District Events Calendar** — National celebrations, public hearings, commissioner visits, development milestones
12. **Service Directory** — Which government services are available at district level, office locations, hours, requirements
13. **District Statistics Dashboard** — Education enrollment, health facility utilization, agricultural output, revenue collection trends
14. **Public Notices** — Gazette notices, land acquisition notices, tender advertisements, appointment announcements
15. **Ward Performance Comparison** — Compare wards on key metrics: school pass rates, health coverage, project completion
16. **DC Office Queue** — Check current wait times, book appointments for specific departments
17. **District Security Updates** — Non-sensitive security situation reports, community policing updates, traffic advisories

## Key Screens

- **District Home** — DC card, quick stats, recent news, emergency banner (if active)
- **DC Profile** — Full bio, office details, contact options
- **Development Projects** — Filterable list/map of projects with budget and progress indicators
- **Report Form** — Category selection, description, photo/document upload, location pin
- **My Reports** — Submitted complaints/suggestions with status tracking
- **District Stats** — Interactive charts for education, health, economy, infrastructure
- **Emergency Center** — Active alerts, emergency contacts, safety guidelines
- **Department Directory** — Browseable list of departments with contact info and services
- **News Feed** — Chronological district announcements and updates

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for government service fee payments at district level; `getTransactions()` for payment history and receipts
- **MessageService** — `sendMessage()` for structured communication to DC office (formal reports, not personal chat); `createGroup()` for district-level coordination channels
- **GroupService** — `createGroup()` for district community group; `joinGroup()` for civic discussion participation; `getMembers()` for district community membership
- **PostService** — `createPost()` for district news and announcements in TAJIRI feed; `sharePost()` for sharing development project updates with geographic targeting
- **StoryService** — `createStory()` for DC office sharing emergency alerts, event highlights
- **NotificationService + FCMService** — Push alerts for district emergencies (floods, disease outbreaks, security threats), report status updates, development milestones, and district announcements
- **LiveUpdateService** — Real-time complaint tracking via Firestore (Received > Assigned > Under Investigation > Resolved)
- **LocationService** — `getRegions()`, `getDistricts()` for GPS-based district detection; content filtering by user's district
- **ProfileService** — `getProfile()` for DC and department head profiles; user location from `RegistrationState` for district assignment
- **PhotoService** — `uploadPhoto()` for project monitoring photos, issue report attachments, development progress documentation
- **CalendarService** — `createEvent()` for district events, national celebrations, public hearings, development milestones
- **EventTrackingService** — Analytics on ward performance comparison, development project metrics, complaint resolution rates
- **LocalStorageService** — Offline caching of district statistics, emergency contacts, service directory
- **MediaCacheService** — Cache project photos and district maps for offline viewing
- **ContributionService** — `createCampaign()` for district-level community fundraising initiatives
- **Cross-module: barozi_wangu** — Escalation path: Ward Councillor issues elevated to DC level
- **Cross-module: ofisi_mtaa** — District services complement Mtaa-level services; DC oversees WEOs
- **Cross-module: rc** — Further escalation from DC to Regional Commissioner for unresolved district issues
- **Cross-module: events/** — District events appear in TAJIRI events module
- **Cross-module: community/** — District civic discussion groups
