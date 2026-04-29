# Implementation Directive — Partner C2B Residue (106 items)

**Audience:** an LLM-based coding agent (Claude, Cursor, GPT-5) joining the project cold.
**Date:** 2026-04-29.
**Scope:** the 106 remaining items from `tasks/multi_session_plan.md` after sessions 1-16 closed 93/199 research enhancements end-to-end.

This document is **self-contained**. Read it linearly. Do not skip the conventions section.

---

## 1. Mission

You are extending **TAJIRI**, a Flutter (3.10.1+) social/marketplace super-app for Tanzania backed by a Laravel 12 + PostgreSQL 16 API. The Partner C2B (customer-to-business) feature set covers 13 verticals (F1–F13: food, mafundi, garage, salon, fitness, doctor, lawyer, business consulting, real estate, events, reviews, availability, multi-skill).

The previous 16 sessions:
- Shipped all foundational layers (notifications, wallet/COA, calendar, chat, Firestore live updates, analytics, JSS scoring)
- Wired 93 research enhancements with full UX
- Pushed 5 schema waves + 12 controllers via SSH against the production server

Your job: pick off the remaining 106 items per the section-by-section punch-list at the end of this document. Each item lives at a known severity (S / M / L / XL) and either has its backend column already shipped or needs a clearly-scoped backend addition.

**Do not** reinvent the foundation. Every backend service, table, and helper you'd need exists or has been planned.

---

## 2. Stack & access

### 2.1 Frontend (this repo)

- **Path:** `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`
- **Language:** Dart 3 / Flutter 3.10.1+
- **State management:** *no external package*. `setState` for widget state, `ValueNotifier` singletons for global state (`ThemeNotifier`, `LanguageNotifier`, `CallState`), Hive via `LocalStorageService` for persistence.
- **Routing:** named routes in `lib/main.dart`; `FutureBuilder<int>` resolves `currentUserId` before screens build.
- **Networking:** `http` package for standard calls; `Dio` only for chunked uploads. Bearer token via `ApiConfig.authHeaders(token)`.
- **i18n:** bilingual Swahili-first via `AppStringsScope.of(context)?.isSwahili`. **Always render copy in both languages.**
- **Lint:** `package:flutter_lints/flutter.yaml`. Run `flutter analyze` on every touched file before declaring done. **Zero new errors / warnings.**

### 2.2 Backend (production)

- **Host:** `172.240.241.180`
- **SSH:** `sshpass -p "ZimaBlueApps" ssh root@172.240.241.180`
- **Project path:** `/var/www/tajiri.zimasystems.com`
- **Domain:** `https://tajiri.zimasystems.com`
- **Stack:** PHP 8.3 / Laravel 12 / PostgreSQL 16 (with **pgvector** + **PostGIS** enabled) / Redis 7 / Typesense 27 / Reverb WebSocket / FCM
- **AI assistant:** `POST /api/ai/ask {prompt, response_type:'json'}` returns `{success:true, data:{answer:"..."}}` (note: response key is `answer`, not `reply`).
- **Embedding service:** `localhost:8200` (intfloat/multilingual-e5-base, 768d). Available for future reuse.

### 2.3 Why SSH not migrations

`php artisan migrate` is broken on this server (legacy `user_profiles` migration conflict). Schema changes are applied via:

```bash
# 1. Write a self-contained PHP script LOCALLY that does Schema::table() calls
cat > /tmp/wave_X.php << 'EOF'
<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;

if (!Schema::hasColumn('table_x', 'col_y')) {
    Schema::table('table_x', function (Blueprint $t) {
        $t->integer('col_y')->nullable();
    });
    echo "added\n";
}
EOF

# 2. SCP it
sshpass -p "ZimaBlueApps" scp -o StrictHostKeyChecking=no /tmp/wave_X.php root@172.240.241.180:/var/www/tajiri.zimasystems.com/wave_X.php

# 3. Run + cleanup
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php wave_X.php && rm wave_X.php"
```

**Do NOT** use `python3 << "PYEOF"` heredocs that contain `$variable` — escapes break inside Python over SSH. Always write the PHP script to a local file, then `scp` then `ssh && php`.

---

## 3. Repo conventions (NON-NEGOTIABLE)

### 3.1 File organisation

```
lib/
├── config/api_config.dart                    # base URLs + headers
├── l10n/app_strings_scope.dart               # AppStringsScope.of(context)?.isSwahili
├── services/local_storage_service.dart       # Hive auth/user
│
├── tajirika/                                 # PARTNER-side code (manage business)
│   ├── models/                               # PartnerProduct, TajirikaPartner, etc.
│   ├── pages/                                # partner_profile_page, manage_*_page
│   ├── services/                             # partner_*_service.dart
│   └── widgets/                              # JssBadge, PartnerKpiBadge, etc.
│
├── food/ mafundi/ housing/ events/           # CUSTOMER-side per-vertical
│   ├── models/                               # vertical-specific models
│   ├── pages/                                # *_home_page, partner_product_detail_page
│   ├── services/                             # vertical-specific services
│   └── widgets/
│
├── customer_orders/                          # source-agnostic order helpers
├── consultations/ engagements/ fitness/      # cross-vertical sub-systems
├── service_garage/ skincare/ hair_nails/     # more verticals
└── calls/                                    # WebRTC infra (don't touch)
```

**Rule:** customer-facing code lives in the vertical folder; partner-management code lives in `lib/tajirika/`. Never mix. (See `feedback_food_vs_tajirika_split` and `feedback_mafundi_module_location` in maintainer memory.)

### 3.2 Model pattern

Every model file MUST have:

```dart
int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class Foo {
  final int id;
  final ...;

  Foo({required this.id, ...});

  factory Foo.fromJson(Map<String, dynamic> json) {
    return Foo(
      id: _parseIntN(json['id']) ?? 0,
      ...
    );
  }
}
```

### 3.3 Service pattern

Every service is a static-method class:

```dart
class FooService {
  static Future<Foo?> show(int id) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/foo/$id'));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true) return null;
      return Foo.fromJson((r['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('[FooService] $e');
      return null;
    }
  }
}
```

### 3.4 Controller pattern (Laravel)

```php
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FooController extends Controller
{
    public function show(int $id)
    {
        $row = DB::table('foos')->find($id);
        if (!$row) return response()->json(['success' => false], 404);
        return response()->json(['success' => true, 'data' => $row]);
    }
}
```

