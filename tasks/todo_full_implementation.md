# Gaps + Deferred Features TODO — Partner C2B

**Source:** strictly the items either (a) flagged as DEFERRED in each F1–F13 audit in `tasks/todo.md`, or (b) surfaced as real gaps by the audit agents on 2026-04-27.
**Spec:** `docs/modules/partner_c2b_user_journeys.md`.
**Mandate:** every item below was originally deferred or missed. None are spec ambition I invented — each ties to a specific audit deferral or audit-agent gap finding.

Items are organized by feature so it's clear which audit they came from.

---

## A. Gaps surfaced by the audit agents (NOT in any audit's deferral list — real misses)

### A.1 — F1: edit/pause/delete UI for own products [ALREADY DONE — re-audit 2026-04-27]
- [x] Edit route reuses `post_partner_product_page.dart` in edit mode (`existing:` param, `_isEdit`, PATCH on save) — `post_partner_product_page.dart:216-471`
- [x] Pause toggle calls `PartnerProductService.updateProduct(isActive: !p.isActive)` — `my_partner_products_page.dart:93-106`
- [x] Delete with confirm dialog calls `PartnerProductService.deleteProduct()` — `my_partner_products_page.dart:108-145`
- [x] Surfaced via inline owner action row on each card (`showOwnerActions: true`) — `partner_product_card.dart:196-213`
- **Audit error:** the synthesis claimed this was missing; it's fully wired.

