# Alerts (Tahadhari) — Feature Description

## Tanzania Context

"Tahadhari" means "warning" or "alert" in Swahili. Tanzania faces various natural and man-made hazards: flooding (especially in Dar es Salaam during heavy rains — the Msimbazi River basin floods regularly), earthquakes (Tanzania sits on the East African Rift, with seismic activity particularly around Lake Tanganyika and Kilimanjaro), landslides in highland areas, and cyclone impacts from the Indian Ocean.

The Tanzania Meteorological Authority (TMA) issues weather warnings, and the Disaster Management Department (DMD) under the Prime Minister's Office coordinates disaster response. However, alert dissemination to the general public is poor — warnings are broadcast on TV and radio, often too late for effective response. There is no nationwide mobile alert system equivalent to the US Emergency Alert System. During the 2023 Cyclone Hidaya and regular flooding events, residents relied on social media and WhatsApp for real-time information. Many deaths and injuries could be prevented with timely, location-specific alerts delivered directly to phones.

## International Reference Apps

1. **FEMA App** — Emergency alerts, safety tips, disaster resources, shelter finder (US)
2. **Red Cross Emergency** — Weather alerts, first aid info, shelter locations, family check-in
3. **Citizen** — Real-time incident alerts with GPS-based notifications
4. **Weather Underground** — Severe weather alerts with hyper-local forecasting
5. **Zello** — Push-to-talk walkie-talkie used during emergencies for communication

## Feature List

1. Weather alerts — TMA severe weather warnings delivered by location (rain, wind, heat)
2. Flood warnings — alerts for flood-prone areas based on rainfall data and river levels
3. Earthquake notifications — seismic event alerts with magnitude, epicenter, safety instructions
4. Government announcements — official emergency communications from government agencies
5. Location-based alerts — only receive alerts relevant to your current GPS location
6. Alert severity levels — tiered system: advisory (blue), watch (yellow), warning (orange), emergency (red)
7. Safety broadcasts — national security announcements and public safety messages
8. Evacuation guides — area-specific evacuation routes and assembly points
9. First aid tips — basic first aid instructions by emergency type (burns, drowning, fractures)
10. Emergency contacts — national emergency numbers (112, 114, 199) and local contacts
11. Family check-in — "I'm safe" button to notify family members during emergencies
12. Shelter finder — locations of emergency shelters, hospitals, and safe zones
13. Power outage alerts — TANESCO power outage notifications by area
14. Water supply alerts — water utility disruption notices
15. Disease outbreak alerts — health emergency notifications (cholera, dengue, etc.)
16. Road hazard alerts — dangerous road conditions fed from traffic module
17. Historical alert archive — past alerts for reference and preparedness planning
18. Emergency preparedness — checklists and guides for different disaster scenarios

## Key Screens

- **Alerts Home** — active alerts list sorted by severity, location-based, "I'm safe" status
- **Alert Detail** — full alert information: type, severity, affected area, instructions, map
- **Alert Map** — geographic visualization of active alerts and affected zones
- **Emergency Contacts** — one-tap dial list with national and local emergency numbers
- **First Aid Guide** — categorized first aid instructions with illustrations
- **Evacuation Map** — local evacuation routes, assembly points, shelter locations
- **Family Check-in** — "I'm safe" broadcast with delivery confirmation to family contacts
- **Preparedness Center** — disaster preparedness checklists and educational content
- **Alert History** — past alerts searchable by type, date, and location
- **Settings** — alert types, severity threshold, location radius, notification preferences

## TAJIRI Integration Points

- **NotificationService + FCMService** — Priority push notifications that override Do Not Disturb for emergencies; FCM priority channel for critical alerts
- **LocationService** — Area-based alerts filtered by GPS location; evacuation routes, shelter locations, hospitals, and hazard zones on TAJIRI maps
- **MessageService.sendMessage()** — Emergency messages and "I'm safe" notifications via TAJIRI messaging; broadcast to emergency contacts
- **GroupService.getMembers()** — Emergency coordination within community groups; broadcast alerts to all group members
- **CalendarService.createEvent()** — Preparedness drills and safety training events synced to calendar
- **PostService.createPost()** — Community emergency updates and safety information posts to the feed
- **ProfileService.getProfile()** — Emergency contact info and location preferences stored in profile
- **LiveUpdateService** — Real-time alert delivery and status updates pushed instantly
- **police module** — Safety alerts from police integrated into alert system
- **neighbourhood_watch module** — Community-level alerts feed into broader alert system
- **traffic module** — Road hazard and flooding alerts shared between modules
- **my_family/ module** — Family check-in targets closest connections first; "I'm safe" broadcast to family
- **community/ module** — Emergency coordination within community groups
- **government/ module** — Official government announcements channeled through alerts
