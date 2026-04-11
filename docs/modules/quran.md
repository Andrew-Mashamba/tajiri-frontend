# Quran — Feature Description

## Tanzania Context

The Quran is the holy book of Islam, recited and studied daily by Tanzania's Muslim population. Quran education begins at a young age — most Muslim children attend madrasa (Quran school) in addition to secular schooling. Memorization (hifz) of the Quran is highly valued and memorizers (huffaz) are deeply respected in the community.

Swahili Quran translations are widely used for understanding, with Sheikh Abdullah Saleh Farsy's translation being the most authoritative and widely referenced in East Africa. Arabic text remains essential for recitation, as Muslims recite prayers and Quran in Arabic. Many Tanzanians can recite Arabic text but need Swahili translation for comprehension. Audio recitation is extremely popular — reciters like Mishary Rashid Alafasy, Abdul Rahman Al-Sudais, and Abdul Basit are commonly listened to. Budget Android phones with limited storage make efficient offline Quran access important.

## International Reference Apps

1. **Quran.com** — Full Quran with translations, audio, tafsir, mobile-optimized
2. **Muslim Pro** — Quran with 40+ translations, word-by-word, audio recitation
3. **iQuran** — Offline Quran with Tajweed, translations, audio, bookmarks
4. **Quran Majeed** — Quran with 25+ translations, Tajweed rules, memorization tools
5. **Tarteel** — AI-powered Quran recitation feedback and memorization helper

## Feature List

1. Full Quran text — complete Arabic mushaf with proper Uthmani script rendering
2. Swahili translation — Sheikh Abdullah Saleh Farsy translation (primary)
3. English translation — Sahih International, Yusuf Ali, or Pickthall (secondary)
4. Parallel view — Arabic and translation side by side or interlinear
5. Audio recitation — multiple reciters (Mishary, Al-Sudais, Al-Ghamdi, etc.)
6. Word-by-word — tap any Arabic word for meaning, transliteration, and grammar
7. Tajweed color coding — color-coded rules (idgham, ikhfa, qalqalah, etc.) on Arabic text
8. Juz/Surah/Ayah navigation — browse by juz (30 parts), surah (114 chapters), or ayah number
9. Bookmarks — save specific ayahs with custom labels
10. Search — search Arabic text, Swahili translation, or surah names
11. Memorization tracker — track memorized surahs/juz with progress visualization
12. Memorization mode — hide/reveal Arabic text for self-testing, repeat ayah playback
13. Last read position — auto-save and resume reading position
14. Reading plan — structured plans (read entire Quran in 30 days, khatm schedule)
15. Tafsir — brief exegesis notes (Swahili) for deeper understanding
16. Share ayahs — share as text or styled image card to feed/messages
17. Offline mode — download entire Quran text and selected audio for offline use
18. Night mode — eye-friendly dark theme for extended reading
19. Font size and style — adjustable Arabic and translation text size

## Key Screens

- **Quran Home** — last read position, daily ayah, memorization progress, reading plan status
- **Surah List** — all 114 surahs with revelation type (Makki/Madani), ayah count
- **Juz Browser** — 30 juz with associated surahs and pages
- **Reading View** — Arabic text with optional translation below, audio controls, Tajweed toggle
- **Word-by-Word View** — interactive Arabic text with pop-up word details
- **Audio Player** — reciter selector, continuous play, repeat ayah/surah, speed control
- **Search Results** — ayah results with surah context, Arabic and translation
- **Memorization Tracker** — surah/juz grid showing memorized, in-progress, not started
- **Memorization Practice** — hide/reveal mode with audio playback for each ayah
- **Bookmark Manager** — saved ayahs organized by label/surah

## TAJIRI Integration Points

- **PostService.createPost(), sharePost()** — share ayah cards to social feed with Swahili translation; styled verse image cards with #QuranAyah hashtag
- **StoryService.createStory()** — daily ayah of the day posted as a story with Arabic and Swahili translation
- **MessageService.sendMessage()** — send ayahs directly in chat conversations or mosque community groups
- **MusicService** — Quran recitation audio by renowned reciters (Mishary, Al-Sudais) streamed through TAJIRI audio player
- **FriendService.getFriends()** — share ayahs with friends; Quran reading partner matching for khatm challenges
- **NotificationService + FCMService** — daily ayah push notification, reading plan reminders, khatm completion alerts
- **HashtagService** — #QuranAyah, #AyahOfTheDay for discoverable Quran posts
- **Cross-module: Wakati wa Sala** — suggested surahs for each prayer time
- **Cross-module: Dua** — Quranic duas linked to full ayah context in Quran reader
- **Cross-module: Hadith** — hadith references to Quran link to relevant ayahs for cross-study
- **Cross-module: Ramadan** — Quran reading plan intensified during Ramadan (khatm in 30 days); daily juz assignment
- **Cross-module: Kalenda Hijri** — special surahs recommended for Islamic occasions (Laylat al-Qadr, Eid, Maulid)
- **Offline Support** — complete offline functionality via LocalStorageService for downloaded text and audio recitations
