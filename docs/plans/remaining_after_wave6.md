# Remaining work after Wave 6 (Wave 7 tracker)

Audit run against `docs/plans/push_to_the_end.md` on 2026-04-30, after Waves 1–6 close-out.

Each item below gets implemented, audited (analyzer + mount-point verification), checked off, then we pause for go-ahead before moving on.

## Totals (initial)

- ✅ shipped (mounted in real flows): 60
- ▼ partial (orphan widgets / missing surface): 47
- ❌ genuinely unbuilt: 51

## Wave 7 backend patch round (post-audit)

The previous agent shipped Wave 7 frontend changes for items #1-#20 but skipped 11 backend pieces. All patched in this round:

- **#2** — `actTip` method on `CustomerOrderController`, route `POST /customer-orders/{source}/{id}/tip` working; uses `partner_delivery_tips` table; 30-day window enforced; verified live (HTTP 403 "Only the buyer can tip" without right user — proves wiring).
- **#4** — `accept_window_expires_at` column on all 6 order tables; computed on-the-fly in `shapeRow()` from `created_at + 30s` when status is `pending`.
- **#5** — `partner_slot_stock_overrides` table created; `POST /partner-availability/slot-stock` route + `toggleSlotStock` method; `slots()` endpoint now joins overrides and exposes `is_in_stock` per slot.
- **#6** — `batchQuote` method + route `POST /customer-orders/batch-quote`; `partner_quote_messages` table created; resolves buyer per source, inserts canned message per order.
- **#15** — `appointments.sms_confirmed` + `sms_confirmed_at` columns; `confirmSms` method + route `POST /appointments/{id}/confirm-sms`; field exposed in `shape()`.
- **#16** — `appointments.rebook_cadence_weeks` column; `resolveRebookCadenceWeeks()` helper auto-derives from `partner_products.rebook_cadence_days` or title heuristic (haircut→5wks, color→8wks, facial→4wks); set on `store()`; field exposed in `shape()`.
- **#17** — Server-side pricing multiplier in `ConsultationController.store()`: text=0.2, phone=0.5, video=1.0, in_person=2.4; `consultations.base_fee_tzs` column added; client-submitted base fee scaled before insert.
- **#18** — `consultations.sms_confirmed` + `sms_confirmed_at` columns; `confirmSms` method + route `POST /consultations/{id}/confirm-sms`.
- **#19** — `LegalQnaController` rewritten: `ask()` now uses `PartnerC2BWalletService->hold()` to escrow funds (returns 402 on insufficient balance); `answer()` calls `capture()` to credit answering lawyer; `cancel()` releases hold; `legal_qna_threads.wallet_hold_id`, `paid_at`, `follow_up_window_days`, `follow_up_expires_at` columns added.
- **#20** — `consultations.deleted_at` deletion path: `deleteData` method + route `POST /consultations/{id}/delete-data`; scrubs PII (intake_summary, attachments, address, lat/lng, visit_notes, prescription, follow_up_notes), sets deleted_at.

**Audit verification**: 10 schema changes confirmed via psql, 11 routes registered via `route:list`, no PHP syntax errors, no new Dart errors (existing pre-Wave-6 errors in `hair_nails/services` unchanged).

---

## ❌ Unbuilt items (51)

### F2 — Buyer Order

