# Audit Report: Partner C2B User Journeys vs. Real Codebase

**Date:** 2026-04-29
**Spec:** `docs/modules/partner_c2b_user_journeys.md` (1,543 lines, 13 features + 9 foundational pattern areas)
**Repo:** `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`

---

## Executive Summary

| Metric | Result |
|--------|--------|
| **Page files required** | ~55 |
| **Page files exist** | ~55 (100%) |
| **Model files required** | ~11 |
| **Model files exist** | ~11 (100%) |
| **Service files required** | ~12 |
| **Service files exist** | ~12 (100%) |
| **Shared widgets required** | ~11 |
| **Shared widgets exist** | ~10 (91%) |
| **Backend API endpoints** | All 9 source families have endpoints |
| **Advanced backend columns** | ~70% threaded into Dart models |

**Verdict:** The codebase has **broad structural coverage** — almost every page, model, and service file referenced in the spec exists. However, **depth is uneven**: some features are production-ready (F9 Real Estate, F10 Events, F7 Consultation), while others have structural shells with incomplete UI wiring (F4 Service Request partner-side, F5 Garage partner-side, foundational patterns like escrow, disputes, and 30-second accept windows).

---

## 1. Feature-by-Feature Audit

### F1 — Partner Posting ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `post_partner_product_page.dart` | ✅ | 39KB, fully featured |
| `post_chef_product_page.dart` | 🟡 | 17KB, legacy, should be deprecated |
| Skill banner + ChoiceChip | ✅ | `_suggestedTagsFor(SkillCategory)` with 20+ skill branches |
| Tag suggestions | ✅ | Per-skill tag lists (cooking, baking, carpentry, plumbing, etc.) |
| Mode chips | ✅ | Pickup / Delivery / Both / Digital |
| Price band hints | 🟡 | Backend field exists; UI hint not confirmed |
| Photo upload | ✅ | Cover + additional photos |
| Active toggle | ✅ | `is_active` |
| Lead time validation | 🟡 | Field exists; 1-720 range validation not confirmed |
| **Productized SKUs** | ✅ | `is_legal_pack`, `catalog_sku_code` |
| **AMC bundles** | ✅ | `amc_visit_count`, `amc_validity_months` UI fields |
| **Service Variants** | ✅ | `_VariantDraft` list, `PartnerProductVariant` model |
| **Patch-test** | ✅ | `requires_patch_test` in model |
| **Add-ons** | 🟡 | Model support; UI wiring partial |
| **Photo quality checks** | ❌ | Not found |
| **Lead-time honesty score** | ❌ | Backend column `actual_lead_minutes_avg` exists; no frontend card |

**Gap:** Photo-quality auto-checks (blur/brightness/dimension), lead-time honesty score dashboard card, and explicit photo-guideline cards per cluster are missing.

---

### F2 — Buyer Order ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| Detail pages (6 verticals) | ✅ | All `partner_product_detail_page.dart` exist |
| `partner_product_card.dart` | ✅ | Shared widget |
| `partner_product_rail.dart` | ✅ | Shared widget |
| Cluster-specific CTAs | ✅ | "Agiza sasa", "Omba huduma", "Hifadhi tarehe" etc. |
| Order sheet | ✅ | Found in `lib/food/pages/partner_product_detail_page.dart` |
| Quantity stepper | ✅ | |
| Mode picker | ✅ | |
| Delivery address | ✅ | |
| Notes field | ✅ | |
| Requested date/time | ✅ | |
| Total breakdown | ✅ | |
| **Reorder carousel** | 🟡 | `MyPartnerC2BActivityCard` exists; not confirmed as top rail |
| **Dietary filters** | ✅ | `halal`, `vegan`, `no_pork`, `gluten_free` in `food_settings_page.dart` |
| **Schedule vs ASAP** | 🟡 | `schedule_mode` column exists; toggle UI not confirmed |
| **Group/shared cart** | ❌ | `shared_cart_page.dart` exists but not wired as group cart |
| **Photo-proof delivery + PIN** | ❌ | Not found |
| **Tip after delivery** | ❌ | Not found |
| **Auto-credit on partner error** | ❌ | Not found |

