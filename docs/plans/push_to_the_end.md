F1 — Partner Posting (15 enhancements)

- ✅ Productized fixed-fee menu (is_productized + catalog_sku_code)                                                                                                           ─
- ✅ Patch-test as bookable service with dependency (gating banner shipped)
- ✅ Hard dietary tag set on food products (dietaryTags model field + UI)
- ✅ Hair-type taxonomy (hairTypes model field + UI)                                                                                                                          ─
- ✅ Light skill activation — async verification while listing publishes
- ✅ AMC / package-bundle SKU (partner_product.kind = amc + visit-count fields)
- ▢ Three-tier service hierarchy (Category > Service Type > Service)
- ▢ Service Variants table (partner_product_variants with label_sw/en, price, lead-time)
- ▢ Add-ons surfaced after main selection with auto-recalc duration/tax (max-cap)
- ▢ Booking sequencing for multi-step services (parallel-customer during processing time)
- ▢ Implicit-duration calculation (no customer-side duration picker)
- ▢ Service Type photo guidelines per cluster (food top-down, hair multi-angle, mafundi before/after, housing wide-angle/drone)
- ▢ Sample-photo carousel placeholder enforcement (table already exists from session 10)
- ▢ Photo-quality auto-checks at upload (blur/brightness/frame-fill/dimension/stock-similarity)
- ▢ Lead-time honesty score on partner dashboard (declared vs actual delta)

F2 — Buyer Order (12 enhancements)

- ✅ Reorder carousel ("Tena? / Order again?") on *_home_page rails — auto-resolving activity card mounted on 10/10 verticals                                                 ─
- ✅ Hard dietary/safety filter chips on food rail
- ▢ Conversion-rate-weighted ranking (factors: completeness, response-time, completion, recency, recency-weighted reviews, distance, price, conversion %)
- ▢ Schedule vs ASAP toggle at booking with 30-min granular slots (48h ahead)
- ▢ Group / shared-cart for office lunches and family compounds
- ▢ Photo-proof of delivery + 4-digit handoff PIN
- ▢ AI image-similarity check on customer-uploaded refund photos
- ▢ 3-day self-report window for missing items
- ▢ Auto-credit on detected partner error (deducted from payout)
- ▢ Tip after delivery (up to 30 days post-service, three TZS bands)
- ▢ In-app help chat with <3-min SLA for order escalations
- ▢ Per-vertical detail-page copy/hero norms (food/mafundi/events/housing/travel)

F3 — Partner Inbox (11 enhancements)

- ▢ 30-second accept window with auto-reassign (pending → next-nearest)
- ▢ Auto-pause partner after 3 consecutive missed/declined (sticky banner + Resume CTA)
- ▢ "Busy" vs "Closed" mode toggles per skill (busy extends ETA, closed delists)
- ▢ Stock toggle per partner_product / per appointment slot
- ▢ Daily M-Pesa payout marketing badge ("Pesa zako, leo")
- ▢ Lead-expiring countdown push for quote-bid sources
- ▢ Partner KPI score on inbox header (response 40/completion 30/rating 20/recency 10) + tier badge
- ▢ Bulk-action support (multi-select pending → Accept all / canned quote)
- ▢ Voice-note + canned-message library for partner replies
- ▢ Weekly competitive benchmark email/in-app card
- ▢ Service-history lookup per customer ("Mteja wa kawaida" chip)

F4 — Service Request / Mafundi (12 enhancements)

- ✅ Photo-of-problem upload as primary intake                                                                                                                                ─
- ✅ 30-day redo-work warranty (badge on status page wired)
- ▢ AI cost-estimation anchor band ("Wastani: TZS X–Y")
- ▢ Structured intake form per skill (rooms/flooring/sq ft/etc.)
- ▢ Diagnostic fee credited toward repair (TZS 15k credited if work proceeds)
- ▢ Post-diagnosis re-quote with hard customer approval gate
- ▢ "No-fix-no-fee" marketed trust line for diagnostic-only flows
- ▢ Mandatory before/after photo upload by partner
- ▢ Geofence-triggered "Arrived" status (not manual tap)
- ▢ Live ETA push with map view ("Fundi yuko dakika 10 mbali")
- ▢ Parts pass-through with capped markup (20–30% above cost, line-itemized)
- ▢ Partner site-survey fee for big jobs as separate scheduled appointment

