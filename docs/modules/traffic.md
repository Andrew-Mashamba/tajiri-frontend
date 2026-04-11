# Traffic (Trafiki) — Feature Description

## Tanzania Context

Traffic congestion is one of the most pressing daily challenges in Dar es Salaam, Tanzania's largest city with over 6 million people. The city's road infrastructure has not kept pace with rapid urbanization and vehicle growth. Key corridors like Morogoro Road, Bagamoyo Road, Nyerere Road, and Ali Hassan Mwinyi Road experience severe gridlock during peak hours (7-9 AM, 4-7 PM). A typical commute that should take 20 minutes can stretch to 2-3 hours.

The BRT (Bus Rapid Transit) system — DART (Dar Rapid Transit) — has improved some corridors but coverage is limited. Other cities like Arusha, Mwanza, and Dodoma face growing traffic challenges too. Road accidents are a major concern — Tanzania has one of the highest road fatality rates in East Africa. Roadworks, flooding during rainy season, and breakdowns on major roads cause unpredictable delays. There is no locally-focused real-time traffic information system — Google Maps provides some data but it is often inaccurate for Tanzanian roads, especially secondary routes.

## International Reference Apps

1. **Waze** — Community-driven traffic reports, navigation, hazard alerts, police reports
2. **Google Maps (Traffic Layer)** — Real-time traffic conditions with routing
3. **INRIX Traffic** — Traffic analytics, parking, route optimization
4. **HERE WeGo** — Offline maps with traffic, public transit, and navigation
5. **Tom Tom Go** — Navigation with real-time traffic updates and speed camera alerts

## Feature List

1. Live traffic map — color-coded road congestion display (green/yellow/red) for major roads
2. Congestion alerts — push notifications for traffic jams on your regular routes
3. Accident reports — community-reported accidents with location, severity, photos
4. Road closure notices — official and community-reported road closures and diversions
5. Alternative routes — suggest less congested routes to your destination
6. Commute planner — set home and work, get best departure time recommendations
7. Community reports — users report real-time conditions (jam, accident, police, flooding)
8. BRT/DART status — real-time BRT bus status on DART corridors
9. Fuel station locator — find nearby fuel stations with price comparison
10. Road condition reports — potholes, construction zones, flooding on specific roads
11. Estimated travel time — realistic ETA based on current conditions
12. Historical traffic patterns — typical congestion by time of day and day of week
13. Rain/flood alerts — weather-related road condition warnings during rainy season
14. Speed camera locations — known speed camera and traffic police checkpoint locations
15. Parking information — parking availability in commercial areas (Kariakoo, Posta, Masaki)
16. Traffic news — traffic-related news updates and infrastructure announcements
17. Favorite routes — save frequently used routes with condition monitoring

## Key Screens

- **Traffic Map** — interactive map with color-coded traffic layer, incident pins, report button
- **My Commute** — saved routes with current conditions, best departure time, ETA
- **Reports Feed** — chronological list of community traffic reports by area
- **Submit Report** — report type (jam, accident, closure, police, flood), location, severity, photo
- **Route Planner** — origin/destination with multiple route options and time comparison
- **Fuel Stations** — map of nearby stations with prices and distance
- **Alerts Settings** — configure route alerts, commute notifications, severe condition warnings
- **Traffic History** — historical congestion charts for specific roads and times
- **BRT/DART Screen** — BRT route map, station list, estimated bus arrival times
- **Parking Finder** — commercial area parking with availability indicators

## TAJIRI Integration Points

- **LocationService** — Live traffic map with GPS-based congestion display; route directions and nearby fuel stations
- **NotificationService + FCMService** — Commute alerts, accident reports, road closure notifications, and flood warnings via push
- **CalendarService.createEvent()** — Commute time estimates inform calendar event arrival planning; route condition alerts before events
- **PostService.createPost()** — Share traffic reports and road condition updates to the TAJIRI social feed
- **GroupService.createGroup()** — Local traffic reporting groups for specific areas and commute corridors
- **WalletService.deposit(amount, provider:'mpesa')** — Parking fee payment, fuel station payments, and traffic fine settlement
- **MessageService.sendMessage()** — Share real-time traffic alerts and accident reports with contacts
- **transport/ module** — Traffic conditions inform ride-hailing and transport suggestions
- **alerts module** — Rain and flood alerts from weather/alerts module affect traffic warnings
- **vehicle/ module** — Fuel station and parking info linked to registered vehicle management; my_cars tabs
- **events/ module** — Traffic warnings for events causing road impacts
- **police module** — Traffic fine lookup and payment; speed camera and checkpoint locations
- **community/ module** — Local traffic reporting discussions in community groups