**Gap:** Group/shared cart, photo-proof delivery with handoff PIN, tip-after-delivery, and auto-credit on detected error are missing.

---

### F3 — Partner Inbox 🟡 FUNCTIONAL BUT INCOMPLETE

| Item | Status | Evidence |
|------|--------|----------|
| `incoming_customer_orders_page.dart` | ✅ | 33KB, substantial |
| `customer_order_detail_page.dart` | ✅ | 36KB, substantial |
| `rate_partner_page.dart` | ✅ | 24KB, substantial |
| Source filter chips | ✅ | `_buildSourceChips()` — "All", "Products", "Services", "Appointments", etc. |
| Skill filter chips | ✅ | `_buildSkillChips()` — hidden when <2 skills |
| Bucket/status chips | ✅ | `_buildBucketChips()` — New, Active, Done, Cancelled |
| Order row with skill icon | ✅ | |
| Empty state | ✅ | |
| Action bar (Accept/Reject/Start/etc.) | ✅ | |
| Pull-to-refresh | ✅ | |
| **Bulk actions** | ❌ | Not found |
| **30-second accept window** | ❌ | Not found |
| **Auto-pause banner** | ✅ | `auto_pause_banner.dart` exists |
| **Lead-expiring countdown** | ❌ | Not found |
| **Partner KPI score** | ✅ | `PartnerKpiBadge` exists |
| **Weekly benchmark card** | ❌ | Not found |
| **Service-history chip** | 🟡 | `Mteja wa kawaida` found in `my_reviews_page.dart`; not in inbox row |
| **Voice notes / canned messages** | ❌ | Not found |
| **Dispatcher to source-specific pages** | 🟡 | `customer_order_detail_page.dart` appears generic; no clear routing to `consultation_detail_page.dart` or `engagement_workspace_page.dart` |

**Gap:** Bulk actions, 30-second accept window, lead-expiring countdown, weekly benchmark, and voice-note replies are missing. The unified inbox dispatcher may not route to source-specific detail pages as specified.

---

### F4 — Service Request (Mafundi) 🟡 CUSTOMER-SIDE STRONG, PARTNER-SIDE WEAK

| Item | Status | Evidence |
|------|--------|----------|
| `request_service_page.dart` | ✅ | Customer multi-step form |
| `service_request_status_page.dart` | ✅ | Status timeline, quotes, warranty badge |
| `service_request_detail_page.dart` | ✅ | Partner detail page |
| `incoming_service_requests_page.dart` | ✅ | **BUILT** 2026-04-29 |
| Skill picker | ✅ | |
| Problem summary | ✅ | |
| Photos upload | ✅ | |
| Address + lat/lng | ✅ | |
| Preferred window | ✅ | |
| Quote dialog | ✅ | Callout fee + estimated cost |
| Status timeline | ✅ | pending → quoted → accepted → en_route → on_site → completed |
| **AI cost estimation** | 🟡 | `ai_cost_low_tzs` in model; UI anchor band not confirmed |
| **Structured intake form** | ❌ | Not found |
| **Diagnostic fee credit** | 🟡 | `diagnostic_fee_tzs`, `diagnostic_fee_credited_tzs` in model |
| **Post-diagnosis re-quote** | ✅ | "Revised post-diagnosis quote" UI found |
| **Before/after photos** | ✅ | `beforePhotos`, `afterPhotos` in model |
| **Geofence "Arrived"** | ❌ | Not found |
| **Live ETA map** | ❌ | Not found |
| **Parts pass-through** | ❌ | `parts_line_items` in model; no UI editor |
| **Site-survey fee** | ❌ | Not found |

