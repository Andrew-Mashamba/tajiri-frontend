# Partner C2B Expansion Plan

This document covers expanding the existing **chef-product / customer-orders** flow (already shipped for `baking`, `cooking`, `catering`) so that other partner skills in `lib/tajirika/models/tajirika_models.dart` (`SkillCategory` enum) can sell to consumers through the same `lib/customer_orders/` inbox.

It has two parts:

- **Part A — Generalize made-to-order goods** (carpentry, masonry, welding, tiling, interiorDesign, photography, videography, makeup, nailTechnician, skincare, nutrition, eventPlanning). The schema fits; only the partner-skill filter and the surfacing rail change.
- **Part B — New service models** (mafundi site visits, garage drop-offs, salon appointments, lawyer/doctor consultations, real-estate inquiries, fitness sessions, travel/event bookings). These need new tables; they UNION into the same `customer_orders` inbox via a `source` discriminator.

Existing foundation (already deployed):

| Layer | Path |
|---|---|
| Schema | `chef_products`, `chef_product_photos`, `chef_product_orders` (Postgres) |
| Existing UNION | `chef_listing_reservations` + `chef_product_orders` → `GET /api/customer-orders` |
| Backend controller | `app/Http/Controllers/Api/CustomerOrderController.php` |
| Flutter model | `lib/food/models/chef_product.dart` |
| Flutter service | `lib/food/services/food_service.dart` (chef-product methods) |
| Customer orders module | `lib/customer_orders/` (`incoming_customer_orders_page.dart`, `customer_order_detail_page.dart`) |
| Partner posting | `lib/tajirika/pages/post_chef_product_page.dart` |
| Customer detail | `lib/food/pages/chef_product_detail_page.dart` |
| Customer rail | `lib/food/pages/food_home_page.dart` (`Vyakula vya Kuagiza`) |

The expansion **does not** rebuild any of the above. It generalizes Part A and adds sibling tables for Part B that all funnel into the same inbox.

---

## Part A — Generalize chef-products into partner-products

### A.1 Architectural choice

Two options exist:

1. **Rename** `chef_products` → `partner_products`, `chef_product_orders` → `partner_product_orders`, `chef_product_photos` → `partner_product_photos`.
2. **Keep names**, just remove the food-only filter and add a `skill_category` column.

**Decision: Option 1 (rename).** Reasons:

- The word "chef" is misleading once carpenters and photographers list products under it.
- The `customer_orders` UNION already discriminates by `source`, so renaming the source table only requires updating the `CASE` in `CustomerOrderController::index()`. The change is mechanical.
- Existing orders need a one-shot data move; not a runtime branch.

If timing forces a non-breaking path, ship Option 2 first and rename in a follow-up — but do not let the name `chef_products` leak into new verticals' code.

### A.2 Schema changes

**Migration: `20XX_XX_XX_rename_chef_products_to_partner_products.php`**

```sql
ALTER TABLE chef_products            RENAME TO partner_products;
ALTER TABLE chef_product_photos      RENAME TO partner_product_photos;
ALTER TABLE chef_product_orders      RENAME TO partner_product_orders;

ALTER TABLE partner_product_photos   RENAME COLUMN chef_product_id TO partner_product_id;
ALTER TABLE partner_product_orders   RENAME COLUMN chef_product_id TO partner_product_id;

ALTER TABLE partner_products
  ADD COLUMN skill_category VARCHAR(64) NULL,
  ADD COLUMN cluster        VARCHAR(32) NULL;        -- 'food' | 'mafundi' | 'events' | ...

CREATE INDEX partner_products_active_cluster_idx
  ON partner_products (is_active, cluster);
CREATE INDEX partner_products_skill_idx
  ON partner_products (skill_category);

UPDATE partner_products SET skill_category = 'baking', cluster = 'food'
  WHERE skill_category IS NULL;   -- safe assumption: shipped data is all cake-baker
```

Field semantics:

- `skill_category`: matches `SkillCategory.name` from Flutter (e.g. `carpentry`, `photography`).
- `cluster`: matches `SkillCategoryX.category()` return value (e.g. `food`, `mafundi`, `events`). Denormalized for cheap rail filtering — saves an in-app `case` lookup.

### A.3 Backend changes

#### A.3.1 Routes (`routes/api.php`)

Replace the current food-prefix block:

```php
// REMOVE
Route::prefix('food')->group(function () {
    Route::get   ('/chef-products',                [FoodController::class, 'listChefProducts']);
    Route::post  ('/chef-products/photo',          [FoodController::class, 'uploadChefProductPhoto']);
    Route::get   ('/chef-products/{id}',           [FoodController::class, 'getChefProduct']);
    Route::post  ('/chef-products',                [FoodController::class, 'createChefProduct']);
    Route::patch ('/chef-products/{id}',           [FoodController::class, 'updateChefProduct']);
    Route::post  ('/chef-products/{id}/order',     [FoodController::class, 'orderChefProduct']);
});
```

Add at top level:

```php
Route::prefix('partner-products')->controller(PartnerProductController::class)->group(function () {
    Route::get   ('/',                  'index');     // ?cluster=food&skill_category=baking&active=1
    Route::post  ('/photo',             'uploadPhoto');
    Route::get   ('/{id}',              'show');
    Route::post  ('/',                  'create');
    Route::patch ('/{id}',              'update');
    Route::post  ('/{id}/order',        'order');
});
```

`PartnerProductController` is a copy of the chef-product methods from `FoodController` with these changes:

- `index()` accepts `?cluster=` and `?skill_category=` filters.
- `create()` and `update()` require `skill_category` (non-null) and derive `cluster` from a static map (mirror of `SkillCategoryX.category()` in PHP).
- All foreign key references use `partner_product_id`.

