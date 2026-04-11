# TAJIRI Faith, Lifestyle & Security Module API Directory

> Available APIs for 25 modules across Faith (Christian), Faith (Islamic), Lifestyle, and Security categories.
> Researched 2026-04-08.

---

## FAITH -- CHRISTIAN

---

### 1. my_faith -- Religious Demographics & Denomination Databases

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Joshua Project API | Joshua Project | People group, country, language, and religion data worldwide | Free (API key required) | REST API with JSON; covers unreached people groups, religions by country; request key at joshuaproject.net/resources/datasets |
| ARDA (Association of Religion Data Archives) | Penn State | 200+ surveys on religion, denomination data, congregational stats | Free (data downloads) | No REST API; bulk CSV/SPSS downloads; covers US religious bodies, membership, congregations |
| Pew Religious Landscape Study | Pew Research Center | Religious affiliation, beliefs, practices, demographics for 35k+ Americans | Free (data downloads) | No live API; downloadable datasets; 2007, 2014, 2023-24 waves |
| World Religion Database | Brill / Gordon-Conwell | Detailed religious affiliation stats for every country | Paid subscription | Academic resource; includes census data and projections; not a REST API |
| U.S. Religion Census | ASARB | County-level religious data for 372+ religious bodies in USA | Free (data downloads) | Downloadable maps and data files; 2020 census available |

---

### 2. biblia -- Bible APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| API.Bible | American Bible Society | 1500+ Bible versions in 1000+ languages; search, verses, passages | Free (API key required) | 5,000 queries/day, 500 verses/request max; docs at docs.api.bible |
| ESV API | Crossway | English Standard Version text retrieval in multiple formats | Free for non-commercial (API key) | 5,000 queries/day, 500 verses/query; register at api.esv.org |
| bible-api.com | Open source | Simple Bible verse lookup (KJV, WEB, etc.) | Free, no auth | Minimal REST API; GET /VERSE returns JSON; limited versions |
| Bible Brain (DBP v4) | Faith Comes By Hearing | World's largest digital Bible platform; audio, text, video | Free for non-commercial (API key) | RESTful JSON; signed URLs for audio/video; 1000+ languages |
| Free Bible API (wldeh) | GitHub community | 200+ versions, multiple languages | Free, no auth | Hosted on GitHub; no rate limits; open source |
| Free Use Bible API | helloao.org | 1000+ Bible translations in JSON | Free, no auth, no copyright | No API key needed; no usage limits; JSON format |

---

### 3. sala -- Prayer & Devotional Content APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| API.Bible Verse of the Day | American Bible Society | Daily verse selection for devotional apps | Free (API key) | Tutorial at docs.api.bible/tutorials/verse-of-the-day |
| Devotionalium API | Max Melzer | Daily devotional verses from Abrahamic scriptures | Free | Simple REST API; multi-faith daily verses; devotionalium.com/api/docs |
| New Hope Devotions API | New Hope Church | Daily devotion content for church websites/apps | Free | Customizable church name, URL, colors; developer.enewhope.org |
| YouVersion/Faith.tools | Life.Church | Bible reader embed, verse of the day, reading plans | Free (developer account) | SDKs for Swift, Kotlin, JS, React Native; 1000+ Bible versions |
| ESV API (Verse of Day) | Crossway | ESV daily verse and passage retrieval | Free for non-commercial | Can build custom VOTD with passage endpoint |

---

### 4. fungu_la_kumi -- Church Giving & Payment APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Tithe.ly API | Tithe.ly | Church giving, transactions, payment categories | Paid (church subscription) | API access by request; email support@tithe.ly; docs at tithelydev.com/api |
| Planning Center Giving API | Planning Center | Donation tracking, fund management, batch giving | Paid (starts $0 for small churches) | OAuth2 or Personal Access Token; developer.planning.center/docs |
| Subsplash Giving API | Subsplash | Church giving, donor management, payment processing | Paid (church subscription) | API access via developer.subsplash.com; integrates with major ChMS |
| Breeze Giving API | Breeze/Tithely | Contribution tracking, donor records | Paid ($0-99/month) | API key from account settings; 20 req/min limit; now part of Tithely |
| Stripe Connect | Stripe | Custom payment processing for church giving | 2.9% + $0.30 per transaction | Build custom giving; Stripe Connect for platform model; stripe.com/docs |
| Flutterwave API | Flutterwave | African payment processing (M-Pesa, cards, bank) | ~1.4% local, 3.8% international | Ideal for East Africa; supports KES, TZS, UGX; flutterwave.com/docs |