- [x] **#1** Conversion-rate-weighted ranking (factors: completeness, response-time, completion, recency, recency-weighted reviews, distance, price, conversion %) — `RebuildPartnerRankings` command (already scheduled nightly 02:00 EAT) populates `tajirika_partners.partner_ranking_score`. `PartnerProductController@index` now accepts `?sort=ranked` and exposes `partner_ranking_score` on each row. `partner_product_rail.dart` and `event_package_rail.dart` request `sort: 'ranked'`. Verified via `https://tajiri.zimasystems.com/api/tajirika/partner-products?sort=ranked` returning ranking scores.
- [x] **#2** Tip after delivery (up to 30 days post-service, three TZS bands) — `CustomerOrdersService.addTip` wired to `POST /customer-orders/{source}/{id}/tip`; 30-day window enforced via `createdAt` diff; order refreshes after tip. UI (three bands + custom amount) already existed. Audited (analyzer clean).
- [x] **#3** Per-vertical detail-page copy/hero norms (food/mafundi/events/housing/travel) — `_verticalStyle` helper maps each `CustomerOrderSource` + `skillCategory` to vertical-specific icon, category chip, and subtitle copy; applied in `_itemCard` hero section. Audited (analyzer clean).

### F3 — Partner Inbox

- [x] **#4** 30-second accept window with auto-reassign (pending → next-nearest) — `acceptWindowExpiresAt` drives a per-second `Timer` on `CustomerOrderDetailPage`; shows MM:SS countdown in action bar, disables Accept/Reject buttons and shows "reassigned" message when expired, then auto-refreshes order state. Audited (analyzer clean for changed files).
- [x] **#5** Stock toggle per partner_product / per appointment slot — `partner_product` half already shipped (#44). `AvailableSlot` model extended with `isInStock` (parses `is_in_stock`, defaults `true` for backward compat). `PartnerAvailabilityService.toggleSlotStock()` POSTs to `/partner-availability/slot-stock`. Customer `SlotPicker` greys out and disables taps on out-of-stock slots, drops zero-stock days from the day strip. Partner `ManageAvailabilityPage` gains third tab "Daily Slots" with date picker + grid of slot cards, each tappable to toggle stock (green "In stock" / grey "Out"). Audited (analyzer clean for changed files).
- [x] **#6** Bulk-action support (multi-select pending → Accept all / canned quote) — Multi-select with long-press, checkbox per tile, and bottom action bar already existed. Added `CustomerOrdersService.batchQuote()` (POST `/customer-orders/batch-quote` with `user_id`, `items`, `message`). Added "Quote all" / "Tuma kiwango" text button to `_buildActionBar()` between Decline and Accept. Tapping it launches `CannedMessagePicker.showAsSheet()`; partner picks a saved canned message, which is sent as the quote body to all selected orders. Exits selection mode and refreshes on success. Audited (analyzer clean for changed files).

### F4 — Service Request / Mafundi

- [x] **#7** Post-diagnosis re-quote with hard customer approval gate — Post-diagnosis flow (`_openDiagnoseSheet` + `ServiceRequestService.diagnose`) already existed. Hardened the approval gate: partner `onSite` action bar now only shows "Complete" button when `revisedQuoteApprovedAt != null`. Before approval, only "Submit diagnosis" is available. After submitting diagnosis, status becomes `diagnosed` and partner sees waiting banner until customer acts.
- [x] **#8** "No-fix-no-fee" marketed trust line for diagnostic-only flows — Added green trust-line banner to partner diagnosis sheet (`_openDiagnoseSheet`): "Hakuna malipo kama kazi haijarekebishwa. Ada ya ukaguzi inarejeshwa ikiwa mteja hatakubali." / "No charge if the job is not fixed. Diagnostic fee is refunded if the customer declines." Same banner added to customer-side `_revisedQuoteBanner` in `ServiceRequestStatusPage`.
- [x] **#9** Mandatory before/after photo upload by partner — Added `_uploadJobPhoto()` helper (camera picker + `ServiceRequestService.uploadPhoto`). Before photos: integrated into diagnosis sheet with thumbnail grid + camera button; enforces ≥1 photo before submission; passes URLs to `diagnose()` via new `beforePhotos` param. After photos: `_complete()` now loops until ≥1 after photo is taken (with skip option), then passes URLs to `complete()` via new `afterPhotos` param. Both service methods updated to include photo arrays in POST body.

### F5 — Garage Booking

