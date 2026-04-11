# Wakati wa Sala (Prayer Times) — Feature Description

## Tanzania Context

"Wakati wa Sala" means "Time for Prayer" in Swahili. The five daily prayers (salat) are the central pillar of Islamic practice for Tanzania's Muslim population (~35% of the country, nearly 100% in Zanzibar). The five prayers — Fajr (dawn), Dhuhr (noon), Asr (afternoon), Maghrib (sunset), and Isha (night) — must be performed at specific times calculated based on the sun's position.

In Tanzania, prayer times vary significantly between coastal Dar es Salaam, inland cities like Dodoma and Mwanza, and different latitudes. Most Tanzanian Muslims rely on mosque adhan (call to prayer) or manually check printed timetables. Younger Muslims increasingly want phone-based prayer time notifications, but global apps like Muslim Pro sometimes have inaccurate times for Tanzanian locations because they use generic calculation methods rather than locally verified times. The Shafi'i school of jurisprudence (predominant in East Africa) has specific calculation preferences.

## International Reference Apps

1. **Muslim Pro** — Prayer times, adhan, Quran, qibla — 150M+ downloads worldwide
2. **Athan (IslamicFinder)** — Accurate prayer times with multiple calculation methods
3. **Al Moazin** — Prayer times with customizable adhan sounds and widgets
4. **Pillars** — Minimalist prayer time tracker with streak gamification
5. **iPray** — Prayer times with mosque finder and Islamic calendar

## Feature List

1. Accurate prayer times — five daily salat times calculated by GPS location
2. Calculation method selector — support multiple methods (Egyptian, MWL, Umm al-Qura, ISNA) with Shafi'i Asr default
3. Adhan alerts — customizable notification with adhan audio for each prayer
4. Fajr alarm — special alarm mode for Fajr with snooze and confirmation
5. Countdown timer — countdown to next prayer displayed prominently
6. Prayer log/tracker — mark prayers as completed (on-time, late, qada), view daily/weekly/monthly stats
7. Prayer streak — gamified consecutive prayer tracking with milestone celebrations
8. Qibla mini-compass — quick-access compass widget on prayer times screen
9. Iqamah times — local mosque iqamah times (if mosque provides data)
10. Jumu'ah reminder — special Friday prayer reminder with khutbah time
11. Manual adjustment — fine-tune prayer times by +/- minutes for local accuracy
12. Home screen widget — persistent prayer times display without opening app
13. Tahajjud time — optional night prayer time calculation
14. Silent mode — auto-enable phone silent mode during prayer times
15. Monthly timetable — printable/shareable monthly prayer schedule
16. Location-based auto-update — times update when traveling to different cities

## Key Screens

- **Prayer Times Home** — current/next prayer highlighted, all five times listed, countdown
- **Prayer Tracker** — calendar grid showing prayer completion by day, streak counter
- **Daily Prayer View** — expandable cards for each prayer with log button and status
- **Settings** — calculation method, adhan selection, notification preferences
- **Monthly Timetable** — table view of all prayer times for the month
- **Fajr Alarm Setup** — alarm time, sound selection, snooze settings
- **Statistics** — weekly/monthly prayer completion rates, charts, streak history
- **Qibla Quick View** — mini compass accessible from prayer times screen

## TAJIRI Integration Points

- **NotificationService + FCMService** — adhan alerts for each of the five daily prayers; Fajr special alarm; Jumu'ah reminder; customizable adhan audio per prayer time
- **CalendarService.createEvent()** — prayer times visible on TAJIRI calendar; prayer schedule as recurring events
- **LocationService.getRegions(), getDistricts()** — GPS-based prayer time calculation; auto-update when traveling between Tanzanian cities
- **ProfileService.getProfile()** — prayer tracker stats visible on faith profile (opt-in); prayer streak milestones
- **EventTrackingService** — track prayer completion rates, streaks, and consistency patterns
- **Cross-module: Qibla** — full Qibla compass opens from mini-compass widget on prayer times screen via LocationService
- **Cross-module: Quran** — suggested surahs for each prayer time; post-prayer reading recommendations
- **Cross-module: Dua** — post-prayer duas displayed after marking prayer complete; occasion-specific supplications
- **Cross-module: Ramadan** — Fajr time used for suhoor timing, Maghrib time used for iftar countdown
- **Cross-module: Tafuta Msikiti** — find nearest mosque for congregational prayer via LocationService
- **Cross-module: Kalenda Hijri** — Islamic events trigger special prayer recommendations (Eid prayers, Taraweeh) via CalendarService