**Gap:** `incoming_service_requests_page.dart` is missing entirely. Partner-side quote management exists in `service_request_detail_page.dart` but lacks a dedicated list view. Geofence, live ETA, parts editor, and site-survey fee are missing.

---

### F5 — Garage Booking 🟡 CUSTOMER-SIDE STRONG, PARTNER-SIDE WEAK

| Item | Status | Evidence |
|------|--------|----------|
| `book_garage_page.dart` | ✅ | |
| `garage_status_page.dart` | ✅ | Warranty card, vehicle card, fault card, OBD2 photos |
| `garage_booking_detail_page.dart` | ✅ | |
| `incoming_garage_bookings_page.dart` | ✅ | **BUILT** 2026-04-29 |
| Skill picker | ✅ | |
| Vehicle fields | ✅ | |
| Fault summary + photos | ✅ | |
| Drop-off slot picker | ✅ | |
| Estimated cost cap | 🟡 | |
| Diagnosis flow | ✅ | `diagnosed` status, customer approval |
| **OBD2 photo upload** | ✅ | `obd2Photos` in model + UI |
| **Mobile vs shop drop-off** | ✅ | `dropOffMode` in model + UI |
| **Vehicle profile / service history** | ✅ | `customer_vehicle_service.dart`, `vin_decode_service.dart` |
| **Symptom wizard** | ✅ | `symptom_wizard_page.dart` |
| **AMC** | ✅ | `kind = 'amc'` reuse |
| **Recall lookup** | 🟡 | `open_recalls` mentioned |
| **Mileage-based reminders** | ✅ | `next_service_at_km/date` |
| **Body-shop bidding** | ❌ | Not found |
| **Service-due dashboard** | ✅ | `ServiceDueDashboardPage` shipped |

**Gap:** `incoming_garage_bookings_page.dart` missing. Body-shop bidding on photos alone not found.

---

### F6 — Appointment (Salon/Fitness) ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `book_hair_nails_appointment_page.dart` | ✅ | |
| `book_fitness_session_page.dart` | ✅ | |
| `appointment_detail_page.dart` | ✅ | |
| `manage_availability_page.dart` | ✅ | Weekly hours + Blackouts tabs |
| `slot_picker.dart` | ✅ | |
| Service picker | ✅ | |
| Location kind | ✅ | |
| Slot picker 7-day grid | ✅ | |
| Address for home visits | ✅ | |
| Notes field | ✅ | |
| Status timeline | ✅ | pending → confirmed → checked_in → in_progress → completed |
| **Hair-type taxonomy** | ✅ | Filter chips |
| **Patch-test dependency** | ✅ | |
| **Photo consent** | ✅ | |
| **Pre-appointment intake** | ✅ | `beauty_profile_service.dart` |
| **Multi-staff bookings** | 🟡 | `multi_staff_slots` in model; UI not confirmed |
| **"Any professional" toggle** | 🟡 | `any_professional_mode` in model |
| **Travel surcharges** | 🟡 | Columns in model |
| **Loyalty stamps** | 🟡 | `loyalty_stamp_card.dart`, `loyalty_stamp_service.dart` exist |
| **Waitlist mode** | 🟡 | `waitlist_mode` in model |
| **Rebook cadence** | 🟡 | `rebook_cadence_days` in model |
| **Recurring booking** | 🟡 | `is_recurring` in model |
| **Cancellation policy tiers** | 🟡 | `cancellation_tier` in model |

**Gap:** Multi-staff booking UI, "Any professional" toggle UI, and travel surcharge line-item editor need confirmation. Loyalty stamp UI exists but may not be fully wired.

---