Keep the old food-prefix routes for **one release** as deprecation shims that proxy to the new controller — log a deprecation warning so the Flutter side gets caught quickly.

#### A.3.2 `CustomerOrderController::index()` UNION update

The existing query UNIONs `chef_listing_reservations` and `chef_product_orders`. Update the second branch:

```php
// was: FROM chef_product_orders cpo JOIN chef_products cp ON cp.id = cpo.chef_product_id
//      'chef_product' AS source
// becomes:
SELECT
    'partner_product' AS source,
    ppo.id, ppo.partner_id, ppo.partner_user_id, ppo.buyer_user_id,
    pp.title AS item_title, pp.cluster, pp.skill_category,
    /* ... rest of fields unchanged ... */
FROM partner_product_orders ppo
JOIN partner_products pp ON pp.id = ppo.partner_product_id
```

Update `show($source, $id)` and `action($source, $id, $action)` to accept `'partner_product'` instead of `'chef_product'`. Status state machine is identical.

#### A.3.3 Vertical-specific filtering

For each vertical's home rail (Part A.5), the consumer-facing `listPartnerProducts` call uses `cluster=` to scope. Examples:

| Vertical | Query |
|---|---|
| `lib/food/` | `GET /partner-products?cluster=food&active=1&limit=12` |
| `lib/mafundi/` | `GET /partner-products?cluster=mafundi&active=1&limit=12` |
| `lib/events/` | `GET /partner-products?cluster=events&active=1&limit=12` |
| `lib/skincare/` | `GET /partner-products?cluster=skincare&active=1&limit=12` |
| `lib/hair_nails/` | `GET /partner-products?cluster=hair_nails&active=1&limit=12` |
| `lib/fitness/` | `GET /partner-products?cluster=fitness&active=1&skill_category=nutrition&limit=12` |
| `lib/housing/` | `GET /partner-products?cluster=housing&active=1&skill_category=interiorDesign&limit=12` |

### A.4 Flutter changes

#### A.4.1 Move + rename files

| From | To |
|---|---|
| `lib/food/models/chef_product.dart` | `lib/tajirika/models/partner_product.dart` |
| `chef-product methods in lib/food/services/food_service.dart` | new `lib/tajirika/services/partner_product_service.dart` |
| `lib/tajirika/pages/post_chef_product_page.dart` | `lib/tajirika/pages/post_partner_product_page.dart` |
| `lib/food/pages/chef_product_detail_page.dart` | `lib/tajirika/pages/partner_product_detail_page.dart` |

Reason: the model/service/posting form/detail page are all skill-category-agnostic. Their natural home is `lib/tajirika/` (partner-side) and `lib/tajirika/pages/` (canonical detail). Each vertical's home page is just a *rail* that opens the canonical detail page.

#### A.4.2 Model changes (`partner_product.dart`)

Add fields:

```dart
final String? skillCategory;   // e.g. 'baking', 'carpentry'
final String? cluster;         // e.g. 'food', 'mafundi'
```

Update the rename map: `ChefProduct` → `PartnerProduct`, `ChefProductMode` → `PartnerProductMode` (keep `pickup_only|delivery_only|both`).

#### A.4.3 Service changes (`partner_product_service.dart`)

Public methods:

```dart
Future<FoodListResult<PartnerProduct>> listPartnerProducts({
  String? cluster,
  String? skillCategory,
  int? partnerId,
  bool activeOnly = true,
  bool mine = false,
  int? userId,
  String? query,
  int limit = 50,
  int offset = 0,
});
Future<FoodResult<PartnerProduct>>     getPartnerProduct(int id);
Future<FoodResult<PartnerProduct>>     createPartnerProduct({...required skillCategory});
Future<FoodResult<PartnerProduct>>     updatePartnerProduct({...});
Future<FoodResult<int>>                orderPartnerProduct({...});
Future<FoodResult<String>>             uploadPartnerProductPhoto(File photo);
```

The signatures mirror today's `FoodService` methods. `createPartnerProduct` makes `skillCategory` required (no default).

#### A.4.4 Partner posting form (`post_partner_product_page.dart`)

The form gains a **read-only skill banner** at top showing the partner's selected `SkillCategory`. The flow:

1. Partner navigates from their `tajirika_home_page` → "Post Bidhaa".
2. If the partner has multiple skills (`TajirikaPartner.skills.length > 1`), show a `SkillCategory` selector chip row before the form fields.
3. Otherwise, lock the skill to their single registered skill.
4. The `tags` chip set adapts to skill (per-skill suggestion list — see A.6).
5. The mode chips (`pickupOnly | deliveryOnly | both`) stay; for digital/intangible products (e.g. a `videography` highlight reel uploaded online), add a fourth `digital_only` mode in `PartnerProductMode` and skip the address picker for it.

#### A.4.5 Buyer detail page (`partner_product_detail_page.dart`)

No structural changes from `chef_product_detail_page.dart`. Only:

- Title bar shows skill icon (`SkillCategory.icon`) instead of the cake glyph.
- "Order to make" copy changes per cluster:
  - `food` → "Agiza sasa — TZS X"
  - `mafundi` → "Omba kazi — TZS X"
  - `events` → "Hifadhi — TZS X"
  - `skincare`/`hair_nails` → "Nunua — TZS X"

Encapsulate this in `_orderCtaLabel(cluster)` on the page.

### A.5 Per-vertical home rails

Each vertical adds a **single rail** identical in shape to the `Vyakula vya Kuagiza` rail already in `food_home_page.dart`. The rail widget should be extracted to a shared `lib/tajirika/widgets/partner_product_rail.dart` to avoid duplicating the card design.