---

### 5. kanisa_langu -- Church Management APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Planning Center API | Planning Center | People, services, check-ins, groups, calendar, giving | Free for <25 people; paid tiers | OAuth2; APIs for Calendar, Check-Ins, Giving, Groups, People, Services |
| Breeze ChMS API | Breeze/Tithely | Member management, contributions, events, tags | Paid ($0-99/month) | REST API; API key auth; 20 req/min; app.breezechms.com/api |
| ChurchTools API | ChurchTools | Church management, events, groups, attendance | Paid (subscription) | OpenAPI/Swagger documented; JS client on GitHub; popular in DACH region |
| Elvanto API | Elvanto | People, groups, services, reporting | Paid (subscription) | REST API; elvanto.com/api; group and service management |
| ChurchSuite API | ChurchSuite | Contacts, small groups, children, giving, rotas | Paid (subscription) | Embed API and full developer API; churchsuite.com/api-and-json |
| IconCMO API | Icon Systems | Member data, contributions, groups, attendance | Paid (subscription) | REST API; iconcmo.com; multiple programming languages supported |

---

### 6. huduma -- Sermon & Podcast APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| MyChurch Media API | MyChurch Media | Sermon hosting, media player, podcast distribution | Paid (~$49/month) | Simple API to fetch and display sermons; mychurch.media |
| Bible Brain Audio API | Faith Comes By Hearing | Audio Bible content, signed URLs for playback | Free for non-commercial | RESTful; audio/video via CDN signed URLs; 1000+ languages |
| Spotify Web API | Spotify | Podcast/sermon search, playback, playlists | Free (API key, OAuth) | Search podcasts, get episodes; developer.spotify.com |
| Apple Podcasts API | Apple | Podcast search, episode metadata | Free | Search API via iTunes endpoint; limited to metadata |
| Podbean API | Podbean | Podcast hosting, episode management, analytics | Freemium (5hrs free) | REST API for episode CRUD; popular with churches |
| Transistor API | Transistor | Podcast hosting, analytics, distribution | Paid ($19+/month) | API for episode management; used by many churches |

---

### 7. jumuiya -- Small Group Management APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Planning Center Groups API | Planning Center | Group creation, membership, events, attendance | Free for small churches; paid tiers | Part of Planning Center API suite; developer.planning.center |
| ChurchSuite Small Groups API | ChurchSuite | Group management, signups, attendance tracking | Paid (subscription) | Embed API for group listings; developer API for full CRUD |
| Elvanto Groups API | Elvanto | Group management, member assignment, scheduling | Paid (subscription) | Part of Elvanto API; elvanto.com/api |
| ChMeetings API | ChMeetings | Group meetings, attendance, member management | Paid (subscription) | Developer API for custom integrations; chmeetings.com |
| FellowshipOne API | FellowshipOne | Groups, people, attendance, communication | Paid (subscription) | REST architecture; free for churches and qualified partners |

---

### 8. ibada -- Worship Music APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Spotify Web API | Spotify | Music search, playlists, playback, artist data | Free (OAuth required) | Full catalog search; playlist management; 30s previews; developer.spotify.com |
| Apple Music API / MusicKit | Apple | Music catalog, playlists, playback, recommendations | Free (Apple Developer account) | MusicKit for iOS/Android/Web; OAuth; developer.apple.com/musickit |
| CCLI SongSelect API | CCLI | Worship song lyrics, chord charts, sheet music | Paid (partnership required) | 100k+ songs; requires CCLI partnership; NDA may be required |
| Genius API | Genius | Song lyrics, annotations, artist info | Free (API key) | Lyrics search and metadata; docs.genius.com |
| Musixmatch API | Musixmatch | Lyrics database, synced lyrics, music metadata | Freemium (free tier available) | 2000 calls/day free; largest lyrics database; developer.musixmatch.com |

