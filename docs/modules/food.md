# Food — Home-cook marketplace, restaurants, surplus-food sharing, and charitable feeding (TAJIRI)

## Document status

This document is the **module spec** for Food: who it serves, what we want it to do, what is already shipped under `lib/food/`, and the product direction we've converged on after researching modern food-delivery apps, US/Indian home-chef marketplaces, African delivery players, India's surplus-food / "extra-food-today" ecosystem, and global surplus-to-charity networks that route food to orphans, community groups, and NGOs. It complements the backend directives and user-journey docs that will follow. It is **not** a single-PR checklist.

---

## Primary persona & user wants

**Persona (buyer):** Someone in Tanzania who wants a meal — from a restaurant, from a neighbourhood home cook, or from a neighbour with **extra food tonight**. They care about **price**, **distance**, **freshness**, **who made it**, and **how soon they can eat**.

**Persona (seller):** A home cook, caterer, or baker with `cooking` / `catering` / `baking` skills registered via the Tajirika partner flow. They want to **monetise what they already cook**, **fill seats** on slow days, **not waste today's leftovers**, and — when they can — **feed people who can't pay**.

**Persona (beneficiary coordinator):** Someone running an orphanage (kituo cha yatima), a community jumuiya, a mosque or church feeding programme, a women's kikundi, or a registered NGO. They want a **steady, predictable stream of donated meals**, **dignity for the people they feed**, a **verifiable receipt** of what came in (for reporting to trustees / donors / religious obligation tracking), and **zero overhead** — no spreadsheets, no WhatsApp chasing, no dead-ends.

**Persona (charitable donor):** A chef, a restaurant, a caterer who over-prepared for a wedding, or an individual buyer who wants to buy-and-donate rather than buy-and-eat. They want the donation to reach a **real, verified** beneficiary, a **record** they can show (for zaka / sadaka / fungu la kumi), and to do it in **one tap**.

| Want (buyer) | Target fulfillment | Codebase today |
|---|---|---|
| **Know who is cooking it** — real person, real kitchen, real reviews | Chef profile with photos, skills, rating, service area | `PartnerProfilePage` + `ChefCard` wired; uses `TajirikaPartner` model |
| **Trust** — verified NIDA + TIN (and professional licence where required) | Verification badge gated on `VerificationStatus.overallFor(...)` | Backend verification shipped; badge on partner profile |
| **Near me** — ward/district-scoped, not Dar-city-wide | Filter by `PartnerServiceArea.displayText` | Partner service-area model exists; not yet filtered client-side by the buyer's ward |
| **Buy today's extra** — "Nina Chakula Zaidi Leo" | Same-day pickup strip, 2–3-hour window, discounted | **Not shipped** — see proposed `ChefListing.mode == today_extra` |
| **Traditional restaurants** — Mikahawa ya Karibu | Restaurant list with menus and cart | `food_home_page`, `restaurant_page`, `menu_item_card`, `cart_page` shipped |
| **Swahili-first** | `AppStringsScope.of(context)` | Food module copy uses Swahili directly (hardcoded), not yet `AppStrings` |
| **Pay with what I have** — M-Pesa / Airtel Money / Tigo Pesa | Mobile-money checkout per-order | Payment surface exists via TAJIRI wallet; chef listings not yet wired |

| Want (seller) | Target fulfillment | Codebase today |
|---|---|---|
| **List what I plan to cook** | "Panga Menu Yangu" — scheduled listings (Cookr-style) | Not shipped |
| **Sell extras tonight** | "Nina Chakula Zaidi Leo" — one-tap quick post, 2–3-hour window | Not shipped |
| **Give away to a neighbour** | "Toa Bure" — ubuntu/OLIO-style free share to first-taker | Not shipped |
| **Give to an orphanage / jumuiya / NGO** | "Toa kwa Yatima / Jumuiya / NGO" — earmarked donation to a verified beneficiary | Not shipped |
| **Record zaka / sadaka / fungu la kumi** | Auto-receipt in the donor's giving log; feeds `zaka` and `fungu_la_kumi` modules | Not shipped |
| **Get paid** | Mobile-money payout to the partner's wallet | TAJIRI wallet exists; chef-listing settlement not wired |
| **Be discoverable** | Appear in `FoodChefsPage` + home "Wapishi wa Nyumbani" rail | **Shipped** — merged parallel fetch of cooking/catering/baking skills, deduped, rating-sorted |