### F7 — Consultation ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `book_legal_consultation_page.dart` | ✅ | |
| `book_medical_consultation_page.dart` | ✅ | |
| `book_business_consultation_page.dart` | ✅ | |
| `consultation_detail_page.dart` | ✅ | |
| `consultation_intake_form.dart` | ✅ | |
| `nda_acceptance_gate.dart` | ✅ | |
| NDA gate | ✅ | |
| Mode picker (in_person/phone/video) | ✅ | |
| Slot picker | ✅ | |
| Duration picker | ✅ | |
| Intake summary (encrypted) | ✅ | |
| Attachment upload | ✅ | |
| Wallet pre-auth | ✅ | |
| WebRTC join | ✅ | |
| Prescription field | ✅ | `erx_pharmacy`, `erx_qr_code` |
| Follow-up notes | ✅ | `visit_notes`, `care_plan` |
| **Three-tier SKU** | ✅ | `sku_tier` in model |
| **NHIF/AAR/Jubilee filter** | ✅ | Shipped session 16 |
| **Symptom checker** | ✅ | `symptom_checker_sheet.dart` |
| **Conversational AI triage** | 🟡 | `symptom_checker_sheet.dart` exists; 6-turn chat not confirmed |
| **Pre-visit intake** | ✅ | `pre_visit_intake_completed` |
| **Derm photo intake** | ✅ | `derm_intake_photos` |
| **Pre-call test** | 🟡 | `connectivity_test_passed` in model |
| **Consent screens** | ✅ | `consent_screens_signed` |
| **Follow-up cadence** | ✅ | `followup_due_at` |
| **Retainer UI** | ✅ | `is_retainer`, `retainer_hours_per_month` |
| **Screenshot blocking** | ❌ | Not found |
| **FLAG_SECURE** | ❌ | Not found |

**Gap:** Screenshot blocking (`FLAG_SECURE`) on prescription/NDA screens is missing. Conversational AI triage may be single-shot rather than 6-turn chat.

---

### F8 — Engagement ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `engagement_proposal_review_page.dart` | ✅ | |
| `engagement_workspace_page.dart` | ✅ | TabController-driven |
| `propose_engagement_page.dart` | ✅ | |
| `engagement_dashboard_page.dart` | ✅ | |
| Proposal form | ✅ | Title, scope, pricing model, milestones |
| Proposal review (Accept/Counter/Reject) | ✅ | |
| Milestones tab | ✅ | |
| Time entries tab | ✅ | |
| Invoices tab | ✅ | |
| Files tab | ✅ | |
| Chat tab | ✅ | |
| **Escrow + milestone release** | 🟡 | Backend comment found; UI not fully confirmed |
| **Job Success Score** | ✅ | `JssBadge` |
| **Three contract types** | ✅ | `fixed_price`, `hourly`, `productized` |
| **Five-event milestone fan-out** | ✅ | Notifications shipped |
| **Lead-credit model** | ✅ | `lead_credit_tzs` in model |
| **Dispute window** | 🟡 | `dispute_window_started_at` in model |
| **Public profile pages** | 🟡 | `public_slug` in model; SSR web route not confirmed |

**Gap:** Escrow UI may be partial. Public profile pages (`tajiri.com/p/{slug}`) need web route confirmation.

---

### F9 — Real Estate ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `housing_home_page.dart` | ✅ | |
| `property_listing_detail_page.dart` | ✅ | |
| `property_inquiry_page.dart` | ✅ | |
| `post_property_listing_page.dart` | ✅ | |
| `my_listings_page.dart` | ✅ | |
| `incoming_property_inquiries_page.dart` | ✅ | |
| Filter chips | ✅ | |
| Photo carousel | ✅ | |
| Map view | ✅ | |
| Stats grid | ✅ | |
| Amenities chips | ✅ | |
| Partner card | ✅ | |
| Inquiry form | ✅ | Viewing / Offer / Question |
| WhatsApp CTA | ✅ | `_whatsAppAgent()` in `property_detail_page.dart` |
| **Walk/Bike/Transit Score** | ✅ | `walkScore`, `bikeScore`, `transitScore` in model |
| **Save-search digest** | ✅ | `saved_search_service.dart` |
| **Open-house RSVP** | ✅ | |
| **Pre-qualification** | ✅ | Shipped session 16 |
| **Photo verification** | 🟡 | `photo_verification_status` in model |
| **Location obfuscation** | 🟡 | `obfuscate_location_until_inquiry` in model |
| **Matterport/3D tour** | 🟡 | `matterport_enabled`, `matterport_url` in model |
| **Floor plan** | 🟡 | `floor_plan_urls` in model |
| **EPC band** | 🟡 | `epc_band` in model |
| **Polygon search** | 🟡 | `PolygonSearchService` exists |
| **Commute calculator** | ❌ | Not found |
| **Back-on-market alert** | ❌ | Not found |
| **Pre-approval flow** | ❌ | Not found |
| **Similar home cross-sell** | ❌ | Not found |

