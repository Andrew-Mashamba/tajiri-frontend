# Tafuta Msikiti (Mosque Finder) — Feature Description

## Tanzania Context

"Tafuta Msikiti" means "Find a Mosque" in Swahili. Tanzania has thousands of mosques (misikiti), ranging from grand mosques in Dar es Salaam and Zanzibar (like Masjid al-Qadiriyya, Masjid Mbagala) to small neighborhood mosques in every Muslim community. Finding a mosque is essential for daily prayers (especially Dhuhr during work hours), Jumu'ah (Friday prayers), and Taraweeh during Ramadan.

In Dar es Salaam, mosques are densely distributed in areas like Kariakoo, Ilala, Kinondoni, and Temeke. Zanzibar has historic mosques dating back centuries. When traveling within Tanzania, Muslims need to quickly locate the nearest mosque for prayer. Current options are limited — Google Maps has incomplete listings, and there is no dedicated mosque directory with prayer-relevant information like Jumu'ah times, facilities, or whether there is a women's section. Mosques also serve as community hubs for Islamic education, Quran classes, and social services.

## International Reference Apps

1. **IslamicFinder** — Global mosque directory with prayer times and Qibla
2. **Muslim Pro** — Integrated mosque finder with GPS and user reviews
3. **Salatomatic** — Community-driven mosque directory with detailed listings
4. **Google Maps** — General place search (limited Islamic-specific details)
5. **HalalTrip** — Muslim travel app with mosque finder and halal food

## Feature List

1. Map-based search — interactive map showing mosques near current location
2. List view — mosques sorted by distance with key info (name, distance, next prayer)
3. GPS auto-locate — automatically find nearest mosques based on current position
4. Jumu'ah times — Friday prayer and khutbah start times for each mosque
5. Daily prayer times — mosque-specific iqamah times (may differ from calculated times)
6. Facilities filter — filter by: wudhu area, parking, women's section, wheelchair access, AC
7. Mosque profiles — name, photos, history, imam info, contact, capacity, denomination
8. Directions — turn-by-turn navigation to selected mosque
9. Imam information — current imam's name, qualifications, specialties
10. Islamic education — madrasas and Quran classes offered at the mosque
11. Upcoming events — mosque events (lectures, celebrations, community iftar)
12. Reviews and tips — community feedback on facilities, parking, accessibility
13. Save favorites — bookmark regularly visited mosques
14. Share mosque — recommend a mosque to friends
15. Suggest a mosque — submit unlisted mosques for addition to directory
16. Mosque announcements — push notifications from mosques you follow
17. Parking information — available parking nearby, street parking tips

## Key Screens

- **Map/Search Screen** — map with mosque pins, search bar, distance radius selector
- **Search Results List** — mosque cards with photo, name, distance, next prayer time
- **Mosque Profile** — hero image, info sections (about, prayers, facilities, events, reviews)
- **Facilities View** — icon grid showing available amenities
- **Directions Screen** — route from current location with estimated walking/driving time
- **Jumu'ah Finder** — specialized view for Friday prayer with khutbah times
- **Reviews Screen** — community reviews with facility ratings
- **Suggest Mosque Form** — name, location pin, imam, facilities, prayer times
- **Favorites** — saved mosques with quick-access prayer times

## TAJIRI Integration Points

- **LocationService.getRegions(), getDistricts()** — GPS-based nearby mosque search; filter by region, district, and facilities; map-based discovery with distance calculation
- **ProfileService.getProfile()** — home mosque selection during faith profile setup; denomination preference matching (Sunni, Shia, Ibadhi)
- **MessageService.sendMessage()** — contact mosque directly through TAJIRI messaging; inquire about services, events, and madrasas
- **PostService.createPost()** — "praying at [Mosque Name]" location check-in posts; mosque recommendation posts
- **NotificationService + FCMService** — announcements from followed mosques, Jumu'ah khutbah reminders, new mosque alerts in your area
- **PhotoService.uploadPhoto()** — community-submitted mosque photos for listings; mosque profile imagery
- **events/ module** — mosque events (lectures, Eid celebrations, Maulid, community iftar) appear in TAJIRI events feed
- **Cross-module: Wakati wa Sala** — mosque-specific iqamah times linked from prayer times screen
- **Cross-module: Qibla** — Qibla direction shown relative to nearest mosque locations via LocationService
- **Cross-module: Ramadan** — Taraweeh prayer times and community iftar locations from mosque listings
- **Cross-module: Kalenda Hijri** — Eid prayer locations prominently featured before Eid; Jumu'ah events
- **Cross-module: Zaka** — mosques accepting Zakat payments identified in listings via WalletService
- **Cross-module: Maulid** — mosques hosting Maulid events highlighted in listings