| Want (beneficiary coordinator) | Target fulfillment | Codebase today |
|---|---|---|
| **Register my orphanage / jumuiya / NGO** | Onboarding with BRELA / social-welfare / jumuiya-registration verification | Not shipped |
| **Post a recurring need** | "Tunahitaji chakula cha watoto 20 kila Ijumaa" — standing order that chefs can fulfil | Not shipped |
| **Know what's coming today** | Dashboard of confirmed donations with ETA, portions, donor names | Not shipped |
| **Give donors a receipt** | Auto-issued PDF/in-app receipt per donation with org letterhead + running totals | Not shipped |
| **Not drown in admin** | One-screen monthly summary (portions, donors, value if priced) for trustee reports | Not shipped |

---

## Current shipped state (snapshot)

### Partner integration
- **`lib/food/widgets/chef_card.dart`** — Partner card shaped like `RestaurantCard`. Filters `chef.skills` down to the food-relevant subset (`cooking` / `catering` / `baking`), renders "Wazi" badge when `isActive`, falls back to "Mpya" when `aggregateRating == 0`, uses `CachedNetworkImage` with an initials fallback. Location pulls `chef.serviceArea.displayText`.
- **`lib/food/pages/food_chefs_page.dart`** — Dedicated chef list with client-side search (name / bio / service area). Exports `fetchFoodChefs()`:
  - Issues **three parallel** `TajirikaService.searchPartners` calls — one per food skill — because the backend `whereJsonContains` loop **ANDs** multi-skill filters.
  - Dedupes by `partner.id`, sorts by `aggregateRating` descending.
  - Token via `AuthService.instance.getValidAccessToken()`.
- **`lib/food/pages/food_home_page.dart`** — Added a third parallel fetch for `fetchFoodChefs()` and a "Wapishi wa Nyumbani" rail (top 5, compact card) between active orders and "Mikahawa ya Karibu". Rail is hidden when `_chefs.isEmpty`. Tapping a chef opens `PartnerProfilePage(partnerId: chef.id)`.

### Restaurants (pre-existing)
- `food_home_page.dart` / `restaurant_page.dart` / `cart_page.dart` / `food_orders_page.dart`
- `menu_item_card.dart` / `restaurant_card.dart` / `order_card.dart`
- `models/food_models.dart`, `services/food_service.dart`

### What's still missing
- No chef menu / listing model — tapping a chef goes to the generic partner profile, not a food-specific storefront.
- No buyer-side "today's extras" feed.
- No seller-side posting flow from the partner side of the app.
- No mobile-money settlement tied to a chef order.

---

## Research findings

### Modern food-delivery UX (global baseline)

What best-in-class apps (Uber Eats, DoorDash, Zomato, Swiggy) assume as **table stakes**:
- **Hierarchical home screen:** cuisines → nearby → promotions → past orders → personalised recs. Each scroll reveals the next layer.
- **Order tracking stepper:** `placed → accepted → preparing → picked up → delivered`, with ETAs at each step.
- **Reorder** from past orders (one-tap repeat).
- **Search** with typo-tolerance, cuisine filters, dietary filters.
- **Rating + photo reviews** per dish, not just per restaurant.
- **Loyalty / wallet** integration (Zomato Gold, DashPass equivalents).
- **AI personalisation** — "based on your last orders".

What **leaders** do that followers don't:
- Live courier map with real GPS
- Scheduled orders (order lunch the night before)
- Group orders / split bills
- Sub-cuisine taxonomy (not just "Indian" but "South Indian vegetarian Jain")
- Sustainability nudges (no cutlery by default, reusable packaging)

### Home-chef marketplace models (USA)

| App | Model | Relevant takeaway |
|---|---|---|
| **Shef** | Chef posts a **weekly menu**; buyer orders for scheduled delivery; Shef handles delivery + refrigerated packaging | Scheduled model works when chefs can batch-cook; batch economics beat on-demand |
| **WoodSpoon** | On-demand chef meals (NYC); chef cooks fresh per order; dispatch in 45 min | On-demand fresh is hard to scale; works only in dense urban cores |
| **DishDivvy** | Chef storefront (menu + hours); buyer uses DoorDash for fulfilment | **Marketplace-only** — they sidestep logistics by renting a third-party fleet |

**Lesson for TAJIRI:** Scheduled (Shef/DishDivvy) fits Tanzania better than on-demand (WoodSpoon). Home cooks in Dar es Salaam / Arusha can plan tomorrow's menu the night before; they can't always cook a single order in 45 minutes.