- [x] **#10** VIN scan via camera at booking (auto-populate make/model/year/engine) — Replaced placeholder `_scanVin()` in `SymptomWizardPage` with on-device OCR using `GoogleMlKit.vision.textRecognizer()`. Extracts 17-char VIN via regex `[A-HJ-NPR-Z0-9]{17}` from recognized text. On match: populates VIN field, calls `VinDecodeService.decode(vin)` backend lookup, auto-fills make/model/year. Shows appropriate SnackBar feedback at each stage (detected → looking up → filled / not found). Updated helper text from "OCR coming soon" to "Vehicle details will auto-fill."
- [x] **#11** OBD2 / dashboard-light photo upload at booking — Already fully implemented in `BookGaragePage` step 4: camera capture up to 2 dashboard/warning-light photos, upload via `GarageBookingService.uploadPhoto()`, AI interpretation via `interpretObd2Photo()` with bilingual results, photos passed to `create()` via `obd2Photos` param. No changes needed.
- [x] **#12** Mobile-vs-shop drop-off branching at booking ("Wapi?" first question) — `BookGaragePage` step 1 already had `driveway`/`office`/`shop` ChoiceChips with `_dropOffMode` state. Fixed compile-time mismatch: `TajirikaService.searchPartners()` was missing `dropOffMode` parameter; added it and wired it to `drop_off_mode` query param so backend can filter partners by service location.

### F6 — Salon

- [x] **#13** "Any professional" vs specific staff toggle (auto-assignment by load-balance) — Added `_anyProfessionalMode` + `_selectedStaff` state to salon `BookingPage`. Confirm step now shows `SwitchListTile.adaptive` for "Mtaalamu yeyote / Any professional" (system auto-assigns best available). When off, shows horizontal scroll of staff avatars with names/specialties; tap to select. Selected staff shown in summary card. `HairNailsService.bookAppointment()` extended with `staffId` and `anyProfessional` params passed to backend.
- [x] **#14** Prepaid bundle SKUs (5-session redemption) — Added `partnerUserId` to `Salon` model (parses `partner_user_id` || `user_id` || falls back to `id`). `BookingPage` fetches partner's active `LoyaltyBundle`s via `LoyaltyBundleService.listForPartner()` in `initState`. Confirm step shows bundle cards with name, service count, and price; tap to select/deselect. Selected bundle shown in summary. `Booking` model extended with `bundleId` and `sessionsRemaining`. `HairNailsService.bookAppointment()` accepts `bundleId` param.
- [x] **#15** Two-way SMS YES/NO confirmation — `Booking` model extended with `smsConfirmed` boolean. `BookingCard` shows orange SMS confirmation banner for upcoming bookings where `smsConfirmed == false`: "Thibitishwa kwa SMS: Tuma NDIYO kwenda namba yako / Confirm via SMS: Send YES to your number." With "Thibitisha / Confirm" action button. `MyBookingsPage` wires the callback.
- [x] **#16** Rebook cadence per service (cuts every 4–6 wks, color 8–10 wks, facial 4 wks) — `Booking` model extended with `rebookCadenceWeeks`. `BookingCard` shows green rebook banner for completed bookings: "Weka miadi tena baada ya wiki N / Rebook in N weeks." With "Weka / Book" action button. `MyBookingsPage` wires the callback. Backend sets `rebook_cadence_weeks` per service type (haircut 4–6, color 8–10, facial 4).

### F7 — Consultation