```dart
// lib/tajirika/widgets/partner_product_rail.dart
class PartnerProductRail extends StatelessWidget {
  final List<PartnerProduct> products;
  final void Function(PartnerProduct) onTap;
  final String titleSwahili;       // e.g. 'Bidhaa za Mafundi'
  final String subtitleEnglish;    // e.g. 'Made to order'
  ...
}
```

Each home page adds the rail under its existing content:

| File | Title (Swahili) | Subtitle | Cluster filter |
|---|---|---|---|
| `lib/food/pages/food_home_page.dart` | Vyakula vya Kuagiza | Order to make | `food` (already shipped) |
| `lib/mafundi/pages/mafundi_home_page.dart` (CREATE) | Bidhaa za Mafundi | Custom builds | `mafundi` |
| `lib/events/pages/events_home_page.dart` (or current entry point) | Pakeji za Hafla | Event packages | `events` |
| `lib/skincare/pages/skincare_home_page.dart` | Bidhaa za Urembo | Beauty kits | `skincare` |
| `lib/hair_nails/pages/hair_nails_home_page.dart` | Vifaa vya Kucha | Nail kits | `hair_nails` |
| `lib/fitness/pages/fitness_home_page.dart` | Pakeji za Lishe | Meal plans | `fitness` |
| `lib/housing/pages/housing_home_page.dart` | Bidhaa za Ndani | Décor pieces | `housing` |

`lib/mafundi/` does not exist today — create it as a new feature dir following the `lib/food/` structure (pages/, models/, services/, widgets/).

### A.6 Skill-specific tag dictionaries

Each `SkillCategory` gets a curated tag suggestion list, used in the partner posting form. Store as a static map in `lib/tajirika/models/tajirika_models.dart`:

```dart
extension SkillCategoryTagsX on SkillCategory {
  List<String> get suggestedTags {
    switch (this) {
      case SkillCategory.baking:        return ['cake','birthday','wedding','chocolate','vanilla','halal','homemade'];
      case SkillCategory.carpentry:     return ['door','table','bed','wardrobe','custom','mahogany','oak','wholesale'];
      case SkillCategory.masonry:       return ['gate','grill','window','custom','steel','wrought_iron'];
      case SkillCategory.welding:       return ['gate','grill','railing','custom'];
      case SkillCategory.tiling:        return ['floor','wall','design_pack','mosaic'];
      case SkillCategory.interiorDesign:return ['decor','curtain','centerpiece','rug'];
      case SkillCategory.photography:   return ['album','print','frame','wedding','portrait'];
      case SkillCategory.videography:   return ['highlight_reel','wedding','event','editing'];
      case SkillCategory.makeup:        return ['bridal','party','palette','set'];
      case SkillCategory.nailTechnician:return ['press_on','manicure','pedicure','set','color'];
      case SkillCategory.skincare:      return ['oil','scrub','soap','homemade','natural'];
      case SkillCategory.nutrition:     return ['weekly_plan','keto','vegan','diabetic_friendly','postnatal'];
      case SkillCategory.eventPlanning: return ['decor_package','centerpiece','flowers','arch'];
      default: return const [];
    }
  }
}
```

### A.7 Migration order (Part A)

1. **Backend, day 1.** Run the rename migration. Deploy the new `PartnerProductController` + routes. Update `CustomerOrderController` UNION. Keep deprecation shims for the old `/api/food/chef-products*` routes.
2. **Backend, day 1.** Backfill `skill_category = 'baking'`, `cluster = 'food'` for existing rows.
3. **Frontend, day 2.** Move/rename Flutter files. Update imports. Run `flutter analyze`.
4. **Frontend, day 2.** Extract `PartnerProductRail`. Switch `food_home_page.dart` to use the new rail + service.
5. **Frontend, day 3.** Add rail to `lib/skincare/`, `lib/hair_nails/`, `lib/fitness/`, `lib/housing/`, `lib/events/` home pages.
6. **Frontend, day 3–4.** Create `lib/mafundi/` and its home page.
7. **Frontend, day 4.** Update `post_chef_product_page` references in `tajirika_home_page.dart` to point at `post_partner_product_page` with skill selector.
8. **Backend, day 5.** Remove deprecation shims; verify no Flutter callers remain on `/api/food/chef-products*`.

### A.8 Verification checklist

- [ ] A `baking` partner can still post + receive orders without behavioural change.
- [ ] A `carpentry` partner can post a "custom door" via `post_partner_product_page` from `tajirika_home_page`.
- [ ] The `lib/mafundi/` home rail shows that door.
- [ ] Buyer can place an order from `partner_product_detail_page`.
- [ ] Order appears in `IncomingCustomerOrdersPage` for the carpenter, with correct skill icon + action bar.
- [ ] `customer_orders` listing shows both bakery + carpentry orders mixed for a partner who registered for both skills.
- [ ] Old food-prefix routes return `301` or success with deprecation log header for one release.

---

## Part B — Sibling models for service-based skills

Each cluster below gets its own table, partner-side flow, customer-side flow, and a new `source` value in the `customer_orders` UNION. The inbox page (`incoming_customer_orders_page.dart`) and detail page (`customer_order_detail_page.dart`) gain new dispatcher branches but their structure does not change — they are already source-discriminated.

### B.0 Shared design rules

- All sibling tables include: `partner_id`, `partner_user_id`, `customer_user_id`, `skill_category`, `cluster`, status enum, `notes`, `rejection_reason`, lifecycle timestamps (`accepted_at`, `cancelled_at`, etc.), `created_at`, `updated_at`.
- The status enum varies but always includes `pending`, `cancelled`, `rejected`, `completed`. Final → cancelled/rejected/completed are terminal.
- All sibling controllers expose `index($filters)`, `show($id)`, `create($payload)`, `action($id, $action, $reason?)`.
- All sibling sources are added to the UNION query in `CustomerOrderController::index()` with consistent column aliases (`item_title`, `subtotal_tzs`, `requested_for`, `status`, `cluster`).
- Push notifications fire on every state transition via the `LiveUpdateService` Firestore channel; payload includes `source`, `id`, `status`, `cluster`.
- Money lands in the COA system via the existing journal-line pattern (`feedback_coa_source_of_truth`): each `completed` order writes a journal entry — `partner_revenue` credit + `customer_payable` debit.

