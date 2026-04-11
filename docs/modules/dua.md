# Dua (Supplications) — Feature Description

## Tanzania Context

"Dua" means supplication or personal prayer in Islam. Unlike the formal five daily prayers (salat), duas are informal personal prayers that can be made at any time. Tanzanian Muslims learn many duas from childhood at madrasa — daily adhkar (morning and evening remembrances), duas before eating, sleeping, traveling, entering the mosque, and many other occasions.

Most Tanzanian Muslims know several duas in Arabic but may not understand their meanings. Swahili translations are essential for comprehension and deeper connection. Many people keep physical dua books (often small pocket-sized booklets called "Hisn al-Muslim" or "Fortress of the Muslim" in Swahili translation). A digital version with audio pronunciation, categorized by occasion, and available in Arabic with Swahili translation would replace these worn booklets and make duas accessible anytime.

## International Reference Apps

1. **Hisn al-Muslim (Fortress of Muslim)** — Comprehensive dua app based on the famous book
2. **Muslim Pro** — Duas section with categories and audio
3. **Dua & Azkar** — Extensive dua collection with transliteration and translation
4. **MyDuaa** — Personal dua journal with sharing features
5. **iQuran** — Quranic duas extracted with context and tafsir

## Feature List

1. Morning adhkar — complete morning remembrances with count tracker
2. Evening adhkar — complete evening remembrances with count tracker
3. Duas by category — organized by occasion: travel, eating, sleeping, waking, illness, rain, marketplace, anxiety, anger, entering/leaving home, mosque, bathroom
4. Arabic text — clear Arabic script with proper diacritical marks (tashkeel)
5. Swahili translation — full meaning in Swahili for understanding
6. English translation — English option for bilingual users
7. Transliteration — Latin-script phonetic rendering for those who cannot read Arabic
8. Audio playback — native Arabic pronunciation for each dua
9. Counter/tasbeeh — digital counter for repeated dhikr (SubhanAllah, Alhamdulillah, etc.)
10. Favorites — bookmark frequently used duas for quick access
11. Daily dua notification — push notification with a selected dua each morning and evening
12. Search — find duas by keyword, occasion, or source
13. Quranic duas — duas from the Quran with surah/ayah reference
14. Prophetic duas — duas from hadith with source attribution
15. Share duas — send as text or styled card to messages or feed
16. Font size adjustment — customizable Arabic and translation text size
17. Offline access — complete dua library available without internet
18. Custom duas — add personal duas in any language

## Key Screens

- **Dua Home** — morning/evening adhkar status, daily featured dua, category quick links
- **Category Browser** — illustrated category cards (travel, food, sleep, health, etc.)
- **Dua List** — duas within a category with Arabic preview and occasion label
- **Dua Detail** — full Arabic text, transliteration, Swahili translation, audio, source reference
- **Adhkar Counter** — morning or evening adhkar checklist with repetition counter per item
- **Digital Tasbeeh** — large counter button with preset dhikr phrases and target counts
- **Favorites** — saved duas for quick access
- **Search Results** — matching duas with category and source indicators
- **Dua Card Creator** — styled dua image for sharing

## TAJIRI Integration Points

- **NotificationService + FCMService** — morning/evening adhkar reminders, daily featured dua push notification, occasion-specific dua alerts
- **PostService.createPost()** — share daily dua cards to social feed as styled image cards
- **StoryService.createStory()** — daily dua posted as story with Arabic text and Swahili translation
- **MessageService.sendMessage()** — send duas directly in chat conversations; share with prayer groups
- **FriendService.getFriends()** — share duas with friends list; morning adhkar accountability partners
- **HashtagService** — #Dua, #Adhkar for discoverable supplication posts
- **Cross-module: Wakati wa Sala** — post-prayer duas suggested after marking prayer complete; prayer-specific supplications
- **Cross-module: Quran** — Quranic duas link to full ayah context in Quran reader
- **Cross-module: Hadith** — prophetic duas link to source hadith with authentication grade
- **Cross-module: Ramadan** — daily Ramadan-specific duas during the holy month (iftar dua, suhoor dua, Laylat al-Qadr)
- **Cross-module: Kalenda Hijri** — occasion-specific duas for Islamic events (Eid, Maulid, Isra Mi'raj)
- **Cross-module: travel/ module** — travel duas surfaced automatically when user is traveling
- **Offline Support** — entire dua library works without internet connection via LocalStorageService
