# Police (Polisi) — Feature Description

## Tanzania Context

The Tanzania Police Force (Jeshi la Polisi Tanzania) is the national police service responsible for maintaining law and order. The force is organized into regional commands under OCD (Officer Commanding District) and RPC (Regional Police Commander) structures. Emergency numbers include 112 (general emergency), 114 (police), and 199 (fire). However, these numbers are inconsistently reliable across regions, and many Tanzanians call their local police station directly.

Reporting crimes in Tanzania typically requires visiting a police station in person to file a report (taarifa). This process can be time-consuming and intimidating. Traffic fines are a common interaction — the Tanzania Revenue Authority (TRA) and police handle traffic violations, with fines payable at banks or via mobile money. Safety concerns vary significantly by area — petty theft is common in urban areas, while rural areas face different challenges. Community policing (polisi jamii) is promoted but lacks digital coordination tools. Many citizens lack easy access to their nearest police station's contact information.

## International Reference Apps

1. **Citizen** — Real-time safety alerts, incident reports, live video from nearby incidents
2. **PulsePoint** — Emergency alerts and CPR notification for nearby cardiac events
3. **Noonlight** — Personal safety app with emergency dispatch and location sharing
4. **bSafe** — Personal safety with live GPS tracking, SOS alarm, fake call feature
5. **Nextdoor** — Community safety alerts and police department communication

## Feature List

1. Emergency call — one-tap emergency call to 112/114 with GPS location auto-send
2. Nearest police station — map showing closest stations with distance and contact info
3. Police station directory — searchable list by region, district, with OCD/RPC contacts
4. Report crime — digital crime report submission with incident type, description, photos
5. Case tracking — follow up on filed reports with case number and status updates
6. Traffic fine payment — check and pay traffic fines via M-Pesa
7. Traffic fine lookup — search by vehicle plate number or license number
8. Police contacts by district — regional and district commander contacts
9. Safety tips — crime prevention advice, home security, travel safety
10. Emergency contacts — customizable list of personal emergency contacts with quick-dial
11. SOS alert — silent emergency alert to pre-set contacts with live location
12. Incident map — view reported incidents in your area (anonymized)
13. Community policing — connect with local polisi jamii representatives
14. Lost and found — report lost items or found property
15. Missing persons — report and browse missing person alerts
16. Document reporting — report lost/stolen ID, passport, or important documents
17. Legal rights — know your rights during police interactions (Swahili)

## Key Screens

- **Police Home** — emergency call button (prominent), nearest station, recent alerts, quick actions
- **Emergency Screen** — large SOS button, auto-location, emergency contact dial, countdown timer
- **Station Finder** — map with police station pins, list view with distance and phone numbers
- **Station Detail** — address, contact numbers, OCD info, operating hours, directions
- **Report Crime** — incident type selector, date/time, location, description, photo upload
- **My Reports** — list of filed reports with status (received, investigating, resolved)
- **Traffic Fines** — lookup by plate/license, fine details, M-Pesa payment flow
- **Safety Tips** — categorized safety advice articles and infographics
- **SOS Settings** — configure emergency contacts, alert preferences, auto-location sharing
- **Incident Map** — heat map and pins showing recent incidents by area

## TAJIRI Integration Points

- **LocationService** — Find nearest police station with distance, contact info, and directions; GPS auto-send with emergency calls
- **MessageService.sendMessage()** — SOS alert messages to emergency contacts via TAJIRI messaging; emergency contact quick-dial
- **WalletService.deposit(amount, provider:'mpesa')** — Traffic fine payment and other police-related fees via M-Pesa
- **NotificationService + FCMService** — SOS confirmations, case status updates, and safety alerts via push notifications
- **CalendarService.createEvent()** — Court dates, case follow-up appointments, and report deadlines synced to calendar
- **ProfileService.getProfile()** — Emergency contact info stored in profile for quick SOS access
- **GroupService.getMembers()** — Community policing groups (polisi jamii) for neighborhood coordination
- **PhotoService.uploadPhoto()** — Attach photos to crime reports and incident documentation
- **neighbourhood_watch module** — Community policing integration with neighborhood safety groups
- **alerts module** — Police-issued safety alerts fed into broader emergency alert system
- **traffic module** — Traffic fine lookup linked to registered vehicles; live map integration
- **transport/ module** — Directions to nearest police station, safe route suggestions
- **my_family/ module** — Family emergency notifications and check-in during safety incidents
- **community/ module** — Community policing discussions in local groups