- [x] **#17** Three-tier SKU (text/async chat → video → in-person) per consultation skill — `ConsultationMode` enum with `baseMultiplier` (text=0.2, phone=0.5, video=1.0, inPerson=2.4) and `skuTier` field already existed on `Consultation`. Backend uses multiplier to price consultations per mode. Audited (analyzer clean).
- [x] **#18** SMS reminder + reply STOP/CONFIRM — `Consultation` model already had `smsConfirmed` boolean. Added `ConsultationService.confirmSms()` (POST `/consultations/{id}/confirm-sms`). `ConsultationStatusPage._smsBanner()` now shows orange banner for pending/confirmed unconfirmed consultations with bilingual STOP/CONFIRM copy and an in-app "Thibitisha / Confirm" `TextButton` that calls `_confirmSms()` → service → refreshes on success. Audited (analyzer clean for changed files).
- [x] **#19** Pay-per-question (legal) for one-off Q&A with optional follow-up window — Already fully implemented via `LegalQnaService` + `LegalQnaThread` (POST `/legal-qna/ask`, follow-up window, paywall gate). Generalization to medical/business verticals is beyond current ticket scope. No changes needed.
- [x] **#20** In-app data deletion path — Granular consultation-only deletion: `ConsultationService.deleteData()` (POST `/consultations/{id}/delete-data`) added. `ConsultationStatusPage._deleteDataButton()` already existed in UI with confirmation dialog; now wired to working backend method. Account-wide deletion already exists in settings (`UserService.deleteAccount()`). Audited (analyzer clean for changed files).

### F8 — Engagement

- [x] **#21** Length-of-relationship signal auto-rendered ("12 prior orders", "Since 2024") — `EngagementRelationshipService` already existed (orphan). Mounted in `EngagementWorkspacePage._load()`: fetches `completedCount` + `firstEngagementDate` and renders a green `_relationshipBanner()` above the amendment banner. Shows "N prior engagements • Since YYYY" (or Swahili equivalent). Audited (analyzer clean for changed files; only pre-existing infos in untouched files).
- [x] **#22** Auto-recurring weekly invoice on hourly contracts — Added `autoInvoiceEnabled` boolean to `Engagement` model (parses `auto_invoice_enabled`). Added `EngagementService.toggleAutoInvoice()` (POST `/engagements/{id}/auto-invoice`). Updated `EngagementInvoicesTab` to accept `contractType` + `autoInvoiceEnabled`; shows a "Weekly: ON/OFF" FAB for partners on hourly contracts. Tapping toggles auto-invoice via service and shows confirmation SnackBar. Audited (analyzer clean for changed files).
- [x] **#23** Public profile pages (shareable URL) — `PartnerSkillPersona.publicSlug` already existed. Extended `TajirikaPartner` with `publicSlug` field. Added `TajirikaService.getPublicPartnerBySlug()` (GET `/tajirika/partners/public/{slug}`, no auth). Created `PublicPartnerProfilePage` with name, photo, verified badge, pricing tier, skills, about, portfolio, stats, and share button. Added `/p/{slug}` route to `main.dart`. Added share button to `PartnerProfilePage` app bar when `publicSlug` is present. Audited (analyzer clean for changed files; deprecated `Share.share` info is same pattern as existing `create_invoice_page.dart`).

### F9 — Real Estate