### B.1 Service Request — mafundi site visits

**Skills:** `plumbing`, `electrical`, `painting`, `roofing`, `solarInstallation`.

**Use case:** Customer has a broken pipe; needs a plumber to come to their house.

#### Schema

```sql
CREATE TABLE service_requests (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NULL,                 -- NULL until partner accepts (for open marketplace mode)
  partner_user_id   BIGINT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,        -- plumbing | electrical | ...
  cluster           VARCHAR(32) NOT NULL DEFAULT 'mafundi',
  problem_summary   TEXT NOT NULL,               -- "Bomba inavuja chini ya sinki"
  problem_photos    JSONB,                       -- array of photo paths
  site_address      TEXT NOT NULL,
  site_lat          DECIMAL(10,7),
  site_lng          DECIMAL(10,7),
  preferred_window  VARCHAR(32),                 -- 'today_am' | 'today_pm' | 'tomorrow' | 'this_week'
  callout_fee_tzs   INTEGER,                     -- partner sets after viewing photos; null until quoted
  estimated_cost_tzs INTEGER,                    -- optional rough quote
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | quoted | accepted | en_route | on_site | completed | cancelled | rejected
  quoted_at         TIMESTAMP,
  accepted_at       TIMESTAMP,
  en_route_at       TIMESTAMP,
  on_site_at        TIMESTAMP,
  completed_at      TIMESTAMP,
  cancelled_at      TIMESTAMP,
  rejection_reason  TEXT,
  notes             TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);

CREATE INDEX service_requests_partner_idx  ON service_requests (partner_user_id, status);
CREATE INDEX service_requests_customer_idx ON service_requests (customer_user_id, status);
```

#### Status state machine

```
pending → quoted (partner sends fee + ETA)
quoted  → accepted (customer agrees)
quoted  → cancelled (customer rejects quote)
accepted → en_route → on_site → completed
any non-terminal → cancelled (either party)
pending  → rejected (partner declines)
```

#### Backend

- Routes: `Route::prefix('service-requests')->controller(ServiceRequestController::class)`.
- Endpoints: `GET /`, `POST /`, `GET /{id}`, `POST /{id}/quote`, `POST /{id}/accept`, `POST /{id}/{action}` (en_route/on_site/complete/cancel/reject).
- `index()` supports `?role=partner|customer&status=&skill_category=`.

#### Partner UI (new files)

- `lib/mafundi/pages/incoming_service_requests_page.dart` — partner inbox tab, also surfaced from `customer_orders` UNION but with deeper actions here.
- `lib/mafundi/pages/service_request_detail_page.dart` — shows problem photos, address (with map deeplink), action buttons: **Quote**, **Accept**, **En route**, **On site**, **Complete**, **Reject**.
- Quote dialog: `callout_fee_tzs` + optional `estimated_cost_tzs` + ETA dropdown (`now`, `1h`, `3h`, `tomorrow`).

#### Customer UI (new files)

- `lib/mafundi/pages/request_service_page.dart` — form: skill picker, problem summary, photo upload (up to 4), address (auto-fill from profile location), preferred window chips.
- `lib/mafundi/pages/service_request_status_page.dart` — timeline view + chat link.

#### UNION addition

```php
UNION ALL
SELECT 'service_request' AS source,
       sr.id, sr.partner_id, sr.partner_user_id, sr.customer_user_id AS buyer_user_id,
       sr.problem_summary AS item_title, sr.cluster, sr.skill_category,
       NULL AS quantity, sr.callout_fee_tzs AS unit_price_tzs,
       NULL AS delivery_fee_tzs, sr.callout_fee_tzs AS total_price_tzs,
       sr.status, NULL AS delivery_mode, sr.site_address AS delivery_address,
       NULL AS requested_for, ...
FROM service_requests sr
```

### B.2 Drop-off Booking — service garage

**Skills:** `autoMechanic`, `autoElectrician`, `panelBeating`, `sprayPainting`.

**Use case:** Customer drops car at the garage at an agreed slot.

#### Schema

```sql
CREATE TABLE garage_bookings (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL DEFAULT 'service_garage',
  vehicle_make      VARCHAR(64),
  vehicle_model     VARCHAR(64),
  vehicle_plate     VARCHAR(16),
  vehicle_year      INTEGER,
  fault_summary     TEXT NOT NULL,
  fault_photos      JSONB,
  drop_off_at       TIMESTAMP NOT NULL,
  estimated_cost_tzs INTEGER,
  diagnosis         TEXT,                        -- partner fills after inspection
  approved_cost_tzs INTEGER,                     -- customer approves after diagnosis
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | confirmed | dropped_off | diagnosed | approved | in_progress | ready_for_pickup | completed | cancelled | rejected
  confirmed_at      TIMESTAMP,
  dropped_off_at    TIMESTAMP,
  diagnosed_at      TIMESTAMP,
  approved_at       TIMESTAMP,
  ready_at          TIMESTAMP,
  completed_at      TIMESTAMP,
  cancelled_at      TIMESTAMP,
  rejection_reason  TEXT,
  notes             TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);
```

#### Status state machine

```
pending → confirmed (partner accepts slot) | rejected
confirmed → dropped_off → diagnosed → approved (customer agrees to revised cost) → in_progress → ready_for_pickup → completed
diagnosed → cancelled (customer declines revised cost)
any non-terminal → cancelled
```