### African food-delivery context

- **Chowdeck (Nigeria):** Profitable unit economics using bicycle couriers in Lagos. Lesson: **lean fleet + dense routes** matter more than fancy UX.
- **Glovo (multi-country):** Super-app approach (food + groceries + errands). Lesson: bundling demand lowers courier idle time.
- **Jumia Food:** **Exited Africa in 2023** after failing to reach profitability. Lesson: pure restaurant aggregation without logistics ownership is fragile.

**Lesson for TAJIRI:** Do not try to own a delivery fleet on day one. Start **pickup-only** or **chef-delivers-own** so we don't burn runway on couriers. Add a courier layer only after demand is proven per ward.

### Indian home-chef & surplus-food ecosystem

**Home-chef apps (paid):**

| App | Pattern | Relevant takeaway |
|---|---|---|
| **Cookr** | Chefs set a **master menu** + flexible daily schedule | Best "menu + schedule" UX for scheduled sales |
| **Mealawe** | Chefs **post daily** by a cook-start cutoff; no buffet, one-meal focus | Daily-posting cadence fits the Tanzanian home cook |
| **HighRices** | Apartment-complex-scoped marketplace (seller = same building) | Ward/estate-scoping is the Tanzanian analogue |
| **Homeal** | Homely tiffins + one-off plates | Validates mixed "subscription + single-plate" |
| **Homefoodi** | FSSAI-inspected kitchens | Verification by a neutral party = trust multiplier |

**Surplus-food / giveaway apps:**

| App | Pattern | Relevant takeaway |
|---|---|---|
| **Too Good To Go (EU→world)** | "Surprise Bag" at **⅓ price**; pickup window 30–60 min at end of day | The canonical "extra food tonight" model — price anchored at ⅓, mystery bag reduces merchandising cost |
| **OLIO (UK→world)** | **Free** community food sharing; user-to-user giveaway | Ubuntu fit — "toa bure" culturally natural |
| **No Food Waste (India)** | Donation-logistics-as-a-service for excess food | Bulk catering surplus is a separate segment |
| **Feeding India / IFSA** | NGO distribution of surplus | Reminds us giveaways have both charitable and neighbourly modes |

### Surplus-to-charity networks (orphanages, shelters, NGOs)

These aren't consumer apps — they're matching layers between surplus food and the institutions that feed vulnerable people. They define the template for the charitable mode.

| Organisation | Model | Relevant takeaway |
|---|---|---|
| **Robin Hood Army (India, global)** | Volunteer "Robins" collect restaurant / wedding surplus and run it to slums, shelters, orphanages on a schedule | Scheduled, route-based runs with volunteer couriers — not on-demand. Works because beneficiaries are *fixed locations* |
| **Copia (US, now closed)** | Businesses log surplus in-app → Copia dispatches pickup → routes to nonprofits; tax-receipt auto-generated | **Auto-receipt** was the unlock — businesses donated more when the tax value was computed for them |
| **Replate (US)** | Similar to Copia — business-to-nonprofit food-rescue logistics | Same auto-receipt pattern; confirms it's a category feature, not one-company quirk |
| **Food Rescue US** | Volunteer app — anyone with a car can claim a pickup and drop at a shelter | Volunteer "claim-a-run" model; low-ops, scales sideways |
| **City Harvest (NYC)** | Truck fleet + warehouses; moves 100M+ lbs / year to soup kitchens | Fleet-heavy; only works at scale we should not aspire to for v1 |
| **Zakat Foundation / Islamic Relief** | Faith-anchored distribution; donors track zakat in an accountable ledger | The **ledger for religious giving obligation** is the durable primitive — zaka / fungu la kumi modules in TAJIRI should receive these records |

**Lesson for TAJIRI:**
- Auto-generated receipts are the feature that makes donors donate more. Ship them from day one.
- Volunteer claim-a-run (Food Rescue US) beats owned fleet (City Harvest) at our stage.
- Beneficiary organisations are **fixed locations with recurring needs** — this is very different from peer-to-peer OLIO. Design them as first-class entities, not users in disguise.
- Faith-based giving in Tanzania (zaka, sadaka, fungu la kumi) is *the* durable demand driver; a donation that plugs into those ledgers gets more repeat use than one that doesn't.