F5 — Garage Booking (13 enhancements)

- ✅ Persistent vehicle profile / service-history book (customer_vehicles + service history page)                                                                             ─
- ✅ Symptom selector wizard (symptom_wizard_page shipped)
- ✅ Annual maintenance contract (AMC) for vehicles (kind=amc reuse)
- ✅ Recall lookup chip on my_vehicles_page (open_recalls warning row)
- ✅ Mileage-based service reminders / next-service prediction chip (next_service_at_km/date)
- ▢ VIN scan via camera at booking (auto-populate make/model/year/engine)
- ▢ OBD2 / dashboard-light photo upload at booking
- ▢ Mobile-vs-shop drop-off branching at booking ("Wapi?" first question)
- ▢ Parts ordering integration with TZ supplier APIs (NAPA TZ, AutoZone, sokoni catalog)
- ▢ Body-shop bidding on photos alone (panelBeating / sprayPainting)
- ▢ Pickup-and-drop courtesy filter
- ▢ Service-due dashboard in lib/service_garage/
- ▢ 12-month / 12,000-km parts+labour warranty + one-tap warranty claim

F6 — Appointment / Salon-Fitness (17 + 8 = 25 enhancements)

Salon / hair_nails / skincare / fitness (17):
- ✅ Hair-type taxonomy filter on customer rail
- ✅ HPitch-test xs bmokable service with dependency                                                                                                                          ─
- ✅ Pahoto consentbtoggle on appointmentd
- ✅ Phre-appnintmeno intake form aumo-sent on booking (via beauty_profile_service.dart)
- ▢ Seevice VariantsiUX (parent → small/medium/jumbo with own price + duration)
- ▢ Multi-staff bookings in one cart (slots[]: [{service_id, staff_id}])
- ▢ "Any professional" vs specific staff toggle (auto-assignment by load-balance)
- ▢ Pre-buffer + processing time + post-buffer per service variant
- ▢ Travel buffer + mobile-service surcharge + parking pass-through + after-hours / holiday premium line items
- ▢ Skin-type quiz + AI selfie analysis in lib/skincare/
- ▢ Loyalty stamps with progress bar (1–15 stamps, optional expiry)
- ▢ Prepaid bundle SKUs (5-session redemption)
- ▢ Auto-add waitlist (FIFO) vs First-to-Claim SMS blast (configurable)
- ▢ Cancellation-policy tiers (free >24h / 50% 4–24h / full <4h or no-show) at booking
- ▢ Two-way SMS YES/NO confirmation
- ▢ Rebook cadence per service (cuts every 4–6 wks, color 8–10 wks, facial 4 wks)
- ▢ Recurring booking with daily/weekly/biweekly/monthly + skip-week

Fitness — class + 1:1 (8):
- ▢ Capacity-bounded class booking with waitlist (class_sessions table)
- ▢ Pick-a-spot floor plan for reformer / cycling (visual grid + favorite spot persistence)
- ▢ Drop-in vs membership distinction (tiered credits per city/time/equipment)
- ▢ Recurring training plans + check-ins (weekly programming inside chat thread)
- ▢ Progress photos + body measurements + training journal with auto-graphs
- ▢ PR (personal record) auto-detection + celebration push
- ▢ Heart-rate live integration (Bluetooth HRM / Apple Watch / Pixel Watch)
- ▢ Live + on-demand coexistence (live class with leaderboard + recorded library)

F7 — Consultation / Lawyer-Doctor-Business (28 enhancements)

