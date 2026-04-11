# TIRA (Tanzania Insurance Regulatory Authority) — Feature Description

## Tanzania Context

TIRA is the government body that regulates the insurance industry in Tanzania under the Insurance Act, 2009. It oversees all insurance companies, brokers, agents, loss adjusters, and actuaries operating in the country.

**What TIRA Does:**
- Licenses and supervises insurance companies, brokers, and agents
- Protects insurance consumers through complaint resolution
- Sets minimum insurance rates (especially motor vehicle insurance)
- Maintains a public register of all licensed insurance market players
- Publishes consumer education materials on insurance rights
- Investigates insurance fraud

**How Citizens Interact:**
- Verifying that an insurance company or broker is legitimately licensed
- Filing complaints when an insurer refuses to pay a valid claim
- Checking if a motor vehicle insurance sticker/policy is genuine (massive problem)
- Understanding what their insurance policy covers
- Reporting suspected insurance fraud
- Checking approved premium rates before buying insurance

**Current Pain Points:**
- **Fake insurance is epidemic** — Thousands of vehicles in Tanzania carry forged motor vehicle insurance stickers. Drivers discover they're uninsured only after an accident. Fake brokers sell "policies" that don't exist in any insurer's system
- **Claims denial** — Insurers frequently deny claims on technicalities. Most policyholders don't understand their policy terms and have no easy way to challenge denials
- **Complaint process is opaque** — Filing a complaint with TIRA requires letters, forms, and physical visits. Most people give up
- **No real-time verification** — Police, traffic officers, and citizens cannot instantly verify if a vehicle's insurance is genuine
- **Broker trust issues** — Hard to distinguish legitimate insurance agents from fraudsters
- **Low insurance penetration** — Only ~1.5% of Tanzanians have insurance due to mistrust and complexity

## International Reference Apps

1. **NAICOM (Nigeria)** — National Insurance Commission portal with insurer directory, complaint portal, and policy verification
2. **IRA Kenya** — Insurance Regulatory Authority of Kenya with licensed companies register, complaint filing, and consumer education
3. **IRDA (India)** — Insurance Regulatory and Development Authority with Bima Sugam platform for policy verification, grievances, and product comparison
4. **FSCA (South Africa)** — Financial Sector Conduct Authority with online complaint system, licensed FSP register, and consumer education portal
5. **PolicyBazaar (India)** — Commercial app that lets users compare insurance products, verify policies, and file claims — a model for consumer-facing insurance tools

## Feature List

1. **Licensed Insurers Directory** — Complete searchable list of all TIRA-licensed insurance companies with contact details, branches, products offered, financial strength ratings, and complaint history
2. **Policy Verification** — Enter policy number and insurer name to verify if an insurance policy is genuine and active. Critical for motor vehicle insurance — scan or enter sticker number to check authenticity
3. **Broker/Agent Verification** — Check if an insurance broker or agent is licensed by TIRA. View their licence number, authorized insurers, and any disciplinary history
4. **File Complaint** — Submit a complaint against an insurance company with policy details, claim reference, complaint category (claim denial, delay, mis-selling, fraud), and supporting documents
5. **Complaint Tracking** — Track complaint status with reference number. View timeline, TIRA responses, and resolution outcome
6. **Insurance Rights Guide** — Plain-language guide to policyholder rights under Tanzanian law. Covers: what insurers must disclose, claim timelines, unfair terms, and cancellation rights
7. **Premium Rate Reference** — TIRA-approved minimum and maximum premium rates by insurance type. Helps consumers spot underpriced policies (likely fake) or overpriced ones
8. **Product Comparison** — Compare insurance products across licensed insurers by coverage, premium, exclusions, and claim settlement ratio
9. **Fraud Reporting** — Report suspected insurance fraud — fake policies, unlicensed brokers, staged accidents. Anonymous reporting option
10. **Claims Dispute Guide** — Step-by-step guide for disputing a denied claim. Templates for complaint letters. Escalation path from insurer to TIRA to courts
11. **Consumer Education** — Articles and videos explaining insurance basics: types of cover, how to read a policy, what to do after an accident, why insurance matters
12. **Motor Vehicle Insurance Scanner** — Camera-based scanner that reads insurance sticker details and verifies against TIRA database in real-time
13. **Insurance Calculator** — Estimate insurance premium for motor vehicle, health, property, and life insurance based on basic parameters
14. **Insurer Performance Dashboard** — Complaint resolution rates, claim settlement ratios, and consumer satisfaction scores per insurer
15. **Renewal Reminders** — Set reminders for policy renewal dates. Push notification before expiry

## Key Screens