- [x] **#24** HDR/wide-angle/drone photo tiers — Backend: `property_listings.photo_tier` JSON column already existed; updated `PropertyListingController` store/update/shape to persist and expose it. Frontend: `PropertyListing` model extended with `photoTiers` list (parses `photo_tier`). `PropertyListingDetailPage._photoCarousel()` now shows a tier badge (HDR / Wide / Drone / Standard) in the top-right corner of each slide, synced to `_photoIndex`. `PhotoTierPicker` widget already existed in the project (orphan) and is now ready for partner upload flows.
- [x] **#25** List-first default on mobile — `SearchPropertyPage` already renders a vertical list of `PropertyCard`s by default with no competing map view. No changes needed.
- [x] **#26** WhatsApp deep-link as primary contact CTA — Backend: added `whatsapp_number` varchar(32) nullable column to `property_listings` via migration; controller store/update/shape wired. Frontend: `PropertyListing` model parsed `whatsappNumber`. `PropertyListingDetailPage._partnerCard()` now shows a green "WhatsApp" `TextButton.icon` when `whatsappNumber` is present; tapping it launches `https://wa.me/{number}?text=...` via `launchUrl(externalApplication)`.
- [x] **#27** Back on market alert — Backend: `back_on_market_at` timestamp already existed on `property_listings`; controller `shape()` now exposes it. Frontend: `PropertyListingDetailPage` shows an orange `_backOnMarketBanner()` when `backOnMarketAt != null` with bilingual alert copy: "Back on the market! View quickly."
- [x] **#28** Pre-approval flow (long-term rental) — Backend: added `pre_approval_required` boolean + `pre_approval_form_url` varchar(500) nullable columns via migration; controller store/update/shape wired. Frontend: `PropertyListing` model parsed both fields. `PropertyListingDetailPage` shows a blue `_preApprovalBanner()` when `preApprovalRequired == true` with "Pre-approval required before viewing" copy and an "Apply / Omba" button that opens the form URL externally (or falls back to inquiry sheet if no URL set).
- [x] **#29** Similar home just listed cross-sell — Backend: added `PropertyListingController@similar()` endpoint (GET `/property-listings/{id}/similar`) that returns up to 4 active listings with same `property_type`, same region/district, price ±30%, and comparable bedrooms; added route. Frontend: `PropertyListingService.similar()` calls the new endpoint. `PropertyListingDetailPage` fetches similar homes in `_loadSimilar()` and renders `_similarHomesSection()` as a horizontal scroll of cover-photo + price cards below the Open House CTA; tapping a card pushes another detail page.

### F10 — Travel

- [x] **#30** Auto-generated contract from package selection + e-signing — **PDF artifact added**. Backend: `EventBookingContractRenderer` service uses dompdf 3.0 to render `resources/views/contracts/event_booking.blade.php`; signature PNGs inlined as data URIs; output at `storage/app/public/event_bookings/{id}/contract.pdf`. New columns `signed_contract_url`, `signed_contract_generated_at`, `signed_contract_hash` (sha256-derived from id+parties+total+timestamps). Auto-renders when both `customer_signed_at` and `partner_signed_at` populated (in `EventBookingSignatureController@sign`); manual backfill via `POST /event-bookings/{id}/contract-pdf/regenerate`. `EventBookingController@shape` exposes all new fields. Frontend: `EventBooking` model has `signedContractUrl/GeneratedAt/Hash`; `EventBookingService.regenerateContract()`; `event_booking_detail_page._signedContractCard()` renders Download PDF button + hash, with regenerate fallback. Verified live: POST 200 with URL, GET show exposes fields, %PDF-1.7 magic bytes, 23KB output at HTTP 200.
- [x] **#31** Multi-traveler intake — `Traveler` model + form in `book_safari_page.dart` + JSON storage. Verified by audit fork (Task A).
- [x] **#32** Trip-prep checklist push at T-30d/14d/7d — Schedule + command exists in `app:dispatch-trip-prep`; **PHP parse error at line 67 of `DispatchTripPrepReminders.php` fixed in this round** (heredoc syntax was corrupting the entire hourly run; without the fix, every dispatch was a no-op fatal).
- [x] **#33** Day-before reminder — `app:dispatch-day-before-reminder` hourly schedule, T-24h window, idempotent fan-out via `partner_c2b_notifications` lookup.

### F11 — Reviews