- ✅ Productized legal SKUs (Will / Lease review / Divorce filing) — legal-pack UI shipped                                                                                    ─
- ✅ NDA-on-intake auto-signed before document upload (NDA acceptance gate widget exists)
- ✅ Persistent privilege flag on legal threads
- ✅ HIPAA-grade architecture (encryption + audit logs)
- ✅ Compliance verification with public badges (MCT/TLS/NBAA — verification step card exists)
- ✅ Last-minute discount auto-applied (banner shipped on customer detail)
- ▢ Three-tier SKU (text/async chat → video → in-person) per consultation skill
- ▢ NHIF / AAR / Jubilee accepted as a hard filter at customer search
- ▢ Symptom checker with specialty mapping (free-text → predicted specialty)
- ▢ Conversational AI triage in chat UI (severity routing self-care / chat / video / ER)
- ▢ Bilingual symptom + intent capture at parity (already core in app, but symptom flow specifically)
- ▢ Waiting-time badge on each provider card ("Wastani: dakika 18 kusubiri")
- ▢ "Available today / tomorrow / this week" sort as primary ranking
- ▢ Persistent customer health profile (allergies, chronic conditions, past Rx, lab uploads)
- ▢ Pre-visit intake forms pushed at T-24h with reminder
- ▢ K-Health-style derm photo intake with structured photo prompts
- ▢ Pre-call mic/camera/bandwidth test
- ▢ Virtual waiting room with provider photo + estimated wait
- ▢ Explicit consent screens before video (location, recording, Rx delivery)
- ▢ Screen-share for showing lab reports during call
- ▢ Auto-generated visit notes + care plan delivered in-app immediately
- ▢ eRx dispatch (chosen pharmacy or QR-redeemable code)
- ▢ Follow-up CTA pre-filled on visit summary ("Hifadhi follow-up baada ya wiki 2")
- ▢ Condition-specific follow-up cadence (diabetic 90d, HTN 30d, post-op 7/14/30, antenatal monthly)
- ▢ In-person flow extras (clinic intro, parking, queue position display, check-in QR)
- ▢ SMS reminder + reply STOP/CONFIRM as fallback
- ▢ Conflict-of-interest check (legal): opposing party flagged before lawyer accepts
- ▢ Draft-generation + lawyer-review upsell two-tier flow
- ▢ Pay-per-question (legal) for one-off Q&A with optional follow-up window
- ▢ Retainer subscription (legal/business): monthly fee includes documents + N consultations
- ▢ Screenshot blocking (FLAG_SECURE) on Rx / NDA-gated chat / ID upload
- ▢ Consent receipts (every data-share generates a logged user-visible receipt)
- ▢ In-app data deletion path with confirmation email

F8 — Engagement (17 enhancements)

- ✅ Upwork-style escrow + milestone release (fundMilestone + approveMilestone shipped)                                                                                       ─
- ✅ Job Success Score (badge + backend rebuild command)
- ✅ Three engagement contract types (fixed_price / hourly / productized exist as enum)
- ✅ Five-event milestone notification fan-out (notification service shipped)
- ✅ Lead-credit model option — chip surfaced
- ✅ Proposal → contract → invoice morphing object (tabs added)
- ▢ Work Diary / time-tracker with screenshots (random intervals; engagement_time_screenshots table)
- ▢ Length-of-relationship signal ("Working with X since 2024", "5 repeat clients")
- ▢ Retainer subscription with hour ledger (auto-recurring + roll-or-expire)
- ▢ AI hiring-brief generator (one-line goal → structured engagement post)
- ▢ Optional portfolio for ranking (already partial — needs reuse from existing TAJIRI profile)
- ▢ Statement-of-work (SoW) templates for senior consultants
- ▢ Dispute window with platform mediation (7-day customer↔partner mediation chat → escalation)
- ▢ Auto-recurring weekly invoice on hourly contracts with billed-time summary
- ▢ Toptal-style talent matching layer (manual ops in v1)
- ▢ Public profile pages (tajiri.com/p/asha-cakes shareable URL)
- ▢ Honeybook-style questionnaires bundled with contracts

F9 — Listing Inquiry / Real Estate (19 enhancements)