Add routes to `routes/api.php` via the SCP-then-SSH pattern (NOT artisan migrate).

### 3.5 COA money rule

**ALL money calculations** must use the COA / `journal_lines` table. Never raw-table sums. Use the existing `JournalPostingService`. Key accounts:

- `1010` wallet_cash
- `1840` advance_payments (escrow holds)
- `4520` misc_income (revenue)
- `3140` retained_earnings (commissions)

Wallet hold/capture/release goes through `PartnerC2BWalletService`.

### 3.6 Bilingual UI rule

```dart
final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
Text(isSw ? 'Hifadhi' : 'Save');
```

Every label needs both. **Swahili first** in design copy.

### 3.7 Design system rule

Read `docs/DESIGN.md` before adding visual elements:
- Monochromatic palette: `#1A1A1A` primary, `#FAFAFA` light, `#666666` secondary, `#EEEEEE` border
- Material 3, `_rounded` icon variants
- 48dp minimum touch targets
- `maxLines` + `TextOverflow.ellipsis` on every dynamic text
- `SafeArea` mandatory at the top of pages
- Dispose every controller in `dispose()`

Common semantic colours used across this codebase:
- Success / "Verified": `#1B5E20` on `#E8F5E9`
- Warning / "Busy": `#E65100` on `#FFF8E1`
- Error / "Closed": `#B71C1C` on `#FFEBEE`
- Info / "Tier": `#0D47A1` on `#E3F2FD`

### 3.8 Hard prohibitions (from project memory)

- **No fallback logic.** If a source is empty, treat empty as truth — don't add "if empty try another source" branches.
- **Admin actions are backend-only.** Don't add admin screens to Flutter.
- **No git operations** unless the user explicitly asks.
- **No new file creation** when an existing file fits.
- **Never run `git push --no-verify` / `--no-gpg-sign`** under any circumstance.
- **Don't comment what code does** (well-named identifiers do that). Comment only WHY when non-obvious.
- **No half-finished implementations.** Either ship a feature with full UX or don't touch the surface.

---

## 4. What's already shipped (DO NOT DUPLICATE)

### 4.1 Backend tables (live in production)

`partner_product_variants`, `class_sessions`, `class_session_bookings`, `training_plans`, `training_plan_checkins`, `progress_measurements`, `customer_health_profiles`, `consent_receipts`, `engagement_time_screenshots`, `engagement_relationships`, `peer_endorsements`, `ai_review_summaries`, `partner_vip_slots`, `customer_partner_favorites`, `partner_canned_messages`, `vin_decode_cache`, `ai_brief_cache`, `ai_symptom_specialty_cache`, `shared_carts`, `shared_cart_items`, `review_image_embeddings` (with `vector(512)`), `dtc_explanations`.

### 4.2 Backend columns added to existing tables

- `partner_products`: `is_in_stock`, `declared_lead_minutes`, `actual_lead_minutes_avg`, `min_notice_minutes`, `max_advance_days`, `pre_buffer_minutes`, `processing_minutes`, `post_buffer_minutes`, `travel_buffer_minutes`, `rebook_cadence_days`, `cancellation_policy_tiers (json)`, `last_minute_discount_pct`, `requires_patch_test`, `ai_cost_anchor`, `is_legal_pack`, `legal_pack_deliverables (json)`
- `tajirika_partners`: `availability_mode`, `busy_until`, `busy_eta_extra_minutes`, `auto_paused_at`, `consecutive_misses`, `kpi_score`, `kpi_response_pct`, `kpi_completion_pct`, `kpi_rating_pct`, `kpi_recency_pct`, `job_success_score`, `public_slug`, `intro_video_url`
- `partner_skill_personas`: `pricing_tier`, `is_paused`, `public_slug`, `tala_license_number`, `insurance_cert_url`, `tala_verified`, `migration_pricing (json)`
- `partner_availability`: `reminder_cadence_hours`, `pricing_modifier_pct`, `booking_horizon_days`, `min_notice_minutes`, `last_minute_discount_enabled`, `last_minute_discount_pct`, `waitlist_mode`
- `service_requests`: `warranty_days`, `ai_cost_low_tzs`, `ai_cost_high_tzs`, `diagnostic_fee_tzs`, `diagnostic_fee_credited_tzs`, `revised_quote_tzs`, `revised_quote_approved_at`, `intake_form (json)`, `before_photos (json)`, `after_photos (json)`, `geofence_arrived`, `parts_line_items (json)`, `parts_markup_pct`
- `garage_bookings`: `drop_off_mode`, `pickup_drop_offered`, `warranty_claimed`, `warranty_km`, `warranty_days`, `obd2_photos (json)`
- `appointments`: `variant_id`, `any_professional_mode`, `multi_staff_slots (json)`, `travel_surcharge_tzs`, `after_hours_surcharge_tzs`, `holiday_premium_tzs`, `parking_pass_through_tzs`, `cancellation_fee_tzs`, `cancellation_tier`, `is_recurring`, `recurring_skip_dates (json)`
- `consultations`: `sku_tier`, `insurance_provider`, `avg_wait_minutes`, `pre_visit_intake_completed`, `derm_intake_photos (json)`, `connectivity_test_passed`, `consent_screens_signed (json)`, `visit_notes (json)`, `care_plan (json)`, `erx_pharmacy`, `erx_qr_code`, `followup_due_at`, `opposing_party_check (json)`, `flag_secure_active`
- `engagements`: `lead_credit_tzs`, `is_retainer`, `retainer_hours_per_month`, `retainer_rolls_over`, `dispute_window_started_at`, `dispute_escalated_at`, `sow_template_id`, `sow_payload (json)`
- `property_listings`: `floor_plan_urls (json)`, `epc_band`, `obfuscate_location_until_inquiry`, `matterport_enabled`, `matterport_url`, `back_on_market_at`, `walk_score`, `bike_score`, `transit_score`, `photo_verification_status`, `geo (geography(POINT, 4326))`
- `listing_inquiries`: `prequal_move_in`, `prequal_financing`, `prequal_working_with_agent`, `prequal_completed_at`, `is_open_house_rsvp`, `partner_response_minutes`
- `event_bookings`: `backup_performer`, `backup_performer_amount_tzs`, `force_majeure_at`, `payment_plan_installments (json)`, `song_requests (json)`, `travel_radius_km`, `travel_per_km_tzs`, `refund_policy (json)`, `package_tier`, `qr_voucher_code`, `travel_insurance_optin`, `trip_prep_notifications_sent (json)`, `day_before_payload (json)`, `early_bird_applied`, `group_discount_applied`, `group_discount_pct`, `per_stop_reviews (json)`
- `partner_reviews`: `is_returning_customer`, `prior_orders_count`, `per_item_thumbs (json)`, `requires_photo_proof`, `reply_discount_offer (json)`, `reply_window_expires_at`, `is_verified_booking`, `dimensions (json)`, `media_urls (json)`, `helpfulness_yes`, `helpfulness_no`
- `partner_product_orders`: `handoff_pin`, `delivery_proof_photo`, `tip_tzs`, `tip_added_at`, `customer_self_reported_issue`, `self_report_deadline`, `schedule_mode`, `group_cart_id`
- `messages`: `is_canned`, `voice_note_url`, `voice_duration_seconds`