**Gap:** Commute calculator, back-on-market alert, pre-approval flow, and similar-home cross-sell are missing.

---

### F10 — Event Booking / Travel ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `book_event_package_page.dart` | ✅ | |
| `book_safari_page.dart` | ✅ | |
| `travel_home_page.dart` | ✅ | |
| `event_booking_detail_page.dart` | ✅ | |
| Event title, kind, date | ✅ | |
| Party size | ✅ | |
| Add-ons | ✅ | |
| Deposit breakdown | ✅ | 50% default, deposit due tracking |
| Safari itinerary | ✅ | Day-by-day rows |
| Status flow | ✅ | pending → held → deposit_paid → confirmed → day_of → completed |
| **Backup performer** | ✅ | `backup_performer` in model |
| **Force majeure** | ✅ | `force_majeure_at` in model |
| **Payment plan** | ✅ | `payment_plan_installments` in model |
| **Song requests** | ✅ | `song_requests` in model |
| **Travel radius** | ✅ | `travel_radius_km` in model |
| **QR voucher** | ✅ | `qr_voucher_code` in model |
| **Early bird / group discount** | ✅ | `early_bird_applied`, `group_discount_applied` in model |
| **Per-stop reviews** | ✅ | `per_stop_reviews` in model |
| **Migration season calendar** | ✅ | `MigrationSeasonCalendar` shipped |
| **TALA badge** | 🟡 | `tala_license_number`, `tala_verified` in model |
| **Multi-traveler intake** | 🟡 | `travelers` support |
| **Trip-prep checklist** | ❌ | Not found |
| **Day-before reminder** | ❌ | Not found |
| **On-tour live updates** | ✅ | `my_trip_page.dart` built 2026-04-29 |
| **Travel insurance upsell** | ❌ | Not found |

**Gap:** Trip-prep checklist, day-before reminder, on-tour live updates page (`my_trip_page.dart`), and travel insurance upsell are missing.

---

### F11 — Reviews ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `rate_partner_page.dart` | ✅ | |
| `my_reviews_page.dart` | ✅ | |
| Stars (1-5) | ✅ | |
| Comment | ✅ | |
| Tags | ✅ | |
| Anonymous toggle | ✅ | |
| Partner reply | ✅ | |
| **Multi-dimensional rating** | ✅ | `dimensions` in model + service |
| **Per-item thumbs** | ✅ | `PerItemThumbsPicker` shipped |
| **Photo/video reviews** | ✅ | `mediaUrls` in model |
| **Verified booking badge** | ✅ | `is_verified_booking` in model |
| **Helpfulness vote** | ✅ | `helpfulnessYes`, `helpfulnessNo` + UI row |
| **Peer endorsements** | ✅ | `PeerEndorsementsSection` |
| **AI review summary** | ✅ | `AiReviewSummaryCard` |
| **Returning customer flag** | ✅ | `is_returning_customer`, `prior_orders_count` |
| **Reply discount offer** | 🟡 | `reply_discount_offer` in model |
| **Review weighting by recency** | ❌ | Not found |
| **Disease-specific outcome** | ❌ | Not found |

**Gap:** Review weighting by recency and disease-specific outcome tracking are missing.

---