---

### 9. shule_ya_jumapili -- Sunday School Curriculum APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| API.Bible (Kids content) | American Bible Society | Bible text for children's lessons and quizzes | Free (API key) | Filter by version (e.g., NLT, ICB); build lesson content dynamically |
| Bible Brain (Kids audio) | Faith Comes By Hearing | Audio Bible for children's listening activities | Free for non-commercial | Audio content in multiple languages; great for listening exercises |
| Planning Center Services API | Planning Center | Schedule teachers, track attendance, manage rotas | Paid (subscription) | Useful for managing Sunday School volunteer schedules |
| Group Publishing Digital | Group Publishing | DIG IN curriculum, Simply Loved, FaithWeaver NOW | Paid (subscription) | No public REST API; digital platform with exportable content |
| wonder.ink | Wonder Ink | Children's ministry curriculum, 30/60/75-min lessons | Paid (subscription) | No public API; web-based curriculum delivery; customizable lessons |

**Note:** No dedicated Sunday School curriculum REST APIs exist. Best approach: use Bible APIs for scripture content and church management APIs for scheduling/attendance. Curriculum content from Group Publishing or Wonder Ink is accessed via their platforms.

---

### 10. tafuta_kanisa -- Church Directory & Location APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Places API (New) | Google | Search for churches by location, get details, reviews | Freemium (10k free/month Essentials) | type=church; place details, photos, hours; developers.google.com/maps |
| MonkCMS Churches API | MonkCMS | Church directory search by zip/city with radius | Free (with MonkCMS account) | developers.monkcms.com; US-focused church directory |
| ChurchTools Finder | ChurchTools | Church discovery by location or text search | Free to search | Primarily DACH region; churchtools.academy |
| Foursquare Places API | Foursquare | Venue search including churches/religious orgs | Freemium (10k calls/month free) | Category filter for religious places; foursquare.com/developer |
| OpenStreetMap Overpass API | OpenStreetMap | Query churches/religious buildings from OSM data | Free, open source | amenity=place_of_worship; overpass-turbo.eu; unlimited |

---

## FAITH -- ISLAMIC

---

### 11. wakati_wa_sala -- Prayer Times APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Aladhan API | Islamic Network | Prayer times by coordinates, address, or city | Free, no auth required | Multiple calculation methods (MWL, ISNA, Egypt, etc.); aladhan.com/prayer-times-api |
| IslamicFinder API | IslamicFinder | Prayer times, Athan alerts | Free (limited) | islamicfinder.org; used by many Muslim apps |
| PrayTimes.org | Hamid Zarrabi-Zadeh | Open-source prayer time calculation library | Free, open source | JavaScript/Python library; multiple calculation methods; client-side |
| Aladhan Dart Package | pub.dev | Flutter/Dart prayer times integration | Free | aladhan_prayer_times on pub.dev; direct Dart integration |
| Open-Meteo (sunrise/sunset) | Open-Meteo | Sun position data for prayer calculations | Free, no auth | Supplement with astronomical data; open-meteo.com |

---

### 12. qibla -- Qibla Direction APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Aladhan Qibla API | Islamic Network | Qibla direction from any coordinates | Free, no auth | GET /v1/qibla/{lat}/{lng}; returns direction in degrees |
| Device Compass API | Flutter | Device compass heading for Qibla overlay | Free (Flutter plugin) | flutter_compass package on pub.dev; combine with Qibla angle |
| Custom Calculation | Local | Calculate Qibla from coordinates using great circle | Free | Formula: atan2(sin(dLng), cos(lat)*tan(Kaaba_lat) - sin(lat)*cos(dLng)) |

---

