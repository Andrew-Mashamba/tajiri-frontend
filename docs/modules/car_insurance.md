# Car Insurance — Feature Description

## Tanzania Context

Car insurance in Tanzania is regulated by TIRA (Tanzania Insurance Regulatory Authority). Third-party motor vehicle insurance is mandatory by law for all vehicles on public roads, yet compliance rates remain low — estimated at 40-50% of vehicles, particularly outside major cities. The insurance penetration rate in Tanzania overall is among the lowest in Africa at roughly 0.5% of GDP.

Types of motor vehicle insurance available:
- **Third-Party Only (TPO)** — Mandatory minimum. Covers damage to other vehicles, property, and injury to third parties. Does not cover your own vehicle. Cheapest option.
- **Third-Party, Fire and Theft (TPFT)** — Covers third-party liabilities plus fire damage and theft of your own vehicle.
- **Comprehensive** — Full coverage including own damage, third-party, fire, theft, windscreen, and additional perils. Most expensive.

Major insurance providers in Tanzania:
- **NIC (National Insurance Corporation)** — State-owned, largest insurer, widely accessible
- **Jubilee Insurance** — Regional player (Kenya-headquartered), strong in East Africa
- **Britam Insurance (formerly Real Insurance)** — Growing market share, mobile-friendly
- **Heritage Insurance** — Well-established, competitive pricing
- **Alliance Insurance** — Comprehensive motor products
- **Sanlam Insurance** — South African parent company, professional claims process
- **NIKO Insurance** — Competitive in motor segment
- **Bumaco** — Burundian origin, growing in TZ
- **GA Insurance** — Strong motor portfolio
- **Strategis Insurance** — Digital-forward approach

Pain points: buying insurance requires visiting a broker's office physically, comparing quotes across providers is nearly impossible without calling each one, claims processes are slow and opaque (average motor claim takes 3-6 months), fake insurance stickers are a widespread problem, premium pricing is not transparent, renewal is cumbersome, and there is no easy way to verify if a policy is active.

Mobile money (M-Pesa, Tigo Pesa) is increasingly accepted for premium payments, but the purchase process itself remains largely offline. TIRA has been pushing for digitalization but adoption by insurers is uneven.

## International Reference Apps

1. **Jerry (USA)** — AI-powered insurance comparison. Aggregates quotes from 50+ carriers in seconds, one-tap switching, policy management, claims filing, renewal reminders, savings tracking. No phone calls needed.

2. **Lemonade (USA/Global)** — Digital-first insurance. AI chatbot for quotes and claims, instant policy issuance, claims paid in seconds via AI, transparent pricing, social impact model (unclaimed premiums go to charity).

3. **Root Insurance (USA)** — Telematics-based pricing. Uses phone sensors to assess driving behavior, safe drivers get lower rates, app-based everything, instant ID cards, simple claims process.

4. **Naked Insurance (South Africa)** — AI-driven insurance for Africa. Instant online quotes, month-to-month policies (no annual lock-in), claims via app, transparent pricing breakdown, excess buydown options.

5. **M-TIBA / Bima (Kenya/Tanzania)** — Mobile-first micro-insurance. USSD-based purchase, M-Pesa payment, simple product design for low-income users, claims via mobile, partnership with telcos.

## Feature List

### Quote Comparison
1. Instant quote comparison from 10+ Tanzanian insurance providers
2. Input vehicle details once — get multiple quotes simultaneously
3. Side-by-side comparison of coverage, premiums, excesses, and exclusions
4. Filter by coverage type (TPO, TPFT, Comprehensive)
5. Sort by price, coverage level, provider rating, or claims satisfaction
6. Highlight best value and most comprehensive options
7. Vehicle value assessment tool for comprehensive coverage calculation
8. Discount indicators (no-claims bonus, anti-theft device, safe parking)
9. Add-on comparison (windscreen, political violence, accessories, personal accident)
10. Save and compare quotes over time to track price trends