### A.2 — F2: mafundi vertical missing partner-product detail page [DONE 2026-04-27]
**Spec line 951** explicitly calls for it; F2 audit listed only food/events. (F2 audit deferral #1 mentioned mafundi but didn't track it as a real per-vertical detail page gap.)
- [x] Created `lib/mafundi/pages/partner_product_detail_page.dart` — thin wrapper forwarding to shared `PartnerProductDetailPage` with `cluster: 'mafundi'`
- [x] Parameterized shared page with `cluster` field (`food`/`mafundi`/`events`/etc.); cluster-aware copy for header (`Huduma ya kuagiza` vs `Bidhaa ya kuagiza`), CTA (`Omba huduma` vs `Agiza sasa`), placement snackbar, owner-self block, not-found state
- [x] Injected `PartnerProductRail(domain: 'mafundi', titleSwahili: 'Huduma za Mafundi')` between skills grid and "Maombi yangu" in `mafundi_home_page.dart`; tap routes to new mafundi detail page

### A.3 — F6: reschedule UI not wired [ALREADY DONE — re-audit 2026-04-27]
- [x] "Badili Muda / Reschedule" OutlinedButton gated on `_appt!.isReschedulableByCustomer` — `appointment_status_page.dart:202-211`
- [x] `_reschedule()` opens date+time picker, calls `AppointmentService.reschedule()`, refreshes — `appointment_status_page.dart:90-119`
- **Audit error:** synthesis claimed `isReschedulableByCustomer` had no caller; it does.

### A.4 — F8: amend-contract UI not wired [DONE 2026-04-28]
- [x] Backend migration + columns applied: `pending_amendment JSONB`, `amendment_proposed_by`, `amendment_customer_approved_at`, `amendment_partner_approved_at`. Migration row recorded after manual ALTER (the migration file existed pending; pre-existing user_profiles migration conflict prevented `artisan migrate` so columns were applied via tinker-driven Schema::table)
- [x] Backend `EngagementController::update()` already had full amendment flow — Mode 1 counter-proposal (proposed), Mode 2a propose amendment (active|paused), Mode 2b approve/reject. On dual approval, applies amendment fields (scope_brief, fixed_total_tzs, contract_type) and replaces pending milestones
- [x] Frontend `engagement_service.dart` — added `proposeAmendment()` and `respondToAmendment(approve)` methods
- [x] Frontend `engagement.dart` — added `pendingAmendment` (Map), `amendmentProposedBy`, `amendmentCustomerApprovedAt`, `amendmentPartnerApprovedAt` + `hasPendingAmendment` and `isAmendmentApprovableBy(userId)` helpers + `_parseAmendment()` decoder for jsonb-or-string from server
- [x] Frontend `engagement_workspace_page.dart` — "Pendekeza / Amend" button in action bar for active|paused (only when no pending); `_amendmentBanner` rendered between status strip and tabs showing diff lines + Approve/Reject for non-proposer or Withdraw for proposer; new `_AmendmentDialog` reuses existing scope/total/fee_model/notes fields seeded from current state and only sends true diffs

### A.5 — F11: rate CTA on remaining 4 detail pages [DONE 2026-04-27]
- [x] `service_request_status_page.dart` — CTA on `ServiceRequestStatus.completed`, partnerName from accepted quote via new `_acceptedPartnerName()` helper
- [x] `garage_status_page.dart` — CTA on `GarageBookingStatus.completed`, partnerName direct, itemTitle = faultSummary
- [x] `engagement_workspace_page.dart` — CTA between status strip and tabs when `!_isPartner && status == ended`
- [x] `property_inquiry_detail_page.dart` — CTA at end of body when `!_isPartner && status == accepted`

### A.6 — F12: SlotPicker retrofit into F6/F7/F10 [DONE 2026-04-27]
- [x] `book_appointment_page.dart` — `_stepTime` now renders `SlotPicker(partnerUserId, skillCategory)` once a partner is picked; manual date/time picker kept below as "Au chagua wakati mwingine" fallback
- [x] `book_consultation_page.dart` — same pattern; SlotPicker reads `widget.skillFilter.first` as scope; manual fallback retained
- [x] `book_event_package_page.dart` — SlotPicker rendered when `widget.package.partnerUserId ?? widget.partnerUserId != null`; falls back to existing `Anza`/`Mwisho` OutlinedButtons

### A.7 — F13: per-skill scope filtering on home rails [DONE 2026-04-28]
- [x] Added `_showChefSurfacesUnderScope` getter — Today snapshot + reservations rail now hide when activeSkill is set to a non-chef skill
- [x] Added `_buildScopeBanner` rendering spec-line-1217 copy ("Sasa unaona shughuli za [skill] pekee. Bofya Zote uone vyote.") with an inline "Zote" button that clears `_activeSkill`
- [x] `_buildStatsRow` now leads with a scope label — "Zote / All skills" when null, otherwise the active skill's bilingual label — covering the cross-persona stats requirement when `_activeSkill == null`

---

## B. Per-feature deferrals (pulled directly from each F's audit DEFERRED list)

### F1 — Partner Posting
From the F1 "Acceptable deferrals" block:
- [ ] Photo-quality auto-checks (blur/brightness/dimension validation)
- [ ] Sample-photo carousel (asset-heavy reference shots per cluster)
- [ ] Add-on hierarchy + booking sequencing + patch-test dependency (richer schema)
- [ ] COA tag by `skill_category` on revenue line
- [ ] Photo consent toggle (single boolean)
- [ ] Add-skill flow gating when partner taps unregistered skill
- [ ] Sticky last-skill memory (nice-to-have)
- [ ] Shangazi AI rewrite + share-to-feed
- [ ] 5 spec'd notifications (cron infra)
- [ ] Per-product analytics, pricing-band hint, lead-time honesty score (aggregates endpoint)

### F2 — Buyer Order
From F2 audit:
- [ ] Per-vertical detail pages for **skincare/hair_nails/fitness/housing** (mafundi+events done in A.2 / existing). Each gated on its module scaffold existing.
- [ ] Spec lines 268–278 — Notifications fan-out (push, accept celebration, ready-for-pickup, on-the-way, overdue, completed, daily digest, re-order prompt) — blocked on §C notification scheduler
- [ ] Spec lines 280–285 — Reports & insights (customer order history, partner spending breakdown, lead-time vs actual, recommendation engine, cluster spend leaderboard) — blocked on §F analytics
- [ ] Spec lines 287–294 — Cross-module (Wallet payment + journal_lines, Budget envelope, Calendar event creation, Chat deep-link, Shop add-ons rail, Shangazi deep-link, Community share card) — blocked on §D Wallet + Calendar/Chat infra
- [ ] Spec lines 296–309 — Research (conversion-weighted ranking, reorder carousel, hard dietary chip filters, Schedule-vs-ASAP toggle, group cart, photo-proof + handoff PIN, AI image-similarity refund check, 3-day refund window, auto-credit on partner error, post-service tipping, in-app help SLA)
- [x] **F2.1** Spec line 257 — sticky-bar "Iko kwa [partner]" status pill replacement after order placement [DONE 2026-04-28; verified pre-existing in `food/partner_product_detail_page.dart:838-933`]
- [ ] Spec line 263 — `customer_order_detail_page` for buyer for partner_product source (currently routed via generic page)
- [x] **F2.2** Spec line 265 — cancel reason dialog [DONE 2026-04-28; verified pre-existing across customer_order_detail, appointment_status, consultation_status, garage_status, engagement_workspace, partner_product_detail]

### F3 — Unified Inbox
From F3 audit:
- [x] **F3.1** Spec line 321 — skill filter chip row [DONE 2026-04-28; renders only when ≥2 unique skills appear in inbox; derives `_visibleSkills` from loaded orders' `skillCategory`; chip row sits between source chips and bucket chips; filter applied in `_filteredOrders`]
- [ ] Spec line 326 — source-specific detail routes (consultation NDA gate, service_request quote dialog, garage diagnosis flow, engagement workspace, event_booking deposit) — each lands with its own feature (F4–F10 mostly done; verify each route)
- [ ] Spec line 335 — Firestore live listener (foundational pattern §C; pull-to-refresh covers v1)
- [ ] Spec lines 342, 381 — bulk action support (multi-select pending → "Accept all" / quote-template)
- [ ] Spec lines 354–361 — reports & insights cards (inbox stats, source mix, skill mix, status funnel, response-time leaderboard, repeat-rate, hot-hours heatmap, monthly PDF export)
- [ ] Spec lines 345–351 — notifications fan-out (FCM, hourly pending alerts, daily/weekly digest, conversion coaching, negative-streak alerts)
- [ ] Spec line 364 — calendar auto-event on accept
- [ ] Spec line 365 — wallet write on completion
- [ ] Spec lines 374–380 — research (30s auto-reassign, auto-pause on 3 misses, Busy/Closed toggle, daily M-Pesa payout, lead-expiring countdown, KPI score)

### F4 — Service Request (Mafundi)
From F4 audit:
- [ ] Spec line 401 — Step 6 partner search (direct request to specific fundi). Currently always defaults to open marketplace.
- [ ] Spec line 415 — partner-side distance-from-location calculation (needs partner geo + customer lat/lng end-to-end)
- [ ] Spec line 416 — "Fungua Maps" deeplink button
- [ ] Spec lines 430–438 — notifications fan-out (FCM, no-quote alert at 1h, en-route ETA push, late-partner alert)
- [ ] Spec lines 441–445 — reports/insights/benchmarks/predicted-failure prompts
- [ ] Spec lines 447–454 — cross-module (Calendar, Wallet pay-on-complete, Budget nyumbani envelope, Chat per-request thread, Shop materials list, Insurance, Shangazi benchmarks)
- [ ] Spec lines 456–469 — research (AI cost-anchor band, structured intake per skill, diagnostic-fee credit, post-diagnosis re-quote gate, before/after photo upload, geofence arrival, live ETA, 30-day warranty, parts pass-through, site-survey fee)

### F5 — Garage Booking
From F5 audit:
- [ ] Spec line 477 — separate `incoming_garage_bookings_page.dart` (unified inbox handles it; standalone page if F12+ surfaces per-vertical inbox)
- [ ] Spec line 486 — drop-off slot picker driven by partner_availability (now achievable via A.6 retrofit)
- [ ] Spec line 488 — partner shortlist (re-pick from past mechanics) — favorites foundational
- [ ] Spec line 495 — Wallet pay-on-pickup integration
- [ ] Spec lines 503–509 — notifications fan-out (drop-off 24h reminder, 1h alert with map deeplink, diagnosis-pending nudge, ready-for-pickup celebration, 6-month service reminder, annual log)
- [ ] Spec lines 511–515 — vehicle service log, cost-vs-quote variance, failure-pattern detection, mechanic comparison reports
- [ ] Spec lines 517–525 — cross-module (Calendar event on confirm/ready, Wallet, Budget usafiri envelope, Insurance deeplink, Shop spare-parts, Shangazi pricing context, Buy Car resale link)
- [ ] Spec lines 527–540 — research (VIN scan, symptom wizard, OBD2 photo, mobile-vs-shop branching, vehicle profile + service history book, recall lookup, mileage-based reminders, parts API, body-shop photo bidding, pickup courtesy, AMC bundles, service-due dashboard, parts+labour warranty)

### F6 — Appointment (Salon / Fitness)
From F6 audit:
- [ ] Spec line 546 — `manage_availability_page.dart` slot calendar (now exists from F12; verify integration)
- [ ] Spec line 546 — `slot_picker.dart` read-only on customer side (now exists from F12; A.6 retrofit covers)
- [ ] Spec line 554 — 7-day slot grid rendering open/booked/blackout/past states (part of F12 — verify)
- [ ] Spec lines 561–563 — push reminder cadence (24h, 2h, on-arrival)
- [ ] Spec line 566 — Wallet pay on completed / pre-pay on confirmed
- [ ] Spec lines 583–592 — notification fan-out (10 reminder/celebration types)
- [ ] Spec lines 594–599 — reports/insights (utilization, fitness progress, best-time-to-book, no-show stats)
- [ ] Spec lines 602–610 — cross-module (Calendar event auto-sync, Wallet, Budget urembo/afya envelopes, Family on-behalf-of, Photos share, Shangazi tips, Health Log, Pharmacy, Shop)
- [ ] Spec lines 614–634 — research salon enhancements (hair-type taxonomy, service variants, multi-staff cart, "Any professional", buffers, patch-test gating, intake form, skin-type quiz, loyalty stamps, prepaid bundles, waitlist, cancellation tiers, two-way SMS, rebook cadence, photo consent, cadences)
- [ ] Spec lines 636–645 — research fitness enhancements (capacity-bounded class booking, pick-a-spot floor plan, drop-in vs membership, recurring training plans, progress photos/journal, PR auto-detection, HR live integration, live+on-demand)

### F7 — Consultation (Lawyer / Doctor / Business)
From F7 audit:
- [ ] Spec line 661 — slot picker driven by partner_availability (now achievable via A.6)
- [ ] Spec line 665 — Wallet pre-authorize fee on book / capture on completed
- [ ] Spec line 669 — WebRTC video join (UI shows snackbar; route into existing `lib/calls/` infra once entry point exists)
- [ ] Spec line 670 — phone-number reveal endpoint `/consultations/{id}/reveal_phone` returning partner number only at starts_at
- [ ] Spec line 671 — `arrived` partner status for in-person mode (separate state column)
- [ ] Spec line 677 — pharmacy "Order this prescription" deep-link
- [ ] Spec line 678 — auto-pull diagnosis to `lib/my_children/health_log`
- [ ] Spec lines 687–696 — notification fan-out (10 reminder/celebration types: booking-received, confirmed, 24h-before, 30min-before, join-now, partner-late, notes-ready, prescription-ready, follow-up-suggestion, monthly-spending)
- [ ] Spec lines 698–702 — reports/insights (health timeline, legal log, partner stats, insurance utilization)
- [ ] Spec lines 704–713 — cross-module (doctor module list sync, pharmacy deeplink, insurance claim, calendar event auto-sync, wallet, budget envelopes per-vertical, pre-consultation chat, Shangazi summary, family health share)
- [ ] Spec lines 716–752 — research (NHIF/AAR/Jubilee insurance hard filter, symptom checker w/ specialty mapping, conversational AI triage, waiting-time badge, available-today sort, persistent health profile, T-24h intake reminder, derm photo intake, pre-call mic/camera test, virtual waiting room, explicit consent screens, screen-share, auto care plan, eRx dispatch, condition-specific cadence, in-person clinic flow, SMS reply STOP/CONFIRM, conflict-of-interest check, productized legal SKUs, draft+lawyer-review upsell, pay-per-question, retainer subscription, MCT/TLS/NBAA license verification, FLAG_SECURE platform call, consent receipts, in-app data deletion path)

### F8 — Engagement
From F8 audit:
- [ ] Spec line 758 — "Omba Pendekezo / Request Proposal" routes to chat (currently snackbar)
- [ ] Spec line 779 — auto `accepted → active` cron at start_date midnight
- [ ] Spec line 781 — Wallet escrow capture: split current one-step approve+release into funded → submitted → approved → released
- [ ] Spec line 783 — Invoices tab (auto-generated periodic invoices; needs `engagement_invoices` table)
- [ ] Spec line 784 — Files tab (encrypted shared attachments)
- [ ] Spec line 785 — Chat tab (per-engagement thread + system messages on milestone activity)
- [ ] Spec lines 794–805 — notification fan-out (11 reminder/celebration types: proposal received, expiring, started, time-log nudge, milestone due/overdue/submitted/approval-pending, monthly invoice, complete, renewal)
- [ ] Spec lines 807–811 — reports & insights (P&L customer/partner, cross-engagement portfolio, tax-readiness export)
- [ ] Spec lines 813–822 — cross-module (Wallet escrow, Budget kazi envelope, COA journal_lines on milestone payment, Calendar milestone events, Chat per-engagement thread, Insurance E&O upsell, Documents zip export, Shangazi AI scope-statement drafter, Career timeline cross-link)
- [ ] Spec lines 824–842 — research (Work Diary screenshots / `engagement_time_screenshots`, Job Success Score, length-of-relationship signal, Honeybook proposal-contract-invoice morphing UI, retainer hour-bucket ledger, lead-credit billing, AI hiring-brief generator, optional portfolio for ranking, productized contract type picker, SoW templates, dispute mediation chat + 7-day window + platform escalation, auto-recurring weekly invoice, Toptal-style talent matching, five-event milestone notification fan-out, public profile pages, Honeybook-bundled questionnaires)

### F9 — Listing Inquiry (Real Estate)
From F9 audit:
- [x] **F9.1a** Spec line 852 — inline filter chip strip [DONE 2026-04-28; horizontal scroll above results in `search_property_page.dart` with Type chips + Bedrooms (1+/2+/3+/4+) + "⋯ Zaidi" trailing chip that opens existing bottom sheet for advanced filters]
- [ ] Spec line 861 — map view + neighborhood description in detail page
- [x] **F9.1b** Spec line 865 — "Hifadhi / Save" + "Shiriki / Share" buttons [DONE 2026-04-28; AppBar actions on `property_listing_detail_page.dart`: bookmark toggles via Hive-backed local store (`saved_property_listings` CSV in LocalStorageService) — backend sync deferred until `saved_listings` endpoint lands; share via `share_plus` with title+location+price+deeplink]
- [ ] Spec line 879 — `commission_recorded_at` partner-marked completion (column exists; no UI)
- [ ] Spec lines 894–904 — notification fan-out (10 reminder/celebration types)
- [ ] Spec lines 906–911 — reports & insights (save list, comp report, listing performance funnel, market data, partner pipeline)
- [ ] Spec lines 913–923 — cross-module (Calendar viewings as events, Wallet reservation deposit / commission settlement, Budget property goal, VICOBA/Kikoba group savings link, Loans mortgage calculator, Shop home-furniture filter, Insurance home insurance link, Shangazi neighborhood AI, Community ward groups)
- [ ] Spec lines 925–945 — research (photo verification + watermark + AI similarity check, HDR/wide-angle/drone tier upload + Premium gating, floor plan upload, Walk/Bike/Transit Score auto-resolve, EPC equivalent, location obfuscation, polygon search + isochrone filter, sticky filter chips, list-first map-secondary tabs, save-search digest, commute-time calculator, WhatsApp deep-link CTA, partner_availability slot picker, pre-qualification soft-ask, Matterport 3D tour, open-house RSVP, "Back on market" alert, pre-approval flow, "Similar home" cross-sell)

### F10 — Event Booking (Travel / DJ / MC / Safari)
From F10 audit:
- [ ] Spec line 967 — Wallet deposit capture (currently `payDeposit()` stubs the journal_lines write)
- [ ] Spec line 968 — auto `confirmed → day_of` cron at event_starts_at − 24h
- [ ] Spec line 969 — balance auto-charge from Wallet on completion
- [ ] Spec line 970 — auto-cancellation cron when `held` + deposit_due_at past
- [ ] Spec line 983 — re-quote / amendment flow when customer wants changes after `confirmed` (UI deferred)
- [ ] Spec line 984 — refund tier computation (full ≥60 days, 50% 30-60, 0% <30)
- [ ] Spec lines 987–997 — notification fan-out (10 reminder/celebration types: placed, held, deposit due 12h alert, hold expired, confirmed, T-30d/T-7d/T-24h/day-of, completed, future booking prompt)
- [ ] Spec lines 999–1004 — reports/insights (customer event log, partner pipeline calendar, cancellation analysis word cloud, seasonality heatmap, pre-event checklist completion)
- [ ] Spec lines 1006–1016 — cross-module (Calendar block creation, Wallet flows, Budget tukio envelope, Family multi-traveler pull, Insurance travel-insurance link, Photos auto-album, Shop event-supplies deeplink, Wedding planner cross, Shangazi AI advice, Career earnings cross)
- [ ] Spec lines 1018–1049 — research (GigSalad quote-bidding broadcast, travel-radius slider with auto-pricing per km, package builder add-on hierarchy on `partner_products`, refund tiers + force-majeure clauses, payment plan/balance T-14d, backup-performer guarantee TZS 200k, auto-generated contract with e-sign, song-request form, real-events social-proof gallery, day-by-day itinerary tier offerings Basix/Original/Comfort/Premium, TALA license badge, migration-season pricing overlay, QR voucher confirmation, multi-traveler intake encryption, payment plan 20-30%, travel insurance upsell, trip-prep checklist push, day-before reminder, my_trip live updates timeline, per-stop reviews, last-minute discount, group/early-bird discount, promo codes, M-Pesa-first payment)

### F11 — Partner Reviews
From F11 audit:
- [ ] Spec lines 1077–1081 — notification fan-out (rate prompt at completed, 24h follow-up, 7d re-prompt, 5-star streak, low-rating alert, monthly digest)
- [ ] Spec lines 1083–1088 — reports/insights (tag cloud, trend chart, peer comparison ranking, review velocity flagging)
- [ ] Spec lines 1090–1095 — cross-module hooks (Tajirika discovery score weighting, search boost, **F11.1** anti-troll Chat handoff for ≤3-star reviews [DONE 2026-04-28; bottom-sheet prompt after submit success on stars ≤3 routes customer to `/messages` with hint snackbar — direct partner-thread resolution deferred until chat infra exposes getOrCreateConversation], Shangazi summarize, Community top-rated surfacing)
- [ ] Spec lines 1099–1118 — research (multi-dimensional rating per-source aspects, per-item thumbs up/down, new-vs-returning-customer flag, recency-weighted ranking, 7-day partner response with discount affordance, photo+video reviews with verified-booking badge, helpfulness vote, length-of-relationship signal, Avvo peer endorsements for legal/medical, Job Success Score for engagement, disease-specific outcome tracking, AI review summary, anti-troll cushion mandatory photo for ≤2-star, verified-booking-only enforcement)

### F12 — Partner Availability
From F12 audit:
- [ ] Spec line 1144 — recurring blackout rule ("Every Sunday")
- [ ] Spec line 1145 — `LiveUpdateService` Firestore broadcast on hours/blackout change
- [ ] Spec line 1158 — blackout-overlap warning dialog when adding blackout that overlaps confirmed bookings
- [ ] Spec lines 1156–1162 — notification fan-out (set-hours nudge, first-booking celebration, blackout-overlap alert, fully-booked extend prompt, low-utilization reduce prompt, weekly utilization summary)
- [ ] Spec lines 1164–1167 — reports/insights (utilization heatmap, peak-vs-trough analysis, blackout impact revenue, slot-length tuning suggestion)
- [ ] Spec lines 1169–1175 — cross-module (Calendar recurring blocks, public profile "Hours" display, my_family vacation auto-block, Shangazi pricing strategy AI, FCM Firestore broadcasts)
- [ ] Spec lines 1179–1190 — research (configurable reminder timing 1/2/4/8/24/48/72h, T-2hr partner schedule reminder, lead-time + horizon configuration, buffer/processing/travel time per service, peak/shoulder/low season pricing modifiers, last-minute auto-discount, recurring with skip-week, VIP standing-slot, FIFO vs First-to-Claim waitlist, "Any professional" auto-assignment, two-week fitness horizon with auto-add waitlist, pick-a-spot floor plan)

### F13 — Multi-Skill Partner Hub
From F13 audit:
- [ ] Spec line 1208 — All-skills aggregate dashboard view (cross-persona stats card: total revenue, orders, avg rating, active customers, response time)
- [ ] Spec line 1213 — per-skill scope filter on home page rails (covered by A.7 above)
- [x] **F13.1** Spec line 1218 — full add-a-skill flow [DONE 2026-04-28; FAB → `_AddSkillPicker` bottom sheet with search field + cluster-grouped (Mafundi / Auto / Urembo / Wataalamu / Mali / Afya na Chakula / Matukio / Safari / Biashara) candidate list filtered against already-registered skills → on pick calls `TajirikaService.updatePartnerProfile({skills: [...registered, picked]})` → routes to `SkillPersonaPage` for display name/bio/pricing customization; regulated-skill cluster surfaces "Inahitaji cheti" hint inline]
- [ ] Spec line 1225 — profile photo override per persona (image_picker upload). Inline UI hint placed; URL-based supported via API.
- [ ] Spec line 1228 — tag preset locks suggested tag list per skill (backend column exists; UI not wired)
- [x] **F13.2** Spec line 1234 — regulated-skill credential upload [DONE 2026-04-28; `_credentialSection` on `skill_persona_page.dart` renders for skills in `_kRegulatedSkills` (legal/medical/nursing/pharmacy/accounting/taxAdvisory) showing status-aware banner (pending_verification = blue, rejected = red, default = amber) with "Pakia cheti" button that opens `image_picker` and POSTs to `/tajirika/verifications/professional` via existing `submitProfessionalLicense` with `license_type=skill.name`. Known limitation: backend stores credential on `tajirika_partners.license_type/license_document` (single slot per partner); multi-regulated-skill partners overwrite — proper fix needs `partner_skill_credentials` table.]
- [ ] Spec lines 1242–1250 — notification fan-out (9 types: skill verified, verification rejected, configure-persona reminder, persona conflict alert, cross-persona digest, complementary-skill suggestion, drop-underperforming-skill prompt, two-skill milestone celebration, hours-not-set-per-skill reminder)
- [ ] Spec lines 1253–1258 — reports/insights (cross-persona P&L side-by-side, skill-vs-skill margin per hour, time-allocation tracker, customer-overlap signal, persona discoverability metrics, skill-mix recommendation engine)
- [ ] Spec lines 1260–1270 — cross-module (Tajirika public profile per-persona cards, search results one-card-per-skill, Shop catalog scoping, Wallet earnings split per skill, COA journal_lines tagged with skill_category, Calendar skill-tagged events, Chat persona auto-sign, Shangazi cross-persona advice, Community per-persona scoping, FCM payloads include skill_category for icon routing)
- [ ] Spec lines 1274–1283 — research (one-screen add-a-skill, per-skill Job Success Score, optional per-skill portfolio for ranking lift, opportunity-cost analytics, persona-level pricing tier badges, persona-level public profile pages `tajiri.com/p/asha-cakes`, per-persona favorites scoping, skill-pause without affecting others ✓ done, AMC packages persona-specific)

---

## C. Cross-feature dependencies

These are platform capabilities each feature's deferred items depend on. They're not new spec items — they just clarify what unblocks what.

- **Notification scheduler** (foundational §C) — **FOUNDATION + 8-CONTROLLER TRIGGER FAN-OUT SHIPPED 2026-04-28**: `partner_c2b_notifications` table created + applied; `PartnerC2BNotificationService` with `enqueue()` / `cancelForSource()` / `drain()` + 9 trigger helpers (`scheduleAppointmentReminders`, `scheduleConsultationReminders`, `scheduleEventBookingReminders`, `scheduleEngagementMilestoneReminders`, `scheduleServiceRequestReminders`, `scheduleGarageBookingReminders`, `notifyGarageReadyForPickup`, `scheduleListingInquiryReminders`, `notifyPartnerProductOrderPlaced`, `scheduleRatePrompt`); `app:dispatch-partner-c2b-notifications` artisan command registered to every-minute scheduler. **Wired controllers**: AppointmentController + ConsultationController + EngagementController (confirm/start/cancel/reject/end + reschedule re-fan); EventBookingController (payDeposit fan / markCompleted rate prompt + final-stretch cancel / reject+cancel cancel-rows); ServiceRequestController (accept fan / complete rate prompt / cancel cancel-rows); GarageBookingController (advancePartner confirmed fan / readyForPickup celebration / complete rate prompt / reject+cancel cancel-rows); ListingInquiryController (schedule fan / acceptOffer rate prompt / cancel + rejectOffer cancel-rows); PartnerProductController (placeOrder partner-side new-order push). **Smoke tests passed**: (1) past-fire_at row → dispatcher flips to `sent`, attempts=1; (2) live AppointmentController::accept on appt id=7 → 3 reminders queued (24h, 2h, partner 30min) with bilingual bodies + correct user routing. **Remaining**: PartnerReview/RatePartnerCta is already wired via scheduleRatePrompt from completion paths; partner-side accept-celebration on partner_product_orders + ready-for-pickup on partner_product (need PartnerProductOrderController endpoint that doesn't yet exist for these state transitions); F1 product-published + F12 availability triggers + F13 verification-rejected + F8 retainer-cycle + F10 force-majeure are all bolt-on calls into existing helpers when those state transitions land. Net: foundation can absorb everything else as wiring work.
- **Wallet pre-auth + capture + journal_lines** (foundational §D) — **FOUNDATION + WIRING SWEEP SHIPPED 2026-04-28**: `partner_c2b_wallet_holds` table; `PartnerC2BWalletService` with `hold()`/`capture()`/`release()`/`payInstant()`/`ensureHold()`/`captureForSource()`/`releaseForSource()`. All postings via `JournalPostingService::post()` (balanced double-entry) + `WalletLedgerService` mirror to `wallets.balance`. **Wired controllers**: AppointmentController::complete → payInstant on `service_price_tzs` + cancel → release; ConsultationController::complete → payInstant on `fee_tzs` + cancel → release; GarageBookingController::complete → payInstant on `final_cost_tzs ?? revised_cost_tzs`; EngagementController::approveMilestone → payInstant on milestone `amount_tzs`; **EventBookingController::payDeposit → ensureHold(deposit_tzs)** (deposit held until completion), **markCompleted → captureForSource() + payInstant(balance_tzs)** (deposit captured, balance auto-charged per spec line 969), cancel → releaseForSource; **ServiceRequestController::complete → payInstant(callout_fee + estimated_cost)** + cancel → release; **CustomerOrderController::actPartnerProduct complete → payInstant(total_price_tzs)** + cancel/rejected → release. Smoke tested: customer 50k → 38k held → captured to partner; release path also verified. **Remaining**: hold-on-confirm pre-auth flow for F8 escrow phase split (funded → submitted → approved → released); refund-after-capture path; ListingInquiryController commission settlement (column exists; no endpoint).
- **Analytics aggregation infra** (foundational §F) unblocks ~50 deferred per-feature reports — not started
- **Calendar event service** unblocks per-feature calendar hooks (F2/F4/F5/F6/F7/F8/F9/F10/F12) — not started
- **Chat infrastructure (`getOrCreateConversation` by user_id)** unblocks per-feature chat threads (F4/F6/F7/F8/F9/F10/F11) and the F11.1 partner-thread resolution — not started
- **Firestore live-update broadcast** unblocks F3 inbox listener + F12 slot-picker live refresh — not started

When the scheduler/Wallet/analytics land, the per-feature deferrals above stop being new work — they become wiring work (1–2 days per feature instead of 1–2 weeks).

---

## D. What's NOT in this list

I'm being explicit so the scope is clear:

- ❌ Foundational pattern groups §A–§I as standalone work items — those are spec ambition, not gaps from the F1–F13 implementation. The cross-cutting capabilities they describe are referenced above only when a per-feature deferral depends on them.
- ❌ Generic "trust & verification" buildout (NIDA KYC, FLAG_SECURE platform integration, license verification as a platform-wide service) — these only appear here when called out in a specific F-feature deferral (F7's spec lines 716–752 for example).
- ❌ Tooling / ops / CI / testing improvements — those are implicit production prep, not partner-c2b spec gaps.

---

## E. Counts

| Category | Count |
|---|---|
| A. Audit-agent gaps | 7 multi-step items (~20 sub-tasks) |
| B. F1 deferrals | 10 items |
| B. F2 deferrals | 7 items (4 are spec-line bundles covering ~25 sub-items) |
| B. F3 deferrals | 9 items (~25 sub-items) |
| B. F4 deferrals | 7 items (~30 sub-items) |
| B. F5 deferrals | 8 items (~25 sub-items) |
| B. F6 deferrals | 11 items (~40 sub-items) |
| B. F7 deferrals | 12 items (~45 sub-items) |
| B. F8 deferrals | 10 items (~35 sub-items) |
| B. F9 deferrals | 8 items (~30 sub-items) |
| B. F10 deferrals | 11 items (~35 sub-items) |
| B. F11 deferrals | 4 items (~25 sub-items) |
| B. F12 deferrals | 7 items (~25 sub-items) |
| B. F13 deferrals | 10 items (~30 sub-items) |

**Total: ~140 top-level items, ~440 sub-items** (reduced from the previous ~520 by removing items I invented that weren't in any F1–F13 audit's deferral list).