### 13. quran -- Quran APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Quran.com API v4 | Quran Foundation | Chapters, verses, recitations, translations, tafsir | Free (OAuth2 required) | Client credentials flow; 1hr tokens; api-docs.quran.foundation |
| Al Quran Cloud API | alquran.cloud | Quran text, translations, audio recitations | Free, no auth | 77+ editions; JSON; alquran.cloud/api |
| Fawaz Ahmed Quran API | GitHub | 90+ languages, 400+ translations | Free, no auth | CDN-hosted JSON files; github.com/fawazahmed0/quran-api |
| GlobalQuran API | GlobalQuran.com | Quran text with multiple translations and audio | Free | JSON/JSONP format; globalquran.com |
| Tanzil.net | Tanzil | Verified Quran text in multiple scripts | Free (download) | Unicode text files; multiple scripts; tanzil.net/download |

---

### 14. kalenda_hijri -- Hijri Calendar APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Aladhan Hijri Calendar API | Islamic Network | Hijri-Gregorian conversion, Islamic calendar | Free, no auth | Monthly calendar, date conversion; aladhan.com/islamic-calendar-api |
| hijri_calendar (Dart) | pub.dev | Dart library for Hijri dates | Free | fromGregorian(), toGregorian(); direct Flutter integration |
| hijri_date (Dart) | pub.dev | Hijri dates with moon phases, Islamic events | Free | Multi-language (ar, en, tr, etc.); moon phase calculations |
| Hijri Calendar Web API | hijri.habibur.com | REST API for today's Hijri date and conversions | Free | Simple GET requests; JSON responses |

---

### 15. ramadan -- Ramadan-Specific APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Aladhan API (Ramadan) | Islamic Network | Suhoor/Iftar times (Fajr and Maghrib prayer times) | Free, no auth | Use timings endpoint; Fajr=Suhoor end, Maghrib=Iftar time |
| Aladhan Hijri Calendar | Islamic Network | Ramadan calendar for any year | Free, no auth | GET /v1/hijriCalendar?month=9&year=YYYY for Ramadan |
| IslamicFinder Ramadan | IslamicFinder | Ramadan timetables, iftar/suhoor schedules | Free (limited) | islamicfinder.org/ramadan-calendar |
| Open-Meteo (sunset times) | Open-Meteo | Precise sunset times for Iftar verification | Free, no auth | High-accuracy astronomical data; supplement prayer times |

**Note:** Ramadan times are derived from prayer times APIs (Fajr for Suhoor, Maghrib for Iftar). No separate "Ramadan API" exists -- use Aladhan with Hijri month 9.

---

### 16. zaka -- Zakat Calculation & Islamic Finance APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Halal Terminal API | Halal Terminal | Shariah screening, zakat, purification, 58+ endpoints | Freemium | 5 methodologies (AAOIFI, DJIM, FTSE, MSCI, S&P); halalterminal.com |
| Zoya Shariah Compliance API | Zoya Finance | Stock/ETF screening, zakat calculation, purification | Paid (subscription) | 20k+ stocks/funds; per-company zakat calculation; zoya.finance/api |
| Finispia API | Finispia | Basic halal/haram stock screening | Paid | Simple binary compliance check; limited methodology |
| Gold/Silver Price APIs | Various (e.g., metals-api.com) | Nisab threshold calculation (gold/silver prices) | Freemium | Nisab = 87.48g gold or 612.36g silver; real-time prices needed |
| Exchange Rate API | exchangerate-api.com | Currency conversion for zakat in local currency | Free (1500 req/month) | Needed for converting zakat amounts to KES, TZS, etc. |

---

### 17. dua -- Dua & Supplication APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Dua-Dhikr API | FitrahHive (GitHub) | Authentic Sunnah duas and dhikr collection | Free, open source | RESTful JSON; github.com/fitrahive/dua-dhikr |
| Sunnah.com API | Sunnah.com | Hadith collections including duas from Prophet (SAW) | Free (API key required) | Request key via GitHub issue; sunnah.stoplight.io/docs/api |
| Dua and Zikir API | RapidAPI | Dua and dhikr database | Freemium | Available on RapidAPI marketplace; rapidapi.com |
| Duas.org | Duas.org | Comprehensive dua collection (Quran, Sunnah, Ahlulbayt) | Free (web scraping) | No official API; extensive Arabic + English content |
| Hisnul Muslim (Fortress) | Greentech Apps | Fortress of the Muslim duas database | Free (open source) | Popular open-source app; data files on GitHub |