### Purchase & Binding
11. Complete policy purchase within the app — no branch visit required
12. Digital KYC (Know Your Customer) with NIDA ID verification
13. Vehicle details auto-populated from TAJIRI My Cars module
14. Payment via M-Pesa, Tigo Pesa, Airtel Money through TAJIRI Wallet
15. Installment payment options (monthly, quarterly for comprehensive policies)
16. Instant digital insurance certificate generation
17. TIRA policy verification — confirm policy is registered with regulator
18. E-sticker delivery or pickup scheduling for physical sticker
19. Policy effective date selection (immediate or future start)
20. Gift insurance — purchase for another person's vehicle

### Policy Management
21. Dashboard showing all active policies with status indicators
22. Policy document storage — certificate, terms, schedule, endorsements
23. Policy details view — coverage summary, premium breakdown, excess amounts
24. Renewal countdown with 60, 30, 14, 7 day reminders
25. One-tap renewal with option to switch providers
26. Policy amendment requests (change vehicle, add driver, update address)
27. No-claims discount tracking and certificate generation
28. Coverage calculator — understand exactly what is and isn't covered
29. Excess explanation — clear breakdown of what you pay in each claim scenario
30. Multi-vehicle policy management

### Claims Filing
31. File a claim directly in the app with guided step-by-step process
32. Accident scene photo upload (damage, location, other vehicle)
33. Police report reference number entry (OB number)
34. Accident diagram/sketch tool showing how the incident occurred
35. Third-party details capture (other driver, vehicle, insurance)
36. Witness information recording
37. Claim status tracking with real-time updates
38. Document upload for supporting evidence
39. Direct communication with claims assessor via in-app messaging
40. Claim history and settlement records
41. Garage authorization for approved repairs

### Documentation
42. Digital insurance card/certificate for police checks
43. QR code policy verification — police can scan to verify authenticity
44. Policy wording access — full terms and conditions
45. Premium payment receipts and history
46. Tax deduction certificates where applicable
47. Share policy documents via WhatsApp, email, or SMS

### Safety & Telematics (Future Phase)
48. Driving behavior monitoring via phone sensors (optional, for discounts)
49. Trip safety scoring with improvement tips
50. Speed alerts and harsh braking detection
51. Annual mileage tracking for low-mileage discounts
52. Dashcam integration for incident recording
53. Accident detection with automatic emergency alert

### Education & Transparency
54. Insurance jargon glossary in Swahili and English
55. Coverage explainer videos per policy type
56. FAQ section with Tanzania-specific insurance questions
57. Rights and obligations guide for policyholders
58. TIRA regulations summary for consumers
59. Insurance fraud awareness and reporting

## Key Screens

1. **Insurance Home** — Active policies overview, renewal alerts, quick actions
2. **Get Quotes** — Vehicle details input and multi-provider quote comparison
3. **Quote Comparison** — Side-by-side feature and price comparison grid
4. **Policy Purchase** — Checkout flow with payment and document generation
5. **Policy Details** — Full policy view with coverage, documents, and claim history
6. **File a Claim** — Step-by-step claim submission wizard
7. **Claim Tracker** — Active claims with status timeline and communication
8. **Documents** — All insurance documents organized by vehicle and policy
9. **Renewal Center** — Expiring policies with one-tap renewal or switch options
10. **Insurance Education** — Guides, FAQs, and glossary content

## TAJIRI Integration Points

