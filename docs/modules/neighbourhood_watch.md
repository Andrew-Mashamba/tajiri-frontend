# Neighbourhood Watch (Ulinzi wa Mtaa) — Feature Description

## Tanzania Context

"Ulinzi wa Mtaa" means "neighbourhood security" in Swahili. Community-based security has deep roots in Tanzania. The Sungusungu movement, originating from the Sukuma and Nyamwezi communities in the 1980s, became a nationwide community policing model endorsed by the government. Today, most urban neighborhoods in Tanzania have informal security arrangements — night watchmen (walinzi/askari), neighborhood patrol groups, and ten-cell leaders (wajumbe wa nyumba kumi) who serve as the smallest unit of local governance.

Despite this strong tradition of community security, coordination is entirely manual and fragmented. Wajumbe communicate via phone calls and physical meetings. When incidents occur, word spreads slowly through personal calls and WhatsApp messages. There is no structured way to alert all residents of a neighborhood simultaneously. Gated communities and apartment complexes have slightly better coordination, but open neighborhoods (which house the majority of Tanzanians) rely entirely on informal networks. Crime reporting to local leadership is inconsistent, and tracking patterns is impossible without data.

## International Reference Apps

1. **Nextdoor** — Neighborhood social network with safety alerts, community discussions, recommendations
2. **Neighbors (Ring)** — Safety alerts, video sharing, community crime reporting
3. **Citizen** — Real-time crime and safety alerts with live video and GPS tracking
4. **PeaceKeeper** — Community safety app connecting neighbors for emergency response
5. **Namola** — South African safety app connecting to private security and police

## Feature List

1. Community safety alerts — broadcast urgent alerts to all neighborhood members instantly
2. Report suspicious activity — submit reports with description, location, time, photos/video
3. Neighbourhood groups — join/create groups based on geographic boundaries (mtaa level)
4. Emergency broadcast — panic button sending alert to all group members simultaneously
5. Incident feed — chronological feed of reported incidents in the neighborhood
6. Safety map — heat map showing incident density by area over time
7. Volunteer patrol coordination — schedule and track neighborhood patrol shifts
8. Night watchman check-in — watchmen log patrol check-ins with GPS and timestamp
9. Gate/visitor management — log expected visitors for gated neighborhoods/apartments
10. Emergency contacts — neighborhood-specific emergency numbers (mjumbe, OCD, hospital)
11. Safety tips — seasonal and situational safety advice for residents
12. Anonymous reporting — option to report incidents without revealing identity
13. Incident categories — theft, break-in, suspicious person, noise, fire, flooding, road hazard
14. Photo/video evidence — attach media to reports for documentation
15. Resolution tracking — mark incidents as resolved, share outcomes with community
16. New resident welcome — onboarding for new neighborhood members with safety protocols
17. Meeting coordination — schedule and announce neighborhood security meetings

## Key Screens

- **Neighbourhood Home** — active alerts banner, recent incidents, patrol status, quick report button
- **Alert Broadcast** — emergency alert creation with type, description, location, send to group
- **Incident Feed** — scrollable feed of community reports with filters (type, date, status)
- **Report Incident** — form: type selector, description, location pin, time, photo/video upload
- **Safety Map** — map overlay showing incident pins and density heat map
- **Patrol Schedule** — weekly patrol roster, check-in points, active patrol tracker
- **Group Members** — neighborhood member list with roles (coordinator, patrol, resident)
- **Emergency Contacts** — one-tap dial list: mjumbe, police, hospital, fire, security company
- **Visitor Log** — expected visitors with name, time, vehicle, approval status
- **Meeting Planner** — schedule neighborhood security meetings with agenda and RSVP

## TAJIRI Integration Points

- **GroupService.createGroup() / joinGroup()** — Neighbourhood watch operates as a specialized TAJIRI group; ward-based groups with membership management
- **LocationService** — Ward-based neighbourhood boundaries; incident locations and patrol routes on TAJIRI maps
- **MessageService.sendMessage() / createGroup()** — Neighbourhood group chat uses TAJIRI messaging infrastructure; alert broadcast to all members
- **NotificationService + FCMService** — Emergency broadcasts via priority push notifications with sound override for urgent alerts
- **CalendarService.createEvent()** — Patrol schedules and neighbourhood security meetings synced to calendar
- **PostService.createPost()** — Community safety updates in local feed (opt-in, non-sensitive only)
- **PhotoService.uploadPhoto()** — Attach photos and video evidence to incident reports
- **ProfileService.getProfile()** — Resident verification and role assignment (coordinator, patrol, resident)
- **police module** — Escalate serious incidents to police with one tap; link to crime reporting
- **alerts module** — Neighbourhood alerts integrated with broader emergency alert system
- **community/ module** — Neighbourhood watch operates within community module groups
- **my_family/ module** — Family check-in and safety notifications during neighbourhood emergencies
- **housing/ module** — Neighbourhood safety ratings visible in housing/property listings