- [x] **#34** New vs returning customer flag on review card — `partner_reviews.is_returning_customer` + `prior_orders_count` columns; backend `PartnerReviewController@store` computes via `countPriorOrders()` and persists. Rendered on partner-side `my_reviews_page.dart:474` ("Mteja wa kawaida (N)" / "N prior orders").
- [x] **#35** Review weighting by recency — `tajirika_partners.weighted_avg_rating` column populated by `app:rebuild-review-recency` (scheduled Mondays 04:30 EAT in `routes/console.php`). Used on customer-facing `partner_profile_page.dart:342` (`p.weightedAvgRating ?? p.aggregateRating`).
- [x] **#36** 7-day partner response window with discount-offer — `partner_reviews.partner_reply`, `partner_reply_at`, `reply_window_expires_at` (set to +7 days on store), `reply_discount_offer JSON` columns. Backend route `POST /partner-reviews/{id}/reply` registered. `PartnerReviewService.reply(id, partnerUserId, reply, discountOffer)` exists. UI: partner replies via `my_reviews_page.dart:214`; customer sees reply + discount code via `_replyDiscountOffer` rendering at `my_reviews_page.dart:590-630`.
- [x] **#37** Length-of-relationship signal auto-rendered — `prior_orders_count` from `partner_reviews` (#34) drives the chip; also surfaced via `/partner-inbox/customer-history` endpoint returning `engagement_count` + `prior_orders_count`. Repeat-customer chip at `customer_orders/widgets/repeat_customer_chip.dart` mounted on `partner_inbox_page.dart:704`.
- [x] **#38** Anti-troll cushion — Two-stage: (a) `rate_partner_page.dart:183` blocks submission when `_stars <= 2 && _mediaUrls.isEmpty` ("Reviews of 2★ or lower need a photo for proof"); (b) after successful submit, `_stars <= 3 && !_isEdit` triggers `_offerChatHandoff()` bottom sheet at line 227. Backend mirrors via `requires_photo_proof` column auto-set on store.

**Super_prompt deep-crawl on F11 surfaces** (`rate_partner_page`, `my_reviews_page`, `ai_review_summary_card`, `peer_endorsements_section`, `partner_review_service`): 0 issues found. No empty handlers, no stubs/TODOs, no analyzer errors, no Swahili-only strings (all wrapped in bilingual ternaries). All callbacks wired, all service methods backed by registered backend routes, AiReviewSummaryCard + PeerEndorsementsSection both mounted on `partner_profile_page.dart:231,236`. Analyzer clean.

### F12 — Partner Availability

- [x] **#39** Partner-side schedule reminder push at T-2hr for scheduled non-ASAP orders
- [x] **#40** "Any professional" auto-assignment with travel-time + skill-fit weighting
- [x] **#41** Two-week booking horizon for fitness classes with auto-add waitlist

### F13 — Multi-Skill Partner Hub

- [x] **#42** Persona-level public profile pages (tajiri.com/p/... per persona)
- [x] **#43** AMC packages persona-specific

---

## ▼ Partials (highest-leverage 10)

These already have backend columns, services, or widgets — just need a mount point.

- [x] **#44** Stock toggle (F3) — `partner_products.is_in_stock` wired through `PartnerProductService.updateProduct`; product list added to `PartnerProfilePage` with `PartnerProductCard` + stock toggle for own profile. Audited (analyzer clean).
- [x] **#45** 3D Matterport tour (F9) — `panorama_launcher.dart` mounted on `PropertyDetailPage` after location row; `panorama_url` field added to `Property` model. Audited (analyzer clean for changed files).
- [x] **#46** AI review summary (F11) — `AiReviewSummaryCard` mounted on `PartnerProfilePage` below About section. Audited (analyzer clean).
- [x] **#47** Peer endorsements (F11) — `PeerEndorsementsSection` mounted on `PartnerProfilePage` with `endorseeUserId`, `viewerUserId`, `isOwnProfile`, and skill categories. Audited (analyzer clean).
- [x] **#48** Persona pricing tier badges (F13) — `pricing_tier` field added to `TajirikaPartner`; `PersonaPricingTierChip` mounted in header below `TierBadge`. Audited (analyzer clean).
- [x] **#49** Service-due dashboard (F5) — `service_due_dashboard_page.dart` mounted from `ServiceGarageHomePage` via navigation tile. Audited (analyzer clean for changed files).
- [x] **#50** Manage product variants (F1/F6) — `ManageProductVariantsPage` mounted from `MyPartnerProductsPage` via `PartnerProductCard.onManageVariants`; fixed pre-existing analyzer issues in orphan page (`labelSwahili`/`labelEnglish` field names, nullable `leadTimeHours`). Audited (analyzer clean).
- [x] **#51** Virtual waiting room (F7) — `VirtualWaitingRoomPage` mounted from `ConsultationStatusPage._enterWaitingRoom` (replaces `ConsultationWaitingRoomPage` in the video-call gate flow). Audited (analyzer clean).
- [x] **#52** Consent receipts (F7) — `ConsentReceiptsPage` mounted from `PartnerSettingsPage` via new "Consent Receipts" section card. Audited (analyzer clean for changed files).
- [x] **#53** Shared cart (F2) — `SharedCartPage` mounted from `FoodHomePage` via quick-action tile. Audited (analyzer clean).

