# LegalGPT — Feature Description

## Tanzania Context

Legal services in Tanzania are expensive and inaccessible to the majority. The Tanzania Law Society (TLS) has approximately 10,000 registered advocates for a population of 65+ million. Most lawyers practice in Dar es Salaam, Arusha, and Mwanza, leaving rural areas severely underserved.

**Legal landscape:**
- Court system: Primary Courts (Mahakama za Mwanzo) > District Courts > High Court > Court of Appeal
- Primary Courts handle most civil disputes, land cases, and minor criminal matters; no lawyers allowed in primary courts
- Land disputes are the single biggest legal issue — estimated 60%+ of all court cases
- Family law (inheritance, marriage, divorce) governed by multiple overlapping systems: customary law, Islamic law, statutory law
- Employment disputes common but workers rarely know their rights under the Employment and Labour Relations Act 2004
- Tenant-landlord disputes rampant in cities, governed by Rent Restriction Act (outdated)
- Small business owners need contracts but can't afford lawyers (simple contract: TZS 200,000-500,000)
- Legal aid organizations exist (TAWLA, Legal Aid Committee of TLS, LHRC) but are overwhelmed

**Pain points:**
- 80%+ of Tanzanians cannot afford a lawyer
- Citizens don't know their basic legal rights
- Legal documents in English; most citizens need Swahili explanations
- No accessible guide to court procedures — people fear courts
- Contract templates unavailable — people rely on verbal agreements
- Inheritance disputes tear families apart due to ignorance of succession laws
- Workers exploited because they don't know employment law protections
- Police arrest procedures poorly understood — citizens don't know their rights

## International Reference Apps

1. **DoNotPay (US/UK)** — AI lawyer for consumer rights: fight parking tickets, cancel subscriptions, draft legal letters, small claims court filing. Automated dispute resolution.
2. **LegalZoom (US)** — Document templates (LLC formation, wills, trademarks, contracts), lawyer marketplace, legal advice subscriptions.
3. **Harvey AI (US)** — AI legal assistant for lawyers: research, drafting, analysis. Built on GPT-4.
4. **Rocket Lawyer (US/UK)** — Free legal documents, ask-a-lawyer service, business formation, affordable legal plans.
5. **Haqdarshak (India)** — AI-powered platform helping low-income citizens discover and access government schemes and legal entitlements.

## Feature List

1. **Ask Legal Questions** — AI chatbot answering legal questions in Swahili and English, citing relevant Tanzanian laws and providing practical advice
2. **Know Your Rights Cards** — Visual cards explaining fundamental rights: arrest rights, worker rights, tenant rights, women's rights, children's rights, land rights
3. **Document Templates** — Downloadable/fillable templates: employment contracts, rental agreements, sale agreements, power of attorney, wills, business contracts, demand letters
4. **Court Procedures Guide** — Step-by-step guides for filing cases in Primary Court, District Court, and High Court with fees, forms, and timelines
5. **Legal Dictionary** — Swahili-English legal terms glossary with plain-language definitions
6. **Lawyer Directory** — Find lawyers by specialization (land, family, criminal, corporate, immigration) and location, with ratings and fee ranges
7. **Legal Aid Finder** — Locate free legal aid services: TAWLA, LHRC, TLS Legal Aid, Paralegal centers, university law clinics
8. **Land Law Guide** — Comprehensive guide to land ownership, Village Land Act, Urban Land Act, title deeds, customary rights of occupancy, dispute resolution
9. **Employment Law Assistant** — Workers' rights: minimum wage, working hours, leave entitlements, termination procedures, NSSF/WCF obligations, complaint filing
10. **Family Law Guide** — Marriage, divorce, child custody, inheritance under statutory/customary/Islamic law, maintenance obligations
11. **Tenant Rights** — Rental law guide: lease requirements, eviction procedures, rent increases, deposit rules, dispute resolution
12. **Business Law Basics** — Legal requirements for starting and running a business: registration, licenses, tax obligations, compliance
13. **Police & Arrest Guide** — What to do when arrested: rights during arrest, bail procedures, police complaint mechanisms, legal representation
14. **Consumer Rights** — Product returns, fraud reporting, TCRA complaints, unfair contract terms, warranty rights
15. **Document Review** — Upload contracts or legal documents for AI-powered review highlighting risky clauses and missing protections
16. **Case Tracker** — Track your court case status by case number across all court levels
17. **Legal News** — New laws, court decisions, legal reforms, and regulatory changes affecting citizens
18. **Emergency Legal Hotline** — Quick connect to on-call lawyers for urgent matters (arrests, evictions, domestic violence)
19. **Mediation Services** — Connect with registered mediators for out-of-court dispute resolution
20. **Document Notarization** — Find notary publics and commissioners for oaths near you

