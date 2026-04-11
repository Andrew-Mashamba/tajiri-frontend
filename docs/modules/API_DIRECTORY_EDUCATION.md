# TAJIRI Education Module API Directory

> Available APIs for Education modules. Researched 2026-04-08.

---

## 1. my_class — Class/Course Management

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Classroom API | Google | Course CRUD, roster management, grading periods, announcements | Free (Google Workspace for Education) | OAuth 2.0, REST v1. Requires Google Workspace admin approval. Covers courses, courseWork, studentSubmissions. |
| Canvas LMS REST API | Instructure | Full LMS: courses, modules, enrollments, grades | Free (with Canvas instance) | OpenAPI 3.0 spec available. OAuth2. Widely used by universities globally. |
| Moodle Web Services API | Moodle | Course management, user enrollment, grade book | Free (self-hosted Moodle) | REST endpoint at `/webservice/rest/server.php`. 400+ API functions. Requires admin to enable web services. |
| Schoology API | PowerSchool | K-12 course management, assignments, gradebook | Paid (institutional license) | REST API, OAuth 1.0. Popular in US K-12. |

**Tanzania context:** Most Tanzanian universities use custom portals (ARIS, SARIS, OSIM). No standardized API exists — would need web scraping or institutional partnerships.

---

## 2. timetable — Scheduling

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Calendar API | Google | Calendar CRUD, recurring events, reminders | Free (quota limits) | REST v3. OAuth 2.0. Can model class schedules as recurring calendar events. |
| Microsoft Graph Calendar API | Microsoft | Outlook calendar integration | Free tier available | Part of Microsoft 365. Good for institutions using Office 365 Education. |
| Cronofy Calendar API | Cronofy | Unified calendar access (Google, Outlook, iCloud) | Free tier: 5 users; Paid from $49/mo | Unified API across calendar providers. Scheduling links, availability. |
| UniTime API | UniTime (open-source) | University timetabling, exam scheduling | Free (open-source) | Java-based. Complex setup but purpose-built for university scheduling. |

**Tanzania context:** No Tanzania-specific timetable API. Build custom with Google Calendar as sync backend.

---

## 3. assignments — Assignment/LMS Management

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Classroom API | Google | Create/grade courseWork, manage submissions | Free (Google Workspace for Education) | Supports assignment creation, rubrics, student submissions with attachments. |
| Canvas LMS REST API | Instructure | Assignment CRUD, submission management, rubrics | Free (with Canvas instance) | Rich assignment types: online upload, URL, media. SpeedGrader integration. |
| Moodle Web Services API | Moodle | Assignment plugin, grading, file submissions | Free (self-hosted) | `mod_assign_*` functions for assignment management. |
| Turnitin API | Turnitin | Plagiarism detection for submissions | Paid (institutional) | Integration API for plagiarism checking. Requires institutional license. |

---

## 4. class_chat — Education Messaging

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| TAJIRI Messaging (internal) | TAJIRI | In-app messaging, already built | N/A | Leverage existing TAJIRI chat infrastructure for class-specific channels. |
| Stream Chat API | Stream | Scalable chat with moderation, threads | Free: 10K MAU; Paid from $399/mo | Flutter SDK available. Education-friendly with content moderation. |
| CometChat | CometChat | Real-time messaging, voice/video | Free: 25 MAU; Paid from $149/mo | Flutter SDK. Group chat, file sharing, typing indicators. |
| Sendbird | Sendbird | In-app messaging, moderation | Free: 25 MAU; Paid from $399/mo | Flutter SDK. Rich messaging features, offline support. |

**Recommendation:** Use TAJIRI's existing messaging system with class-specific group channels. No external API needed.

---

## 5. class_notes — Document Storage & OCR

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Google Cloud Vision API | Google | OCR text extraction from images | Free: 1,000 units/mo; $1.50/1K after | Handwriting recognition, document text detection. $300 free credits for new users. |
| Google ML Kit Text Recognition | Google | On-device OCR (no network needed) | Free | Flutter package: `google_mlkit_text_recognition ^0.15.0`. Works offline. iOS/Android only. |
| Tesseract OCR | Open-source | On-device OCR, 100+ languages | Free (open-source) | Flutter packages: `flutter_tesseract_ocr`, `tesseract_ocr`. Slower than ML Kit but fully offline. |
| Google Drive API | Google | Cloud document storage, sharing | Free (15GB per user) | Upload, organize, share notes. Google Docs viewer integration. |
| Firebase Storage | Google | File storage for uploaded notes | Free: 5GB; Pay-as-you-go after | Already in TAJIRI stack. Good for storing scanned/uploaded notes. |
| Mathpix OCR API | Mathpix | Math equation OCR from handwriting | Free: 20 requests/mo; $9.99/mo for 1K | Specialized for STEM — converts handwritten math to LaTeX. |

