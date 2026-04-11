# Kalenda Hijri (Islamic Calendar) — Feature Description

## Tanzania Context

"Kalenda Hijri" means "Hijri Calendar" in Swahili. The Islamic (Hijri) calendar is a lunar calendar of 12 months used to determine Islamic holidays and observances. In Tanzania, the Hijri calendar is essential for the Muslim community — Eid al-Fitr and Eid al-Adha are national public holidays, and Ramadan timing affects daily routines for millions.

Moon sighting is a significant practice in Tanzania. The beginning and end of Ramadan, as well as Eid dates, are traditionally determined by local moon sighting committees (often associated with the Mufti's office or BAKWATA — Baraza Kuu la Waislamu Tanzania). This means dates can differ from Saudi Arabia or other countries by a day. Moon sighting announcements are currently broadcast via radio and TV, creating uncertainty and last-minute planning challenges. A reliable Hijri calendar app with local moon sighting integration would be highly valuable.

## International Reference Apps

1. **Hijri Calendar (IslamicFinder)** — Hijri-Gregorian converter with Islamic events
2. **Muslim Pro** — Integrated Hijri calendar with event reminders
3. **Islamic Calendar (Athan)** — Hijri dates with moon phase information
4. **HijriCalendar.com** — Web-based converter with country-specific adjustments
5. **Islamicity** — Islamic calendar with historical events and observances

## Feature List

1. Hijri date display — current Hijri date prominently shown alongside Gregorian date
2. Hijri-Gregorian converter — convert any date between calendars in both directions
3. Islamic events calendar — all major Islamic dates: Eid al-Fitr, Eid al-Adha, Maulid un-Nabi, Isra Mi'raj, Laylat al-Qadr, 1st Muharram, 10th Muharram (Ashura), Sha'ban nights
4. Moon sighting reports — community-submitted and official moon sighting updates for Tanzania
5. BAKWATA announcements — official announcements from Tanzania's Muslim council
6. Event reminders — push notifications before each Islamic occasion
7. Moon phase display — current moon phase visualization with percentage
8. Monthly Hijri view — full month calendar in Hijri with Gregorian equivalents
9. Event descriptions — educational content about each Islamic occasion (history, significance, practices)
10. Country-specific adjustments — local date adjustments based on Tanzania moon sighting
11. Countdown to next event — days remaining until next major Islamic occasion
12. Share events — send event reminders to friends and family
13. Historical events — notable historical Islamic events on their Hijri dates
14. Widget — home screen widget showing today's Hijri date
15. Year planner — annual view of all Islamic events for planning

## Key Screens

- **Calendar Home** — today's Hijri/Gregorian date, moon phase, next event countdown
- **Monthly Calendar** — dual calendar view with Hijri primary, Gregorian secondary
- **Events List** — chronological list of upcoming Islamic events with descriptions
- **Event Detail** — full description, significance, recommended practices, duas
- **Date Converter** — interactive converter with date pickers for both calendars
- **Moon Sighting** — latest sighting reports, official announcements, submit sighting
- **Settings** — calculation method, country adjustment, notification preferences

## TAJIRI Integration Points

- **CalendarService.createEvent()** — Hijri dates and Islamic events (Eid al-Fitr, Eid al-Adha, Maulid, Isra Mi'raj, 1st Muharram) synced with TAJIRI calendar; dual Hijri-Gregorian display
- **NotificationService + FCMService** — event reminders before each Islamic occasion, moon sighting alerts, BAKWATA official announcements pushed to users
- **PostService.createPost()** — Islamic occasion greetings shareable to social feed; Eid mubarak posts
- **ProfileService.getProfile()** — Islamic calendar visible only to users with Muslim faith profile
- **events/ module** — community Eid celebrations, Maulid gatherings, and Islamic events appear in TAJIRI events feed
- **Cross-module: Ramadan** — Ramadan start/end dates determined from Hijri calendar; moon sighting coordination for 1 Ramadan and 1 Shawwal
- **Cross-module: Wakati wa Sala** — special prayers on Islamic occasions (Eid prayers, Taraweeh) linked from calendar events
- **Cross-module: Quran** — recommended surahs and readings for each Islamic occasion
- **Cross-module: Dua** — occasion-specific duas linked from event detail pages
- **Cross-module: Maulid** — 12 Rabi ul-Awwal date synced for Maulid countdown and event planning
- **Cross-module: events/** — Eid celebrations, Maulid events via CalendarService