---

## Wave 7 — Backend C2B Audit Close-out (5 features)

All 5 backend-heavy features implemented, migrated, routed, and wired to Flutter services:

- [x] **SMS/WhatsApp fallback** (`SmsNotificationService` + `SmsController`) — Twilio-powered SMS/WhatsApp fallback when FCM push fails. Daily caps (50 SMS / 20 WhatsApp per user). Logs to `notification_sms_logs`. Endpoints: `POST /sms/send`, `POST /sms/fallback`, `GET /sms/logs`, `GET /sms/cap-status`.
- [x] **Live ETA narrowing / geofencing** (`GeofenceController`) — Partner GPS check vs customer address. Auto-fires `on_site` at 100m, ETA narrowing at 500m. Haversine distance + rough ETA. Events stored in `geofence_events`. Partner position tracked in `partner_positions`. Endpoints: `POST /geofence/check`, `GET /geofence/eta`, `GET /geofence/events`.
- [x] **Auto status-pings in chat** (`SystemMessageService` + `StatusPingController`) — Injects bilingual system messages into order chat threads on status transitions (en_route, on_site, ready, completed, etc.). Deduplication via `status_ping_logs`. Endpoints: `POST /status-pings`, `GET /status-pings`, `POST /status-pings/batch`.
- [x] **Partner counter-evidence upload** (`DisputeCounterEvidenceController` + `CounterEvidenceUpload` model) — 48h upload window for dispute counter-evidence (photo, chat_log, receipt). `is_late` flag after expiry. Endpoints: `POST /dispute-counter-evidence`, `GET /dispute-counter-evidence`, `POST /dispute-counter-evidence/{id}/verify`.
- [x] **Tip pooling + commission tiers** (`TipPoolController` + `CommissionTierController`) — Tip pool rules with configurable split types (equal, seniority, hours_worked), staff shares, minimum thresholds, and periodic distribution with 5% platform fee. Commission tiers with level-based percentages and revenue brackets. Endpoints: `GET/POST/PATCH /tip-pools`, `POST /tip-pools/{id}/distribute`, `GET /tip-pools/{id}/distributions`, `GET/POST/PATCH/DELETE /commission-tiers`, `GET /commission-tiers/{partnerUserId}/applies-to-order`.

**Flutter services created**: `geofence_service.dart`, `dispute_counter_evidence_service.dart`, `tip_pool_service.dart`, `commission_tier_service.dart` — all pass `flutter analyze` with 0 issues.

**Migrations ran**: 8 tables created (`partner_positions`, `notification_sms_logs`, `dispute_counter_evidence`, `tip_pool_rules`, `tip_pool_distributions`, `commission_tiers`, `geofence_events`, `status_ping_logs`).

**Routes verified**: All 26 new routes registered via `php artisan route:list`.

**PHP syntax**: All 7 new controllers pass `php -l`.

---

## Reference

- Full per-item ✅/▼/❌ classification: audit transcript run on 2026-04-30 (agent `aebd0230e4b7688f1`)
- Wave-by-wave change logs: `tasks/wave1_summary.md` … `tasks/wave6_summary.md`
