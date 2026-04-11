# Katiba (Constitution) — Feature Description

## Tanzania Context

The Constitution of the United Republic of Tanzania (Katiba ya Jamhuri ya Muungano wa Tanzania) was enacted in 1977 and has been amended multiple times. It is the supreme law governing the union between Tanganyika (mainland) and Zanzibar.

**Structure:**
- 152 Articles organized into 11 Chapters (Sura)
- Chapter 1: The United Republic (Articles 1-11)
- Chapter 2: Bill of Rights (Haki za Binadamu, Articles 12-29) — added via 5th Amendment (1984)
- Chapter 3: Executive (Articles 33-60)
- Chapter 4: Legislature (Articles 62-109)
- Chapter 5: Judiciary (Articles 107A-120)
- Plus chapters on finance, armed forces, miscellaneous provisions

**Current reality:**
- Most Tanzanians have never read the Constitution despite it being publicly available
- Physical copies are hard to find; PDF versions exist online but are not mobile-friendly
- Constitutional literacy is extremely low — citizens don't know their basic rights
- The 2014 proposed new constitution (Katiba Mpya) via Constituent Assembly was never finalized; referendum never held
- Zanzibar has its own separate constitution (Katiba ya Zanzibar, 1984)
- Legal Swahili in the Constitution is archaic and difficult for ordinary citizens to understand
- No existing app provides the Tanzania Constitution in a searchable, user-friendly format
- Key amendments (e.g., 8th amendment on multi-party politics, 13th amendment on presidential term limits) are historically significant but poorly documented for public

**Pain points:**
- Citizens don't know their constitutional rights when dealing with police, employers, or government
- Journalists, students, and activists need quick reference but lack good tools
- No plain-language explanations of constitutional provisions
- Comparison between current constitution and proposed 2014 draft unavailable in one place

## International Reference Apps

1. **ConstitutionUS (US)** — Full US Constitution with amendments, searchable, with annotations and explanations. Clean reading interface.
2. **iConstitution (US)** — Offline-capable constitution reader with bookmarks, highlights, sharing, and quiz features.
3. **Constitution of India App** — All articles searchable, with amendments, schedules, and case law references.
4. **South Africa Constitution App** — Bill of Rights focused, plain-language summaries, available in all 11 official languages.
5. **Constitute Project (Global)** — Comparative constitution database with thematic browsing (rights, government structure, elections).

## Feature List

1. **Full Text Browser** — Complete Katiba ya Tanzania 1977 (as amended) organized by Chapter > Part > Article, in both Swahili and English
2. **Search** — Full-text search across all articles with highlighted results and filters by chapter
3. **Article Reader** — Clean reading view for individual articles with font size control, dark mode, and reading position memory
4. **Plain Language Summaries** — Each article explained in simple Swahili and English for non-lawyers (Maelezo Rahisi)
5. **Bookmarks** — Save frequently referenced articles for quick access
6. **Highlights & Notes** — Highlight text and add personal notes on any article
7. **Bill of Rights Focus** — Dedicated section for Chapter 2 (Articles 12-29) with real-life examples of each right
8. **Know Your Rights Guides** — Practical guides: rights when arrested, worker rights, land rights, women's rights, children's rights, press freedom
9. **Amendments History** — Timeline of all constitutional amendments with what changed, when, and why
10. **2014 Draft Comparison** — Side-by-side comparison of current constitution vs proposed Katiba Mpya (2014 draft)
11. **Zanzibar Constitution** — Full text of Katiba ya Zanzibar 1984 with same browsing features
12. **Constitutional Court Cases** — Key court decisions interpreting constitutional provisions, linked to relevant articles
13. **Quiz & Learning** — Interactive quizzes on constitutional knowledge for students and citizens
14. **Share Articles** — Share specific articles via TAJIRI messaging, WhatsApp, or social media with formatted citation
15. **Offline Access** — Full constitution text available offline after initial download
16. **Audio Version** — Listen to articles read aloud in Swahili for accessibility and low-literacy users
17. **Daily Article** — Push notification with a "Constitutional Article of the Day" with explanation
18. **Glossary** — Legal terms used in the Constitution explained in plain Swahili and English

## Key Screens

- **Home** — Constitution overview with chapter list, search bar, daily article card
- **Chapter Browser** — Expandable chapter list with article counts and brief descriptions
- **Article Reader** — Clean text view with highlight, bookmark, note, and share actions
- **Search Results** — Filtered search with context snippets and article navigation
- **Bill of Rights** — Special section with rights cards, real-life examples, and "What to do if violated"
- **Know Your Rights** — Thematic guides with scenarios and actionable advice
- **Amendments Timeline** — Visual timeline of constitutional changes
- **Quiz** — Multiple choice and true/false questions with explanations
- **Bookmarks & Notes** — Saved articles and user annotations
- **Settings** — Language, font size, dark mode, offline download, notification preferences

## TAJIRI Integration Points

- **MessageService** — `sendMessage()` to share constitutional articles in TAJIRI chats with rich preview and formatted citation
- **PostService** — `createPost()` for daily constitutional article posts and awareness content; `sharePost()` for sharing specific articles to feed
- **StoryService** — `createStory()` for "Constitutional Article of the Day" highlights
- **GroupService** — `createGroup()` for constitutional discussion groups and civic education communities; `joinGroup()` for citizens engaging in constitutional literacy
- **NotificationService + FCMService** — Push alerts for daily article of the day, amendment news, and constitutional awareness campaigns
- **LocalStorageService** — Offline caching of full constitution text, bookmarks, highlights, and personal notes for areas with poor connectivity
- **MediaCacheService** — Cache audio versions of articles for offline listening
- **ProfileService** — `getProfile()` for displaying "Constitutional Scholar" badges earned through quiz completion
- **EventTrackingService** — Analytics on quiz completion rates, most-read articles, popular rights guides
- **Cross-module: legal_gpt** — Cross-reference: ask AI to explain constitutional provisions in context; legal_gpt cites Katiba articles when answering rights questions
- **Cross-module: lawyer/** — Direct link from "What to do if violated" guides to lawyer/ module for legal representation
- **Cross-module: barozi_wangu** — Links to Barozi Wangu for understanding government structure at ward level; councillor accountability tied to constitutional mandates