---

### 18. hadith -- Hadith Collection APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Sunnah.com API | Sunnah.com | Official hadith API; Bukhari, Muslim, Abu Dawud, etc. | Free (API key required) | Request key via GitHub; docs at sunnah.stoplight.io; comprehensive collections |
| HadithAPI.com | HadithAPI | Hadith search and retrieval | Free | hadithapi.com; REST API with JSON |
| Hadith Dart Package | pub.dev | Dart package for hadith data | Free | Direct Flutter integration; pub.dev/packages/hadith |
| Al Quran Cloud (Hadith) | alquran.cloud | Hadith editions alongside Quran | Free, no auth | Limited hadith content; primarily Quran-focused |

---

### 19. tafuta_msikiti -- Mosque Directory APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| MasjidNear.me API | MasjidNear.me | Search mosques by city/location | Free | REST GET; JSON response; api.masjidnear.me/v1/masjids/search |
| Google Places API | Google | Search for mosques by location, get details | Freemium (10k free/month) | type=mosque; full place details; developers.google.com/maps |
| OpenStreetMap Overpass | OpenStreetMap | Query mosques from OSM database | Free, open source | amenity=place_of_worship + religion=muslim; global coverage |
| IslamicFinder Places | IslamicFinder | Islamic places directory including mosques | Free (limited) | islamicfinder.org/places; location-based search |
| ConnectMazjid | ConnectMazjid | Masjid locator with prayer times | Free | connectmazjid.com/masjid-near-me; global coverage |

---

### 20. maulid -- Islamic Event APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Aladhan Hijri Calendar | Islamic Network | Islamic holidays and events by Hijri date | Free, no auth | Calculate Maulid (12 Rabi ul-Awal), Eid dates, etc. |
| hijri_date Dart Package | pub.dev | Islamic events with Hijri date support | Free | Built-in Islamic event tracking; multi-language |
| Calendarific API | Calendarific | Global holiday API including Islamic holidays | Free (1000 req/month) | Islamic holidays for any country; calendarific.com |
| AbstractAPI Holidays | AbstractAPI | Holiday data including religious observances | Free (limited) | Covers Islamic holidays; abstractapi.com/holidays-api |
| Nager.Date API | Nager.Date | Public holidays API with Islamic observances | Free, open source | date.nager.at; covers Islamic holidays by country |

---

## LIFESTYLE

---

### 21. nightlife -- Venue & Event APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Places API (New) | Google | Venue search, details, photos, reviews, hours | Freemium (10k free Essentials) | Nearby Search, Text Search; filter by type (bar, night_club, restaurant) |
| Foursquare Places API | Foursquare | Venue discovery, tips, photos, ratings | Freemium (10k/month free Pro) | Premium fields extra; 200M+ venues; foursquare.com/developer |
| Yelp Places API | Yelp | Business search, reviews, ratings, photos | Paid ($7.99/1k calls) | 5k free trial calls; rich review data; docs.developer.yelp.com |
| Eventbrite API | Eventbrite | Event discovery, ticketing, venue data | Free (OAuth required) | Event search by location/category; eventbrite.com/platform |
| Ticketmaster Discovery API | Ticketmaster | Events, venues, attractions discovery | Free (5 calls/sec, 5000/day) | Global events; developer.ticketmaster.com |
| Songkick API | Songkick | Live music events, concerts, festivals | Free (API key) | Concert/gig listings; songkick.com |
| PredictHQ API | PredictHQ | Intelligent event data, demand forecasting | Freemium | Events, festivals, concerts; predictive analytics; predicthq.com |

---

## SECURITY

---