- **Wallet (WalletService)** — Premium payments via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Installment payments (monthly, quarterly) for comprehensive policies processed through wallet. Claim payouts deposited directly to wallet via `WalletService.transfer()`. No-claims bonus refunds credited to wallet balance. Transaction history via `WalletService.getTransactions()` shows all premium payments, installments, and claim settlements. PIN verification via `WalletService.setPin()` for high-value claim payouts
- **My Cars Module (my_cars/)** — Auto-populate vehicle details (make, model, year, engine size, VIN) from registered vehicles for instant quote generation. Insurance status (active/expiring/expired) shown on vehicle dashboard with countdown timer. Policy documents stored alongside vehicle documents. Multiple vehicle policies managed from single interface. Insurance history travels with vehicle when sold
- **Service Garage Module (service_garage/)** — Authorized repair shops for insurance claims linked from claim filing flow. Garage authorization for approved repairs routed through verified garages. Repair cost estimates from garages attached to claim submissions. Panel beater and body shop recommendations for accident damage
- **Ambulance Module (ambulance/)** — Emergency services coordination after accident — auto-trigger ambulance from accident claim filing. Accident scene documentation (photos, location) shared between ambulance and insurance claim. Medical bills from emergency linked to insurance claim for health coverage
- **Messaging (MessageService)** — Direct communication with insurance agents via `MessageService.sendMessage()`. Claims assessor chat during claim processing with photo sharing. Quote clarification conversations with insurance providers. Auto-created conversation thread per active claim via `MessageService.createGroup()` linking policyholder, agent, and assessor
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: renewal reminders at 60/30/14/7 days before expiry, claim status updates (submitted, under review, approved, settled), policy confirmation after purchase, premium payment receipts, no-claims bonus notifications, TIRA policy verification results, installment due reminders
- **Buy Car Module (buy_car/)** — Insurance quote generation integrated into car purchase flow — get quotes while browsing vehicles. Pre-purchase insurance cost estimation factored into total cost of ownership calculator. Insurance binding during escrow purchase process. Transfer of existing policy to new vehicle
- **Sell Car Module (sell_car/)** — Insurance transfer or cancellation guidance during vehicle sale. Pro-rata premium refund calculation for cancelled policies. Insurance status verified before listing to build buyer confidence
- **Profile (ProfileService)** — Insured driver verification badge on TAJIRI profile via `ProfileService.getProfile()`. No-claims bonus years displayed. Driving record linked to insurance profile for telematics-based pricing
- **Groups (GroupService)** — Insurance community groups via `GroupService.createGroup()` for tips and provider reviews. Claim experience sharing within groups. Provider-specific discussion groups. Group posts via `GroupService.getGroupPosts()` for insurance advice
- **Posts & Stories (PostService + StoryService)** — Share insurance claim resolution stories via `PostService.createPost()`. Provider review posts with ratings. Insurance awareness content shared to feed
- **Loans Module (loans/ + kikoba/)** — Premium financing for comprehensive coverage through TAJIRI lending partners. Kikoba group insurance pools — savings groups collectively insure members' vehicles. Loan eligibility enhanced by active insurance coverage proof
- **TIRA Module (tira/)** — Deep integration for policy verification — scan sticker or enter policy number to verify authenticity against TIRA database. Licensed insurer directory for provider selection. Premium rate reference to detect over/under-priced policies. Fraud reporting for fake insurance stickers
- **Location (LocationService)** — Accident location capture via GPS during claim filing using `LocationService.searchLocations()`. Nearest authorized garage finder post-accident. Regional insurance pricing variations displayed
- **Calendar (CalendarService)** — Policy renewal dates synced to calendar via `CalendarService.createEvent()`. Premium installment due dates as calendar reminders. Claim follow-up appointments scheduled
- **Media (PhotoService)** — Accident scene photos uploaded via `PhotoService.uploadPhoto()` for claims. Vehicle damage documentation. Policy document and insurance card photo storage. QR code policy verification images
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time claim status changes. Policy activation confirmation events. Renewal processing status updates
- **Analytics (EventTrackingService)** — Track insurance spending patterns, claim frequency, premium cost trends over time. Provider comparison analytics based on claim settlement ratios
- **Budget (BudgetService)** — Insurance premiums tracked as recurring expense in budget. Annual insurance cost projections. Premium comparison analytics across renewal periods