**Recommendation:** Google ML Kit for on-device OCR (free, fast, offline). Firebase Storage for note uploads (already integrated).

---

## 6. exam_prep — Flashcards & Quizzes

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Open Trivia Database API | OpenTDB | Free trivia questions, 20+ categories | Free, no API key | 4,000+ verified questions. Max 50/call. Rate limit: 1 req/5 sec. Session tokens prevent repeats. |
| The Trivia API | the-trivia-api.com | Trivia questions with categories | Free, no API key | Alternative to OpenTDB with more questions. |
| Quizizz API | Quizizz | Gamified quizzes, LMS integration | Free for basic; Paid for schools | Popular in education. AI-powered quiz generation. |
| Anthropic Claude API | Anthropic | AI-generated flashcards, explanations | From $1/M input tokens (Haiku 4.5) | Generate custom flashcards from any topic. TAJIRI already uses AI backend. |
| OpenAI API | OpenAI | AI-generated quiz questions | From $2.50/M input tokens (GPT-4o) | Generate contextual practice questions. |

**Tanzania context:** Build custom NECTA-aligned question banks. Use AI APIs to generate Tanzanian curriculum-specific content.

---

## 7. past_papers — Exam Paper Archives

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| NECTA API (unofficial) | Community (Vincent Laizer) | Fetch CSEE/ACSEE results from NECTA | Free (open-source, PyPI: `nectaapi`) | Python package scraping necta.go.tz. Supports school lists, student results, performance comparisons. Not official. |
| NECTA Results Scraper (PHP) | Community (AlexLeoTz) | Scrape NECTA student results | Free (open-source) | PHP alternative to Python NECTA API. GitHub: AlexLeoTz/necta-results-scraper |
| NECTA Website | NECTA (necta.go.tz) | Official results portal | Free (web scraping) | No official API. Results at matokeo.necta.go.tz. Would need custom scraper for past papers. |

**Tanzania context:** NECTA has NO official API. Community packages scrape HTML results pages. For past papers, build a custom archive with PDFs sourced from NECTA publications. Consider partnering with NECTA for official data access.

---

## 8. newton — AI Education Assistant

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Anthropic Claude API | Anthropic | AI tutoring, explanations, problem solving | Haiku 4.5: $1/$5 per M tokens; Sonnet 4.6: $3/$15; Opus 4.6: $5/$25 | Best reasoning. 1M context window. Prompt caching saves 90%. Batch API saves 50%. |
| OpenAI API | OpenAI | AI tutoring, code help, math | GPT-4o: $2.50/$10 per M tokens; GPT-5 available | GPT-4o is cost-effective for general tutoring. |
| Wolfram Alpha API | Wolfram | Step-by-step math solutions, computation | Free: 2,000 calls/mo; Paid plans from $5/mo | Full Results API, Short Answers API. Excellent for STEM subjects. |
| Newton API | Newton (open-source) | Basic math operations (derive, integrate, simplify) | Free, no API key | Simple REST API: `https://newton.now.sh/api/v2/:operation/:expression`. Limited scope. |
| Photomath patterns | N/A | Camera-based math solving | N/A (proprietary) | No public API. Replicate pattern using Claude API + OCR for math image solving. |
| Google Gemini API | Google | AI tutoring, multimodal (image+text) | Free tier available; Paid from $3.50/M tokens | Multimodal: can analyze photos of math problems. |

**Recommendation:** Anthropic Claude API as primary (already in TAJIRI backend). Wolfram Alpha for verified math computation. Google ML Kit for math photo capture.

---

## 9. results — Grade Management

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| NECTA API (unofficial) | Community | Fetch national exam results (CSEE, ACSEE, FTNA) | Free (open-source) | PyPI: `nectaapi`. School summaries, individual results, year comparisons. |
| Google Classroom API | Google | Gradebook, student submissions, rubrics | Free | Access grades programmatically. Calculate GPA, generate reports. |
| Canvas LMS REST API | Instructure | Gradebook API, grade passback (LTI) | Free (with instance) | Comprehensive grading: weighted, curved, letter grades. |
| TCU Central Admission System | TCU (tcu.go.tz) | University admission data | No public API | Web portal only. Would need partnership for data access. |
| NACTE/NACTVET | NACTE | Technical college results, accreditation | No public API | No API available. Web portal at nacte.go.tz. |