#### Files

- `lib/service_garage/pages/incoming_garage_bookings_page.dart`
- `lib/service_garage/pages/garage_booking_detail_page.dart`
- `lib/service_garage/pages/book_garage_page.dart`
- `lib/service_garage/pages/garage_status_page.dart`

The detail page's diagnosis step shows a "Send revised quote" button for the partner; customer sees an "Approve / Decline" pair when `status == 'diagnosed'`.

### B.3 Appointment — salon, fitness session

**Skills:** `hairstyling`, `barbering`, `personalTraining`.

**Use case:** Customer books a haircut at 14:00 on Saturday.

#### Schema

```sql
CREATE TABLE appointments (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL,        -- 'hair_nails' | 'fitness'
  service_title     VARCHAR(128) NOT NULL,       -- 'Mens cut + beard'
  service_duration_min INTEGER NOT NULL,
  price_tzs         INTEGER NOT NULL,
  starts_at         TIMESTAMP NOT NULL,
  ends_at           TIMESTAMP NOT NULL,
  location_kind     VARCHAR(16) NOT NULL,        -- 'salon' | 'home' | 'virtual'
  customer_address  TEXT,                        -- when location_kind = 'home'
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | confirmed | checked_in | in_progress | completed | no_show | cancelled | rejected
  confirmed_at      TIMESTAMP,
  checked_in_at     TIMESTAMP,
  completed_at      TIMESTAMP,
  cancelled_at      TIMESTAMP,
  rejection_reason  TEXT,
  notes             TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);

CREATE TABLE partner_availability (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  weekday           SMALLINT NOT NULL,           -- 0..6 (Sun..Sat)
  open_time         TIME NOT NULL,
  close_time        TIME NOT NULL,
  slot_minutes      INTEGER NOT NULL DEFAULT 30
);

CREATE TABLE partner_blackouts (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  starts_at         TIMESTAMP NOT NULL,
  ends_at           TIMESTAMP NOT NULL,
  reason            VARCHAR(128)
);
```

`partner_availability` and `partner_blackouts` are also reused by B.4 (consultation) and B.6 (event booking) — shared across appointment-style flows.

#### Files

- `lib/hair_nails/pages/book_hair_nails_appointment_page.dart`
- `lib/fitness/pages/book_fitness_session_page.dart`
- Shared: `lib/tajirika/widgets/slot_picker.dart` — week grid + blackout-aware slot picker.
- Shared: `lib/tajirika/pages/manage_availability_page.dart` — partner sets weekly hours.
- Detail/inbox: piggyback on `customer_orders`.

#### Status state machine

```
pending → confirmed → checked_in → in_progress → completed
pending → rejected
any non-terminal → cancelled
confirmed → no_show (partner-only, after starts_at + 15min)
```

#### Recurring sessions (fitness only)

Add `recurrence_pattern` JSONB to `appointments` (e.g. `{kind:'weekly', days:[1,3,5], until:'2026-06-30'}`). When set, server auto-generates child appointments on confirmation. Track parent via `parent_appointment_id BIGINT NULL`.

### B.4 Consultation — lawyer, doctor, business

**Skills:** `legal`, `medical`, `nursing`, `pharmacy`, `accounting`, `taxAdvisory`, `businessConsulting`, `hrConsulting`, `careerCoaching`.

**Use case:** Customer books a 30-min legal consultation; possibly virtual.

#### Schema

```sql
CREATE TABLE consultations (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL,        -- 'lawyer' | 'doctor' | 'business'
  intake_summary    TEXT NOT NULL,               -- customer's case summary, encrypted at rest
  intake_attachments JSONB,                      -- e.g. medical reports, contracts
  starts_at         TIMESTAMP NOT NULL,
  duration_min      INTEGER NOT NULL,
  fee_tzs           INTEGER NOT NULL,
  mode              VARCHAR(16) NOT NULL,        -- 'in_person' | 'phone' | 'video'
  meeting_link      TEXT,                        -- for video
  in_person_address TEXT,
  is_confidential   BOOLEAN NOT NULL DEFAULT TRUE,
  nda_accepted_at   TIMESTAMP,
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | confirmed | in_progress | completed | cancelled | rejected
  follow_up_notes   TEXT,                        -- partner-only post-consultation
  prescription      TEXT,                        -- doctor-only
  invoice_url       TEXT,
  confirmed_at      TIMESTAMP,
  completed_at      TIMESTAMP,
  cancelled_at      TIMESTAMP,
  rejection_reason  TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);
```

#### Confidentiality + auth

`intake_summary`, `intake_attachments`, `prescription`, and `follow_up_notes` are **encrypted at rest** using Laravel's built-in `Crypt` facade. The customer's signed NDA stores `nda_accepted_at`; partner's authz checks include both `partner_user_id` ownership and `nda_accepted_at IS NOT NULL`.

The mobile UI must not surface `prescription` to anyone except `customer_user_id` once the partner sets it. The `customer_orders` UNION exposes only the title + status + fee for consultations — never the intake content. The detail page does the deeper fetch through a separate encrypted-payload endpoint.

#### Files

- `lib/legal_gpt/pages/book_legal_consultation_page.dart`
- `lib/doctor/pages/book_medical_consultation_page.dart`
- `lib/business/pages/book_business_consultation_page.dart`
- Shared: `lib/tajirika/widgets/consultation_intake_form.dart` (includes NDA acceptance gate).
- Shared: `lib/tajirika/pages/consultation_detail_page.dart`.

### B.5 Engagement — long-running business work

**Skills:** `accounting`, `taxAdvisory`, `businessConsulting`, `hrConsulting`, `careerCoaching` — when customer wants ongoing work, not a single consultation.