- **Home Dashboard** — Quick verify policy, find licensed insurer, file complaint
- **Verify Policy** — Input policy/sticker number with verification result (genuine/fake/expired)
- **Insurers Directory** — Searchable, filterable list of licensed companies
- **Broker Lookup** — Search for broker/agent with licence status
- **Complaint Form** — Multi-step form with policy details, complaint type, evidence upload
- **My Complaints** — Complaint list with status tracking
- **Insurance Guide** — Educational content organized by insurance type
- **Compare Products** — Side-by-side product comparison table

## TAJIRI Integration Points

- **Wallet (WalletService)** — Pay insurance premiums directly via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Premium comparison payments when purchasing through TAJIRI. Complaint filing fees (if any) processed through wallet. Transaction history via `WalletService.getTransactions()` shows all insurance-related payments with policy references
- **Car Insurance Module (car_insurance/)** — Deep link from TAJIRI car insurance module for policy verification — scan sticker or enter policy number to verify authenticity. Licensed insurer directory powers provider selection during quote comparison. Premium rate reference used to detect underpriced (likely fake) or overpriced policies. Fraud reporting integration from claim filing flow. Insurer performance dashboard (claim settlement ratios, complaint history) displayed during provider comparison. Product comparison data feeds into insurance quote screens
- **My Cars Module (my_cars/)** — Auto-verify vehicle insurance when adding a car to TAJIRI garage — policy number checked against TIRA database. Insurance verification status displayed on vehicle dashboard (verified/unverified/fake/expired). Insurance expiry alerts triggered from vehicle document tracking. Motor vehicle insurance scanner accessible from vehicle profile
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: policy expiry reminders at 60/30/14/7 days before, complaint status updates (submitted, under review, resolved), fraud alert warnings for reported fake policies, TIRA regulation changes affecting policyholders, insurer performance report updates, premium rate publication alerts, renewal reminder with comparison option
- **Groups (GroupService)** — Insurance discussion groups via `GroupService.createGroup()` — share experiences with insurers, claim resolution stories, broker recommendations. Provider-specific groups. Consumer rights awareness groups. Group posts via `GroupService.getGroupPosts()` for insurance advice and fraud warnings
- **Messaging (MessageService)** — Receive complaint resolution updates via `MessageService.sendMessage()`. TIRA officer communication for escalated complaints. Broker/agent communication channel. Auto-created conversation per complaint for correspondence tracking
- **Profile (ProfileService)** — Licensed broker/agent badge for verified insurance professionals via `ProfileService.getProfile()`. TIRA licence number and authorized insurers displayed on broker profile. Disciplinary history visible. Consumer insurance literacy badges for educated policyholders
- **Posts & Stories (PostService + StoryService)** — Share insurance fraud alerts via `PostService.createPost()` to warn community. Claim resolution stories. Consumer education content shared to feed. Insurer review posts with ratings. Fraud awareness campaigns via `StoryService.createStory()`
- **Location (LocationService)** — Nearest TIRA office finder via `LocationService.searchLocations()` using Tanzania hierarchy. Licensed broker/agent location search. Insurer branch locations on map
- **Calendar (CalendarService)** — Policy expiry dates synced to calendar via `CalendarService.createEvent()`. Complaint follow-up deadlines. Renewal comparison shopping reminders. TIRA hearing dates for escalated complaints
- **Media (PhotoService)** — Insurance sticker photos for scanner verification via `PhotoService.uploadPhoto()`. Complaint evidence photos. Policy document photo storage. Fraud evidence documentation
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time complaint status changes. Policy verification results pushed in real-time. Fraud alert broadcasts
- **People Search (PeopleSearchService)** — Find licensed brokers and agents by location and specialization via `PeopleSearchService.search()`. Verify broker credentials before engaging. Mutual friends who used same broker for trust building
- **Insurance Module (insurance/)** — Broader insurance products beyond motor — health, property, life, travel. TIRA verification applicable across all insurance types. Licensed insurer directory shared across all insurance sub-modules
- **Ambulance Module (ambulance/)** — Insurance coverage verification during emergency dispatch. NHIF and private insurance check integrated with TIRA database for policy authenticity. Pre-authorization for insured ambulance transport
- **Content Discovery (ContentEngineService)** — Insurance education content personalized based on user's insurance status via `ContentEngineService`. Consumer rights information pushed to uninsured users. Policy comparison recommendations
- **Analytics (EventTrackingService)** — Track complaint resolution rates per insurer. Policy verification frequency analytics. Consumer education engagement metrics. Fraud reporting patterns

## Available APIs

- **TIRA Portal** — tira.go.tz provides insurer directory and some forms (no documented public API)
- **TIRA Motor Insurance Database** — Internal database for policy verification (would need partnership/MOU for access)
- **IRA Kenya IMIS** — Reference for insurance market information system architecture
- **NAICOM API (Nigeria)** — Reference for policy verification endpoint design
- TAJIRI backend will need MOU with TIRA for policy verification access and complaint submission integration
