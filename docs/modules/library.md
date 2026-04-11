# Library / Maktaba — Feature Description

## Tanzania Context

Libraries in Tanzanian educational institutions face chronic challenges that severely limit student access to knowledge:

- **Physical book scarcity** — University libraries have limited copies of core textbooks. At UDSM, a recommended textbook might have 5 copies for 500 students. "First come, first served" means most students never access physical books
- **Photocopying culture** — Since books can't be borrowed for long, students photocopy relevant chapters. Photocopy shops near campus charge TZS 50-100 per page, making a full textbook prohibitively expensive
- **E-library access** — Some universities subscribe to databases like JSTOR, Emerald, or SpringerLink, but students don't know how to access them. VPN/proxy setup is confusing, and access often doesn't work on mobile devices
- **Internet challenges** — University Wi-Fi is unreliable. Downloading a 50MB PDF on campus can take 30+ minutes. Students with personal data bundles have an advantage
- **Library hours** — Physical libraries typically close at 9-10 PM. During exam season, demand for seats far exceeds capacity. Some students arrive at 6 AM to secure a spot
- **Research papers** — Undergraduate students struggle to find and access research papers for dissertations. Sci-Hub is widely used despite being technically illegal
- **Local content gap** — Tanzanian-authored textbooks and research papers are hard to find digitally. Most content is imported and expensive
- **Citation struggles** — Students don't know how to properly cite sources. Many have never used a citation manager
- **Open Educational Resources (OER)** — Free textbooks and materials exist (OpenStax, MIT OCW) but awareness is very low among Tanzanian students

## International Reference Apps

1. **Libby (OverDrive)** — Digital library borrowing with beautiful reading interface, offline downloads, annotation, library card integration. Modern library experience.
2. **Google Scholar** — Academic paper search, citation tracking, library links, author profiles, related articles. Essential research tool.
3. **JSTOR** — Academic journal access, primary sources, ebook library, workspace for annotations. Premium academic database.
4. **Z-Library** — Large e-book repository with search, download, format conversion. Controversial but massively popular with students globally.
5. **Mendeley** — Reference manager, PDF annotation, research discovery, collaboration, citation generation. Academic workflow tool.

## Feature List

1. E-book catalog: searchable library of digital textbooks, reference books, and study guides
2. Search by title, author, subject, ISBN, or keyword with smart suggestions
3. Browse by category: Sciences, Arts, Engineering, Medicine, Law, Business, Education, Agriculture
4. Course-linked reading lists: recommended books per course/subject from lecturers
5. Borrow/download e-books with time-limited access (simulating library borrowing)
6. Offline reading: download books for reading without internet
7. In-app reader with adjustable font size, night mode, bookmarks, highlights, and notes
8. Research paper search: find academic papers by topic, author, or journal
9. Open Access papers: curated collection of free-to-access research papers
10. Citation generator: select citation style (APA, MLA, Harvard, Chicago) and auto-generate citation
11. Reading list management: create and organize personal reading lists by course
12. Library card QR code: digital version of physical library card for campus library access
13. Physical library information: hours, location map, available services, contact
14. Book availability checker: see if a physical book is available at your campus library
15. Request books: suggest books for the library to acquire (digital or physical)
16. Reading progress tracker: percentage completed, time spent reading, pages per session
17. Book reviews and ratings: student reviews to help others choose useful books
18. Share books: recommend books to classmates via TAJIRI messaging
19. Audiobook section: audio versions of popular textbooks for learning on the go
20. OER collection: curated free textbooks from OpenStax, MIT OCW, and other open sources
21. Dissertation repository: browse completed dissertations from your institution
22. Book club feature: join reading groups for supplementary reading
23. Recently added: feed of newly available books and papers

## Key Screens

- **Library Home** — Search bar, featured books, course reading lists, recently viewed, categories
- **Book Detail** — Cover, title, author, description, reviews, borrow/download button, citation
- **E-Reader** — Full-screen reading view with toolbar (font, brightness, bookmark, highlight, notes)
- **Search Results** — Filtered list with cover thumbnails, relevance sorting, format indicators
- **My Bookshelf** — Downloaded and borrowed books with reading progress indicators
- **Reading Lists** — Course-organized lists with completion checkboxes
- **Research Papers** — Academic paper search with abstract preview, citation count, access type
- **Citation Generator** — Select papers/books, choose style, copy or export citations
- **Physical Library** — Campus library map, hours, book availability, QR card
- **Book Request** — Form to suggest new acquisitions with justification

## TAJIRI Integration Points

- **PostService.createPost() / sharePost()** — Share reading lists, book recommendations, and reviews to the TAJIRI feed
- **MessageService.sendMessage()** — Share book recommendations with friends via TAJIRI chat
- **WalletService.deposit(amount, provider:'mpesa')** — Purchase premium e-books or extended borrowing via TAJIRI wallet
- **ProfileService.getProfile()** — Reading stats (books read, pages, streaks) displayed on TAJIRI profile
- **CalendarService.createEvent()** — Library hours, book return deadlines, and book club sessions synced to calendar
- **GroupService.createGroup()** — Book clubs as TAJIRI groups with integrated chat and shared reading lists
- **PhotoService.uploadPhoto()** — Upload photos of physical book pages for note-taking and sharing
- **class_notes module** — Highlights from books can be exported to class notes repository
- **newton module** — "Explain this passage" from within the e-reader sends text to Newton for AI explanation
- **assignments module** — Reading lists linked to assignments; cite books directly in assignment work
- **study_groups module** — Book clubs and shared reading lists within study groups
- **my_class module** — Lecturer-assigned reading lists appear in class library section
- **past_papers module** — Link recommended textbook chapters to past paper topics
- **career module** — Professional development books and career-related reading lists