### 22. police -- Emergency Services & Crime Data APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| RapidSOS 911 API | RapidSOS | Connect to 911 emergency services programmatically | Paid (enterprise) | 8 lines of code; rapidsos.com/api; US-focused |
| CrimeoMeter API | CrimeoMeter | Worldwide crime data, safety index, incident mapping | Freemium (limited free) | 50+ US states; Safety Quality Index; crimeometer.com |
| FBI Crime Data API | FBI/DOJ | Uniform Crime Reporting (UCR) data for US | Free, no auth | Read-only; JSON/CSV; github.com/fbi-cde/crime-data-api |
| UK Police API | data.police.uk | Crime data, outcomes, stop-and-search for UK | Free, no auth | data.police.uk/docs; comprehensive UK coverage |
| SpotCrime API | SpotCrime | Neighborhood-level crime mapping and alerts | Freemium | Crime maps from regional police departments |
| NCVS API | Bureau of Justice Statistics | Criminal victimization survey data | Free | RESTful; property and violent crime statistics |

**Note for East Africa:** No public crime data APIs exist for Tanzania/Kenya. Recommended approach: build custom incident reporting system with local police integration, use Google Places for police station locations.

---

### 23. traffic -- Traffic Data APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Maps Routes API | Google | Directions, traffic-aware routing, ETAs | Freemium (free tier + $10/1k Advanced) | Replaced legacy Directions API Mar 2025; real-time traffic |
| TomTom Traffic API | TomTom | Real-time traffic flow, incidents, routing | Freemium (2.5k free non-tile/day) | $0.08/1k extra; 80+ countries; developer.tomtom.com |
| HERE Traffic API v7 | HERE Technologies | Real-time traffic flow, incidents, speed data | Freemium (5k free/month) | $2.50/1k after free tier; here.com/docs; global coverage |
| Mapbox Directions API | Mapbox | Traffic-aware routing, navigation, ETAs | Freemium (100k free/month) | Real-time traffic; mapbox.com; great mobile SDKs |
| OpenStreetMap + OSRM | OpenStreetMap | Open-source routing (no live traffic) | Free, open source | Self-hosted routing; project-osrm.org; no traffic data |
| Waze for Cities | Waze/Google | Traffic data sharing for municipalities | Free (for cities) | wazeforcities.com; requires government partnership |

---

### 24. neighbourhood_watch -- Community Safety APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| CrimeoMeter API | CrimeoMeter | Crime data around specific locations | Freemium | Safety scores, crime types, radius search; crimeometer.com |
| CityProtect | CityProtect (Motorola) | Public safety data, crime mapping | Free (public portal) | cityprotect.com; partner with local law enforcement |
| SaferWatch API | SaferWatch | Panic alerts, incident reporting, communication | Paid (enterprise) | saferwatchapp.com; used by communities and schools |
| Firebase Cloud Messaging | Google | Push notifications for safety alerts | Free (with Firebase) | Ideal for real-time community alerts; topic-based messaging |
| Twilio API | Twilio | SMS/voice alerts for emergency notifications | Pay-per-use ($0.0079/SMS) | Mass SMS alerts; twilio.com; reliable delivery |
| OneSignal | OneSignal | Push notifications for safety broadcasts | Free (up to 10k subscribers) | Segmented push; onesignal.com; great for community alerts |

**Note:** No dedicated "neighborhood watch" APIs exist. Best approach: build custom incident reporting with Firebase/Firestore for real-time data, CrimeoMeter for crime context, and push notifications (FCM/OneSignal) for alerts.

---