### 4.3 Backend endpoints (live + smoke-tested)

```
GET  /api/vin/decode?vin=...
POST /api/ai/brief
POST /api/symptoms/check
POST /api/listings/search-polygon
POST /api/reviews/check-similarity
GET  /api/ai/review-summary/{partnerUserId}
POST /api/shared-carts
GET  /api/shared-carts/{token}
POST /api/shared-carts/{token}/items
DELETE /api/shared-carts/{token}/items/{itemId}
POST /api/shared-carts/{token}/settle
GET  /api/partner-product-variants
POST /api/partner-product-variants
PATCH /api/partner-product-variants/{id}
DELETE /api/partner-product-variants/{id}
GET  /api/class-sessions
POST /api/class-sessions
POST /api/class-sessions/{id}/book
POST /api/class-session-bookings/{id}/cancel
GET  /api/training-plans
POST /api/training-plans
POST /api/training-plans/{id}/checkin
GET  /api/training-plans/{id}/checkins
GET  /api/progress-measurements
POST /api/progress-measurements
GET  /api/customer-health-profiles/{userId}
PUT  /api/customer-health-profiles/{userId}
GET  /api/consent-receipts
POST /api/consent-receipts
GET  /api/peer-endorsements
POST /api/peer-endorsements
DELETE /api/peer-endorsements/{id}
GET  /api/customer-partner-favorites
POST /api/customer-partner-favorites
DELETE /api/customer-partner-favorites/{id}
GET  /api/partner-canned-messages
POST /api/partner-canned-messages
DELETE /api/partner-canned-messages/{id}
GET  /api/partner-vip-slots
POST /api/partner-vip-slots
DELETE /api/partner-vip-slots/{id}
PATCH /api/partners/{id}/availability-mode
POST /api/partners/{id}/resume
GET  /api/engagement-relationships
PATCH /api/partner-skill-personas/{skillCategory}
... + many more in routes/api.php; grep before adding duplicates.
```

### 4.4 Backend services (use these — don't reinvent)

`PartnerC2BNotificationService` (FCM + scheduling) — `enqueue`, `cancelForSource`, `drain`, plus per-vertical `schedule*Reminders` helpers
`PartnerC2BWalletService` (COA-correct wallet) — `hold`, `capture`, `release`, `payInstant`, `ensureHold`, `captureForSource`, `releaseForSource`
`PartnerC2BCalendarService` — `upsertEvent`, `cancelForSource`, `fanBooking`
`PartnerC2BLiveUpdateService` (Firestore broadcasts) — `broadcastOrderUpdate`
`PartnerC2BMetricsService` — daily aggregator
`JournalPostingService` — single source of truth for double-entry COA postings

**NEVER** post to wallet tables directly. Always call these services.

### 4.5 Flutter widgets/services already built (reuse)

- `JssBadge` — Job Success Score 0-100 with tier classification
- `PartnerKpiBadge` — composite KPI badge
- `PartnerStatusChip` — open/busy/closed display chip
- `LoyaltyBundleRail` — partner profile rail
- `PeerEndorsementsSection` — endorse + list
- `PartnerC2BMetricsDashboard`, `PartnerC2BSourceMixCard`, `PartnerC2BActivitySparkline`
- `MyPartnerC2BActivityCard` — auto-resolving customer activity card
- `PromoCodeField` — drop-in promo code applicator
- `AiBriefSheet` — AI hiring-brief generator bottom sheet
- `SymptomCheckerSheet` — AI symptom triage bottom sheet
- `PanoramaLauncher` — Matterport replacement
- `CannedMessagePicker` — chat reply picker
- `AutoPauseBanner`, `PartnerAvailabilityModeSheet`
- `SkillPauseToggle`, `PersonaPricingTierChip`, `DailyPayoutBadge`
- `PerItemThumbsPicker` — multi-line review thumbs
- `MigrationSeasonCalendar` — safari pricing tier calendar
- `AiReviewSummaryCard` — partner profile AI summary
- Service classes: `AiBriefService`, `SymptomCheckerService`, `VinDecodeService`, `PolygonSearchService`, `SharedCartService`, `ImageSimilarityService`, `LoyaltyBundleService`, `ProductVariantService`, `PeerEndorsementService`, `CustomerPartnerFavoriteService`, `PartnerCannedMessageService`, `PartnerVipSlotService`, `PartnerAvailabilityModeService`, `EngagementRelationshipService`, `AiReviewSummaryService`, `ConsentReceiptService`, `HealthProfileService`, `TrainingPlanService`, `ClassSessionService`

---

## 5. Workflow per item

For every item:

1. **Read** `tasks/multi_session_plan.md` for cumulative context.
2. **Confirm backend status** with the table at §4 above. If schema is shipped, proceed; if not, write the tinker-compatible PHP migration script and SCP it.
3. **Thread the model** in the relevant Dart `models/*.dart` file. Add `final` field, constructor param, `fromJson` extraction. Use the `_parseIntN`, `_parseBool`, `_parseDate` helpers verbatim.
4. **Build the widget** under the conventional folder. Match the visual language at §3.7.
5. **Wire the widget** into the parent page. Show in both Sw + En.
6. **Run** `flutter analyze <touched_files>`. Fix until 0 errors / 0 warnings on YOUR files. Don't fix pre-existing lint elsewhere.
7. **Update** `tasks/multi_session_plan.md` with a one-line entry per item shipped.
8. **Verify** with at least one of: live-smoke-test the endpoint via `curl https://tajiri.zimasystems.com/api/...`, or `flutter run` and tap through the UI.