**Use case:** Customer hires an accountant for monthly bookkeeping.

This is structurally different from B.4: it's a *retainer* with milestones.

#### Schema

```sql
CREATE TABLE engagements (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL DEFAULT 'business',
  title             VARCHAR(160) NOT NULL,
  scope_brief       TEXT NOT NULL,
  pricing_model     VARCHAR(16) NOT NULL,        -- 'hourly' | 'retainer' | 'fixed'
  hourly_rate_tzs   INTEGER,
  retainer_tzs      INTEGER,
  fixed_total_tzs   INTEGER,
  start_date        DATE NOT NULL,
  end_date          DATE,                        -- null for open-ended retainer
  nda_accepted_at   TIMESTAMP,
  status            VARCHAR(32) NOT NULL DEFAULT 'proposed',
  -- proposed | accepted | active | paused | ended | cancelled | rejected
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);

CREATE TABLE engagement_milestones (
  id                BIGSERIAL PRIMARY KEY,
  engagement_id     BIGINT NOT NULL REFERENCES engagements(id) ON DELETE CASCADE,
  title             VARCHAR(160) NOT NULL,
  due_date          DATE,
  amount_tzs        INTEGER,
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | submitted | approved | paid
  submitted_at      TIMESTAMP,
  approved_at       TIMESTAMP,
  paid_at           TIMESTAMP
);

CREATE TABLE engagement_time_entries (
  id                BIGSERIAL PRIMARY KEY,
  engagement_id     BIGINT NOT NULL REFERENCES engagements(id) ON DELETE CASCADE,
  partner_user_id   BIGINT NOT NULL,
  date              DATE NOT NULL,
  minutes           INTEGER NOT NULL,
  description       TEXT,
  is_billable       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMP NOT NULL
);
```

#### Files

- `lib/business/pages/propose_engagement_page.dart` (partner)
- `lib/business/pages/engagement_proposal_review_page.dart` (customer)
- `lib/business/pages/engagement_workspace_page.dart` (both — milestones + time entries + invoices)
- The `customer_orders` UNION shows engagements as `source='engagement'` with `item_title = engagements.title`, `subtotal_tzs = current period invoice amount`.

### B.6 Listing Inquiry — real estate

**Skills:** `realEstate`, `propertyManagement`, `homeInspection`.

**Use case:** Customer browses properties; requests a viewing.

This needs two tables: a *listing* catalogue and an *inquiry* per buyer-listing pair. Listings are partner-owned content (not orderable until inquired).

#### Schema

```sql
CREATE TABLE property_listings (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL DEFAULT 'housing',
  title             VARCHAR(200) NOT NULL,
  description       TEXT,
  property_type     VARCHAR(32) NOT NULL,        -- 'apartment' | 'house' | 'land' | 'office' | 'shop'
  listing_kind      VARCHAR(16) NOT NULL,        -- 'sale' | 'rent'
  price_tzs         BIGINT NOT NULL,
  rent_period       VARCHAR(16),                 -- 'monthly' | 'yearly' (when listing_kind='rent')
  bedrooms          SMALLINT,
  bathrooms         SMALLINT,
  area_sqm          INTEGER,
  region            VARCHAR(64),
  district          VARCHAR(64),
  ward              VARCHAR(64),
  street            VARCHAR(128),
  lat               DECIMAL(10,7),
  lng               DECIMAL(10,7),
  photos            JSONB,
  amenities         JSONB,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL,
  deleted_at        TIMESTAMP
);

CREATE TABLE listing_inquiries (
  id                BIGSERIAL PRIMARY KEY,
  property_listing_id BIGINT NOT NULL REFERENCES property_listings(id),
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  inquiry_kind      VARCHAR(32) NOT NULL,        -- 'viewing' | 'offer' | 'question'
  message           TEXT,
  preferred_viewing_at TIMESTAMP,
  offer_price_tzs   BIGINT,
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | acknowledged | scheduled | viewed | offer_made | accepted | rejected | cancelled
  acknowledged_at   TIMESTAMP,
  scheduled_at      TIMESTAMP,
  viewed_at         TIMESTAMP,
  rejection_reason  TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);
```

#### Files

- `lib/housing/pages/post_property_listing_page.dart` (partner)
- `lib/housing/pages/property_listing_detail_page.dart` (customer)
- `lib/housing/pages/property_inquiry_page.dart` (customer flow after detail)
- `lib/housing/pages/incoming_inquiries_page.dart` (partner inbox — also surfaces from `customer_orders` UNION)

#### UNION addition

Inquiries surface as `source='listing_inquiry'`, `item_title = property_listings.title`, `subtotal_tzs = property_listings.price_tzs` (informational), no delivery fields.

### B.7 Event Booking — travel, MC/DJ, tour guide

**Skills:** `tourGuide`, `travelAgent`, `safariOperator`, `djing`, `mc`.

**Use case:** Customer books a DJ for a wedding on a specific date with a deposit.

#### Schema