**Synthesis:** There are really four distinct seller intents — "I planned to cook this for sale" / "I have leftovers tonight at a discount" / "I want to give to a neighbour" / "I want to give to an orphanage / jumuiya / NGO" — which collapse into three listing modes by treating the two giveaway flavours as variants of one `giveaway` mode differentiated by a `recipient_type` field.

---

## Proposed architecture — three-mode listing taxonomy

One table, one list endpoint, one card shape. The mode flag drives pricing rules, expiry, and badge.

### `ChefListing` modes

| Mode | Swahili label | Pricing | Window | Visibility | Inspiration |
|---|---|---|---|---|---|
| `scheduled` | **Panga Menu Yangu** | Full price set by chef | Pickup/delivery on a future slot (today + N days) | Main chef list + chef storefront | Cookr, Shef |
| `today_extra` | **Nina Chakula Zaidi Leo** | Discounted (suggested ⅓–½ off) | Pickup in next **2–3 hours** | "Chakula cha Leo" same-day strip on food home | Too Good To Go |
| `giveaway` (community) | **Toa Bure** | Free | Pickup in next **2–3 hours** | Same-day strip, "Bure" badge | OLIO |
| `giveaway` (institutional) | **Toa kwa Yatima / Jumuiya / NGO** | Free (earmarked to an org) | Chef picks a beneficiary; org has 2–4h claim / pickup window | Org dashboard + donor's giving log; **not** on public strip | Robin Hood Army, Copia, Replate |

All four share the same buyer/recipient-side card; colour, badge, and call-to-action differ. The two giveaway variants share schema — they differ only in `recipient_type` and whether a `beneficiary_org_id` is attached.

### `ChefListing` data model (proposed)

```
chef_listings
├── id                  bigint
├── partner_id          bigint → tajirika_partners.id
├── title               string           // "Pilau ya nyama ya ng'ombe"
├── description         text?
├── photo_url           string?
├── mode                enum('scheduled','today_extra','giveaway')
├── recipient_type      enum('public','community','organisation')  // public: paid sales; community: OLIO-style; organisation: earmarked donation
├── beneficiary_org_id  bigint? → beneficiary_organisations.id    // set when recipient_type='organisation'
├── portions_total      int              // e.g. 6
├── portions_remaining  int              // decremented per order/claim
├── price_tzs           bigint?          // null when mode=giveaway
├── original_price_tzs  bigint?          // only for today_extra, shows strikethrough
├── pickup_window_start timestamptz
├── pickup_window_end   timestamptz
├── pickup_address      string           // ward + landmark
├── pickup_lat/long     decimal?
├── dietary_tags        jsonb            // ['halal','no_pork','vegetarian']
├── is_active           bool
├── created_at / updated_at
└── expires_at          timestamptz      // auto-hide past this
```

### `BeneficiaryOrganisation` data model (proposed)

A beneficiary is a first-class entity, not a regular user. This is the table that makes institutional giving trustworthy.

```
beneficiary_organisations
├── id                     bigint
├── name                   string           // "Kituo cha Watoto Yatima Bagamoyo"
├── type                   enum('orphanage','jumuiya','mosque','church','ngo','kikundi','school_feeding')
├── registration_number    string?          // BRELA / social welfare / NGO Board / jumuiya certificate
├── registration_authority enum('brela','social_welfare','ngo_board','tcra','faith_council','jumuiya_local')
├── registration_doc_url   string?          // uploaded certificate
├── contact_user_id        bigint → users.id   // the coordinator running the account
├── contact_phone          string
├── service_area           jsonb            // region / district / ward
├── address                string
├── lat / lng              decimal?
├── population_served      int?             // "we feed ~20 children"
├── recurring_schedule     jsonb?           // cron-ish: {days:['mon','fri'], portions:20, meal:'lunch'}
├── verification_status    enum('pending','verified','rejected')
├── verified_at            timestamptz?
├── verified_by            bigint?          // admin user id (verification is backend-only)
├── is_active              bool
└── created_at / updated_at
```

```
donation_receipts
├── id                     bigint
├── listing_id             bigint → chef_listings.id
├── donor_partner_id       bigint → tajirika_partners.id
├── donor_user_id          bigint → users.id        // the human receiving the receipt
├── beneficiary_org_id     bigint → beneficiary_organisations.id
├── portions               int
├── imputed_value_tzs      bigint?                  // optional "what this would have sold for"
├── zaka_tagged            bool                     // donor marked this as zakat
├── fungu_la_kumi_tagged   bool                     // donor marked this as tithe
├── delivered_at           timestamptz?             // when org confirmed receipt
├── receipt_pdf_url        string?
└── created_at
```