**Tanzania context:** No official government API for academic results. NECTA unofficial scraper is the only programmatic option. For university results, each institution has its own portal (ARIS, SARIS, OSIM) with no unified API.

---

## 10. fee_status — Fee & Loan Tracking

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| M-Pesa API (Vodacom TZ) | Vodacom Tanzania | Mobile money payments, fee collection | Transaction-based fees | Open API with sandbox. C2B (collection), B2C (refunds). Register at business.m-pesa.com. |
| Tigo Pesa API | MIC Tanzania | Mobile money payments | Transaction-based fees | Alternative mobile money for fee payment. |
| Airtel Money API | Airtel Tanzania | Mobile money payments | Transaction-based fees | Third mobile money option for coverage. |
| HESLB OLAS Portal | HESLB (heslb.go.tz) | Student loan status, allocation | No public API | Web portal at olas.heslb.go.tz. No API — would need web scraping or partnership. HESLB allocated TZS 426.5B to 135,240 students in 2025/26. |
| Flutterwave API | Flutterwave | Payment processing, cards, mobile money | 1.4% per transaction (Africa) | Supports M-Pesa, cards, bank transfers. Good aggregator for multiple payment methods. |
| DPO Group / Network International | DPO | Payment gateway, Tanzania coverage | Transaction-based | Card and mobile money processing. Tanzania presence. |

**Tanzania context:** HESLB has NO public API. Students check loan status via OLAS web portal. For fee payments, M-Pesa API (Vodacom) is essential — most Tanzanian students pay fees via mobile money. Consider building HESLB status scraper with user consent.

---

## 11. library — Digital Library

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Open Library API | Internet Archive | Book search, covers, metadata (17M+ books) | Free, no API key | Search, Covers, Works/Editions APIs. JSON/YAML/RDF. Extensive catalog. |
| Google Books API | Google | Book search, previews, metadata | Free (1,000 req/day default) | REST v1. Search by ISBN, title, author. Preview links. Some full-text access. |
| CrossRef API | CrossRef | Academic paper metadata, DOI lookup | Free (public); Polite (free + email); Plus (paid) | 180M+ records. Search journals, papers by DOI. Great for academic references. |
| Semantic Scholar API | Allen Institute | AI-powered academic paper search | Free: 100 req/5 min; API key for higher limits | 200M+ papers. Citation graphs, SPECTER2 embeddings. Excellent for research. |
| JSTOR XML Gateway | JSTOR | Academic journal access | Institutional license required | Metasearch API. Requires JSTOR Metasearch License Agreement. Not for individual use. |
| CORE API | Open University | Open access research papers | Free (API key required) | 300M+ metadata records, 40M+ full texts. Aggregates open access research. |
| OpenAlex API | OurResearch | Academic paper, author, institution data | Free, no API key | Successor to Microsoft Academic Graph. 250M+ works. Fast, well-documented. |
| Library of Congress API | US Library of Congress | Digital collections, cataloging | Free | loc.gov JSON/XML API. Books, maps, manuscripts, audio. |
| Z-Library patterns | N/A | Book access | N/A (legal gray area) | No public API. Not recommended for official integration. |

**Recommendation:** Open Library + Google Books for general books. Semantic Scholar + CrossRef for academic papers. OpenAlex as free academic metadata backbone.

---

## 12. campus_news — University News & Announcements

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| RSS/Atom Feeds | Various universities | University news, announcements | Free | Most university websites publish RSS feeds. Parse with Dart `xml` or `webfeed` package. |
| NewsAPI | NewsAPI.org | News articles by keyword, source | Free: 100 req/day (dev); Paid from $449/mo | Search news by keyword (e.g., "UDSM", "university Tanzania"). 150K+ sources. |
| GNews API | GNews | Google News aggregation | Free: 100 req/day; Paid from $84/mo | Filter by country (Tanzania), category (education). |
| Bing News Search API | Microsoft | News search with filters | Free: 1K calls/mo; Paid from $1/1K | Part of Azure Cognitive Services. Filter by market, category. |
| TCU Website | TCU (tcu.go.tz) | University accreditation news, admissions | Free (web scraping) | No API. Scrape public notices and admission guidebooks. |

**Tanzania context:** Scrape RSS feeds from UDSM, SUA, UDOM, Ardhi, MUHAS, DIT, etc. TCU publishes admission cycles and accreditation updates. Build custom scraper for Tanzania university news aggregation.

---

