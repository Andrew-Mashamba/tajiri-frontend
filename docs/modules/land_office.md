# Ardhi (Land/Property Services) — Feature Description

## Tanzania Context

Land is the single most contentious issue in Tanzania. The Ministry of Lands, Housing, and Human Settlements Development oversees land management. All land in Tanzania is public land vested in the President as trustee, and citizens hold rights of occupancy rather than outright ownership.

**Land tenure system:**
- **General Land** — Administered by Commissioner for Lands, urban and peri-urban areas
- **Village Land** — Administered by Village Councils under Village Land Act 1999, rural areas (~70% of all land)
- **Reserved Land** — National parks, forests, game reserves, etc.
- **Right of Occupancy** — Granted (99 years max) or Deemed (customary, no time limit)
- **Certificate of Customary Right of Occupancy (CCRO)** — For village land, issued by Village Council
- **Title Deed (Hati ya Kumiliki Nyumba/Ardhi)** — For general land, issued by Commissioner for Lands

**Current reality:**
- Only ~10% of land in Tanzania is formally titled or registered
- Land disputes make up 60%+ of all court cases in Primary and District Courts
- Average time to get a title deed: 6-24 months (officially should be weeks)
- Land offices severely understaffed, files physically stored in deteriorating conditions
- Double allocation of plots is common — same plot issued to multiple people
- Boundary disputes rampant due to poor surveying and missing beacons
- Women's land rights poorly protected despite legal provisions
- Land grabbing by powerful individuals/companies affects smallholders and pastoralists
- Urban plot prices have skyrocketed — fraud in land transactions is epidemic
- Village land increasingly converted to general land without proper compensation
- Squatter settlements (informal) house millions who have no formal tenure

**Key pain points:**
- Verifying whether someone actually owns a plot before purchase is extremely difficult
- Fake title deeds are sophisticated and common — verification requires visiting land office
- Survey fees and procedures are expensive and time-consuming
- Land offices demand bribes to process routine applications
- Transfer of ownership requires 10+ steps across multiple offices
- Inheritance of land (especially for women) contested despite clear law

## International Reference Apps

1. **HM Land Registry (UK)** — Search property ownership, download title plans, check for restrictions, register land. Complete digital land registry with 25M+ titles.
2. **Zillow/Redfin (US)** — Property search with ownership info, price history, neighborhood data, zoning info. Consumer-facing property intelligence.
3. **PropertyGuru (Southeast Asia)** — Property listings with land title verification, market analytics, mortgage calculator.
4. **eCitizen Land Search (Kenya)** — Kenya land registry search: verify title, check encumbrances, track application status.
5. **ILIS (Rwanda)** — Integrated Land Information System: search parcels, verify ownership, submit applications. Rwanda model for Africa.

## Feature List

1. **Title/Plot Search** — Search by plot number, location, or owner name to check registered ownership status
2. **Title Verification** — Verify a title deed or CCRO authenticity using certificate number or QR code
3. **Ownership History** — View ownership transfer history for a specific plot (chain of title)
4. **Plot Map Viewer** — Interactive map showing surveyed plots, boundaries, and ownership status
5. **Application Tracking** — Track land-related applications: title deed, transfer, subdivision, change of use
6. **Land Purchase Checklist** — Step-by-step guide for safely buying land: what to verify, documents needed, red flags to watch
7. **Transfer of Ownership Guide** — Complete process for transferring land title: documents, offices, fees, timeline
8. **Fee Calculator** — Calculate government fees: stamp duty (1% buyer, 1% seller), registration fees, survey fees, valuation fees
9. **Surveyor Directory** — Find licensed land surveyors by location with qualifications, fees, and ratings
10. **Lawyer Directory (Land)** — Land transaction lawyers with specialization, fees, and verification
11. **Fraud Alert System** — Report suspected land fraud, check if a plot has been flagged, community warnings
12. **Village Land (CCRO)** — Guide to obtaining Certificate of Customary Right of Occupancy: Village Council process, district approval
13. **Land Laws Reference** — Searchable Land Act 1999, Village Land Act 1999, Land Registration Act, Urban Planning Act with plain-language summaries
14. **Women's Land Rights** — Dedicated section on women's land ownership rights, matrimonial property, inheritance, and how to protect them
15. **Dispute Resolution Guide** — Options for land disputes: Village Land Council, Ward Tribunal, District Land and Housing Tribunal, High Court Land Division
16. **Development Conditions** — Check building/development conditions attached to a plot: zoning, setbacks, building permits
17. **Valuation Service** — Request property valuation or check recent valuations in an area for fair market price estimation
18. **Land Conversion** — Process for converting village land to general land, change of use applications
19. **Mortgage Information** — Which banks offer land/property mortgages, requirements, interest rates, CCRO as collateral
20. **Land Office Finder** — Map of District Land Offices, Zonal Land Offices, and Ministry offices with hours and contacts
21. **Complaint System** — Report corruption, delays, or irregularities at land offices with tracking