If you can't complete an item end-to-end (e.g. it needs a new pubspec package, or native iOS code), **stop and ask the user**. Do not half-ship.

---

## 6. Punch-list — 106 items grouped by F-section

Each item lists: `# Title — backend status | frontend status | files to touch | acceptance`

### F1 — Partner Posting (8 items)

#### #1 Three-tier service hierarchy (L)
- **Spec line 144.** `Category > Service Type > Service` taxonomy.
- **Backend status:** new table needed `service_taxonomy(id, level, parent_id, name_sw, name_en, sort_order)` seeded from research.
- **Frontend:** typeahead picker on `lib/tajirika/pages/post_partner_product_page.dart`.
- **Acceptance:** partner can navigate Category → Service Type → Service in posting; selection auto-fills `skill_category`. Customer search uses Service Type as anchor.

#### #2 Add-ons surfaced after main selection (M)
- **Spec line 146.** Each add-on carries duration + tax; total auto-recalcs.
- **Backend:** `partner_products.add_ons (json)` already shipped.
- **Frontend:** rewire `partner_product_booking_sheet.dart` to compute live totals; cross-cluster.
- **Acceptance:** picking an add-on instantly updates `total_minutes` and `total_tzs` displayed; partner-set max-cap enforced.

#### #3 Booking sequencing for multi-step services (XL)
- **Spec line 148.** Fresha-style: customer B books same chair while customer A's colour develops.
- **Backend:** new table `service_dependencies(parent_id, prerequisite_id, valid_days)` + scheduler in `partner_availability/slots`.
- **Frontend:** dependency-authoring UI on partner side.
- **Acceptance:** slot expansion respects processing-time gaps; capacity multiplier visible.

#### #4 Implicit-duration calculation (L)
- **Spec line 150.** Customer never picks duration; partner sets `duration_minutes` per variant.
- **Backend:** column already on `partner_product_variants`.
- **Frontend:** remove duration pickers from booking flows in food/mafundi/hair/fitness — cross-cluster refactor.
- **Acceptance:** booking math derives duration from variant; UI hides the picker.

#### #5 Service Type photo guidelines per cluster (M)
- **Spec line 152.** Different per-cluster photo standards.
- **Frontend:** `lib/<vertical>/widgets/photo_guideline_card.dart` shown above the photo-upload step.
- **Acceptance:** posting flow blocks submit when count < 4 originals; cluster-specific copy.

#### #6 Sample-photo carousel placeholder enforcement (M)
- **Backend:** `skill_sample_photos` table shipped. Endpoint TBD.
- **Frontend:** new partner-side upload page + customer-side carousel with watermarks.
- **Acceptance:** partner uploads sample photos per skill; customer detail shows them in a separate carousel tab.

#### #7 Photo-quality auto-checks (M)
- **Spec line 156.** Blur / brightness / dimension / stock-similarity.
- **Frontend:** add `image: ^4.x` package; Laplacian variance for blur, mean luminance for brightness; reuse `ImageSimilarityService` for stock check.
- **Files:** `lib/tajirika/utils/photo_quality.dart` + integrate into all upload sites (`partner_product_photo_*`, `service_request_*`, `property_listing_*`).
- **Acceptance:** soft-block with "Picha hii ina ukungu / This photo is blurry — try again?" when below thresholds.

#### #8 Lead-time honesty score (M)
- **Spec line 160.** Partner dashboard surfaces "Una uongo wa muda — declared 2hr, actual 3.5hr".
- **Backend:** scheduled job to recompute `partner_products.actual_lead_minutes_avg`. Add `app:rebuild-lead-honesty` artisan command.
- **Frontend:** card on `tajirika_home_page` when delta > 30%.

---

### F2 — Buyer Order (5 items)

#### #9 Conversion-rate-weighted ranking (L)
- **Spec line 230.** Composite score across all customer-facing rails.
- **Backend:** materialised view `partner_ranking_score` + nightly cron `app:rebuild-partner-rankings`. Used in every "list partners by skill" endpoint.
- **Frontend:** none direct, but partner profile shows their rank tier.
- **Acceptance:** `ORDER BY` on every partner-search endpoint switches to `partner_ranking_score DESC`. Existing rating-only sort deprecated.

#### #10 Schedule vs ASAP toggle at booking (L)
- **Spec line 233.** Toggle + 30-min slots up to 48h ahead.
- **Backend:** `partner_product_orders.schedule_mode` already shipped; needs slot-grid endpoint.
- **Frontend:** rewire every booking sheet (food, mafundi, hair, fitness) to expose the toggle. **Cross-cluster.**
- **Acceptance:** customer picks ASAP or specific slot; partner inbox shows the difference.

#### #11 Auto-credit on detected partner error (L)
- **Spec line 236.** Customer self-reports + AI accepts → auto-credit wallet.
- **Backend:** rule engine using `customer_orders.requires_chat_first` + AI assistant check. Use `JournalPostingService` for COA-correct reversal.
- **Frontend:** toast "Imerejeshwa moja kwa moja / Refunded automatically".

#### #12 In-app help chat with <3-min SLA (XL)
- **Spec line 238.** Entire customer-support function.
- **Backend:** ops queue + on-call rotation; new `support_tickets` table.
- **Frontend:** "Pata msaada" CTA on every order; partner-side ops console.
- **DEFER:** This is a platform commitment, not a feature. Coordinate with ops team before scoping.

#### #13 Per-vertical detail-page copy/hero norms (M)
- **Spec line 240.** Different cluster wrappers.
- **Frontend:** edit cluster-wrapper copies in `lib/food`, `lib/mafundi`, `lib/events`, `lib/housing`, `lib/travel` `partner_product_detail_page.dart` files.
- **Acceptance:** food = "Agiza sasa"; mafundi = "Omba huduma"; events = "Hifadhi tarehe"; housing = "Tuma swali"; travel = "Anza safari".

---

### F3 — Partner Inbox (7 items)

#### #14 30-second accept window with auto-reassign (M)
- **Backend:** scheduled job per pending order. Use `PartnerC2BNotificationService` for fan-out to next-nearest after 30s timeout. Add `partner_product_orders.auto_reassigned_at` column.
- **Frontend:** countdown chip on partner inbox row.

#### #15 Stock toggle inline edit ✅ SHIPPED session 16

#### #16 Daily M-Pesa payout marketing badge ✅ SHIPPED session 16 (`DailyPayoutBadge`)