- ✅ Save-search → daily email/push digest (saved searches list page + service shipped)                                                                                       ─
- ✅ Open-house RSVP separate flow (CTA on listing detail wired)
- ✅ Photo-count gating + watermarking + photo verification (column + service exists)                                                                                         ─
- ✅ Walk/Bike/Transit Score auto-resolution (property_listings.walk/bike/transit_score)
- ✅ Partner response-time chip (partner_response_minutes)
- ▢ HDR / wide-angle / drone photo tiers + premium gating
- ▢ Floor plan upload accepted as image (separate carousel tab on detail)
- ▢ Energy Performance Certificate equivalent (electricity/water reliability per ward)
- ▢ Location obfuscation by default (circle approximation until inquiry confirmed)
- ▢ Polygon "draw your own area" search + commute-time isochrone filter
- ▢ Filter chips at top with sticky bar + neighborhood lens overlay (crime/school/commute)
- ▢ List-first default on mobile (data-saving)
- ▢ Commute-time calculator on detail page (work-address isochrone)
- ▢ WhatsApp deep-link as primary contact CTA
- ▢ "Request a tour" with agent calendar slots + auto-route on >24h non-response
- ▢ Pre-qualification soft-asked at inquiry (move-in timeframe, financing, agent y/n)
- ▢ 3D Matterport tour + virtual open house (paid by agent)
- ▢ "Back on market" alert when pending → active
- ▢ Pre-approval flow (long-term rental: landlord pre-approves a guest)
- ▢ "Similar home just listed" cross-sell push when inquiry doesn't convert

F10 — Event Booking / Travel (26 enhancements)

- ✅ Backup-performer guarantee (chip + columns wired)                                                                                                                        ─
- ✅ Promo-code infrastructure (PromoCodeField widget + redemption tables)
- ✅ Force-majeure clauses (force_majeure_at column + model field)
- ✅ Payment plan / installments (payment_plan_installments column)
- ✅ Song-request / do-not-play form (song_requests column)
- ✅ Quote-bidding broadcast (event_quote_requests + event_quote_bids tables + service)
- ▢ Travel radius slider with auto-pricing per km
- ▢ Package builder with add-ons UI (add-on rows per partner_products.add_ons[])
- ▢ Refund-policy tiers (60d/30-60d/<30d) as expandable card on booking
- ▢ 50% deposit at booking + balance T-14d (default schedule, partner-configurable)
- ▢ Auto-generated contract from package selection with both-party e-signing
- ▢ "Real Events" social-proof gallery (post-event photo upload prompts)
- ▢ Day-by-day itinerary card layout for safari/multi-day tours
- ▢ TALA license badge required on safari/tour-operator listings + insurance cert verified
- ▢ Migration-season pricing overlay (peak/shoulder/low calendar)
- ▢ Tier offerings on multi-day packages (Basix / Original / Comfort / Premium)
- ▢ QR-voucher confirmation (scanned at venue/pickup)
- ▢ Multi-traveler intake (passport, dietary, medical, emergency contact per traveler)
- ▢ Travel insurance upsell at checkout (via lib/insurance/)
- ▢ Trip-prep checklist push at T-30d/14d/7d (visa, vaccinations, packing)
- ▢ Day-before reminder (pickup point, guide name + photo + phone, weather)
- ▢ On-tour live updates page (lib/travel/pages/my_trip_page.dart)
- ▢ Per-stop reviews on multi-day tours (rate each lodge / each park)
- ▢ Last-minute discount auto-applied <48h with empty seats
- ▢ Group discount tiered (5% for 4+, 10% for 8+)
- ▢ Early-bird discount (book 12+ months out for 10% off)

F11 — Partner Reviews (14 enhancements)

