# Hadith — Feature Description

## Tanzania Context

Hadith are the recorded sayings, actions, and approvals of Prophet Muhammad (peace be upon him). They are the second most important source of Islamic guidance after the Quran. In Tanzania, hadith study is integral to Islamic education — madrasas teach hadith from an early age, and Friday khutbahs (sermons) regularly reference hadith.

The major hadith collections (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah) are widely studied, with Sahih Bukhari and Sahih Muslim considered the most authentic. While Arabic texts are available, Swahili translations are limited and often only available in printed form from Islamic bookshops. Many Tanzanian Muslims share individual hadith via WhatsApp — often without proper source verification, leading to circulation of weak or fabricated hadith. A reliable app with authenticated hadith in Swahili would serve a major educational need.

## International Reference Apps

1. **Sunnah.com** — Comprehensive hadith database with multiple collections and search
2. **Hadith Collection (Green Tech)** — All six major collections with search and bookmarks
3. **Muslim Pro** — Daily hadith feature with multiple collections
4. **iHadith** — Curated hadith with themes, favorites, and sharing
5. **Daily Hadith** — One hadith per day with notification and widget

## Feature List

1. Major collections — Sahih Bukhari, Sahih Muslim, Sunan Abu Dawud, Jami at-Tirmidhi, Sunan an-Nasai, Sunan Ibn Majah
2. Browse by collection — navigate by book and chapter within each collection
3. Arabic text — original Arabic with proper diacritical marks
4. Swahili translation — full Swahili translation of hadith text
5. English translation — English option for bilingual reference
6. Search — full-text search across all collections in Arabic, Swahili, or English
7. Hadith grading — authenticity grade displayed (sahih, hasan, da'if) with scholar references
8. Daily hadith — featured hadith each day with push notification
9. Topic-based browsing — hadith organized by theme: prayer, fasting, charity, marriage, business, ethics, manners
10. Favorites — save hadith for personal reference library
11. Share — send hadith as text or styled card to messages or feed
12. Narrator chain (isnad) — view chain of narration for each hadith
13. Cross-references — related hadith from other collections linked
14. Quran references — hadith explaining Quranic verses linked to Quran module
15. Bookmarks with notes — add personal study notes to saved hadith
16. Offline access — full hadith collections downloadable for offline reading
17. 40 Hadith Nawawi — special curated collection often memorized by students
18. Reading progress — track which books/chapters have been read

## Key Screens

- **Hadith Home** — daily hadith card, continue reading, recently viewed, favorites count
- **Collections Browser** — six major collection covers with hadith count and progress
- **Book/Chapter View** — navigable list of books within a collection, then chapters
- **Hadith Detail** — Arabic text, translation, grading, narrator chain, related hadith, share
- **Topic Browser** — thematic categories with illustration icons
- **Search Results** — matching hadith with collection source, grading badge, preview
- **Favorites Library** — saved hadith organized by collection or custom tags
- **40 Nawawi** — special study section with all 40 hadith and commentary
- **Reading Tracker** — collection-level and book-level completion progress

## TAJIRI Integration Points

- **PostService.createPost(), sharePost()** — share daily hadith or favorites to social feed as styled cards with #HadithOfTheDay hashtag; authenticity grade displayed
- **MessageService.sendMessage()** — send hadith directly in chat conversations; share in mosque community groups
- **NotificationService + FCMService** — daily hadith push notification, reading plan reminders, collection completion milestones
- **GroupService.getMembers()** — share hadith in mosque study groups for discussion and reflection
- **FriendService.getFriends()** — share hadith with friends; hadith study partner matching
- **ProfileService.getProfile()** — hadith reading progress on faith profile (opt-in); collection completion tracking
- **HashtagService** — #HadithOfTheDay, #SahihBukhari for discoverable hadith content
- **Cross-module: Quran** — hadith explaining Quranic verses link directly to Quran reader for cross-reference study
- **Cross-module: Dua** — prophetic duas sourced from hadith with direct links to source narration
- **Cross-module: Ramadan** — Ramadan-specific hadith highlighted during the holy month
- **Cross-module: Kalenda Hijri** — occasion-relevant hadith surfaced on Islamic dates (Ashura, Maulid, Eid)
- **Offline Support** — complete offline access to all six major collections via LocalStorageService