#### #17 Lead-expiring countdown push for quote-bid (M)
- **Backend:** scheduled job per quote source. Use `PartnerC2BNotificationService.enqueue` with payload `{kind: 'lead_expiring', minutes_left, competitor_count}`.
- **Frontend:** chip on quote-bid sources (mafundi service_request, event quote, engagement, listing inquiry).

#### #18 Bulk-action support (M)
- **Backend:** new endpoint `POST /customer-orders/batch-accept` + `/batch-decline`.
- **Frontend:** selection-mode UI on `lib/customer_orders/pages/partner_inbox_page.dart`; long-press triggers select; floating action bar with "Kubali zote".
- **Acceptance:** ≥10 items selected → bulk-accept under 1 second.

#### #19 Weekly competitive benchmark (M)
- **Backend:** aggregation pipeline + `partner_weekly_benchmarks(partner_id, week_start, peer_avg_orders, my_orders, peer_avg_response_min, my_response_min)`. Cron `app:rebuild-weekly-benchmarks` Mondays 03:00.
- **Frontend:** card on `tajirika_home_page` Mondays only.

#### #20 Service-history "Mteja wa kawaida" chip on partner inbox (M)
- **Backend:** reuse `engagement_relationships` and `partner_reviews.prior_orders_count`. Endpoint `GET /partner-inbox/customer-history?customer_user_id=&partner_user_id=`.
- **Frontend:** chip on every partner-inbox row that includes a customer with ≥2 prior orders. Use `MyPartnerC2BActivityCard` or build a small `RepeatCustomerChip` widget.

---

### F4 — Service Request / Mafundi (5 items)

#### #21 Structured intake form per skill (L)
- **Spec line 466.** Long guided questionnaire per `SkillCategory`.
- **Backend:** new table `skill_intake_forms(skill_category, form_schema_json)` seeded with 20-30 forms (one per skill).
- **Frontend:** dynamic form renderer in `lib/mafundi/widgets/intake_form_renderer.dart` reading the JSON schema.
- **Acceptance:** customer requesting plumbing fills "How many rooms? What flooring? Square meters?"; data lands in `service_requests.intake_form` (column shipped).

#### #22 Geofence-triggered "Arrived" (L)
- **Frontend:** add `geolocator: ^x` package. Background location permission. Foreground service on Android. Geofence batching.
- **Files:** `lib/services/geofence_service.dart` + integrate into `lib/mafundi/pages/service_request_status_page.dart` (partner side).
- **Acceptance:** partner phone crosses 100m radius of customer address → `on_site_at` auto-fills + push fires. **Battery-conscious:** only watches geofences after partner taps "En route".

#### #23 Live ETA push with map view (L)
- **Frontend:** add `flutter_map` package. WebSocket marker stream. Native background-location service.
- **Backend:** new endpoint `POST /service-requests/{id}/eta-update` + Reverb broadcast on `service-request.{id}` channel.
- **Files:** `lib/mafundi/widgets/live_eta_map.dart`.
- **Acceptance:** customer sees rotating marker + ETA text "Fundi yuko dakika 10 mbali"; updates every 15s.

#### #24 Parts pass-through line-item viewer (M)
- **Backend:** `service_requests.parts_line_items (json)` already shipped. Endpoint `PATCH /service-requests/{id}/parts` to add/edit.
- **Frontend:** partner-side `lib/mafundi/widgets/parts_line_editor.dart`; customer-side display showing cost vs markup separately.
- **Acceptance:** "Mafuta TZS 12,000 (markup 25%)" line item visible.

#### #25 Partner site-survey fee for big jobs (M)
- **Backend:** `service_requests.site_survey_fee_tzs` + `parent_request_id` columns. Migration needed.
- **Frontend:** survey is a separately-priced sub-booking before the full job; "Endesha ukaguzi" button creates a child request.

---

### F5 — Garage Booking (5 items)

#### #26 OBD2 / dashboard-light photo upload (M)
- **Backend:** `garage_bookings.obd2_photos (json)` already shipped. AI interpretation via `/api/ai/ask`.
- **Frontend:** photo step on `lib/service_garage/pages/book_garage_page.dart`. Upload → call AI → display interpretation.
- **Acceptance:** customer photographs dashboard; AI returns "Engine warning + ABS sensor likely" in Sw/En.

#### #27 Mobile-vs-shop drop-off branching (M)
- **Backend:** `garage_bookings.drop_off_mode` already shipped. Different SKU pools per choice — backend filter.
- **Frontend:** rewire `book_garage_page` step 1 to ask "Wapi? driveway / office / shop". Filter partner pool accordingly.

#### #28 Parts ordering integration with TZ supplier APIs (XL)
- **Backend:** new tables `parts_catalog(sku, name_sw, name_en, vehicle_compat_json, typical_price_low_tzs, typical_price_high_tzs)`.
- **Data:** scrape Kariakoo / Tanga / Mwanza supplier lists. Normalize to canonical schema.
- **Frontend:** parts picker on quote step.
- **DEFER:** Strategic moat. Coordinate with ops + scrape ethics review.

#### #29 Body-shop bidding on photos alone (L)
- **Backend:** new flow on `service_requests` where `skill_category IN ('panelBeating', 'sprayPainting')` enters `photo_bid` state.
- **Frontend:** new mini-flow forking from `request_service_page`. Partner-side bid review screen.
- **Acceptance:** customer uploads 4+ damage photos; multiple body shops bid; customer drives in only after acceptance.

#### #30 Service-due dashboard ✅ SHIPPED session 16 (`ServiceDueDashboardPage`)

---

### F6 — Salon / hair_nails / skincare / fitness (11 items)

#### #31 Multi-staff bookings in one cart (L)
- **Backend:** `appointments.multi_staff_slots (json)` already shipped. `parent_appointment_id` for child rows. Migration needed.
- **Frontend:** booking sheet becomes a multi-slot wizard. Add "+ Ongeza huduma" button.
- **Acceptance:** customer books "cut by Maria + nails by Asha" in one cart; one wallet hold.

#### #32 "Any professional" toggle (M)
- **Backend:** `appointments.any_professional_mode` shipped. Add load-balance service.
- **Frontend:** toggle on booking step.
- **Acceptance:** "Any" → backend assigns least-busy qualified staff.

#### #33 Pre/post-buffer + processing time per variant (M)
- **Backend:** columns on `partner_products` already shipped. `/partner-availability/slots` endpoint must respect them.
- **Frontend:** config UI on `_HoursDialog` in `manage_availability_page.dart`.

