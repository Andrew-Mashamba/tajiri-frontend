# Ramadan — Feature Description

## Tanzania Context

Ramadan is the holiest month in the Islamic calendar, observed by fasting from dawn (Fajr) to sunset (Maghrib). In Tanzania, Ramadan transforms daily life for the Muslim community. Suhoor (pre-dawn meal) is typically eaten at 4:00-4:30 AM, and iftar (breaking fast) at around 6:15-6:30 PM depending on location and time of year. Tanzania's position near the equator means fasting hours are relatively consistent year-round (approximately 13-14 hours), unlike extreme variations in northern/southern countries.

Ramadan in Tanzania has a strong communal character — mosques organize communal iftar, families gather for evening meals, and charitable giving increases dramatically. In Zanzibar and coastal areas, Ramadan is particularly vibrant with Taraweeh prayers, Quran recitation competitions, and special food markets. Food vendors set up special iftar stalls. Zakat al-Fitr (obligatory charity before Eid) must be paid before Eid prayers. Many Tanzanians struggle to track fasting days, manage suhoor/iftar times across different cities, and calculate Zakat al-Fitr.

## International Reference Apps

1. **Muslim Pro** — Ramadan timetable, fasting tracker, dua of the day
2. **Ramadan Legacy** — Goal-setting, habit tracking, Quran tracker during Ramadan
3. **Athan** — Suhoor/iftar alerts, Ramadan calendar, daily duas
4. **Quran Companion** — Ramadan Quran reading challenge (khatm in 30 days)
5. **Cookpad/Tasty** — Recipe apps with Ramadan/iftar recipe collections

## Feature List

1. Suhoor and iftar times — accurate daily times based on GPS location
2. Fasting day counter — current day of Ramadan, days remaining, progress bar
3. Suhoor alarm — reliable alarm with enough time to eat before Fajr
4. Iftar countdown — live countdown timer to iftar with notification at Maghrib
5. Daily dua — morning and evening Ramadan-specific supplications
6. Quran reading tracker — khatm (complete reading) plan with daily juz assignment
7. Taraweeh tracker — log nightly Taraweeh prayers with rakaat count
8. Ramadan goals — set and track personal goals (extra prayers, charity, Quran completion)
9. Iftar recipes — Tanzanian and international iftar recipes (sambusa, dates, juices, pilau)
10. Zakat al-Fitr calculator — calculate obligation based on local food prices (rice, flour)
11. Charity tracker — log daily sadaqah (charitable acts) during Ramadan
12. Laylat al-Qadr guide — information about the Night of Power, last 10 nights devotion tracker
13. Community iftar — find and announce communal iftar events at mosques and venues
14. Ramadan timetable — full month suhoor/iftar schedule, downloadable/printable
15. Health tips — hydration reminders at suhoor, nutrition advice for fasting
16. Children's Ramadan — simplified fasting tracker and educational content for kids learning to fast
17. Eid preparation — countdown to Eid, Eid prayer locations, Eid greetings

## Key Screens

- **Ramadan Home** — day counter, suhoor/iftar times, today's dua, Quran progress, goals summary
- **Daily View** — expanded view of the day with all trackers and activities
- **Fasting Calendar** — month view marking fasted/missed days with makeup tracker
- **Quran Khatm Tracker** — juz checklist with daily reading progress
- **Iftar Recipes** — recipe cards with ingredients, prep time, photos
- **Zakat Calculator** — input assets, calculate Zakat al-Fitr per family member
- **Goals Dashboard** — personal Ramadan goals with progress indicators
- **Community Iftar Finder** — map of communal iftar locations and events
- **Laylat al-Qadr Guide** — last 10 nights devotion schedule and tracker

## TAJIRI Integration Points

- **WalletService.deposit(amount, provider:'mpesa')** — Zakat al-Fitr payment and daily sadaqah charity contributions via M-Pesa during Ramadan
- **ContributionService.createCampaign(), donate()** — Ramadan charity campaigns; community iftar fundraising; mosque renovation drives during holy month
- **NotificationService + FCMService** — suhoor alarm with configurable lead time, iftar Maghrib alert, daily dua push notification, Quran khatm reading reminder
- **PostService.createPost()** — share Ramadan milestones (fasting streaks, khatm completion) and Eid greetings to social feed
- **CalendarService.createEvent()** — fasting day tracker on calendar; Taraweeh schedule; community iftar events; Eid preparation countdown
- **LiveUpdateService** — real-time community iftar event updates; Ramadan charity goal progress
- **events/ module** — community iftar gatherings and Eid celebrations appear in TAJIRI events feed
- **Cross-module: Wakati wa Sala** — Fajr time for suhoor cutoff, Maghrib time for iftar; Taraweeh prayer scheduling
- **Cross-module: Quran** — daily khatm juz reading opens in Quran reader; 30-day completion plan
- **Cross-module: Dua** — Ramadan-specific duas integrated from dua library; iftar dua, suhoor dua, Laylat al-Qadr duas
- **Cross-module: Zaka** — Zakat al-Fitr calculator and payment integrated before Eid via WalletService
- **Cross-module: Kalenda Hijri** — Ramadan start/end dates from Islamic calendar; moon sighting coordination
- **Cross-module: food/ module** — iftar recipes (sambusa, pilau, dates) crosslinked with TAJIRI food module