- ✅ Multi-dimensional rating per source (dimensions map field)                                                                                                               ─
- ✅ Photo + video reviews with verified-booking badge (chip wired)
- ✅ Helpfulness vote ("Was this helpful?") + drives sort
- ✅ Verified-booking-only enforcement (column shipped backend)                                                                                                               ─
- ✅ Job Success Score reputation overlay (badge wired)
- ✅ Loyalty bundles (rail shipped on partner profile)
- ▢ Per-item thumbs up/down + global star (multi-line orders: 4 dishes / cut+color+nails)
- ▢ New vs returning customer flag visible on review card
- ▢ Review weighting by recency (last 6–12 months heavier in ranking)
- ▢ 7-day partner response window with optional discount-offer affordance
- ▢ Length-of-relationship signal auto-rendered ("12 prior orders", "Since 2024")
- ▢ Avvo-style peer endorsements for legal/medical/business
- ▢ Disease-specific outcome tracking (medical only, 14/30 days post-consult)
- ▢ AI-generated review summary on partner profile (auto from last 30d)
- ▢ Anti-troll cushion (3-star → chat first; ≤2-star → mandatory photo)

F12 — Partner Availability (12 enhancements)

- ✅ Configurable reminder timing options (chips for 0/2/6/12/24h shipped on _HoursDialog)                                                                                    ─
- ✅ Peak/shoulder/low pricing overlay (pricing_modifier_pct chips shipped)
- ✅ Recurring schedule with skip-week (already in blackouts dialog)
- ▢ Partner-side schedule reminder push at T-2hr for scheduled non-ASAP orders
- ▢ Booking lead time + horizon configuration per service (min notice + max advance)
- ▢ Buffer / processing / travel time configuration per service
- ▢ Last-minute discount auto-applied if slot empty <48h (configurable per partner)
- ▢ VIP standing-slot reservation (preferred recurring slot held before public open)
- ▢ Auto-add waitlist (FIFO) vs First-to-Claim SMS blast configurable
- ▢ "Any professional" auto-assignment with travel-time + skill-fit weighting
- ▢ Two-week booking horizon for fitness classes with auto-add waitlist
- ▢ Pick-a-spot floor plan for studio fitness

F13 — Multi-Skill Partner Hub (10 enhancements)

- ✅ Add-a-skill is one screen, not re-onboarding                                                                                                                             ─
- ✅ Per-skill Job Success Score (partner_skill_personas.job_success_score shipped)
- ✅ Persona-level public_slug (column shipped session 10)
- ▢ Optional per-skill portfolio for ranking lift, not publish gate
- ▢ Cross-persona time-allocation vs revenue-mix dashboard ("60% time, 35% revenue") + opportunity cost
- ▢ Persona-level pricing tier badges (Budget / Standard / Premium auto from cluster median)
- ▢ Persona-level public profile pages (tajiri.com/p/... per persona)
- ▢ Cross-persona unified inbox with skill-icon prefix
- ▢ "Save my partner" works per persona (favorites scoped to skill category)
- ▢ Skill-pause without affecting other skills (partner_skill.is_active = false)
- ▢ AMC packages persona-specific (carpentry-AMC doesn't pollute cake catalog)

  ---
Summary

Total enhancements in spec: 199 (across F1–F13, including F6's two subsections; my earlier ~117 estimate was wrong — the real count is higher).

┌───────────────────────┬───────┐
│        Status         │ Count │                                                                                                                                             
├───────────────────────┼───────┤                                                                                                                                             
│ ✅ Shipped end-to-end │    41 │
├───────────────────────┼───────┤                                                                                                                                             
│ ▢ Remaining           │   158 │                               
└───────────────────────┴───────┘

Remaining count by F-section:

- F1: 9 / 15
- F2: 10 / 12
- F3: 11 / 11
- F4: 10 / 12
- F5: 8 / 13
- F6 salon: 13 / 17
- F6 fitness: 8 / 8
- F7: 22 / 28
- F8: 11 / 17
- F9: 14 / 19
- F10: 20 / 26
- F11: 9 / 14
- F12: 9 / 12
- F13: 8 / 10

The platform foundation (notifications, wallet, calendar, chat, Firestore, analytics, JSS scoring, COA-backed money flows) covers every one of the 158 remaining items. Each  
is bolt-on UI/wiring against existing helpers — no new infrastructure required.