#### #34 Travel buffer + surcharges (M)
- **Backend:** `appointments.travel_surcharge_tzs`, `after_hours_surcharge_tzs`, `holiday_premium_tzs`, `parking_pass_through_tzs` shipped.
- **Frontend:** line-item editor for partner; line-item display for customer.

#### #35 Skin-type quiz + AI selfie analysis (L)
- **Backend:** `customer_health_profiles.beauty_profile` (already shipped). Endpoint `POST /skincare/analyze-selfie` calling `/api/ai/ask` with image URL.
- **Frontend:** quiz page in `lib/skincare/pages/skin_type_quiz_page.dart`. Selfie capture + analysis result display.

#### #36 Loyalty stamps with progress bar (M)
- **Backend:** new table `loyalty_stamp_cards(partner_id, customer_user_id, stamps_earned, target, expires_at)`.
- **Frontend:** stamp card UI on partner profile customer view.

#### #37 Auto-add waitlist (FIFO) vs First-to-Claim SMS blast (M)
- **Backend:** `partner_availability.waitlist_mode` shipped. New table `appointment_waitlist`. SMS provider integration (see #39).
- **Frontend:** mode toggle on `manage_availability_page`.

#### #38 Cancellation-policy tiers display ✅ Backend column shipped, threading done session 16; partner-side editor + customer display still need polish UI.

#### #39 Two-way SMS YES/NO confirmation (L)
- **Backend:** SMS provider (Africa's Talking recommended for TZ). Inbound webhook on `/sms/webhook`.
- **Frontend:** none direct; the confirmation flips appointment status server-side.

#### #40 Rebook cadence per service (M)
- **Backend:** `partner_products.rebook_cadence_days` shipped. Scheduled job uses `PartnerC2BNotificationService.scheduleRatePrompt` pattern adapted to rebook.
- **Frontend:** partner config UI on partner_product edit; customer-side push handled.

#### #41 Recurring booking with daily/weekly/biweekly/monthly + skip-week (L)
- **Backend:** new table `appointment_series(template_appointment_id, cadence, skip_dates_json, until_date)`.
- **Frontend:** "Rudia mara kwa mara" toggle on booking + cancel-series flow.

---

### F6 — Fitness extras (4 items)

#### #42 Pick-a-spot floor plan (L)
- **Backend:** new table `partner_studio_layouts(partner_id, layout_json)` storing grid coords + spot_id list. `class_session_bookings.spot_number` shipped.
- **Frontend:** custom canvas widget in `lib/fitness/widgets/spot_picker_canvas.dart`. Spot-locking via WebSocket.

#### #43 Drop-in vs membership (L)
- **Backend:** new `memberships(user_id, partner_id, plan, credits_remaining, expires_at)` table.
- **Frontend:** ClassPass-style credits display + deduction at booking.

#### #44 Heart-rate live integration (M)
- **Frontend:** add `flutter_blue_plus` package. Standard GATT 0x180D Heart Rate Service.
- **Files:** `lib/fitness/services/hrm_ble_service.dart` + live HRM stream UI on `lib/fitness/pages/live_class_page.dart`.
- **Acceptance:** Polar H10 / Wahoo TICKR connects; live BPM displayed.

#### #45 Live + on-demand coexistence (XL)
- **Backend:** LiveKit or AWS IVS for live; recording pipeline; leaderboard service.
- **Frontend:** entire live-class sub-app.
- **DEFER:** Coordinate with infra team.

---

### F7 — Consultation (16 items)

#### #46 NHIF/AAR/Jubilee hard filter ✅ SHIPPED session 16

#### #47 Conversational AI triage (M)
- **Backend:** extend `/api/symptoms/check` to accept `{conversation_history: [...]}` + return `{follow_up_question_sw, follow_up_question_en, ready: bool}`.
- **Frontend:** chat-like UI replaces single-shot symptom checker. Cap at 6 turns.

#### #48 Bilingual symptom + intent capture (M)
- **Frontend:** Swahili UX rewrite of every health-concern capture surface. No new backend.

#### #49 "Available today / tomorrow / this week" sort (M)
- **Backend:** compute next available slot per provider in `tajirika_partners`. Cron updates daily.
- **Frontend:** primary ranking signal on doctor search.

#### #50 Pre-visit intake forms pushed at T-24h (M)
- **Backend:** `consultations.pre_visit_intake_completed` shipped. Scheduled job + specialty-specific schema.
- **Frontend:** form renderer per specialty.

#### #51 K-Health-style derm photo intake (M)
- **Backend:** `consultations.derm_intake_photos (json)` shipped. Structured photo prompts.
- **Frontend:** guided photo capture page in `lib/consultations/pages/derm_intake_page.dart`.

#### #52 Pre-call mic/camera/bandwidth test (M)
- **Frontend:** WebRTC self-test UI in `lib/calls/pages/pre_call_test_page.dart`. Persist results in `consultations.connectivity_test_passed`.

#### #53 Virtual waiting room (L)
- **Frontend:** new page `lib/consultations/pages/waiting_room_page.dart`. Provider photo + estimated wait. Provider sees patient + intake on join.
- **Backend:** ws channel for waiting-room state.

#### #54 Explicit consent screens before video (M)
- **Frontend:** consent modal in `lib/consultations/widgets/pre_call_consent_modal.dart`. Persist signatures into `consultations.consent_screens_signed (json)` + `consent_receipts` table.

#### #55 Screen-share for lab reports (L)
- **Frontend:** WebRTC datachannel; PDF annotation overlay. Likely needs `flutter_pdfview` package.

#### #56 Auto-generated visit notes + care plan (L)
- **Backend:** voice transcription via `/api/ai/ask` with audio. AI structures into `visit_notes (json)` + `care_plan (json)` (columns shipped).
- **Frontend:** doctor-side editor; patient-side display.

#### #57 Condition-specific follow-up cadence (M)
- **Backend:** new rules table `consultation_followup_rules(condition, days)`. Scheduler reads + sets `consultations.followup_due_at` (column shipped).
- **Frontend:** none direct beyond existing follow-up CTA.

#### #58 In-person flow extras (L)
- **Backend:** `consultations.clinic_intro_html`, `parking_blob`, `queue_position` columns. Updates pushed on join.
- **Frontend:** new sections on `consultation_status_page` for in-person mode.

#### #59 SMS reminder + reply STOP/CONFIRM (L)
- Same SMS provider integration as F6 #39.

#### #60 Draft + lawyer-review upsell two-tier flow (L)
- **Backend:** new SKU type `legal_draft_then_review`. Two-tier billing.
- **Frontend:** wizard schema per legal SKU.

#### #61 Pay-per-question (legal) Q&A (M)
- **Backend:** new SKU `legal_qna`. Threading model.
- **Frontend:** lightweight Q&A page.

#### #62 Retainer subscription full UI (M)
- **Backend:** `engagements.is_retainer`, `retainer_hours_per_month`, `retainer_rolls_over` shipped.
- **Frontend:** configuration page + monthly hour ledger view + roll-or-expire toggles.

#### #63 Screenshot blocking (FLAG_SECURE) (M)
- **Native:** Android `WindowManager.FLAG_SECURE` + iOS workaround (overlay screen on `applicationWillResignActive`).
- **Frontend:** Method channel call when entering Rx / NDA-gated chat / ID upload screens.

#### #64 Consent receipts page ✅ SHIPPED session 16 (`ConsentReceiptsPage`)

#### #65 Data deletion path with email confirmation (L)
- **Backend:** new endpoint `DELETE /users/{id}/data` with 30-day grace period. Email confirmation pipeline.
- **Frontend:** "Futa data zangu" button on settings; confirmation flow.

---

### F8 — Engagement (8 items)

#### #66 Work Diary / time-tracker with screenshots (L)
- **Backend:** `engagement_time_screenshots` table shipped.
- **Frontend:** **mobile screenshot capture is platform-restricted; this is mostly a desktop feature.** For mobile MVP, partner manually attaches photos at random intervals via existing `PartnerProductService.uploadPhoto`.
- **Acceptance:** customer-side gallery view shows screenshots with timestamps.

#### #67 Optional portfolio for ranking lift (M)
- **Backend:** add `portfolio_items.skill_category_tag` column.
- **Frontend:** partner UI to tag existing portfolio items per skill.

#### #68 SoW templates for senior consultants (L)
- **Backend:** new table `sow_templates(skill_category, name, schema_json)` + `engagements.sow_template_id` (shipped).
- **Frontend:** template picker + structured editor on `propose_engagement_page`.

#### #69 Dispute window with platform mediation (L)
- **Backend:** `engagements.dispute_window_started_at`, `dispute_escalated_at` shipped. Need ops queue UI.
- **Frontend:** 7-day mediation chat thread + escalation button + release decision UI.

#### #70 Auto-recurring weekly invoice (M)
- **Backend:** scheduled job + invoice rendering. COA postings via `JournalPostingService`.
- **Frontend:** invoice email template + in-app dispute window.

#### #71 Toptal-style talent matching (XL)
- **Backend:** matcher ops console + 48h SLA.
- **DEFER:** Coordinate with talent-acquisition team.

#### #72 Public profile pages (`tajiri.com/p/{slug}`) (M)
- **Backend:** Laravel web route serving SSR profile page. SEO meta + open-graph tags. `tajirika_partners.public_slug` shipped.
- **Frontend:** none direct (web).

#### #73 Honeybook-style questionnaires bundled with contracts (L)
- **Backend:** new tables `engagement_questionnaires` + `engagement_questionnaire_responses`.
- **Frontend:** questionnaire designer + auto-fill on contract step.

---

### F9 — Real Estate (10 items)

#### #74 HDR / wide-angle / drone photo tiers + premium gating (M)
- **Backend:** `property_listings.photo_tier (json)` column. Paywall via `tajirika_partners.subscription_plan`.
- **Frontend:** tier picker on photo upload; "Premium" badge on customer detail.

#### #75 Filter chips at top + neighborhood lens overlay (L)
- **Frontend:** sticky filter bar + map overlay layers (crime/school/commute) using OpenStreetMap data.
- **Data:** crime/school data sourcing for TZ — partner with NBS or scrape.

#### #76 List-first default ✅ Already default (verified session 16)

#### #77 Commute-time calculator (M)
- **Backend:** OpenRouteService isochrone API + Redis cache.
- **Frontend:** isochrone polygon overlay on `property_listing_detail_page`.

#### #78 Polygon-search MAP UI (M)
- **Frontend:** add `flutter_map` package. Custom polygon-draw via tap points. Use shipped `PolygonSearchService.search()`.
- **Files:** `lib/housing/pages/polygon_search_page.dart`.

#### #79 "Request a tour" with agent calendar slots + auto-route (M)
- **Backend:** pulls `partner_availability` slots; reroute logic with 24h timeout via `PartnerC2BNotificationService`.
- **Frontend:** slot picker on `property_inquiry_page`.

#### #80 Pre-qualification form ✅ SHIPPED session 16

#### #81 "Back on market" alert push (M)
- **Backend:** scheduled job watching `property_listings.back_on_market_at` (column shipped) + saved-search match query + FCM.
- **Frontend:** push payload routes to listing.

#### #82 Pre-approval flow (long-term rental) (M)
- **Backend:** add `listing_inquiries.pre_approved_at` + `pre_approval_status`. Bidirectional flow.
- **Frontend:** "Pre-approve" button on partner-side inquiry detail.

#### #83 "Similar home just listed" cross-sell push (M)
- **Backend:** similarity engine using existing `walk_score` / `bike_score` / `transit_score` + price band.
- **Frontend:** push payload routes to similar listing.

---

### F10 — Events / Travel (15 items)

#### #84 Travel radius slider partner UI ✅ Backend shipped; partner editor needed.
- **Frontend:** add slider on `lib/tajirika/pages/post_partner_product_page.dart` for events/travel skill_category.

#### #85 Package builder with add-ons UI (M)
- **Backend:** `partner_products.add_ons (json)` shipped.
- **Frontend:** drag-and-add editor on partner product edit.

#### #86 50% deposit + balance T-14d (M)
- **Backend:** `event_bookings.payment_plan_installments (json)` shipped. Scheduled job per booking pushes T-14 reminder.
- **Frontend:** partner-configurable schedule UI.

#### #87 Auto-generated contract from package selection (L)
- **Backend:** PDF generation via DomPDF or wkhtmltopdf. E-sign capture (signature image + cryptographic timestamp).
- **Frontend:** sign-here pad widget; PDF preview.

#### #88 "Real Events" social-proof gallery (M)
- **Backend:** new table `partner_event_showcase(partner_id, event_booking_id, photo_urls, caption, moderated_at)`.
- **Frontend:** rail on partner profile + post-event upload nudge.

#### #89 Day-by-day itinerary polish ✅ Already rendered; needs UX polish only.

#### #90 TALA license badge + insurance cert verified (M)
- **Backend:** `partner_skill_personas.tala_license_number`, `insurance_cert_url`, `tala_verified` shipped. Admin verification queue (BACKEND-ONLY per memory rule).
- **Frontend:** badge display on customer detail.

#### #91 Migration-season pricing overlay ✅ SHIPPED session 16 (`MigrationSeasonCalendar`)

#### #92 Multi-traveler intake polish (M)
- **Backend:** `event_bookings.travelers (json)` already supports it.
- **Frontend:** richer per-traveler form with passport + dietary + medical + emergency contact.

#### #93 Trip-prep checklist push at T-30/14/7d (M)
- **Backend:** scheduled jobs per booking. `event_bookings.trip_prep_notifications_sent (json)` shipped.

#### #94 Day-before reminder (M)
- **Backend:** scheduled push T-24h with `event_bookings.day_before_payload (json)` (shipped).

#### #95 On-tour live updates page (L)
- **Backend:** `lib/travel/services/trip_update_service.dart` + Reverb channel.
- **Frontend:** new `lib/travel/pages/my_trip_page.dart` with timeline + in-app chat with guide.

#### #96 Per-stop reviews on multi-day tours (M)
- **Backend:** `event_bookings.per_stop_reviews (json)` shipped.
- **Frontend:** per-stop review UI in `lib/travel/widgets/per_stop_reviewer.dart`.

#### #97 Last-minute discount auto-applied <48h (M)
- **Backend:** scheduled job flags empty-seat inventory. `event_bookings` already has fields.
- **Frontend:** chip auto-applied; existing discount infrastructure.

#### #98 Real Events gallery moderation (M)
- **Backend:** admin-only moderation queue (no Flutter admin UI per project rule).

---

### F11 — Reviews (3 items)

#### #99 Per-item thumbs ✅ SHIPPED session 16 (`PerItemThumbsPicker`).

Mounting: caller passes the order's line-item list to the widget; submit persists to `partner_reviews.per_item_thumbs (json)` (column shipped). Partner dashboard aggregates.

#### #100 Review weighting by recency (M)
- **Backend:** ranking aggregation rewrite. `partner_reviews.created_at`-weighted query everywhere `avg_stars` is computed. Last 6-12 months heavier.
- **Frontend:** none direct.

#### #101 Disease-specific outcome tracking (M)
- **Backend:** `consultations.outcome_followup` already shipped. New `outcome_score` table. Scheduled job at T+14 / T+30 days.
- **Frontend:** "Hali yako imeboresha?" dialog at outcome trigger time.

---

### F12 — Availability (8 items)

#### #102 T-2hr partner schedule reminder (M)
- **Backend:** scheduled job per non-ASAP booking via `PartnerC2BNotificationService`.

#### #103 Booking lead time + horizon UI ✅ Threading done session 16; visual chips on `_HoursDialog` partial.

#### #104 Buffer config UI ✅ Same — threading done; visual config UI partial.

#### #105 Last-minute slot discount auto-apply (M)
- **Backend:** scheduled job flags empty slots <48h; pushes customers via `PartnerC2BNotificationService`.

#### #106 Auto-add waitlist FIFO vs First-to-Claim (L)
- **Backend:** `partner_availability.waitlist_mode` shipped. SMS provider integration for First-to-Claim.

#### #107 "Any pro" auto-assign with travel/skill weighting (L)
- **Backend:** booking endpoint logic; partner skill scoring. Use existing JSS as input.

#### #108 Two-week fitness horizon + waitlist auto-promotion (M)
- **Backend:** scheduled job promotes waitlist when `class_session_bookings.status = 'cancelled'` opens spots.
- **Frontend:** none direct.

#### #109 Pick-a-spot floor plan — same as #42.

---

### F13 — Multi-Skill (5 items)

#### #110 Cross-persona time-allocation vs revenue dashboard (L)
- **Backend:** aggregation across personas. New endpoint `GET /partners/{id}/persona-analytics`.
- **Frontend:** charts on `partner_profile_page` own-profile section.

#### #111 Persona-level public profile pages — same as #72.

#### #112 Cross-persona unified inbox (M)
- **Backend:** inbox query rewrite to dedupe across personas + tag with skill icon.
- **Frontend:** `lib/customer_orders/pages/partner_inbox_page.dart` shows skill prefix per row.

#### #113 Optional per-skill portfolio for ranking lift — same as #67.

#### #114 AMC packages persona-specific scoping ✅ Reuses existing `partner_products.skill_category` filter.

#### #115 Skill-pause toggle UI ✅ SHIPPED session 16 (`SkillPauseToggle` widget).

---

## 7. Output expectations

For every PR / commit:

```markdown
### What

One-paragraph plain-English description of what changed.

### Why

Tie back to spec line + F-section #.

### Files touched

- `lib/...` (new/modified)
- `app/Http/Controllers/Api/...` (new)
- Schema additions (if any) — applied via SSH script `wave_X.php`

### Smoke test

- `flutter analyze <files>` → 0 errors / 0 warnings
- `curl https://tajiri.zimasystems.com/api/...` → expected payload (paste output)
- (If UI) screenshot in both Sw + En

### Plan doc update

One line appended to `tasks/multi_session_plan.md` under a new session header.
```

## 8. When to STOP and ask

- Item needs a new pubspec package not in the project
- Item needs native iOS/Android code
- Item touches the existing call infrastructure (`lib/calls/`)
- Item requires SMS / email provider procurement
- Item is XL-tier (#12, #28, #45, #71)
- A backend column you need is missing from §4.2

In all these cases, **describe the blocker and stop**. Do not invent a workaround.

## 9. Final reminders from project memory

- **Always work on main repo, never in worktrees.**
- **Don't fall back to manual-submission docs** when `./scripts/ask_backend.sh` fails — go straight to SSH.
- **No git operations** unless the user explicitly asks.
- **Bilingual is non-negotiable.** Every label in Sw + En.
- **Capture every interaction as data.** Backend caching tables (`ai_brief_cache`, `vin_decode_cache`, etc.) are part of the moat. Don't bypass them.
- **Don't write summaries** at the end of responses unless the user asks. Just say what you did.

Good luck. Ship one item at a time, end-to-end, with proof.