## Key Screens

- **Chat Interface** — AI conversation with legal assistant, supporting text and voice input in Swahili/English
- **Rights Cards** — Swipeable cards organized by category with illustrations and key points
- **Document Templates** — Template browser with preview, fill-in wizard, and download/share
- **Court Guide** — Step-by-step procedure screens with timeline, fees, and forms per court type
- **Lawyer Search** — Map and list view of lawyers with filters (specialization, location, price, rating)
- **Legal Aid Map** — Map of free legal aid centers with services offered and contact info
- **Topic Guides** — Deep-dive articles on land, employment, family, tenant, business law
- **Document Upload** — Camera/file upload for contract review with AI-annotated results
- **Case Tracker** — Case number input, court selection, status display with hearing dates
- **Emergency** — One-tap emergency legal contacts and nearest police station/court

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for premium legal consultations; `transfer()` for lawyer fees and document notarization payments
- **MessageService** — `sendMessage()` for encrypted legal conversations with lawyers; `getConversations()` for tracking ongoing legal consultations
- **GroupService** — `createGroup()` for legal discussion communities (land owners, tenants, workers); `joinGroup()` for citizens seeking peer legal support
- **PostService** — `createPost()` for sharing legal news, new laws, court decisions; `sharePost()` for distributing Know Your Rights content
- **NotificationService + FCMService** — Push alerts for case hearing dates, legal deadline reminders, new law alerts, and regulatory changes
- **CalendarService** — `createEvent()` for court hearing date reminders, filing deadlines, statute of limitations tracking
- **PhotoService** — `uploadPhoto()` for contract/document uploads for AI-powered review
- **ProfileService** — `getProfile()` for lawyer verified profiles with specialization, ratings, and fee ranges
- **LocalStorageService** — Offline caching of core legal rights content, Know Your Rights cards, court procedures, and legal dictionary
- **MediaCacheService** — Cache document templates for offline access in areas with poor connectivity
- **EventTrackingService** — Analytics on most-asked legal topics, document template usage, lawyer connection rates
- **Cross-module: katiba** — Cross-reference constitutional provisions (Articles 12-29 Bill of Rights) when explaining citizen rights
- **Cross-module: lawyer/** — Lawyer directory integration; emergency legal hotline connects to lawyer/ module professionals
- **Cross-module: barozi_wangu** — Explain ward-level governance processes and citizen rights in local government
- **Cross-module: ofisi_mtaa** — Guide on rights when dealing with Mtaa office services and fee disputes
- **Cross-module: nida** — Identity verification for legal document authentication; explain NIDA rights
- **Cross-module: rita** — Birth/death/marriage certificate guidance for inheritance and family law cases
- **Cross-module: tra** — Tax dispute guidance and assessment objection assistance
- **Cross-module: brela** — Business law guidance linking to BRELA registration, director liabilities, compliance
- **Cross-module: land_office** — Land law questions, title deed verification guidance, dispute resolution options
- **Cross-module: business/** — Business law basics integrated with TAJIRI entrepreneur features
- **Cross-module: all government tabs** — LegalGPT can explain processes and citizen rights for every government service module