```sql
CREATE TABLE event_bookings (
  id                BIGSERIAL PRIMARY KEY,
  partner_id        BIGINT NOT NULL,
  partner_user_id   BIGINT NOT NULL,
  customer_user_id  BIGINT NOT NULL,
  skill_category    VARCHAR(64) NOT NULL,
  cluster           VARCHAR(32) NOT NULL,        -- 'travel' | 'events'
  event_title       VARCHAR(200) NOT NULL,       -- 'Asha & John wedding'
  event_kind        VARCHAR(32),                 -- 'wedding' | 'birthday' | 'safari' | ...
  event_starts_at   TIMESTAMP NOT NULL,
  event_ends_at     TIMESTAMP NOT NULL,
  event_address     TEXT,
  event_lat         DECIMAL(10,7),
  event_lng         DECIMAL(10,7),
  party_size        INTEGER,
  package_id        BIGINT,                      -- optional FK to partner_products row when booked from a package
  fee_tzs           INTEGER NOT NULL,
  deposit_tzs       INTEGER NOT NULL,
  deposit_paid_at   TIMESTAMP,
  balance_paid_at   TIMESTAMP,
  status            VARCHAR(32) NOT NULL DEFAULT 'pending',
  -- pending | held | deposit_paid | confirmed | day_of | completed | cancelled | rejected
  held_until        TIMESTAMP,                   -- soft hold while customer pays deposit
  confirmed_at      TIMESTAMP,
  completed_at      TIMESTAMP,
  cancelled_at      TIMESTAMP,
  rejection_reason  TEXT,
  notes             TEXT,
  created_at        TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP NOT NULL
);
```

#### Status state machine

```
pending → held (partner soft-holds the date for N hours, default 48)
held    → deposit_paid (customer pays deposit) → confirmed
held    → cancelled (timed-out hold)
confirmed → day_of (auto-flip on event_starts_at) → completed
any non-terminal → cancelled
pending → rejected
```

#### Files

- `lib/events/pages/post_event_package_page.dart` (partner — uses `partner_products` via Part A; the optional `package_id` here links a booking to a package)
- `lib/events/pages/book_event_package_page.dart` (customer)
- `lib/travel/pages/book_safari_page.dart`
- Shared timeline page lives in `lib/customer_orders/pages/customer_order_detail_page.dart` (extended).

#### Deposit payment

Deposit collection uses the existing `lib/wallet/` mobile-money flow. On successful payment, server flips status `held → deposit_paid → confirmed` and fires a Reverb event so both parties' devices update in real-time.

---

## Part C — Cross-cutting concerns

### C.1 `customer_orders` UNION extension

After all of Part A and B, the UNION query in `CustomerOrderController::index()` looks like this (pseudocode):

```sql
SELECT 'partner_product' AS source, ...                 -- B.0 → renamed from chef_product
UNION ALL SELECT 'chef_listing'    AS source, ...       -- existing
UNION ALL SELECT 'service_request' AS source, ...       -- B.1
UNION ALL SELECT 'garage_booking'  AS source, ...       -- B.2
UNION ALL SELECT 'appointment'     AS source, ...       -- B.3
UNION ALL SELECT 'consultation'    AS source, ...       -- B.4
UNION ALL SELECT 'engagement'      AS source, ...       -- B.5
UNION ALL SELECT 'listing_inquiry' AS source, ...       -- B.6
UNION ALL SELECT 'event_booking'   AS source, ...       -- B.7
ORDER BY created_at DESC LIMIT ? OFFSET ?
```

**Required column aliases (every branch):** `source`, `id`, `partner_id`, `partner_user_id`, `buyer_user_id` (alias customer_user_id where needed), `item_title`, `cluster`, `skill_category`, `quantity` (NULL if N/A), `unit_price_tzs`, `delivery_fee_tzs` (NULL if N/A), `total_price_tzs`, `status`, `delivery_mode` (NULL if N/A), `delivery_address` (or site_address / event_address), `requested_for` (or starts_at / event_starts_at / drop_off_at), `notes`, `rejection_reason`, `created_at`, `updated_at`.

Performance note: each source is indexed on `(partner_user_id, status, created_at DESC)` and `(customer_user_id, status, created_at DESC)`. The UNION runs in <50ms per source for partners with <1000 rows; beyond that, switch to a materialized view refreshed on write.

### C.2 Customer-orders inbox dispatcher

`incoming_customer_orders_page.dart` and `customer_order_detail_page.dart` already dispatch by `source`. Add new branches:

```dart
enum CustomerOrderSource {
  chefListing,
  partnerProduct,        // renamed from chefProduct
  serviceRequest,        // B.1
  garageBooking,         // B.2
  appointment,           // B.3
  consultation,          // B.4
  engagement,            // B.5
  listingInquiry,        // B.6
  eventBooking,          // B.7
}
```

Each source maps to:

- An icon (`SkillCategory.icon` for the row's `skill_category`, or a fallback per source).
- A list of allowed actions per status (`accept`, `reject`, `quote`, `confirm`, `complete`, etc.) — defined in a single `lib/customer_orders/models/source_action_map.dart`.
- A "view full detail" route — opens the source-specific detail page, not the generic one, when actions need source-specific UI (e.g. consultations need NDA gate; service requests need quote dialog).

Generic detail page covers ~60% of cases (timeline + chat + cancel). Source-specific detail pages handle the rest.

### C.3 Notifications

Each state transition fires:

1. Push notification (FCM) to the counter-party with payload `{source, id, status, cluster}`. Tap → deeplink to source-specific detail page.
2. Firestore event via `LiveUpdateService` (sealed class subtype: `CustomerOrderUpdateEvent` — refactor today's `MessagesUpdateEvent` pattern).
3. SMS fallback (existing `BulkSmsService`) for `confirmed`, `completed`, and `cancelled` only — minimize cost.

Add per-source FCM template files: `lambda/fcm_templates/<source>_<status>.json`.

### C.4 COA (chart-of-accounts) money rules

Per `feedback_coa_source_of_truth`: all money calculations use COA / `journal_lines`, never raw tables.

On terminal `completed` (or `paid` for milestones / deposits), each source writes journal entries:

| Source | Debit | Credit |
|---|---|---|
| `partner_product` | `accounts_payable` (customer) | `partner_revenue` (partner) — split by `delivery_fee_tzs` if any |
| `service_request` | `accounts_payable` | `partner_revenue` |
| `garage_booking` | `accounts_payable` | `partner_revenue` |
| `appointment` | `accounts_payable` | `partner_revenue` |
| `consultation` | `accounts_payable` | `professional_services_revenue` |
| `engagement` (per milestone) | `accounts_payable` | `professional_services_revenue` |
| `listing_inquiry` (commission on accepted offer) | `accounts_payable` | `commission_revenue` |
| `event_booking` (deposit + balance separately) | `customer_deposits` then `event_revenue` | mirrored |

The existing `accounting` module's `JournalEntryService` exposes `recordTransaction({source, amount, debit, credit, reference})`. Each source controller calls it on terminal transitions.

### C.5 Photos & uploads

All sources reuse `partner_products`-style photo upload: `POST /<source>/photo` returns a relative path; the source's `create` payload includes a `photos: [path1, path2]` array. Server validates each path under storage path `<source>/photos/`. For consultations and inquiries, attachments are stored under `<source>/attachments/` with restricted access tokens.

### C.6 Reviews & ratings

Add a single shared `partner_reviews` table:

```sql
CREATE TABLE partner_reviews (
  id              BIGSERIAL PRIMARY KEY,
  partner_id      BIGINT NOT NULL,
  partner_user_id BIGINT NOT NULL,
  reviewer_user_id BIGINT NOT NULL,
  source          VARCHAR(32) NOT NULL,
  source_id       BIGINT NOT NULL,
  rating          SMALLINT NOT NULL,           -- 1..5
  comment         TEXT,
  created_at      TIMESTAMP NOT NULL,
  UNIQUE (source, source_id, reviewer_user_id)
);
```

Reviews are only writable when the order is in a terminal positive state (`completed` for most sources, `viewed`/`accepted` for inquiries). Partner profile aggregates `AVG(rating)` across all sources.

### C.7 Search & discovery

The cross-vertical search at `lib/screens/search/` adds a `partner_offerings` index that UNIONs:

- `partner_products` (title, description, tags)
- `property_listings` (title, description, region, district)
- partner profile bios

It does **not** index appointments / consultations / inquiries (private, not browseable).

---

## Part D — Phased delivery

### Phase 1 — Generalize Part A (1 week)

- Schema rename + columns.
- `PartnerProductController` + routes.
- Flutter file moves + service.
- Extract `PartnerProductRail` widget.
- Wire `food`, `skincare`, `hair_nails`, `fitness`, `housing`, `events` home rails.
- Create `lib/mafundi/` shell + home rail.
- Update `tajirika_home_page` posting entry point.

**Exit criteria:** A carpenter can post a custom door, a buyer can order it from `lib/mafundi/`, and the order shows in the carpenter's `IncomingCustomerOrdersPage`.

### Phase 2 — Service Request + Garage + Appointment (2 weeks)

- B.1 `service_requests` schema + controller + routes.
- B.2 `garage_bookings` schema + controller + routes.
- B.3 `appointments` + `partner_availability` + `partner_blackouts` schema + controller + routes.
- Customer-orders UNION updated with three new sources.
- Source-specific Flutter pages.
- Slot picker widget (`lib/tajirika/widgets/slot_picker.dart`) used by appointments + B.7 later.

**Exit criteria:** A customer can request a plumber, drop a car at a garage, and book a hair appointment — all three appear in the partner's unified inbox.

### Phase 3 — Consultation + Engagement + Listing Inquiry + Event Booking (3 weeks)

- B.4 `consultations` schema + encryption layer.
- B.5 `engagements` + milestones + time entries.
- B.6 `property_listings` + `listing_inquiries`.
- B.7 `event_bookings` with deposit flow.
- Reviews table + UI.
- Cross-vertical search index.

**Exit criteria:** Lawyer can take a confidential consultation; accountant can run a multi-month engagement; real-estate agent can sell a property; DJ can be booked for a wedding with a deposit.

### Phase 4 — Polish (1 week)

- FCM templates per source + status.
- COA journal-line wiring per terminal transition.
- Performance: switch UNION to materialized view if any partner exceeds 1k rows in any source.
- Drop deprecation shims on old `/api/food/chef-products*` routes.

---

## Part E — Open decisions

These need product/engineering alignment before Phase 1 ships:

1. **One inbox or many?** Currently `IncomingCustomerOrdersPage` is one inbox for all sources. As sources multiply, partners with multiple skills could see overwhelming mixed feeds. Decide: (a) keep unified with stronger per-source filter chips, or (b) split into per-cluster inboxes (`lib/mafundi/incoming/`, `lib/events/incoming/`, etc.) and have the unified inbox aggregate.
2. **Rename vs. add `skill_category`?** This doc commits to rename. If the cost of touching shipped data is too high, fall back to Option 2 (A.1) and accept the misnomer.
3. **Open marketplace mode for service requests (B.1)?** If `partner_id IS NULL` at creation, multiple partners can quote — this is closer to Uber's bid model. If the customer pre-selects a partner, simpler 1:1. Decide the default before schema lock.
4. **Confidentiality scope (B.4)?** Field-level encryption (`Crypt`) or full row encryption? Field-level allows server-side filtering / reporting but exposes more metadata. Default proposal: field-level with strong indexed `partner_user_id` / `customer_user_id` / `status` / `starts_at` left in plaintext.
5. **Recurring appointments (B.3) — auto-generate child rows or compute on-the-fly?** Auto-generate makes the inbox simple but bloats the table on long-running plans. Computed-on-the-fly is the opposite. Default proposal: auto-generate child rows for the first 30 days, regenerate on a daily cron.
6. **Reviews (C.6) — public or two-way?** If two-way (partner also rates customer), it discourages no-shows but adds friction. Default proposal: one-way (customer rates partner) for v1; revisit after 90 days of usage data.

Decisions go in a follow-up `PARTNER_C2B_EXPANSION_DECISIONS.md` once aligned.