### F12 — Availability ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `manage_availability_page.dart` | ✅ | |
| `slot_picker.dart` | ✅ | |
| Weekly hours tab | ✅ | 7 day rows |
| Blackouts tab | ✅ | |
| ON/OFF toggle | ✅ | |
| Time pickers | ✅ | |
| Slot minutes | ✅ | |
| Skill scope picker | ✅ | |
| **Configurable reminder timing** | ✅ | `reminder_cadence_hours` |
| **Peak/shoulder/low pricing** | ✅ | `pricing_modifier_pct` |
| **Recurring blackout** | 🟡 | Mentioned in spec; UI not confirmed |
| **Booking lead time/horizon** | 🟡 | `booking_horizon_days`, `min_notice_minutes` in model |
| **Last-minute discount** | 🟡 | `last_minute_discount_enabled` in model |
| **Waitlist mode** | 🟡 | `waitlist_mode` in model |
| **VIP standing slot** | ❌ | Not found |
| **Auto-add waitlist** | ❌ | Not found |

**Gap:** VIP standing-slot reservation and auto-add waitlist FIFO/SMS blast are missing.

---

### F13 — Multi-Skill Hub ✅ STRONG

| Item | Status | Evidence |
|------|--------|----------|
| `tajirika_home_page.dart` | ✅ | Skill switcher pill row |
| `manage_skills_page.dart` | ✅ | |
| `skill_persona_page.dart` | ✅ | |
| `skill_switcher.dart` | ✅ | |
| Skill switcher pills | ✅ | |
| All-skills aggregated view | ✅ | |
| Per-skill filtered view | ✅ | |
| Add Skill FAB | ✅ | |
| Persona config | ✅ | Display name, photo, bio, pricing tier |
| Pause/Resume skill | ✅ | `SkillPauseToggle` |
| **Per-skill JSS** | ✅ | `job_success_score` in `partner_skill_persona.dart` |
| **Persona-level public_slug** | ✅ | `public_slug` in model |
| **Cross-persona dashboard** | 🟡 | `PartnerC2BMetricsDashboard` exists; time-allocation vs revenue-mix not confirmed |
| **Cross-persona unified inbox** | 🟡 | Inbox has skill chips; dedupe not confirmed |
| **"Save my partner" per persona** | 🟡 | `CustomerPartnerFavoriteService` exists |

**Gap:** Cross-persona time-allocation vs revenue-mix dashboard with opportunity cost may be partial.

---

## 2. Foundational Patterns Audit