### 25. alerts -- Weather, Disaster & Emergency Alert APIs

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| OpenWeatherMap API | OpenWeather | Current weather, forecasts, severe weather alerts | Freemium (1000 calls/day free) | One Call API 3.0 includes alerts; openweathermap.org |
| Open-Meteo API | Open-Meteo | Weather forecasts, historical data, alerts | Free, no auth, open source | 1-11km resolution; SDKs for Dart/Kotlin/Swift; open-meteo.com |
| AccuWeather API | AccuWeather | Weather, forecasts, MinuteCast, severe alerts | 14-day free trial; from $2/month | 500 calls/day trial; developer.accuweather.com |
| USGS Earthquake API | U.S. Geological Survey | Real-time earthquake data, alerts, feeds | Free, no auth | GeoJSON feeds; earthquake.usgs.gov; global coverage |
| GDACS API | UN/EC Joint Research Centre | Global disaster alerts (earthquakes, floods, cyclones) | Free | REST API; gdacs.org; worldwide disaster events |
| WeatherAPI.com | WeatherAPI | Weather, astronomy, alerts, historical data | Free (1M calls/month) | Generous free tier; weatherapi.com; 14-day forecast |
| Weatherbit API | Weatherbit | Severe weather alerts, forecasts, historical | Freemium (50 calls/day free) | Global severe weather alerts; weatherbit.io |
| NOAA Weather API | NOAA (US Gov) | US weather alerts, forecasts, observations | Free, no auth | api.weather.gov; US coverage only |
| ReliefWeb API | UN OCHA | Humanitarian reports, disaster updates | Free, no auth | api.reliefweb.int; disaster reports and situation updates |

---

## Summary: Recommended Free/Low-Cost APIs per Module

| Module | Primary Recommendation | Cost |
|--------|----------------------|------|
| my_faith | Joshua Project API | Free |
| biblia | API.Bible + bible-api.com | Free |
| sala | Devotionalium + API.Bible VOTD | Free |
| fungu_la_kumi | Flutterwave (East Africa) + Stripe | Transaction fees only |
| kanisa_langu | Planning Center API | Free for small churches |
| huduma | Bible Brain Audio + Spotify Web API | Free |
| jumuiya | Planning Center Groups | Free for small churches |
| ibada | Spotify Web API + Musixmatch | Free |
| shule_ya_jumapili | API.Bible + Planning Center | Free |
| tafuta_kanisa | Google Places API + OpenStreetMap | Freemium |
| wakati_wa_sala | Aladhan API | Free |
| qibla | Aladhan Qibla API | Free |
| quran | Al Quran Cloud API | Free |
| kalenda_hijri | Aladhan Hijri Calendar API | Free |
| ramadan | Aladhan API (Fajr/Maghrib times) | Free |
| zaka | Halal Terminal + Exchange Rate API | Freemium |
| dua | Dua-Dhikr API (GitHub) | Free |
| hadith | Sunnah.com API | Free |
| tafuta_msikiti | MasjidNear.me + Google Places | Free/Freemium |
| maulid | Aladhan Hijri + Calendarific | Free |
| nightlife | Google Places + Foursquare | Freemium |
| police | CrimeoMeter + custom reporting | Freemium |
| traffic | TomTom Traffic + Google Routes | Freemium |
| neighbourhood_watch | Firebase + CrimeoMeter + OneSignal | Free/Freemium |
| alerts | Open-Meteo + USGS + GDACS | Free |

---

## Key Integration Notes for TAJIRI

1. **East Africa Focus**: For payment APIs, prioritize Flutterwave (M-Pesa, Airtel Money support) over US-centric options like Tithe.ly
2. **Offline Support**: Cache prayer times (Aladhan), Quran text, and duas locally using Hive for offline access
3. **Islamic APIs are strong**: Aladhan (prayer/qibla/calendar) and Al Quran Cloud are production-ready, free, and well-documented
4. **Church APIs require subscriptions**: Most ChMS APIs (Planning Center, Breeze, ChurchSuite) require the church to have an active subscription
5. **No auth required**: Aladhan, USGS, GDACS, Open-Meteo, bible-api.com, Al Quran Cloud -- simplest to integrate
6. **Dart packages available**: aladhan_prayer_times, hijri_calendar, hijri_date, hadith -- direct pub.dev integration for Flutter
7. **Crime data gap**: No public crime APIs exist for East Africa; build custom incident reporting system
8. **Rate limits to watch**: API.Bible (5k/day), ESV (5k/day), Foursquare (10k/month free), AccuWeather (500/day trial)
