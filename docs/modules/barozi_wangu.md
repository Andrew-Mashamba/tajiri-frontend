# Barozi Wangu (My Councillor) — Feature Description

## Tanzania Context

In Tanzania's local government structure, Ward Councillors (Madiwani) are the most accessible elected officials. Each ward (Kata) elects a councillor to represent citizens in the District Council (Halmashauri). Tanzania has over 3,900 wards across its 169 districts.

**Current reality:**
- Most citizens do not know who their councillor is, let alone how to contact them
- Councillors hold irregular community meetings (Mikutano ya Hadhara) with poor attendance
- No standardized way to report ward-level issues (broken roads, water shortages, sanitation)
- Campaign promises go untracked — no accountability mechanism exists
- Ward Development Committees (Kamati za Maendeleo ya Kata) operate opaquely
- Women and youth participation in ward governance is especially low
- Special seats councillors (Viti Maalum) are even harder to identify and contact
- Ward Executive Officers (WEOs) are the administrative counterpart but equally unreachable

**Pain points:**
- Citizens travel to ward offices only to find them closed or the councillor absent
- No digital record of councillor performance or attendance at council meetings
- Development funds (e.g., from TASAF, constituency development funds) lack transparency
- Complaints about services get lost — no ticketing or tracking system
- Language barrier: most government info is in English, citizens need Swahili

## International Reference Apps

1. **Countable (US)** — Find elected officials, read bills, vote on issues, send messages to representatives. Clean UI showing how officials voted.
2. **GovTrack (US)** — Track legislators, bills, votes. Excellent data visualization of legislative activity and voting records.
3. **mySociety / TheyWorkForYou (UK)** — Look up MPs by postcode, see their speeches, voting record, expenses. WriteToThem lets citizens send messages.
4. **Civis (India)** — Ward-level civic engagement, report issues, track resolution. Designed for Indian municipal governance.
5. **FixMyStreet (UK/Global)** — Report local problems (potholes, street lights, graffiti) with photo and GPS, routed to responsible authority.

## Feature List

1. **Find Your Councillor** — Enter ward name, street, or GPS location to identify your councillor with photo, party, contact info, and term dates
2. **Councillor Profile** — Bio, education, committee memberships, office location, phone, email, office hours
3. **Direct Messaging** — Send messages/petitions to your councillor through the app (with read receipts)
4. **Issue Reporting** — Report ward issues with photo, GPS pin, category (roads, water, sanitation, electricity, security), and priority level
5. **Issue Tracking Dashboard** — Track reported issues through stages: Submitted > Acknowledged > In Progress > Resolved, with timeline
6. **Promise Tracker** — Community-sourced list of campaign promises with status (Kept / In Progress / Broken / Not Started), evidence links
7. **Performance Scorecard** — Rate councillor on responsiveness, presence, development delivery; aggregate community scores displayed publicly
8. **Council Meeting Minutes** — Summaries of District Council meetings, how your councillor voted, key decisions
9. **Ward Forum** — Community discussion board per ward for residents to discuss local issues, share updates, organize
10. **Development Projects** — List of ongoing/completed projects in the ward with budgets, contractors, timelines, photos
11. **Ward Budget Tracker** — Visualize ward development budget allocation vs actual spending
12. **Community Notices** — Councillor can post announcements, meeting invitations, emergency alerts to ward residents
13. **Petition System** — Citizens can create petitions, collect signatures from ward residents, submit to council
14. **Councillor Comparison** — Compare councillors across wards on metrics (response time, issues resolved, projects delivered)
15. **Election History** — Past election results for the ward, candidate list, vote counts
16. **Push Notifications** — Alerts for councillor responses, issue updates, upcoming meetings, new community notices
17. **Ward Map** — Interactive map showing ward boundaries, polling stations, key infrastructure, reported issues

## Key Screens

- **Home/Discovery** — Map-based ward finder with councillor card overlay
- **Councillor Profile** — Full profile with scorecard, contact options, activity feed
- **Issue Report Form** — Photo capture, GPS pin, category picker, description
- **Issue Tracker** — List/map view of all reported issues with status filters
- **Promise Tracker** — Campaign promises list with community verification status
- **Ward Forum** — Threaded discussion board with topic categories
- **Council Meetings** — Meeting calendar, minutes, voting records
- **Development Projects** — Project cards with budget, timeline, progress bar, photos
- **Petition Builder** — Create petition, share link, track signatures

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for donations to ward development initiatives; `transfer()` for community project contributions via ContributionService
- **ContributionService** — `createCampaign()` for ward harambee/fundraising drives; `donate()` for residents to contribute to community projects
- **MessageService** — `sendMessage()` for direct chat with councillor; `createGroup()` for ward-level group conversations; `getConversations()` for tracking ongoing discussions with officials
- **GroupService** — `createGroup()` for auto-creating ward forum per ward; `joinGroup()` for residents joining their ward community; `getMembers()` for ward resident directory; `inviteUsers()` for councillor to invite constituents
- **PostService** — `createPost()` for councillor announcements appearing in local feed; `sharePost()` for residents sharing ward issues; `likePost()` for community engagement on local matters
- **StoryService** — `createStory()` for councillor sharing quick project updates, ward visit highlights
- **NotificationService + FCMService** — Push alerts for issue status changes, councillor responses, upcoming council meetings, emergency alerts, and petition milestones
- **LiveUpdateService** — Real-time status changes on reported issues via Firestore (Submitted > Acknowledged > In Progress > Resolved)
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()`, `getStreets()` for GPS-based ward detection and councillor assignment; shared location hierarchy across modules
- **ProfileService** — `getProfile()` for councillor verified profiles linked to TAJIRI user profiles; user location data for ward matching
- **PhotoService** — `uploadPhoto()` for issue report photo/video attachments, project progress documentation
- **CalendarService** — `createEvent()` for council meetings, community gatherings, and development milestone dates
- **EventTrackingService** — Analytics on councillor engagement, issue resolution rates, community participation metrics
- **LocalStorageService** — Offline caching of ward data, councillor info, and issue reports for areas with poor connectivity
- **PeopleSearchService** — Search residents by ward location for petition signature collection
- **Cross-module: community/** — Ward forum integrates with TAJIRI community module for threaded discussions
- **Cross-module: events/** — Council meetings and community events listed in TAJIRI events module
- **Cross-module: ofisi_mtaa** — Escalation path from Mtaa-level issues to Ward Councillor via Barozi Wangu
- **Cross-module: dc** — Further escalation from ward councillor to District Commissioner for unresolved issues
