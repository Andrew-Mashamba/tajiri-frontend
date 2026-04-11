# Ambulance Services — Feature Description

## Tanzania Context

Emergency medical services in Tanzania are critically underdeveloped. The country has no unified national emergency number equivalent to 911 — though 114 exists for police and 115 for fire, there is no dedicated ambulance dispatch number that works reliably nationwide. Most Tanzanians resort to private transport (personal cars, taxis, bodaboda motorcycles) to reach hospitals during emergencies, leading to preventable deaths.

Current ambulance providers in Tanzania:
- **Ministry of Health (MoH)** — Operates ambulances at regional and district hospitals, but fleet is small, poorly maintained, and response times are long (often 45+ minutes in urban areas, hours in rural)
- **AAR Health Services** — Private emergency provider, primarily serving insured clients in Dar es Salaam, Arusha, and Mwanza. Subscription-based with 24/7 call center
- **CCBRT (Comprehensive Community Based Rehabilitation in Tanzania)** — Disability-focused hospital with limited ambulance services
- **Muhimbili National Hospital** — Has ambulances but primarily for inter-facility transfers
- **St. John Ambulance Tanzania** — Volunteer-based, limited operational capacity
- **Red Cross Tanzania** — Disaster response focused, not routine emergency transport

Key challenges: vast distances in rural areas with poor road infrastructure, very few ambulances per capita (estimated 1 per 100,000+ people), no centralized dispatch system, patients must often call multiple providers to find availability, no GPS tracking of ambulances, payment demands before service begins, lack of trained paramedics (most ambulances are staffed by drivers only, not EMTs).

The market is ripe for a technology solution that aggregates all available ambulance services, enables GPS tracking, and provides a single-tap emergency call experience.

## International Reference Apps

1. **Flare (Kenya)** — East Africa's leading emergency response app. One-tap ambulance request, GPS location sharing, connects to nearest available ambulance from multiple providers, tracks ambulance en route, stores medical profile, works with insurance. Operating in Nairobi and expanding.

2. **Uber Health (USA)** — Non-emergency medical transport. HIPAA-compliant, scheduling for patients, caregiver booking, integration with healthcare systems, no smartphone required for patients (SMS-based).

3. **MUrgency (India/UAE)** — Global emergency response network. Connects to nearest verified first responders (paramedics, doctors, firefighters), real-time tracking, medical profile storage, multi-language support.

4. **Red Cross First Aid App (Global)** — Step-by-step first aid instructions, emergency number directory by country, preparedness checklists, quizzes for learning, works offline.

5. **PulsePoint (USA)** — Community CPR response. Alerts nearby CPR-trained citizens when cardiac arrest occurs near them, shows AED locations, integrates with 911 dispatch.

## Feature List

