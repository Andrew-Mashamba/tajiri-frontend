# Ofisi ya Mtaa (Ward/Street Office) — Feature Description

## Tanzania Context

The Mtaa (street/neighborhood) is the lowest unit of urban local government in Tanzania. Each Mtaa is led by a Mwenyekiti wa Mtaa (Street Chairperson), elected by residents, and administered by a Mtendaji wa Mtaa (Street Executive Officer), a government appointee. In rural areas, the equivalent is the Kitongoji (sub-village) under the Village (Kijiji).

**Services provided by Mtaa offices:**
- Barua ya Utambulisho (Introduction/reference letters) — needed for jobs, bank accounts, SIM registration, school enrollment
- Land use verification letters
- Residence confirmation
- Business permit recommendations
- Dispute mediation (family, neighbor, land)
- Community security coordination (Sungusungu/Polisi Jamii)
- Census and voter registration support
- Forwarding complaints to Ward level

**Current reality:**
- Mtaa offices have irregular hours; Mtendaji may serve multiple streets
- Getting a simple reference letter can take 3-5 visits over multiple days
- No appointment system — first come, first served, often outdoors
- Fees are informal and inconsistent — some Mtendaji charge unofficial amounts
- Record-keeping is paper-based; files get lost, damaged, or take weeks to locate
- Citizens often don't know which documents they need before visiting
- Communication is word-of-mouth or mosque/church announcements
- No way to track application status once submitted

**Pain points:**
- Long wait times for basic letters (3+ hours common)
- Corruption at street level — "chai" (bribes) expected to speed up services
- Mtendaji absence with no notification to residents
- No transparency on official fees vs unofficial charges
- Young people find the process humiliating and outdated

## International Reference Apps

1. **NYC 311 (US)** — Report issues, request city services, track service requests with status updates. Multi-channel (app, phone, web, text).
2. **FixMyStreet (UK)** — Report neighborhood problems, automatically routed to responsible council. Photo + GPS. Public issue map.
3. **Seoul Smart Complaint (South Korea)** — Municipal service requests with AI routing, real-time tracking, satisfaction surveys.
4. **mySydney (Australia)** — Local council services app: report issues, book facilities, pay rates, waste collection schedules.
5. **Decidim (Barcelona)** — Participatory democracy platform for citizen proposals, community budgeting, neighborhood assemblies.

## Feature List

1. **Service Catalog** — Complete list of Mtaa office services with descriptions, required documents, official fees, and estimated processing time
2. **Document Checklist Generator** — Select a service, get exact list of documents needed (e.g., ID copies, passport photos, witness letters)
3. **Service Request Submission** — Apply for reference letters, land verification, and other services digitally with document uploads
4. **Application Tracking** — Track status of submitted requests: Received > Under Review > Ready for Collection, with estimated dates
5. **Appointment Booking** — Book time slots with Mtendaji to avoid waiting; see available hours
6. **Office Hours Display** — Current week schedule, holiday closures, Mtendaji availability status (Available / Out of Office / On Leave)
7. **Contact Directory** — Phone numbers and roles for Mwenyekiti, Mtendaji, Mjumbe (ten-cell leaders), security contacts
8. **Community Notices Board** — Digital noticeboard for Mtaa announcements: meetings, water schedules, security alerts, construction
9. **Issue Reporting** — Report street-level issues: broken infrastructure, security concerns, sanitation, noise, illegal construction
10. **Fee Transparency** — Official government fee schedule for each service, with option to report overcharging
11. **Digital Reference Letter** — Generate verifiable digital reference letters with QR code for authenticity
12. **Meeting Calendar** — Schedule of Mtaa meetings (Mkutano wa Mtaa) with agendas and minutes
13. **Resident Directory** — Opt-in directory of Mtaa residents for community networking (privacy-controlled)
14. **Emergency Contacts** — Police, fire, hospital, water emergency, electricity emergency for the area
15. **Feedback & Rating** — Rate service quality after each interaction; anonymous option available
16. **Payment Integration** — Pay official service fees via M-Pesa through the app with digital receipt
17. **Multi-Mtaa Support** — Users who own property or reside in multiple areas can manage multiple Mtaa connections
18. **Notification System** — Push alerts for application status changes, meeting reminders, community announcements

## Key Screens

- **Mtaa Home** — Your Mtaa overview: chairperson, Mtendaji, quick actions, recent notices
- **Service Catalog** — Browseable/searchable list of all available services with details
- **Apply for Service** — Step-by-step form with document upload, fee display, submission confirmation
- **My Applications** — List of all submitted requests with status tracking timeline
- **Book Appointment** — Calendar view with available slots, confirmation flow
- **Community Board** — Feed of notices, announcements, and alerts from Mtaa leadership
- **Issue Report** — Photo + GPS + category + description form for reporting problems
- **Contacts** — Directory of Mtaa officials and emergency numbers
- **Fee Schedule** — Official fees table with report overcharging option

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for paying official service fees (reference letters, land verification); `getTransactions()` for digital payment receipts replacing informal cash payments
- **MessageService** — `sendMessage()` for direct chat with Mtendaji or Mwenyekiti; `getConversations()` for tracking service request discussions
- **GroupService** — `createGroup()` for auto-creating Mtaa community group; `joinGroup()` for residents joining their street community; `getMembers()` for opt-in resident directory; `inviteUsers()` for Mtendaji to onboard residents
- **PostService** — `createPost()` for community notices appearing in local feed; `sharePost()` for sharing Mtaa announcements
- **StoryService** — `createStory()` for Mtendaji sharing quick updates on office hours, meeting reminders
- **NotificationService + FCMService** — Push alerts for application status changes (Received > Under Review > Ready for Collection), meeting reminders, community announcements, emergency alerts
- **LiveUpdateService** — Real-time application status tracking via Firestore for service requests
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()`, `getStreets()` for GPS-based Mtaa detection and automatic assignment; full mtaa hierarchy navigation
- **ProfileService** — `getProfile()` for Mtaa official verified profiles; user location data from `RegistrationState` for Mtaa matching
- **PhotoService** — `uploadPhoto()` for document uploads (ID copies, passport photos for reference letters), issue report attachments
- **CalendarService** — `createEvent()` for Mtaa meetings (Mkutano wa Mtaa), appointment slots with Mtendaji
- **LocalStorageService** — Offline caching of service catalogs, fee schedules, document checklists, and emergency contacts
- **MediaCacheService** — Cache digital reference letters and document templates for offline access
- **EventTrackingService** — Analytics on service request volumes, resolution times, resident satisfaction ratings
- **PeopleSearchService** — Search residents by street/mtaa location for community directory
- **Cross-module: barozi_wangu** — Escalation path from Mtaa issues to Ward Councillor when Mtaa-level resolution fails
- **Cross-module: community/** — Mtaa community group integrates with TAJIRI community module
- **Cross-module: events/** — Mtaa meetings listed in TAJIRI events calendar