| Pattern Area | Status | Notes |
|-------------|--------|-------|
| **A. Trust & Verification** | |
| Tiered partner badges | ✅ | `PartnerTier` enum (mwanafunzi/mtaalamu/bingwa) |
| NIDA + selfie KYC | ✅ | `VerificationItem nida` in model |
| Skill-specific license verification | 🟡 | TALA for tours; MCT/TLS/NBAA not confirmed in UI |
| Insurance display + expiry tracking | 🟡 | Only in `my_cars`; not partner-profile |
| Photo consent toggle | ✅ | |
| Screenshot blocking (FLAG_SECURE) | ❌ | Not found |
| **B. Discovery & Ranking** | |
| Composite ranking algorithm | 🟡 | `content_engine_models.dart` has ranking scores |
| Hard filters (halal/NHIF/hair-type) | 🟡 | Halal/vegan in food; hair-type in hair_nails; NHIF not confirmed |
| List-first over map-first | ✅ | Default in housing |
| WhatsApp deep-link CTA | ✅ | Housing + events |
| Photo-count gating | 🟡 | `photo_verification_status` in model |
| Saved-search push | ✅ | `SavedSearchService` |
| Response-time score | 🟡 | `kpi_response_pct` in model |
| Waiting-time badge | ❌ | Not found |
| **C. Notifications & Lifecycle** | |
| SMS + WhatsApp fallback | ❌ | Not found |
| 30-second accept window | ❌ | Not found |
| Auto-pause after 3 misses | 🟡 | `autoPausedAt`, `consecutiveMisses` in model; banner exists |
| Lead-expiring countdown | ❌ | Not found |
| Live ETA narrowing | ❌ | Not found |
| Rebook prompt at cadence | 🟡 | `rebook_cadence_days` in model |
| Photo-proof delivery + PIN | ❌ | Not found |
| Pre-call tech check | 🟡 | `connectivity_test_passed` in model |
| Post-visit care plan | 🟡 | `care_plan` in model |
| **D. Pricing & Payouts** | |
| Tiered SKUs (text/video/in-person) | ✅ | `sku_tier` in consultation model |
| Productized fixed-fee menus | ✅ | `is_legal_pack`, `catalog_sku_code` |
| Layered fee disclosure | 🟡 | Partial |
| Diagnostic fee credit | 🟡 | Model support |
| No-fix-no-fee | ❌ | Not found |
| Surge/urgency premiums | ❌ | Not found |
| Daily M-Pesa payout | ✅ | `DailyPayoutBadge` |
| Escrow + auto-release | 🟡 | Backend comment found; UI partial |
| Tip after delivery | ❌ | Not found |
| Lead-credit model | ✅ | `lead_credit_tzs` |
| **E. Communication** | |
| In-app chat with quote attachment | 🟡 | Chat exists; structured quote attachment not confirmed |
| Quote/message templates | ❌ | Not found |
| Voice notes + photo replies | ❌ | Not found |
| Masked phone numbers | ❌ | Not found |
| Privilege flag on legal threads | 🟡 | NDA gate exists; persistent UI label not confirmed |
| Auto status-pings | 🟡 | `PartnerC2BNotificationService` exists |
| **F. Disputes & Refunds** | |
| In-app dispute opener | ❌ | Not found |
| Tiered escalation | ❌ | Not found |
| Partner counter-evidence | ❌ | Not found |
| Self-report window (3 days) | ❌ | Not found |
| Auto-credit on partner error | ❌ | Not found |
| Redo-work warranty | ✅ | `warranty_days` in service_request + garage |
| **G. Recurring & Retention** | |
| "Save my partner" | ✅ | `CustomerPartnerFavoriteService` |
| Recurring schedule | 🟡 | `is_recurring` in appointment |
| AMC | ✅ | `amc_visit_count`, `amc_validity_months` |
| Service-due dashboard | ✅ | `ServiceDueDashboardPage` |
| Warranty tracking | ✅ | `warranty_claimed`, `warranty_km`, `warranty_days` |
| Loyalty stamps | 🟡 | `loyalty_stamp_card.dart`, `loyalty_stamp_service.dart` exist |
| Prepaid packages | 🟡 | `loyalty_bundle_service.dart` exists |
| **H. Partner Dashboard** | |
| Pause/busy-mode toggle | ✅ | `PartnerAvailabilityModeSheet` |
| Stock toggle per item | ✅ | `is_in_stock` in model |
| Unified queue | ✅ | `incoming_customer_orders_page.dart` |
| Prep-time accuracy score | ❌ | Not found |
| Bio-link / "Book with me" | ❌ | Not found |
| Auto-watermarked portfolio | ❌ | Not found |
| Business analytics | ✅ | `PartnerC2BMetricsDashboard` |
| **I. Onboarding & Growth** | |
| Short onboarding (3 screens) | 🟡 | `registration_page.dart` exists; 3-screen flow not confirmed |
| Pick skills chip multi-select | ✅ | |
| Skill-specific add-ons | 🟡 | Partial |
| Payout & ward config | 🟡 | Partial |
| AI hiring-brief generator | ✅ | `AiBriefSheet` |
| Profile completeness nudge | 🟡 | Found in models but not prominent |

---

## 3. Critical Gaps (High Priority)