## 13. study_groups — Collaborative Learning

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| TAJIRI Groups (internal) | TAJIRI | Group management, already built | N/A | Leverage existing TAJIRI groups infrastructure. Add education-specific features. |
| Google Classroom API | Google | Course roster, group management | Free | Student groups within courses. Shared materials. |
| Firebase Realtime Database | Google | Real-time collaboration, shared state | Free: 1GB stored, 10GB/mo transfer | Already in TAJIRI stack. Good for real-time study session state. |
| Firebase Firestore | Google | Structured data, real-time sync | Free tier generous | Already used by TAJIRI for live updates. Model study group activities. |
| Miro API | Miro | Collaborative whiteboard | Free: 3 boards; Paid from $8/user/mo | Visual collaboration for study sessions. REST API available. |

**Recommendation:** Use TAJIRI's existing groups + Firebase infrastructure. No external API needed for core functionality.

---

## 14. career — Job Search & Career

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| BrighterMonday | BrighterMonday Tanzania | Tanzania's #1 job board | No public API | 276+ job offers. Part of Ringier One Africa Media. Would need partnership or scraping. |
| Ajira Portal | PSRS Tanzania | Government/public sector jobs | No public API | Portal at ajira.go.tz. Managed by Public Service Recruitment Secretariat. Scraping possible. |
| Indeed Job Sync API | Indeed | Job search, salary data | Partner program (free for ATS) | GraphQL API. 6-week integration timeline. Requires partnership agreement. |
| LinkedIn Job Posting API | LinkedIn/Microsoft | Job postings, applications | Paid (Talent Solutions license) | Requires LinkedIn Talent Solutions subscription. Limited to partners. |
| Adzuna API | Adzuna | Job search aggregation, salary data | Free tier available (API key required) | 12 countries supported. Tanzania NOT currently covered. Good for international job search. |
| JSearch API (RapidAPI) | OpenWeb Ninja | Aggregated job search (Indeed, LinkedIn, etc.) | Free: 200 req/mo; Paid from $30/mo | Aggregates from multiple job boards. Good for MVP. |
| RemoteOK API | RemoteOK | Remote job listings | Free (JSON feed) | Remote jobs only. Good for tech/remote-friendly roles. No API key needed. |
| Arbeitnow API | Arbeitnow | Remote/flexible job listings | Free (JSON feed) | Simple JSON endpoint. No authentication required. |

**Tanzania context:** BrighterMonday Tanzania and Ajira Portal have NO public APIs. For Tanzania-specific jobs, build a scraper for BrighterMonday, Ajira, Mabumbe, and Zoom Tanzania. For international/remote jobs, use Adzuna or JSearch APIs.

---

## Summary: Tanzania-Specific API Availability

| Service | Has API? | Access Method | Status |
|---------|----------|---------------|--------|
| NECTA (National Exams) | Unofficial only | Community Python package (`nectaapi`) | Scrapes HTML; fragile |
| HESLB (Student Loans) | No | Web portal (olas.heslb.go.tz) | No programmatic access |
| TCU (Universities Commission) | No | Web portal (tcu.go.tz) | PDF guidebooks, no API |
| NACTE/NACTVET (Technical Ed) | No | Web portal (nacte.go.tz) | No programmatic access |
| M-Pesa (Vodacom TZ) | Yes | REST API with sandbox | Open to developers |
| BrighterMonday TZ | No | Web scraping | No public API |
| Ajira Portal | No | Web scraping | Government portal |
| University Portals (ARIS/SARIS) | No | Per-institution | Each university separate |

## Recommended API Stack by Priority

### Must-Have (Core Functionality)
1. **Anthropic Claude API** — AI tutoring (newton), flashcard generation (exam_prep)
2. **M-Pesa API** — Fee payments (fee_status)
3. **Google ML Kit** — On-device OCR for notes (class_notes) — free
4. **Open Library + Google Books API** — Book search (library) — free
5. **Open Trivia DB** — Quiz questions (exam_prep) — free

### High Value (Enhanced Experience)
6. **Wolfram Alpha API** — Math step-by-step (newton) — 2K free calls/mo
7. **Google Classroom API** — LMS integration (my_class, assignments) — free
8. **CrossRef + Semantic Scholar** — Academic papers (library) — free
9. **Google Calendar API** — Timetable sync (timetable) — free
10. **NECTA unofficial API** — Exam results (results, past_papers) — free

### Nice-to-Have (Future Phases)
11. **JSearch / Adzuna API** — Job search (career)
12. **NewsAPI / GNews** — Campus news aggregation (campus_news)
13. **Canvas/Moodle API** — Advanced LMS (my_class, assignments)
14. **Flutterwave API** — Payment aggregation (fee_status)