### Order lifecycle

`reserved → paid → ready_for_pickup → picked_up → complete`

- `giveaway` with `recipient_type=community` skips `paid`.
- `giveaway` with `recipient_type=organisation` skips `paid` and auto-claims on behalf of the targeted org; it also emits a `donation_receipts` row at `picked_up` (or `delivered`, if a runner is involved).
- `today_extra` collapses to `reserved → picked_up → complete` when the cook marks it handed over.
- Cancellation by buyer within 30 min frees the portion back.

### Endpoints (to spec in backend directive)

**Listings**
- `GET /api/food/chef-listings?mode=&ward=&lat=&lng=&radius=&recipient_type=` — paginated, includes partner summary.
- `GET /api/food/chef-listings/{id}` — detail for buyer / recipient.
- `POST /api/food/chef-listings` — seller creates; mode + recipient_type drive validation.
- `POST /api/food/chef-listings/{id}/reserve` — buyer reserves portions.
- `POST /api/food/chef-listings/{id}/cancel` — buyer cancels within window.
- `POST /api/food/chef-listings/{id}/mark-picked-up` — seller confirms handover.

**Beneficiary organisations**
- `GET /api/food/beneficiary-orgs?type=&ward=&q=` — search verified beneficiaries (powers the chef's "donate to" picker).
- `GET /api/food/beneficiary-orgs/{id}` — public org profile (name, type, population served, recurring schedule).
- `POST /api/food/beneficiary-orgs/register` — coordinator submits org details + registration doc. Goes to `pending`; admin review is **backend-only** per `feedback_admin_actions_are_backend_only`.
- `POST /api/food/beneficiary-orgs/{id}/needs` — coordinator posts a recurring or one-off need ("Tunahitaji chakula cha watoto 20 kila Ijumaa").
- `GET /api/food/beneficiary-orgs/{id}/incoming` — dashboard of confirmed + pending donations (coordinator-gated).
- `POST /api/food/beneficiary-orgs/{id}/confirm-receipt/{listing_id}` — coordinator marks donation delivered; triggers receipt PDF.

**Donor giving log**
- `GET /api/food/donations/mine` — donor's giving history, filterable by `zaka_tagged` / `fungu_la_kumi_tagged`.
- `GET /api/food/donations/{id}/receipt.pdf` — receipt download.

**Needs feed (for chefs considering who to donate to)**
- `GET /api/food/beneficiary-needs?ward=&type=&when=` — list of active needs chefs can browse when they have a surplus.

---

## Seller flows (partner side)

Four entry points surface wherever the partner manages their offerings (Tajirika partner page once it includes a food section, or the food module if we let chefs in as sellers directly). All four reuse one form widget with mode-conditional fields.

1. **Panga Menu Yangu** — chef picks future date(s), sets price, portions, description. Multi-slot.
2. **Nina Chakula Zaidi Leo** — single-tap flow. Photo + title + portions + price. Window auto-suggests "next 3 hours". Intentionally under 45 seconds to complete.
3. **Toa Bure (jirani)** — same as `today_extra` but no price field. "Bure" badge. Optional "first come first served" vs "reply and I'll pick". Published to the public same-day strip.
4. **Toa kwa Yatima / Jumuiya / NGO** — same photo/portions inputs, but chef picks a **verified beneficiary** from a searchable list (filterable by ward, by type: orphanage / jumuiya / mosque / church / NGO / kikundi / school feeding). Optional toggles: *"Tag this as zakat"*, *"Tag this as fungu la kumi"*. On submit:
   - A `chef_listings` row is created with `mode=giveaway`, `recipient_type=organisation`, `beneficiary_org_id=<chosen>`.
   - The beneficiary coordinator gets a push notification ("Amina amechangia sahani 6 za pilau — zichukue kabla ya saa 12:00").
   - A `donation_receipts` row is pre-created in `pending` state; it activates at `picked_up`.
   - The donation is **not** put on the public same-day strip; it's routed privately.

**"Browse needs" adjunct flow** — from any of the above screens, the chef can tap "Kuna mahitaji gani?" to see active `beneficiary_needs` in their ward before deciding what to cook / donate. This turns surplus-donation into need-driven donation.

---

## Buyer surfaces

- **`FoodHomePage`**
  - **Active orders** — existing.
  - **Wapishi wa Nyumbani** — shipped. Top 5 chefs, rating-sorted.
  - **Chakula cha Leo** *(new)* — horizontal strip of `today_extra` + `giveaway (community)` listings expiring in the next few hours, sorted by window end time ascending. "Bure" items get a green badge. Organisational donations are **not** on this strip — they're routed privately.
  - **Saidia Sasa** *(new, optional rail)* — small rail showing open `beneficiary_needs` in the buyer's ward, with a "Changia" CTA that takes them into the donor flow. Think of it as the "ubuntu prompt" on the food home page.
  - **Mikahawa ya Karibu** — existing restaurants.
- **`FoodChefsPage`** — shipped. Add tab / filter for "Menus za Leo" vs "Wapishi wote".
- **Chef storefront** *(new)* — opens from `ChefCard`. Shows the chef's `scheduled` listings grouped by day, their `today_extra` / `giveaway (community)` items, and their bio/reviews. Donation history (aggregate count + total portions given) surfaces as a trust signal. This replaces the current navigation into the generic `PartnerProfilePage` for food skills.
- **Listing detail** *(new)* — full photo, description, chef strip, pickup window, reserve/claim button, map pin.

### Beneficiary & donor surfaces

- **Beneficiary dashboard** *(new)* — only visible to coordinators of a verified `beneficiary_organisation`. Shows today's confirmed incoming donations (donor name, portions, ETA), a button to confirm receipt (which triggers the receipt PDF), the org's recurring needs, and a 30-day summary (portions received, unique donors, imputed value).
- **Beneficiary public profile** *(new)* — org name, type, ward, population served, recurring schedule, running total of portions received. Opened from a chef's "Toa kwa ..." picker so the chef sees *who* they're donating to before confirming.
- **Donor giving log** *(new)* — per-user history of donations, filterable by zaka / fungu la kumi tags. One-tap "download receipts" for the year. Feeds the TAJIRI `zaka` and `fungu_la_kumi` modules rather than duplicating them.
- **Beneficiary registration screen** *(new)* — coordinator flow: org name, type, ward, BRELA / social-welfare / jumuiya-council registration number, upload registration certificate, contact phone. Submits to `pending`; **verification happens backend-only** per `feedback_admin_actions_are_backend_only`.

---

## Why this works for Tanzania

- **Mobile-money native.** Settlement into the partner's TAJIRI wallet via M-Pesa / Airtel / Tigo Pesa. No card infrastructure needed.
- **Ward-scoped.** `PartnerServiceArea.displayText` already anchors to ward / district / region — the scarce-trust primitive (HighRices lesson) is already in the data.
- **No fleet required.** Pickup-only v1 dodges the Jumia Food failure. Chef-delivers-own is the v2 layer; aggregator courier is v3 only after proof.
- **Ubuntu giveaway mode.** "Toa Bure" is culturally natural in a way Too Good To Go's commercial-only framing isn't.
- **Verified chefs.** NIDA + TIN gating (already shipped server-side) gives a verification floor no unregulated neighbour-group can match.
- **Latent supply.** Home cooks, caterers, and bakers already registered as Tajirika partners are the supply side — they just need a front door.
- **Faith-anchored giving demand.** Tanzania's giving calendar is religious: **zaka** and **sadaka** during Ramadan (iftar feeding at mosques, end-of-Ramadan zakat-ul-fitr), **fungu la kumi** and church feeding programmes year-round, Christmas and Easter mass feeding events. Donors already *want* to give food; today they do it via WhatsApp groups, cash to jumuiya leaders, or turning up in person. A one-tap, verified, auto-receipted pipeline is an obvious upgrade.
- **Orphanages and jumuiya are real fixed locations with chronic need.** Unlike peer-to-peer OLIO where supply and demand randomly meet, beneficiary organisations are **predictable demand**. Chefs who want to give but don't know where to give gain an answer. The unit economics of matching are far better than peer-to-peer.
- **Verification leverages existing rails.** BRELA (business registration), the Social Welfare Department (orphanages), the NGO Board (NGOs), and parish / mosque councils (jumuiya) all issue verifiable certificates. The backend already handles verification gating for partners — extending it to organisations reuses the pattern, including the hard rule that *admin review happens server-side, not in the Flutter app*.
- **Cross-module reinforcement.** Every donation logged here becomes a row the `zaka` and `fungu_la_kumi` modules can display, turning food-giving into something the user is *already* tracking religiously. Donations can originate from a `michango` campaign ("feed the orphanage for a month"). Jumuiya groups can publish needs via the same rails they already use in `jumuiya.md`. None of this requires the food module to reinvent those surfaces.

---

## Cross-module integrations

The charitable side of the food module only works if it plugs into what the rest of TAJIRI already does. Integration points:

- **`zaka` module.** When a donor ticks *"Tag this as zakat"* on a donation, the `donation_receipts` row is surfaced in the zaka module's running ledger — the donor can see cumulative zakat for the year, filter by category, and export. The food module is a **source**, the zaka module is the **ledger**.
- **`fungu_la_kumi` module.** Same pattern for Christian tithing — donated food's imputed value counts against the tithe running total if the donor tags it.
- **`michango` / campaigns.** A beneficiary organisation can run a michango campaign ("Help us feed 50 children for Ramadan") where donors either pledge money *or* pledge meals. Meal pledges land as `chef_listings` with `beneficiary_org_id` auto-set to the campaign org.
- **`jumuiya` module.** A jumuiya with an active jumuiya profile can be a beneficiary organisation (auto-eligible once its jumuiya leader is identified). Needs posted via the jumuiya module surface in the food module's need feed.
- **`kanisa_langu` / `tafuta_msikiti` / `tafuta_kanisa`.** Any registered mosque or church can be a beneficiary organisation. The existing registry pages link to a donation CTA ("Changia chakula"). Ramadan and Christmas feeding programmes become first-class events on the org profile.
- **`my_faith`, `sala`, `ramadan`.** During Ramadan, surface a contextual prompt on the `ramadan` module: "Mosques near you need iftar donations tonight" → links into the `Toa kwa Msikiti` flow.
- **`events`.** Mass feeding events (church Christmas lunch, mosque iftar, orphanage anniversary) can be surfaced on the events feed with a food-donation CTA.
- **TAJIRI wallet.** Donation imputed values are posted to the donor's giving log, not their accounting — but if the donor is a registered business (Tajirika partner with TIN), the imputed value can optionally flow into their books as a CSR expense per `feedback_coa_source_of_truth`.

---

## Implementation roadmap

Ordered smallest-wedge first.

1. **Seller quick-post for `today_extra`** (smallest wedge)
   - Backend: `chef_listings` table + the three `today_extra`-scoped endpoints.
   - Frontend: single-page form in under 45s. Settles into wallet on reserve.
   - Buyer: "Chakula cha Leo" strip on food home page. No storefront yet.
   - **Exit criteria:** at least one chef posts extras in a week; at least one buyer reserves.

2. **`giveaway (community)` mode on same plumbing**
   - One flag (`recipient_type=community`), no new endpoints. "Bure" badge. No settlement path.

3. **Beneficiary organisations + institutional giveaway**
   - Backend: `beneficiary_organisations` + `donation_receipts` tables, registration endpoint (pending → verified via **backend-only** admin review), needs feed, coordinator dashboard endpoints.
   - Frontend (seller): "Toa kwa Yatima / Jumuiya / NGO" flow with searchable beneficiary picker. Zakat / fungu la kumi toggles.
   - Frontend (coordinator): registration screen, dashboard, confirm-receipt button, auto-generated receipt PDF.
   - Cross-module: wire `zaka` and `fungu_la_kumi` to consume `donation_receipts`.
   - **Exit criteria:** one verified orphanage or jumuiya, one chef donation, one auto-receipt, one zakat/fungu-la-kumi log entry.

4. **Chef storefront + `scheduled` mode**
   - New storefront page replaces `PartnerProfilePage` when partner has food skills.
   - Scheduled listings grouped by day.
   - Reorder + favourites on this surface.
   - Storefront shows the chef's donation history as a trust signal.

5. **Recurring beneficiary needs + matching**
   - Coordinator posts recurring needs ("tunafeed watoto 20 kila Ijumaa").
   - Chef's "Browse needs" adjunct flow + optional push to chefs in the beneficiary's ward on a matching schedule.
   - Michango campaign integration (meal-pledge mode).

6. **Delivery layer (chef-delivers-own)**
   - Optional `delivery_fee_tzs` + `delivery_radius_km` on a listing.
   - Chef marks `out_for_delivery`; buyer / beneficiary gets a status stepper.
   - Applies to paid sales *and* institutional donations (chef-to-orphanage drop-off).

7. **Volunteer "runner" pool for donations**
   - Food Rescue US pattern — a verified user can claim a pending donation run and drop it at the beneficiary.
   - Only enables where no chef delivery and no coordinator pickup.

8. **Aggregator courier (v3, only if unit economics prove)**
   - Opt-in courier pool. Mimic Chowdeck's lean bicycle model; avoid Jumia Food's fixed-cost fleet.

9. **Scheduled orders + subscriptions (tiffin-style)**
   - Weekly plan from Homeal/Homefoodi.
   - Lower priority — requires solid scheduled volume first.

---

## Gaps vs modern apps (known, deferred)

We will ship without these, in this order of eventual need:
- **Order-tracking stepper with ETAs** — ship after delivery layer exists.
- **Dish-level reviews** (not partner-level) — ship after scheduled mode.
- **Reorder** — trivial once past orders carry listing refs.
- **AI personalisation / "for you"** — not before real scale.
- **Search with typo-tolerance & cuisine filters** — add with scheduled mode.
- **Loyalty / wallet perks** — fold into TAJIRI wallet later.
- **Group orders / split bills** — long tail.

---

## Design system notes

- Monochromatic per `docs/DESIGN.md`: `#1A1A1A` primary, `#FAFAFA` background, `#4CAF50` accent already used in `ChefCard`.
- All copy must route through `AppStringsScope.of(context)` — the food module currently has hardcoded Swahili strings; this needs an `AppStrings` pass before scaling.
- 48dp touch targets; `maxLines` + `TextOverflow.ellipsis` on every dynamic string; `_rounded` icon variants only.
- SafeArea mandatory on every page.

---

## Sources

**Modern food-delivery UX**
- [Uber Eats product features](https://www.uber.com/us/en/eat/)
- [DoorDash product overview](https://www.doordash.com/)
- [Zomato product pages](https://www.zomato.com/)
- [Swiggy Genie / Swiggy One (super-app moves)](https://www.swiggy.com/)

**Home-chef marketplaces**
- [Shef — weekly menu model](https://shef.com/)
- [WoodSpoon — on-demand chef meals](https://woodspoon.com/)
- [DishDivvy — chef storefront + DoorDash fulfilment](https://dishdivvy.com/)

**African food delivery**
- [Chowdeck — Lagos unit economics coverage (TechCabal)](https://techcabal.com/)
- [Glovo — multi-country super-app](https://glovoapp.com/)
- [Jumia Food — Africa exit (Reuters, 2023)](https://www.reuters.com/)

**Indian home-chef apps**
- [Cookr — master menu + flexible schedule](https://cookr.in/)
- [Mealawe — daily-posting cadence](https://www.mealawe.com/)
- [HighRices — apartment-complex scoping](https://www.highrices.com/)
- [Homeal / Homefoodi — tiffin + one-off plates, FSSAI-verified kitchens](https://homefoodi.com/)

**Surplus-food apps**
- [Too Good To Go — Surprise Bag at ⅓ price](https://www.toogoodtogo.com/)
- [OLIO — free community food sharing](https://olioapp.com/)
- [No Food Waste (India)](https://www.nofoodwaste.org/)
- [Feeding India by Zomato](https://www.feedingindia.org/)
- [Indian Food Sharing Alliance (IFSA)](https://www.ifsaindia.org/)

**Surplus-to-charity networks (orphanages, shelters, NGOs)**
- [Robin Hood Army — volunteer "Robins" run surplus to shelters](https://robinhoodarmy.com/)
- [Copia — business surplus → nonprofit matching with tax-receipt auto-generation](https://www.gocopia.com/)
- [Replate — business-to-nonprofit food rescue with auto-receipts](https://www.re-plate.org/)
- [Food Rescue US — volunteer claim-a-run food rescue](https://foodrescue.us/)
- [City Harvest (NYC) — trucks + warehouses at scale](https://www.cityharvest.org/)
- [Zakat Foundation of America — faith-anchored charitable ledger](https://www.zakat.org/)
- [Islamic Relief — global zakat distribution](https://islamic-relief.org/)

**Tanzania charitable-giving context**
- [Tanzania Social Action Fund (TASAF)](http://www.tasaf.go.tz/)
- [Tanzania Department of Social Welfare — orphanage registration](https://www.mcdgc.go.tz/)
- [NGO Board of Tanzania — NGO registration](https://www.ngotanzania.go.tz/)
- [BRELA — business registration for caterers and food businesses](https://www.brela.go.tz/)
