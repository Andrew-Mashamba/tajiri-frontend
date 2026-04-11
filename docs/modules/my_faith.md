# My Faith (Imani Yangu) — Feature Description

## Tanzania Context

Tanzania is one of the most religiously diverse countries in East Africa. Approximately 61% of the population identifies as Christian and 35% as Muslim, with Zanzibar being nearly 100% Muslim. The major Christian denominations include Catholic (largest single denomination), Lutheran (ELCT — historically strong in northern regions), Anglican, Pentecostal/Charismatic, Seventh-day Adventist, and various evangelical churches. Muslims are predominantly Sunni, with smaller Shia and Ibadhi communities (Ibadhi particularly in Zanzibar due to Omani heritage).

Religious identity is central to daily life in Tanzania. People regularly attend services, participate in faith-based community groups, and integrate faith into business and social interactions. However, no single app serves both faith communities with locally relevant content in Swahili. Most global faith apps are English-first and culturally Western.

## International Reference Apps

1. **YouVersion Bible App** — Faith profile with denomination selection, reading plans, community features
2. **Muslim Pro** — Islamic profile with prayer settings, Quran preferences, community
3. **Church Center (Planning Center)** — Church membership profiles and engagement tracking
4. **Pray.com** — Multi-faith prayer and devotional content with personalized feeds
5. **Hallow** — Catholic-specific app with tailored content based on user faith profile

## Feature List

1. Faith selection screen — Christian or Muslim (presented respectfully, no default)
2. Denomination picker — Christian: Catholic, Lutheran (ELCT), Anglican, Pentecostal, SDA, Baptist, Moravian, Evangelical, Other; Muslim: Sunni, Shia, Ibadhi, Other
3. Home church/mosque selector — search by name or location, link to Tafuta Kanisa / Tafuta Msikiti
4. Faith bio — short text describing spiritual journey or beliefs
5. Prayer preferences — preferred prayer times, reminders, private/shared prayer life
6. Faith tab configuration — based on faith selection, show relevant tabs (Christian tabs: Biblia, Sala, Fungu la Kumi, Kanisa Langu, Huduma, Jumuiya, Ibada, Shule ya Jumapili, Tafuta Kanisa; Islamic tabs: Wakati wa Sala, Qibla, Quran, Kalenda Hijri, Ramadan, Zaka, Dua, Hadith, Tafuta Msikiti, Maulid)
7. Spiritual milestones — baptism date, confirmation, Shahada date, Hajj completion
8. Faith-based content feed — devotionals, articles, and community posts filtered by faith
9. Privacy controls — choose who sees faith profile (public, friends only, private)
10. Faith community discovery — find and connect with people of similar denomination/faith nearby
11. Spiritual goals — set and track goals (read entire Bible, memorize Quran juz, daily prayer streak)
12. Faith leader designation — mark if user is pastor, imam, deacon, sheikh, etc.

## Key Screens

- **Faith Selection Screen** — clean two-option selector (Christian / Muslim) with respectful iconography
- **Denomination Picker** — scrollable list with search, grouped by major categories
- **Faith Profile Setup** — multi-step wizard: faith > denomination > church/mosque > bio > preferences
- **Faith Dashboard** — personalized home showing relevant faith modules as card grid
- **Faith Profile View** — public-facing faith information on user profile
- **Spiritual Goals Screen** — goal cards with progress indicators
- **Faith Settings** — privacy, notification preferences, denomination change

## TAJIRI Integration Points

- **ProfileService.getProfile()** — reads `faith` field from user registration (Christian/Muslim) to determine which faith tabs display; faith bio and milestones shown as optional profile section respecting privacy settings
- **GroupService.createGroup(), joinGroup()** — auto-suggest faith-based community groups (jumuiya for Christians, halqa for Muslims) based on selected denomination
- **MessageService.createGroup()** — create prayer groups, jumuiya chat, or mosque community chat channels linked to faith profile
- **FriendService.getFriends()** — share Bible verses or Quran ayahs with friends; surface friends of similar denomination for faith community discovery
- **PostService.createPost(), sharePost()** — share faith content (verse of the day, hadith, sermon clips) as posts; faith-related content prioritization in discover feed
- **StoryService.createStory()** — daily verse or hadith as story, faith milestone announcements
- **WalletService.deposit(amount, provider:'mpesa')** — enables tithe/offering (Fungu la Kumi) and Zakat payment flows via M-Pesa
- **MusicService** — worship/gospel or nasheed/qaswida content filtered by faith preference (Christian or Muslim)
- **CalendarService.createEvent()** — sync church/mosque events to personal TAJIRI calendar
- **NotificationService + FCMService** — prayer time alerts (adhan for Muslims), devotional reminders, church announcement push notifications based on faith selection
- **LocationService.getRegions(), getDistricts()** — find nearby churches or mosques based on faith profile
- **EventTrackingService** — track engagement with faith content to personalize recommendations
- **Cross-module:** my_faith determines tab visibility — Christian users see Biblia, Sala, Fungu la Kumi, Kanisa Langu, Huduma, Jumuiya, Ibada, Shule ya Jumapili, Tafuta Kanisa; Muslim users see Wakati wa Sala, Qibla, Quran, Kalenda Hijri, Ramadan, Zaka, Dua, Hadith, Tafuta Msikiti, Maulid