### 🔴 Missing Pages
1. `lib/tajirika/pages/incoming_service_requests_page.dart` — Partner-side mafundi request list
2. `lib/tajirika/pages/incoming_garage_bookings_page.dart` — Partner-side garage booking list
3. `lib/travel/pages/my_trip_page.dart` — On-tour live updates for safari/multi-day tours

### 🔴 Missing Foundational Patterns
1. **30-second accept window with auto-reassign** — Core to partner responsiveness
2. **Escrow UI with milestone release** — Critical for engagement trust
3. **Dispute flow** — In-app dispute opener, tiered escalation, counter-evidence
4. **Tip after delivery** — Revenue opportunity, fits Tanzania culture
5. **Photo-proof delivery + handoff PIN** — Essential for delivery verification
6. **SMS + WhatsApp fallback** — Critical for Tanzania connectivity gaps
7. **Live ETA with map view** — Expected for mafundi/garage/food delivery
8. **Geofence-triggered "Arrived"** — Automation expected by partners

### 🟡 Partial Implementations
1. **Unified inbox dispatcher** — `customer_order_detail_page.dart` may be generic; needs to route to `consultation_detail_page.dart`, `engagement_workspace_page.dart`, etc.
2. **Loyalty stamps UI** — `loyalty_stamp_card.dart` exists but may not be mounted on all relevant pages
3. **Conversational AI triage** — May be single-shot instead of 6-turn chat
4. **Screenshot blocking** — `FLAG_SECURE` not implemented on sensitive screens
5. **Profile completeness nudge** — Exists in data model but not as prominent UI chip

---

## 4. Backend Integration Status

| Source Family | Endpoint Prefix | Model Coverage |
|--------------|-----------------|----------------|
| Partner Products | `/tajirika/partner-products` | ✅ Strong |
| Service Requests | `/service-requests` | ✅ Strong |
| Garage Bookings | `/garage-bookings` | ✅ Strong |
| Appointments | `/appointments` | ✅ Strong |
| Consultations | `/consultations` | ✅ Strong |
| Engagements | `/engagements` | ✅ Strong |
| Property Listings | `/property-listings` | ✅ Strong |
| Event Bookings | `/event-bookings` | ✅ Strong |
| Partner Reviews | `/partner-reviews` | ✅ Strong |
| Partner Availability | `/partner-availability` | ✅ Strong |
| Partner Skill Personas | `/partner-skill-personas` | ✅ Strong |

**Note:** `php artisan migrate` is broken on the production server (legacy `user_profiles` conflict). All schema changes are applied via SCP'd PHP scripts. This is documented and operational.

---

## 5. Recommendations

### Immediate (This Sprint)
1. **Create `incoming_service_requests_page.dart`** — Partner-side list for mafundi quotes
2. **Create `incoming_garage_bookings_page.dart`** — Partner-side list for garage bookings
3. **Wire inbox dispatcher** — Ensure `customer_order_detail_page.dart` routes to source-specific pages
4. **Implement 30-second accept window** — Countdown chip + backend scheduled job
5. **Add tip-after-delivery UI** — Simple bottom sheet on completed orders

### Short-term (Next 2 Sprints)
1. **Escrow + milestone release UI** — Fund/submit/approve/release flow in engagement workspace
2. **Dispute flow** — Structured reasons + photo evidence + escalation button
3. **Photo-proof delivery + PIN** — Camera capture + 4-digit PIN display
4. **Live ETA map** — `flutter_map` integration for mafundi/food delivery tracking
5. **Geofence "Arrived"** — `geolocator` background service

### Medium-term (Next Month)
1. **SMS + WhatsApp fallback** — Africa's Talking integration for notification fallback
2. **Screenshot blocking** — Android `FLAG_SECURE` + iOS overlay
3. **Conversational AI triage** — Extend symptom checker to 6-turn chat
4. **Commute calculator** — OpenRouteService isochrone for real estate
5. **On-tour live updates** — `my_trip_page.dart` with timeline + guide chat

---

*End of audit. This report should be updated as items from `docs/plans/agent_directive_106.md` are shipped.*