## Key Screens

- **Home** — Search bar, quick verification, recent searches, fraud alerts banner
- **Search Results** — Plot details: number, location, registered owner, encumbrances, map view
- **Title Verification** — Enter certificate number, see verification result with ownership details
- **Plot Map** — Interactive map with plot boundaries, ownership indicators, nearby infrastructure
- **Purchase Guide** — Step-by-step wizard with checklist, red flags, and document requirements
- **Application Tracker** — Status timeline for land applications with office and officer info
- **Fee Calculator** — Input transaction details, see itemized government fees breakdown
- **Professional Directory** — Surveyors and lawyers with map view, filters, and contact options
- **Land Laws** — Browseable legal reference with search and bookmarks
- **Women's Rights** — Information cards, real cases, legal protections, where to get help
- **Dispute Guide** — Decision tree for choosing appropriate dispute resolution forum
- **Office Finder** — Map with land offices, distances, services, and contacts

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for stamp duty (1% buyer + 1% seller), registration fees, survey fees, and valuation fees; `getTransactions()` for payment receipts and transfer fee records
- **MessageService** — `sendMessage()` for connecting with licensed surveyors and land lawyers; `getConversations()` for tracking ongoing land transaction communications
- **NotificationService + FCMService** — Push alerts for application status updates, fraud alerts in your area, fee payment reminders, title deed readiness notifications
- **LiveUpdateService** — Real-time application status tracking via Firestore (Submitted > Surveyed > Verified > Registered)
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()`, `getStreets()` for GPS-based plot location identification, land office finder, surveyor proximity search
- **ProfileService** — `getProfile()` for verified land owner badge on TAJIRI platform; owner identity verification during transactions
- **PhotoService** — `uploadPhoto()` for title deed scans, survey plans, sale agreement documents, beacon photos, property condition evidence
- **CalendarService** — `createEvent()` for application tracking deadlines, court hearing dates for disputes, survey appointment dates
- **LocalStorageService** — Offline caching of land purchase checklists, fee calculators, land law reference, fraud prevention guides
- **MediaCacheService** — Cache title deed scans, survey plans, and sale agreements for secure offline access
- **GroupService** — `createGroup()` for neighborhood and plot-owner communities; `joinGroup()` for shared land issue coordination
- **PostService** — `createPost()` for sharing fraud alerts, land office updates, market price trends
- **EventTrackingService** — Analytics on land transaction volumes, fraud report patterns, dispute resolution rates
- **PeopleSearchService** — Search by location for finding neighbors, previous plot owners for due diligence
- **Cross-module: housing/** — Property listings linked to verified land titles; housing module shows title verification status
- **Cross-module: lawyer/** — Land transaction lawyers directory; dispute resolution legal representation
- **Cross-module: legal_gpt** — AI-powered land law questions (Land Act 1999, Village Land Act 1999), document review, dispute advice, women's land rights guidance
- **Cross-module: nida** — Identity verification for ownership checks and property transfer processes
- **Cross-module: rita** — Death certificates needed for inheritance-based land transfers
- **Cross-module: brela** — Company land ownership verification linked to business registration
- **Cross-module: tra** — Stamp duty calculation and payment for property transfers; capital gains tax on land sales