### Emergency Call & Dispatch
1. One-tap SOS emergency button on home screen — largest, most prominent UI element
2. Automatic GPS location detection and sharing with dispatch
3. Manual address entry when GPS is unavailable or inaccurate
4. Aggregated ambulance network — connects to all available providers (MoH, AAR, private, St. John)
5. Nearest available ambulance algorithm considering distance, traffic, and provider capacity
6. Direct call to ambulance dispatch with location pre-shared
7. SMS fallback for areas with poor data connectivity
8. USSD integration for feature phone accessibility (*150*911#)
9. Emergency contact auto-notification — alerts saved contacts when SOS triggered
10. Silent emergency mode for situations where calling isn't safe

### Real-Time Tracking
11. Live GPS tracking of dispatched ambulance on map
12. Estimated arrival time (ETA) with real-time updates
13. Driver/paramedic profile display (name, photo, qualifications)
14. Two-way communication with ambulance crew (call/chat)
15. Share live tracking link with family members via WhatsApp/SMS
16. Route visualization showing ambulance path to your location

### Medical Profile
17. Personal medical profile storage (blood type, allergies, conditions, medications)
18. Emergency contact list with relationship tags
19. Insurance information storage (NHIF, private insurance policy numbers)
20. Medical history summary accessible to responding paramedics
21. QR code medical ID — scannable even when patient is unconscious
22. Multiple profiles for family members

### Hospital Directory
23. Comprehensive hospital and clinic directory for all of Tanzania
24. Real-time bed availability status (where data is available)
25. Hospital capability filters (trauma center, maternity, pediatric, ICU)
26. Distance and travel time from current location
27. Hospital ratings and reviews from patients
28. Direct call to hospital from directory listing
29. Navigation to hospital via integrated maps
30. Emergency department wait time estimates

### First Aid Guide
31. Offline-accessible first aid instructions for common emergencies
32. Step-by-step guides with illustrations: CPR, choking, bleeding, burns, fractures
33. Swahili and English language support
34. Audio instructions for hands-free guidance during emergency
35. Condition-specific guides: snakebite (common in rural TZ), malaria crisis, drowning
36. Pediatric first aid section
37. Video tutorials for key procedures
38. Emergency medication dosage reference

### Insurance Integration
39. NHIF (National Health Insurance Fund) verification and coverage check
40. Private insurance provider integration (AAR, Jubilee, Britam, Strategis)
41. Pre-authorization for insured ambulance transport
42. Direct billing to insurance provider (cashless where possible)
43. Insurance card photo storage and quick access
44. Coverage eligibility check before dispatch

### Payment & Billing
45. Transparent upfront pricing before ambulance dispatch
46. M-Pesa, Tigo Pesa, Airtel Money payment integration via TAJIRI Wallet
47. Post-service payment option (pay after arrival at hospital)
48. Subscription plans for frequent users or high-risk individuals
49. Family emergency plans covering multiple household members
50. Corporate emergency plans for businesses
51. Invoice generation and payment history

### Community Safety
52. AED (Automated External Defibrillator) location map
53. Community first responder network — trained volunteers alerted for nearby emergencies
54. Blood donor network integration — urgent blood type matching
55. Emergency preparedness tips and seasonal health alerts
56. Report road accidents to alert other drivers and emergency services

## Key Screens

1. **Emergency Home** — Large SOS button, quick-access medical profile, recent emergency contacts
2. **Ambulance Tracking** — Real-time map with ambulance location, ETA, driver info
3. **Medical Profile Editor** — Blood type, allergies, conditions, medications, emergency contacts
4. **Hospital Directory** — Searchable/filterable list with map view, bed availability
5. **First Aid Guide** — Category-based emergency instructions with illustrations
6. **Insurance Manager** — Policy storage, coverage verification, claims history
7. **Emergency History** — Past emergency calls, ambulances used, hospitals visited
8. **Family Profiles** — Manage medical profiles for household members
9. **Payment & Plans** — Subscription management, payment methods, billing history
10. **Community Responders** — Register as volunteer first responder, training status

## TAJIRI Integration Points

- **Wallet (WalletService)** — Pay for ambulance services via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Subscription plan payments (individual, family, corporate) processed through wallet. Post-service payment option with balance deduction. Hospital bill payments routed through wallet. Claim payouts from insurance deposited via `WalletService.transfer()`. Transaction history via `WalletService.getTransactions()` shows all emergency-related payments
- **Messaging (MessageService)** — Two-way communication with ambulance crew via `MessageService.sendMessage()` during dispatch. Hospital coordination messages. Post-emergency follow-up conversations. Auto-created conversation with dispatch upon SOS trigger via `MessageService.createGroup()` linking patient, paramedic, and hospital coordinator
- **Profile (ProfileService)** — Medical profile (blood type, allergies, conditions, medications) linked to main TAJIRI profile via `ProfileService.getProfile()` with privacy controls — only accessible to responding paramedics during active emergency. QR code medical ID generated from profile data. Emergency contact list synced from profile
- **Friends & Family (FriendService + my_family/)** — Emergency contact auto-notification via `FriendService.getFriends()` when SOS triggered. Family member medical profiles managed under My Family module. Share live ambulance tracking link with family. Mutual friends shown for community first responders to build trust
- **Insurance Module (insurance/ + TIRA)** — NHIF verification and private insurance coverage check (AAR, Jubilee, Britam) before dispatch. Pre-authorization for insured transport. Direct billing to insurance provider for cashless service. Insurance card data pulled from TIRA integration for policy verification. Claims filing initiated from emergency history
- **Groups (GroupService)** — Community first responder groups via `GroupService.createGroup()` — trained volunteers organized by neighborhood. Health awareness groups for emergency preparedness. Blood donor network groups for urgent blood type matching. Group posts via `GroupService.getGroupPosts()` for safety tips and training updates
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: ambulance dispatch confirmation, real-time ETA updates, ambulance arrival, nearby emergency alerts for community responders, subscription renewal reminders, first aid tip alerts. Silent notification for background location sharing during emergency
- **Location (LocationService)** — Core GPS functionality for emergency location via `LocationService.searchLocations()` with Tanzania hierarchy (Region, District, Ward). Automatic location detection and sharing with dispatch. Manual address entry fallback using location search. Hospital proximity calculation. Ambulance route tracking on map
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for live ambulance GPS position updates during dispatch. Real-time ETA recalculation. Hospital bed availability status updates. Community responder alert broadcasting via real-time events
- **Doctor Module (doctor/)** — Telemedicine consultation while waiting for ambulance — connect to on-call doctor for immediate guidance. First aid instructions from doctor during emergency. Post-emergency follow-up consultation scheduling. Doctor receives medical profile and emergency details before ambulance arrival
- **Pharmacy Module (pharmacy/)** — Medication information cross-reference with medical profile to alert paramedics of drug interactions. Emergency medication availability check at destination hospital. Post-emergency prescription ordering
- **My Family Module (my_family/)** — Manage medical profiles for all household members (spouse, children, elderly parents). Family emergency plan with designated contacts per member. Pediatric medical profile for children's emergencies. Elderly care emergency protocols
- **Calendar (CalendarService)** — Subscription renewal dates synced to calendar via `CalendarService.createEvent()`. First responder training session scheduling. Follow-up medical appointment reminders post-emergency
- **Posts & Stories (PostService + StoryService)** — Community safety awareness posts via `PostService.createPost()`. First responder training completion shared as stories. Blood drive announcements shared to feed. Road accident reports posted to alert community
- **Transport Module (transport/)** — Non-emergency medical transport coordination. Post-discharge transport home. Integration with ride-hailing for non-critical medical visits
- **Media (PhotoService)** — Accident scene documentation via `PhotoService.uploadPhoto()`. Medical ID QR code generation. Hospital directory photos for identification
- **Presence (PresenceService)** — Community first responder availability status via `PresenceService` batch check. Show which trained volunteers are nearby and active for cardiac arrest or emergency response
- **Content Discovery (ContentEngineService)** — Personalized first aid content recommendations based on user's medical profile (e.g., diabetic users see insulin emergency guides). Seasonal health alerts pushed through content engine
