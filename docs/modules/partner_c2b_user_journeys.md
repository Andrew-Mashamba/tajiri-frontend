# Partner C2B Expansion — Complete User Journeys

**Module:** lib/tajirika/ (all partner management) + per-vertical feature modules (all customer-facing browse/book/order) + lib/customer_orders/ (unified inbox)
**Source spec:** docs/PARTNER_C2B_EXPANSION_PLAN.md
**Audit date:** 2026-04-26

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget, wallet), and **Insightful** (reports, trends, recommendations).

This document covers all nine `customer_orders` sources after Part A generalization (`partner_product`) and Part B siblings (`service_request`, `garage_booking`, `appointment`, `consultation`, `engagement`, `listing_inquiry`, `event_booking`), plus cross-cutting flows for availability and reviews.

## Module-split rule (per `feedback_food_vs_tajirika_split`)

| Side | Lives in | Owns |
|---|---|---|
| **Partner management** (post, list, accept, quote, status updates, inbox, availability, analytics) | `lib/tajirika/pages/*` | All partner-side pages regardless of skill cluster |
| **Customer browse + book/order** (rails, detail page, booking sheet, status timeline, rating) | `lib/<vertical>/pages/*` (food, mafundi, service_garage, hair_nails, fitness, legal_gpt, doctor, business, housing, events, travel) | All consumer-side pages |
| **Unified order inbox** (cross-source partner inbox) | `lib/customer_orders/` | Shared dispatcher; opens source-specific detail pages in `lib/tajirika/pages/` |

The detail page a buyer sees and the detail page a partner sees are separate pages even when they describe the same row. Buyers never enter `lib/tajirika/`; partners never enter a vertical's customer pages.

---

## Foundational patterns (research-driven, cross-cluster)

These patterns apply to every feature below. They are written once here and referenced by feature sections rather than re-listed under each. Source apps cited inline so engineers can copy proven UX rather than reinvent.

### A. Trust & verification (applied to all partner skills)

- **Tiered partner badges, public on profile:** "Partner Mpya / New" → "Mhakikiwa / Verified" → "Mteule / Top Pro" → "Mtaalamu / Elite". Tier driven by composite score: response-time + completion-rate + rating + recency. Visible on every card, drives ranking. *Pattern: Thumbtack Top Pro, TaskRabbit Elite, Angi Certified, Airbnb Superhost.*
- **NIDA + selfie KYC at registration:** Government ID matched to live selfie via on-device camera. Real legal name shown on profile (no anonymous handles, no logos as photo). *Pattern: Urban Company India Aadhaar, TaskRabbit, Handy.*
- **Skill-specific license verification with expiry tracking:**
  - Food: TFDA / TBS hygiene certificate + ward-office permit; cross-checked against business name. *Pattern: Swiggy/Zomato FSSAI verification.*
  - Mafundi/auto: trade certificate or VETA training cert if available; insurance proof for in-home work. *Pattern: Angi license verification.*
  - Doctor: Medical Council of Tanganyika registration number, real-time check; specialty board if applicable. *Pattern: Practo, Vezeeta.*
  - Lawyer: Tanganyika Law Society admission lookup; conflict-of-interest module. *Pattern: Avvo bar lookup.*
  - Housing: BRELA business registration for agents; agent-only listings (no FSBO). *Pattern: Property24 agent-only.*
  - Travel: TALA license (Tanzania Tourist Agents Licensing Authority) badge mandatory for safari/tour. *Pattern: SafariBookings.*
  - Insurance display where applicable, expiry-tracked with renewal reminder push at T-30d, T-7d, T-1d.
- **Reuse existing TAJIRI profile data on partner activation:** Identity (name, NIDA, phone, email), profile photo, and address are already captured during normal user signup — never re-asked. The "Become a Partner" flow only collects what's truly skill-specific (license number where law requires it, M-Pesa payout number if not already on file, ward of operation). Verification badge displays after the legal artifact is submitted; partners can list immediately and badge upgrades asynchronously. *Pattern: Uber driver onboarding reuses rider profile; Honeybook reuses Google account.*
- **Photo consent toggle for portfolio:** Customers opt in per appointment whether before/after photos may be used publicly; defaults to private. *Pattern: GlossGenius — critical in conservative markets.*
- **Screenshot blocking on sensitive screens:** `FLAG_SECURE` on prescription, NDA-gated chat, ID upload screens. *Pattern: Practo, Doctolib.*
- **Insurance-backed property/safety guarantee with claim flow:** Documented coverage cap (e.g. up to TZS 5M for property damage on in-home jobs); marketed prominently as a trust signal. *Pattern: Handy Happiness Guarantee, Airtasker AUD 10k Marsh insurance.*

### B. Discovery & ranking (applied to every customer-facing rail and search)

- **Composite ranking algorithm with published factor weights** so partners can self-improve. Factors: profile completeness, response-time score, completion-rate score, recency, review weighting (last 6–12 months > lifetime), distance, price competitiveness, conversion rate. *Pattern: Thumbtack publishes factors, Uber Eats weights ~90% partner-influenceable + ~10% paid promo.*
- **Hard filters for safety, soft filters for preference.** Halal / vegan / no-pork / gluten-free / hair-texture (1A–4C) / language / NHIF-accepted = HARD. "Halal" never reverse-expands to non-halal. Price range / distance / rating = soft. *Pattern: Uber Eats query understanding, StyleSeat hair-type taxonomy, Zocdoc insurance-first filter.*
- **List-first over map-first on slow connections.** Map view is a secondary tab on mobile. *Pattern: Property24, Lamudi for emerging markets.*
- **WhatsApp deep-link as primary contact CTA** alongside in-app chat for high-touch listings (real estate, events, multi-day travel). *Pattern: Lamudi, PropertyPro, Jumia Travel — essential in Tanzania referral culture.*
- **Photo-count gating to suppress stock-photo scams:** listings with <4 original photos are deprioritized; AI image-similarity check against public stock libraries. *Pattern: Lamudi.*
- **Saved-search push notification within minutes of new match.** *Pattern: 99acres, Zillow.*
- **Response-time score on every partner card** ("Hujibu ndani ya saa 2 / Responds in ~2h"). Median across last 30 days, weighted into ranking. *Pattern: Fiverr, Thumbtack, Vezeeta.*
- **Waiting-time badge** for clinic-style services (queue position estimate). *Pattern: Vezeeta — high-trust signal in markets with notorious queues.*

### C. Notifications & lifecycle (applied across every source)

- **SMS + WhatsApp fallback for every push notification.** Critical for Tanzania connectivity gaps and non-app contacts. Reply YES/NO accepted on confirmation SMS; silent or NO triggers waitlist promotion. *Pattern: Doctolib SMS-first, Booksy two-way SMS.*
- **30-second partner-side accept window with auto-reassign.** Decline and timeout treated identically; offer reassigns to next-nearest partner. *Pattern: Uber Eats, DoorDash.*
- **Auto-pause partner after 3 consecutive misses or declines.** Manual unpause required. *Pattern: DoorDash dash auto-pause.*
- **Lead-expiring countdown push to partner** ("Quote expires in 30 min — 3 other partners have responded"). Drives faster bidding. *Pattern: Thumbtack, Bark.*
- **Live ETA narrowing as slot approaches.** "On the way" geofence-triggered → "Arriving in 10 min" → "Arrived". Map view with marker rotation + interpolation; queue-and-burst on reconnect for 3G. *Pattern: Urban Company, Swiggy rider tracking, RepairSmith.*
- **Quote-revised-approval-needed push** blocks work until customer taps "Approve". *Pattern: YourMechanic post-diagnosis re-quote.*
- **Rebook prompt at recommended cadence per service** ("Mara yako ya mwisho ya kunyoa ilikuwa wiki 6 zilizopita / Your last cut was 6 weeks ago — book again?"). Cadence configurable per partner. *Pattern: Booksy, StyleSeat.*
- **Photo-proof of delivery + handoff PIN** (4-digit code customer reads to courier). Tanzania-fit because street numbering is patchy. *Pattern: industry standard for food delivery; PIN borrowed from Glovo/Bolt Food.*
- **Pre-call tech check** (mic/camera/bandwidth) at the booking page hours before video consult. *Pattern: Doctor on Demand.*
- **Post-visit care plan / job summary delivered within 1 hour.** *Pattern: Babylon Health, Maven Clinic.*
- **Notification cap per module per day:** max 2–3 push per partner per day; all lower-priority items as in-app cards.

### D. Pricing & payouts (applied to all money flows)

- **Tiered SKUs at three price points** for any skill that supports it: text/async chat (cheapest) → video (mid) → in-person (full). Same partner, three productized offerings. *Pattern: Practo three-tier consult, K Health monthly subscription, LegalZoom flat-fee menus.*
- **Productized fixed-fee menus** wherever possible to remove price-discovery friction (e.g. "Will TZS 80,000", "Lease review TZS 60,000", "AC service TZS 35,000"). *Pattern: LegalZoom, Urban Company SKU catalog.*
- **Layered fees disclosed line-by-line:** service price + delivery + platform fee + tip + tax. Opacity is the single biggest review-kill driver. *Pattern: Uber Eats, Urban Company invoice.*
- **Diagnostic fee credited toward repair** (e.g. TZS 15,000 site visit credited if customer proceeds). *Pattern: RepairPal Certified, AAMCO.*
- **No-fix no-fee** as a marketed trust line for diagnosis-only flows. *Pattern: YourMechanic.*
- **Surge / urgency / weekend premiums labeled explicitly,** never hidden. Same-day or after-hours bookings priced higher with the surcharge as its own line. *Pattern: Handy, Urban Company "express".*
- **Daily M-Pesa payout** instead of weekly/biweekly = competitive moat in Tanzania. Talabat T+45 then bi-weekly is global norm; daily wins partners. Frame as "Pesa zako, leo / Your money, today" in onboarding.
- **Escrow with auto-release** on customer "complete" tap or 24–48h after partner-marked "complete" if customer doesn't dispute. Reduces dispute volume. *Pattern: Airtasker escrow, Upwork milestones.*
- **Tip after delivery up to 30 days post-service.** Default suggested 5–10% in TZS bands; "Tip later" option always present. *Pattern: DoorDash NYC test — better tips, less coercion.*
- **Subscription fee-waiver model (Tajirika+):** flat monthly TZS removes per-order delivery/booking fee on eligible partners; M-Pesa standing-order fit. *Pattern: DashPass.*
- **Lead-credit alternative for low-margin verticals** (consulting, legal): partners pay credits to unlock leads. *Pattern: Bark.com.*

### E. Communication (every source has a chat thread)

- **In-app chat with structured quote attachment.** Partner sends a line-itemized quote inside the thread; customer accepts in-thread (one tap creates the order). *Pattern: Thumbtack, Airtasker.*
- **Quote / message templates** ("Karibu / Welcome", "Diagnostic complete", "Work started", "Awaiting parts"). Reduces partner response time, raises booking conversion. *Pattern: Thumbtack Pro app.*
- **Voice notes + photo replies** (faster than typing on the road; Swahili oral preference). *Pattern: Airtasker, Urban Company partner app.*
- **Masked phone numbers** routed through platform numbers — no leaked direct lines on either side. *Pattern: TaskRabbit, Urban Company.*
- **Privilege flag persistent** on legal threads: UI label "Mawasiliano ya Wakili-Mteja / Attorney-Client Privileged Communication" never disappears. *Pattern: Avvo, Lexoo.*
- **Auto status-pings** on every state transition (`accepted` / `on the way` / `arrived` / `diagnosis complete` / `awaiting your approval` / `work started` / `work complete`). *Pattern: RepairSmith, Wrench.*

### F. Disputes & refunds (applied to every order)

- **In-app dispute opener with structured reasons** dropdown (no-show / poor quality / damaged property / overcharged / wrong item) + mandatory photo evidence upload. *Pattern: Airtasker, Handy, Urban Company.*
- **Tiered escalation:** Step 1 customer↔partner chat (24h to resolve) → Step 2 platform mediator → Step 3 insurance claim. *Pattern: TaskRabbit, Handy.*
- **Partner counter-evidence window of 24–48h** with their photos + chat log before platform decides. *Pattern: Airtasker, TaskRabbit.*
- **Self-report window of 3 days** post-completion for missing/incorrect items; prevents indefinite refund liability. *Pattern: Instacart, Uber Eats.*
- **Auto-credit on detected partner error** without forcing customer to fight; cost is later deducted from partner's payout via error-rate fee. *Pattern: DoorDash.*
- **Redo-work warranty window** (30-day service warranty on mafundi/auto, 7-day for cleaning, 1-week on Handy). *Pattern: Urban Company 30-day warranty.*
- **AI image-fraud detection on refund photos** (forged "raw meat" / "damaged" claims). Pilot once volume justifies. *Pattern: Truthscan, Radar.*
- **<3-minute live-chat support SLA** as differentiator vs. existing local apps that respond in days. *Pattern: Zomato chat SLA.*

### G. Recurring & retention (applied to every repeat-able service)

- **"Save my partner" / favorite** with one-tap rebook; partner gets priority on that customer's future leads. *Pattern: Urban Company, Handy, TaskRabbit.*
- **Recurring schedule with same partner** (weekly cleans, monthly AC service, biweekly hair). Auto-rebook with opt-out per occurrence. *Pattern: Handy weekly cleans, Booksy daily/weekly/biweekly cadences.*
- **Annual maintenance contract (AMC)** for AC, water purifier, generator, vehicle: prepaid yearly bundle of 2–4 visits at discount + priority booking. *Pattern: Urban Company AMC, Angi Key.*
- **Service-due dashboard** in Tajirika home for the customer side: visual list of upcoming services with due dates and est. costs (AC service, car oil change, hair refresh). *Pattern: CarAdvise MyCar, RepairPal.*
- **Parts/service warranty tracking** on the job ticket (12mo / 12k mi); one-tap warranty claim if part fails. *Pattern: RepairSmith.*
- **Rebook nudge at recommended cadence** (covered in §C — pairs with this).
- **Loyalty stamps** with progress bar (1–15 stamps configurable, expiry optional) + **prepaid packages** (5-session bundles redeemable per session). *Pattern: Booksy, Vagaro, StyleSeat.*

### H. Partner-side dashboard (applies to all partners regardless of skill)

- **Pause / busy-mode toggle** without de-listing — "Busy" extends ETA, "Closed" hides listing. *Pattern: Talabat partner tablet.*
- **Stock toggle per item** for instant in/out-of-stock. *Pattern: Swiggy/Zomato dish toggle.*
- **Unified queue across all order sources** in `lib/customer_orders/` (kitchens fail when channels are split). One ordered queue with priority logic.
- **Prep-time / response-time accuracy score** visible to partner as a coaching signal (declared vs actual delta). Honest over-quoting beats short-and-miss. *Pattern: Swiggy ranking penalty for short-and-miss.*
- **Bio-link / "Book with me" share** — universal short link or Instagram-bio button auto-generated for the partner. *Pattern: GlossGenius, Booksy, Setmore.*
- **Auto-watermarked portfolio cross-post** to feed/community with partner tag and "Book here" CTA. *Pattern: GlossGenius.*
- **Business analytics:** revenue by source, retention cohorts, no-show rate, top services, average ticket, response-time delta. *Pattern: Fresha, Vagaro, Booksy.*
- **Tip pooling + commission tier configuration** for partners with staff (e.g. salon owner). *Pattern: Vagaro tiered commissions.*

### I. Onboarding & growth

- **Short partner onboarding — reuse, don't re-ask.** Activation flow is 3 screens max:
  1. **Pick skill(s)** — chip multi-select from `SkillCategory` enum. Identity (name, NIDA, phone, email, address, profile photo) is already on file from TAJIRI signup; show as a read-only summary card with an "Edit on Profile" link, never a re-entry form.
  2. **Skill-specific add-ons** — only what the law/cluster genuinely needs (food: TFDA cert photo upload; doctor/lawyer: license number; tour: TALA number; mafundi/hair/home-cook: nothing — go straight to step 3). Optional "Add later" for non-blocking items.
  3. **Payout & ward** — auto-prefill M-Pesa number from `users.phone` (editable), select ward of operation from a list filtered by `users.region`. Done.
- Partner can publish a listing **immediately** after step 3. Verification badge upgrades asynchronously when the legal artifact (where required) is reviewed. No quizzes, no skill tests, no waiting room.
- **AI hiring-brief generator** for customer side: one-line goal → AI drafts the structured job post / event brief. *Pattern: Upwork.*
- **Profile completeness nudge** (not a gate) — partner home shows a single progress chip "Profaili: 70% / Profile: 70%" tapping which lists optional fields (bio, sample photos, hours) that boost ranking score. Partner is never blocked from accepting orders if completeness is low. *Pattern: LinkedIn profile strength.*

---

## 1. PARTNER POSTING — PARTNER PRODUCTS

**Entry:** Tajirika Home → "Post Bidhaa" / "Post Product" button
**Stage/Context:** Partner-side, after partner has registered at least one `SkillCategory` in their Tajirika profile. Used by all made-to-order verticals (food, mafundi, events, skincare, hair_nails, fitness, housing).

### User Journey
1. Partner opens Tajirika home (`lib/tajirika/pages/tajirika_home_page.dart`) and taps "Post Bidhaa" / "Post Product".
2. App routes to `lib/tajirika/pages/post_partner_product_page.dart` (renamed from `lib/tajirika/pages/post_chef_product_page.dart`).
3. **Skill banner** at top (drives the entire form):
   - If partner has one skill → banner is read-only showing that skill's icon + label (e.g. "🪚 Carpentry" / "Useremala").
   - If partner has multiple skills (e.g. baking + carpentry) → ChoiceChip row appears; partner taps to select the skill this product belongs to. The selection is **sticky** — the form remembers the last skill used and pre-selects it next time. The skill chip drives:
     - The tag suggestion list (`SkillCategory.suggestedTags`) — bakers see `cake/birthday/wedding`; carpenters see `door/table/wardrobe`
     - The mode chips relevant for that skill (carpentry rarely uses `delivery_only`; baking rarely uses `digital_only`)
     - The sample-photo carousel placeholder ("Picha kama hii / A photo like this") that hints what good cover art looks like for the cluster
     - The price-band hint at the bottom: "Wenzio wa [skill] hutoza TZS [X]–[Y] / [skill] partners typically charge TZS [X]–[Y]" — pulled from anonymized aggregates
   - If partner taps a skill they haven't registered → routed to "Add Skill" flow first; can't post to a skill not on their profile.
4. Form fields:
   - **Title** / "Jina la Bidhaa" (TextField, required, max 80 chars) — e.g. "Custom mahogany door"
   - **Description** / "Maelezo" (TextArea, optional, max 500 chars)
   - **Cover photo** — tap to pick from camera or gallery; uploads via `POST /partner-products/photo` and stores returned path
   - **Additional photos** (up to 5) — same upload flow
   - **Base price (TZS)** / "Bei" (number field, required, formatted with comma separators on blur)
   - **Lead time (hours)** / "Saa za kutengeneza" (number, required) — partner-supplied prep time
   - **Mode** / "Aina" (ChoiceChips): Pickup only / Delivery only / Both / Digital only — Swahili: "Kuchukua" / "Kuletewa" / "Zote" / "Kidijitali"
   - **Tags** (chip set, multi-select) — pre-populated from `SkillCategory.suggestedTags` for the selected skill (e.g. carpentry → ["door","table","bed","wardrobe","custom","mahogany","oak"])
   - **Custom tag input** — free-form addition
   - **Active toggle** / "Inapatikana" (default ON)
5. Partner taps "Post" / "Tuma".
6. Loading state shows on the button; on success a green snackbar reads "Bidhaa imewekwa" / "Product posted" and the page closes back to Tajirika home.
7. **Error path:** API failure → red snackbar "Imeshindikana — jaribu tena" with retry button; form fields preserved.
8. **Empty cover validation:** if cover not uploaded → inline red helper text under cover slot "Picha inahitajika"; submit button disabled.
9. **Lead-time validation:** value must be 1–720 (1 hour to 30 days) — outside range shows inline error.

### CRUD Operations
- **Create:** Form above → `POST /partner-products` with `{title, description, base_price_tzs, lead_time_hours, skill_category, mode, tags, photos, cover_photo}`. Server derives `cluster` from `skill_category`.
- **Read:** Partner sees their own posts in `tajirika_home_page` "Bidhaa Zangu" section; calls `GET /partner-products?mine=1`. Buyer sees them in per-vertical home rails.
- **Edit:** Tap own product card → action sheet "Hariri" / "Edit" → opens posting form pre-filled → `PATCH /partner-products/{id}`. All fields editable except `skill_category` (locked after creation to keep COA cluster stable).
- **Delete:** Tap own card → "Futa" / "Delete" → confirmation dialog "Una uhakika? Bidhaa itaondolewa kwenye soko" → `DELETE /partner-products/{id}` (soft delete).
- **Toggle active:** Long-press own card → "Sitisha" / "Pause" → flips `is_active` flag without deletion (orders in flight unaffected).

### Notifications & Reminders
- 🔔 **Reminder — Post first product:** 48h after partner registration with no products: "Karibu! Tengeneza bidhaa ya kwanza ya [skill] uione kwenye soko / Welcome! Post your first [skill] product to appear in the marketplace"
- 💡 **Prompt — Refresh stale product:** When a product hasn't sold in 30 days: "[title] haijauziwa kwa siku 30. Boresha picha au punguza bei? / [title] hasn't sold in 30 days. Try better photos or a lower price?"
- 🎉 **Celebration — First sale:** When partner's first ever order arrives: "Pongezi! [title] imepata oda ya kwanza! / Congrats! [title] just got its first order!"
- ⚠️ **Alert — Inactive too long:** If partner's product has been `is_active=false` for 14+ days: "Bidhaa [X] zimezimwa zaidi ya wiki mbili. Washa tena? / [X] products have been paused over two weeks. Reactivate?"
- 📊 **Summary — Weekly product report:** Sunday 7pm: "Wiki hii: maoni [X], oda [Y], mauzo TZS [Z] / This week: [X] views, [Y] orders, TZS [Z] in sales"

### Reports & Insights
- **Per-product analytics card** on partner home: views (last 7d), orders (last 7d), conversion %, average rating
- **Pricing insight:** "Bei yako kwa [tag] ni TZS [X]. Wastani wa wenzako: TZS [Y]" — comparing partner's price vs cluster median
- **Best-selling tags report:** Top 5 tags driving the partner's sales over 30/60/90 days
- **Lead-time accuracy:** Compare partner's stated `lead_time_hours` vs actual prep time computed from `accepted_at` → `ready_at`. If consistently slower: "Wastani wako halisi ni saa [X]. Sasisha lead-time? / Your actual lead time averages [X]h. Update it?"
- **Stock-out detector:** If partner manually deactivates a product 3+ times in 30d → suggest "Add stock_count field" — flag for product team

### Cross-Module Connections
- **Tajirika profile:** `skill_category` chosen on this form must already exist in partner's `TajirikaPartner.skills` — if missing, deeplink to add-skill flow first
- **Shop:** The `partner_offerings` search index includes title + description + tags so cross-vertical search at `lib/screens/search/` finds the product
- **Calendar:** "Block this product when I'm away" → opens `manage_availability_page.dart` (feature 12) — partner sets blackouts so product auto-deactivates on those dates
- **Budget:** Photo upload data (storage costs) tracked passively — no journal entry until first sale
- **Shangazi AI:** "Ask Shangazi how to write a better product description for [skill]" — passes title + current description for AI rewrite
- **Community:** "Tangaza kama post" / "Share as feed post" → opens `create_image_post_screen` with title + price + deeplink + photos pre-filled (already shipped on chef-products page; generalize on rename)

### Research-informed enhancements

- **Three-tier service hierarchy** for searchability: `Category > Service Type > Service` (e.g. `Hair > Haircuts & Styling > Woman's Haircut`). Predefined Service Types act as marketplace search anchors so client-typed queries surface matching partners instantly. *Pattern: Booksy.*
- **Service Variants** to collapse pricing complexity: partner picks a parent service ("Box Braids"), then defines variants (small / medium / jumbo) each with its own price + duration. Avoids 30-row scroll menus. *Pattern: Booksy Service Variants.* New table: `partner_product_variants(id, partner_product_id, label_sw, label_en, price_tzs, lead_time_hours)`.
- **Add-ons surfaced after main selection** (not as separate flow). Each add-on carries its own duration + tax that auto-recalculates the booking total. Partner can cap max add-ons to prevent over-stacking. *Pattern: Booksy, Fresha, GlossGenius.*
- **Booking sequencing for multi-step services** (color + cut + blow-dry). Partner defines order + dependencies; **processing time** during color development hosts another client — a critical capacity multiplier salons request. *Pattern: Fresha sequencing.*
- **Implicit duration** — customers never pick duration directly. Partners set `duration_minutes` per variant; booking math handles the rest. *Pattern: universal across Booksy / Fresha / Vagaro / GlossGenius.*
- **Service Type photo guidelines per cluster** — sample-photo carousel placeholder already exists; tighten with explicit guidance: food = top-down with natural light + scale ref; hair = front + back + side after-shot; mafundi = before/after pair; housing = wide-angle 16–24mm + drone for premium tier. Listings missing minimum photo count (4 originals) are deprioritized. *Pattern: Lamudi photo gating, Zillow HDR guidance.*
- **Productized fixed-fee menu** for legal/business/medical: instead of free-form `partner_product`, partner picks from a curated catalog (`Will TZS 80,000`, `Lease review TZS 60,000`, `30-min consult TZS 25,000`). Reduces price-discovery friction and standardizes COA tagging. *Pattern: LegalZoom, Urban Company SKU catalog.* New field: `is_productized BOOL` + `catalog_sku_code`.
- **Patch-test as a separate bookable service with dependency** for color, lash extensions, microblading. Main booking can't confirm without patch-test completed in last 30 days. *Pattern: industry norm for color.*
- **Hard dietary tag set on every food product** (chip multi-select, max 5): `halali`, `mboga tu / vegan`, `bila nyama ya nguruwe / no pork`, `bila gluten`, `kid-portion`, `ugali-friendly`. Hard filters at search; never reverse-expand. *Pattern: Uber Eats query understanding.*
- **Hair-type taxonomy** for hair_nails partners: ChoiceChip multi-select `1A 1B 1C 2A 2B 2C 3A 3B 3C 4A 4B 4C` + `Locs`, `Braids`, `Natural`, `Relaxed`. Drives customer-side filter. *Pattern: StyleSeat.*
- **Photo consent toggle** at posting time — "Naomba ruhusa kuonyesha kazi hii kwenye portfolio yangu / Allow this product to appear in my public portfolio" (defaults ON for partner-uploaded; required OFF until customer consent for jobs that include identifiable customers e.g. before/after hair). *Pattern: GlossGenius photo consent.*
- **Photo-quality auto-checks** at upload time: blur detection, brightness, frame fill > 60%, dimension ≥ 1080px. Stock-image similarity check against public libraries. Soft-block with "Picha hii ina ukungu / This photo is blurry — try again?". *Pattern: Lamudi.*
- **Light skill activation — listings publish immediately, badges follow:**
  - Food: TFDA/TBS hygiene cert photo uploaded (verification asynchronous; product is live straight away with "Verification inaendelea / Verification in progress" chip)
  - Mafundi/hair/home-cook: no pre-publish gate at all — partner activates skill and posts. Trust signal builds via reviews, photos and completed-order count
  - Doctor/lawyer: license number captured at activation; listing live as "Pending verification". Hard switch to "Verified" once MCT/TLS lookup confirms (usually <24h)
  - Tour operator: TALA license number captured at activation; same async-verify pattern
  All identity fields (NIDA, phone, name, photo) are reused from the user's existing TAJIRI profile — never re-collected. *Pattern: Uber driver onboarding async background-check, Airbnb host instant-list.*
- **Lead-time honesty score** surfaced on partner dashboard — declared vs. actual delta (using `accepted_at → ready_at`). Consistent over-quoting (slow but honest) ranks better than short-and-miss. Partner sees "Una uongo wa muda — declared 2hr, actual 3.5hr" coaching prompt. *Pattern: Swiggy ranking penalty for short-and-miss.*
- **AMC / package-bundle SKUs** as a `partner_product` subtype: `partner_product.kind = 'amc'` with `visit_count`, `validity_months`, `base_price_tzs`. E.g. AC AMC: 3 visits / 12 months / TZS 120,000. *Pattern: Urban Company AMC.*

---

## 2. BUYER ORDER — PARTNER PRODUCTS

**Entry:** Per-vertical home page rail ("Vyakula vya Kuagiza" in food, "Bidhaa za Mafundi" in mafundi, "Pakeji za Hafla" in events, "Bidhaa za Urembo" in skincare, "Vifaa vya Kucha" in hair_nails, "Pakeji za Lishe" in fitness, "Bidhaa za Ndani" in housing) → tap card → `lib/<vertical>/pages/partner_product_detail_page.dart` (one per vertical, sharing `lib/tajirika/widgets/partner_product_card.dart` + a shared booking sheet widget for the order modal)
**Stage/Context:** Customer-side; same flow regardless of cluster, with copy adapted per cluster.

**Module-split note:** The buyer-facing detail page lives in each consumer vertical (`lib/food/pages/`, `lib/mafundi/pages/`, etc.), NOT in `lib/tajirika/`. Spec A.4.1 originally proposed a single `lib/tajirika/pages/partner_product_detail_page.dart` for de-duplication; this user-journey doc overrides that to honor the food/tajirika split — duplication is paid in exchange for clean module ownership. Shared rendering happens via widgets pulled from `lib/tajirika/widgets/`.

### User Journey
1. Customer scrolls vertical home (e.g. `lib/mafundi/pages/mafundi_home_page.dart`) and sees the `PartnerProductRail` with 12 horizontal cards.
2. Each card shows: cover image (130h), title (max 2 lines), partner name, green price badge "TZS [n]", lead-time chip "Saa [X]" or "Siku [Y]".
3. Customer taps card → `partner_product_detail_page.dart` opens.
4. Detail layout:
   - Photo carousel (cover + additional photos, swipeable)
   - Title + skill icon + price
   - Partner card (avatar, name, rating, "View partner") — tap navigates to `lib/tajirika/pages/partner_profile_page.dart`
   - Description block
   - Tags row
   - Lead-time + mode strip ("Itakuwa tayari saa [X] / [pickup/delivery/digital]")
   - Sticky bottom bar with cluster-specific CTA:
     - food → "Agiza sasa — TZS X"
     - mafundi → "Omba kazi — TZS X"
     - events → "Hifadhi — TZS X"
     - skincare/hair_nails → "Nunua — TZS X"
     - fitness → "Anza pakeji — TZS X"
     - housing → "Nunua bidhaa — TZS X"
5. Customer taps CTA → `_OrderSheet` modal slides up:
   - **Quantity** stepper (default 1, max 10)
   - **Mode picker** (only modes the partner allowed — pickup/delivery/digital)
   - **Delivery address** (only if mode=delivery; auto-fills from profile location with edit option)
   - **Notes** / "Maelezo ya ziada" (optional, e.g. "No nuts please")
   - **Requested date/time** picker (must be ≥ now + lead_time_hours)
   - **Total** breakdown: subtotal + delivery_fee (if any) = total
   - "Thibitisha Oda" / "Confirm Order" button
6. Customer taps confirm → `POST /partner-products/{id}/order` → spinner → success card "Oda imefika kwa [partner]. Utajulishwa atakapokubali / Order received. You'll be notified when [partner] accepts."
7. Modal closes; sticky bottom bar replaces CTA with "Iko kwa [partner]" status pill linking to order detail.
8. **Error path:** Network fail → red snackbar with retry. Validation fail (e.g. requested date too soon) → inline error in sheet.
9. **Sold-out / inactive path:** If product became inactive between rail load and tap → detail page shows banner "Hii bidhaa haipatikani sasa / Currently unavailable" and CTA disabled with "Bidhaa zinazofanana" / "Similar products" link.

### CRUD Operations
- **Create:** Order sheet → `POST /partner-products/{id}/order` returning new `partner_product_orders.id`
- **Read:** Customer sees their own orders in `incoming_customer_orders_page.dart` filtered by `role=customer`. Status timeline shows: pending → accepted → in_progress → ready → completed. Tap → `customer_order_detail_page.dart`.
- **Edit:** **NOT AVAILABLE** by design — once placed, customer cannot edit fields. Workaround: cancel + re-order. Note in detail: "Kuhariri, ghairi na uweke mpya / To edit, cancel and re-order".
- **Delete:** Customer can cancel only while `status ∈ {pending, accepted}` — tap "Ghairi Oda" / "Cancel Order" → confirmation → `POST /partner-products/{id}/cancel` with optional reason. After `in_progress`, cancel disabled (or partner-arbitrated).

### Notifications & Reminders
- 🔔 **Reminder — Order placed:** Immediately to customer: "✅ Oda yako ya [title] imefika. [Partner] atajulishwa / Your order for [title] has been received. [Partner] will be notified"
- 🔔 **Reminder — Order placed:** Push to partner: "📦 Oda mpya: [customer] ametaka [title] (TZS [X]). Bofya kuthibitisha / New order: [customer] wants [title]. Tap to confirm"
- ⚠️ **Alert — Partner not responded:** 1h after creation if still `pending`: nudge to partner — "Oda ya [customer] inasubiri / Order from [customer] is waiting"; 4h → second nudge; 24h → auto-cancel
- 🎉 **Celebration — Order accepted:** Customer push: "🎉 [Partner] amekubali oda yako ya [title]! Itakuwa tayari saa [X] / [Partner] accepted your [title]! Ready by [time]"
- 🔔 **Reminder — In progress:** Customer in-app card: "[Partner] anatengeneza [title] sasa / [Partner] is preparing [title] now"
- 📅 **Reminder — Ready for pickup:** When status flips to `ready`: "📍 [title] iko tayari kwa [partner address] / [title] is ready at [partner address]"
- 🔔 **Reminder — On the way (delivery):** When delivery mode + status `out_for_delivery`: "🛵 [Partner] amekuja na [title] / [Partner] is on the way with [title]"
- ⚠️ **Alert — Order overdue:** 30 min after stated `ready_for_delivery_at` if not picked up: "Oda ya [title] iko tayari muda mrefu / [title] has been ready for a while"
- 🎉 **Celebration — Completed:** Customer push: "✅ Oda imekamilika. Toa nyota kwa [partner] / Order complete! Rate [partner]"
- 📊 **Summary — Daily order digest:** Partner: 7am: "Leo: oda [X] zinazosubiri, [Y] zinazoendelea / Today: [X] pending orders, [Y] in progress"
- 💡 **Prompt — Re-order:** 14 days after a completed order: "Ulipenda [title]? Agiza tena / Loved [title]? Order again"

### Reports & Insights
- **Customer order history page:** All past orders grouped by partner, with re-order button per row, total spent per cluster
- **Partner spending breakdown:** "Umetumia TZS [X] kwa mafundi mwezi huu / You spent TZS [X] on mafundi this month" — categorized by cluster, comparable month-over-month
- **Lead-time vs actual:** Customer-facing trust metric — "[Partner] hutoa kwa wakati 95% / [Partner] is on-time 95%"
- **Recommendation engine:** "Watu walioagiza [title] pia walipenda [X, Y, Z] / Customers who ordered [title] also liked [X, Y, Z]"
- **Cluster spend leaderboard:** "Mwezi huu unaongoza kwa matumizi ya [cluster]. Tumetenga bajeti ya TZS [X] / This month you're heavy on [cluster]. Want to set a TZS [X] budget?"

### Cross-Module Connections
- **Wallet:** Customer pays via `lib/my_wallet/` — M-Pesa/Tigo Pesa/Airtel Money flow. On success, `WalletService.recordPayment` writes journal lines: debit `accounts_payable`, credit `partner_revenue`
- **Budget:** Each completed order writes an expenditure to the cluster envelope (`food` → `chakula`, `mafundi` → `nyumbani`, `events` → `tukio`, `housing` → `nyumba`, `fitness` → `afya`, `hair_nails`/`skincare` → `urembo`)
- **Calendar:** `requested_for` timestamp creates a calendar event "[title] kutoka [partner]" on customer's calendar via `CalendarService.createEvent`
- **Chat/Messages:** "Ongea na [partner]" button → opens `lib/screens/messages/conversation_screen.dart` with partner pre-selected and order context as system message
- **Shop:** Side-rail "Vifaa vya kuongeza" / "Add-ons" — for food, suggest related from Shop (drinks, candles); for mafundi, suggest tools/materials
- **Shangazi AI:** "Ask Shangazi about [product]" — passes title + cluster for advice (e.g. "How long does a custom door usually take to install?")
- **Community:** Post-completion share card "Nimeagiza [title] kutoka [partner]" with partner's deeplink

### Research-informed enhancements

- **Conversion-rate-weighted ranking** on every customer-facing rail. Factors: profile completeness, response-time, completion-rate, recency, review weighting (last 6–12 months > lifetime), distance, price competitiveness, conversion %. ~90% partner-influenceable + ~10% paid promo. *Pattern: Uber Eats / Thumbtack — both publish factor weights so partners can self-improve.*
- **Reorder carousel** above discovery: "Tena? / Order again?" rail at top of `lib/<vertical>/pages/*_home_page.dart` showing customer's last 5 partner products. One-tap rebook of the same partner, same item, same notes. *Pattern: DoorDash / Grubhub favorites shelf.*
- **Hard dietary / safety filter chips** at top of food rail: `Halali`, `Mboga tu`, `Bila gluten`. Reverse-expansion forbidden — selecting `Halali` never surfaces non-halal partners. *Pattern: Uber Eats query understanding engine.*
- **Schedule vs ASAP toggle** at booking time, with 30-min granular slots up to 48 hours ahead. Critical for home cooks who batch-cook in the morning, mafundi with set-day routes, and salons with limited evening slots. *Pattern: Swiggy Scheduled, Zomato Order Scheduling.*
- **Group / shared cart** for office lunches and family compounds: one shared link, multiple people add items, one payer. *Pattern: Zomato Group Ordering — high-fit for Tanzanian compound culture.*
- **Photo-proof of delivery + 4-digit handoff PIN** displayed in the customer's order page; delivery courier types it on arrival to confirm receipt. *Pattern: industry standard.*
- **AI image-similarity check on customer-uploaded refund photos** (forged "raw food" / "broken item" claims) before refund auto-issues. *Pattern: Truthscan, Radar.*
- **3-day self-report window** for missing/incorrect items; refunds outside the window require manual review. *Pattern: Instacart, Uber Eats.*
- **Auto-credit on detected partner error** without forcing customer to fight; cost deducted from partner's payout via error-rate fee. *Pattern: DoorDash.*
- **Tip after delivery up to 30 days post-service** at three suggested TZS bands; "Tip later" never hidden. *Pattern: DoorDash NYC test — better tips, less coercion, fits Tanzania post-service tipping norm.*
- **In-app help chat with <3-min SLA** for order-issue escalation. *Pattern: Zomato.*
- **Per-vertical detail page copy / hero image norms:** food = top-down dish + chef face overlay; mafundi = before/after pair if relevant; events = gallery + video reel; housing = exterior + 3D Matterport tab; travel = day-by-day card list. *Pattern: cluster-specific UX from Booksy / GigSalad / Viator / Zillow.*

---

## 3. PARTNER INBOX — UNIFIED CUSTOMER ORDERS

**Entry:** Tajirika Home → "Oda Zangu" / "My Orders" tile → `incoming_customer_orders_page.dart`
**Stage/Context:** Partner-side; aggregates all 9 `customer_orders` sources into a single inbox with per-source filter chips. Source-aware action bar.

### User Journey
1. Partner taps "Oda Zangu" tile from `tajirika_home_page`.
2. `IncomingCustomerOrdersPage` loads `GET /api/customer-orders?role=partner&limit=50`.
3. **Skill filter chip row** at top (only visible when partner has 2+ skills): "Zote / All" (default) + one chip per registered skill (e.g. "🎂 Baking" + "🪚 Carpentry"). Selecting "Baking" filters all rows to `skill_category in ('baking',)`; orders for cakes hide carpentry orders so the baker can focus on a wedding-day rush without seeing a cabinet inquiry mid-icing. Active chip is persisted across sessions per partner.
4. **Source filter chip row** below: "Zote / All" (default), "Bidhaa / Products", "Huduma / Services", "Miadi / Appointments", "Ushauri / Consultations", "Ujenzi / Engagements", "Mali / Properties", "Hafla / Events". Chips map to one or more `source` values. Source × skill filters compose (e.g. "Baking" + "Bidhaa" shows only cake orders).
5. **Status filter chip row** below: "Mpya / New" (pending+quoted+held), "Inaendelea / Active", "Imekamilika / Done", "Imeghairiwa / Cancelled".
6. **Order list:** each row shows skill icon (e.g. 🎂 vs 🪚 makes it instantly clear which persona the partner is dealing with), item title, customer name, status pill (color-coded), price, `requested_for` time-ago label, source badge.
7. **Empty state:** silhouette + "Hakuna oda bado. Tangaza bidhaa au pakeji uone wateja / No orders yet. Post a product or package to attract customers"; CTA "Post Bidhaa".
8. Partner taps a row → `customer_order_detail_page.dart` (generic) for ~60% of cases. Source-specific routes for: `consultation` (NDA gate), `service_request` (quote dialog), `garage_booking` (diagnosis flow), `engagement` (workspace), `event_booking` (deposit flow). The detail page header always shows the skill icon + label so the partner is anchored to which persona this order is for.
9. **Detail page action bar** (state-aware, dispatched via `lib/customer_orders/models/source_action_map.dart`):
   - `pending` → "Kubali / Accept", "Kataa / Reject"
   - `accepted` (partner_product) → "Anza / Start", "Ghairi / Cancel"
   - `in_progress` → "Tayari / Ready", "Ghairi / Cancel"
   - `ready` → "Imefikishwa / Delivered", "Imekamilika / Completed"
   - `quoted` (service_request) → wait
   - `diagnosed` (garage_booking) → wait for customer approval
10. Action tap → confirmation dialog with status preview "Hali itabadilika kuwa [next] / Status will change to [next]". Optional reason field for cancel/reject.
11. **Pull-to-refresh** triggers re-fetch. Firestore listener (`LiveUpdateService`) auto-refreshes when counter-party acts.
12. **Error path:** Stale state (status changed server-side between view + action) → snackbar "Hali ya oda imebadilika. Inasasishwa / Order status changed. Refreshing" + auto-refresh.

### CRUD Operations
- **Read:** UNION query at `GET /api/customer-orders?role=partner&source=&status=&from=&to=&limit=&offset=`
- **Update:** Status transitions via per-source `POST /<source>/{id}/{action}` — actions follow each source's state machine
- **Delete:** **NOT AVAILABLE** — orders are never deleted, only `cancelled`/`rejected`. Audit trail preserved via `*_at` timestamps and `rejection_reason`
- **Bulk action:** **NOT AVAILABLE** — flag as gap; partners with high volume need this (especially food bakers receiving party-day rushes)

### Notifications & Reminders
- 🔔 **Reminder — New order:** Per-source push (see source features for exact text). Channel "partner_orders".
- ⚠️ **Alert — Pending too long:** Hourly to partner if any order has been `pending` >2h: "Oda [X] zinasubiri jibu lako / [X] orders waiting for your reply"
- 🎉 **Celebration — Daily milestone:** When partner completes 5 orders in a day: "🏆 Umemaliza oda 5 leo! Ujue umepata TZS [X] / 5 orders done today! You earned TZS [X]"
- 📊 **Summary — End-of-day digest:** 8pm: "Leo: oda [X] zilipokelewa, [Y] zilikamilika, mauzo TZS [Z] / Today: [X] received, [Y] completed, TZS [Z] revenue"
- 📊 **Summary — Weekly digest:** Sunday 7pm: "Wiki hii: oda [X], mauzo TZS [Y] (+/-[Z]% kuliko wiki iliyopita) / This week: [X] orders, TZS [Y] revenue ([Z]% vs last week)"
- 💡 **Prompt — Conversion coaching:** If partner's accept-rate <60% in last 30d: "Unakubali oda kidogo (% ndogo). Hii inashusha cheo chako / You're accepting fewer orders — this hurts your ranking"
- ⚠️ **Alert — Negative streak:** 3 cancellations in 7d → "Tafadhali wasiliana na wateja kabla ya kughairi / Please contact customers before cancelling"

### Reports & Insights
- **Inbox stats card** (top of page): Pending count, today's orders, today's revenue, avg response time
- **Source mix pie:** Which sources contribute what % of revenue (tells multi-skill partners where to focus)
- **Skill mix bar (multi-skill only):** Per-skill revenue + order count this month vs last month — e.g. "🎂 Baking: TZS 280k (+12%); 🪚 Carpentry: TZS 410k (-8%)". Tap a bar → drills into that skill's filtered inbox. Helps partner decide which persona to invest more time in.
- **Status funnel:** Pending → Accepted → Completed conversion %, plus cancellation/rejection breakdown with reasons word-cloud
- **Response time leaderboard:** Partner's median accept-time vs cluster median — "Unajibu kwa dakika [X]. Wastani wa wenzako: [Y] / You respond in [X] min. Cluster average: [Y]"
- **Customer repeat rate:** % of orders from returning customers per cluster
- **Hot hours heatmap:** Day-of-week × hour-of-day grid showing when orders arrive (helps plan availability)
- **Exportable monthly report:** PDF for partner's records, NIDA-tax-ready summary

### Cross-Module Connections
- **Calendar:** Each accepted order auto-creates a calendar event with `requested_for` (food/services) or `starts_at` (appointment/consultation/event)
- **Wallet:** Completed orders write to `lib/my_wallet/` and Tajirika earnings dashboard via `WalletService.recordIncomingPayment`
- **Chat/Messages:** Per-order chat thread accessible from row "Ongea / Chat" — same `conversation_screen.dart`
- **COA/Accounting:** Terminal `completed`/`paid` writes journal lines via `JournalEntryService.recordTransaction({source, amount, debit, credit, reference: order_id})`
- **Notifications/FCM:** All state transitions fan out via `FlutterLocalNotificationsPlugin` for foreground + FCM for background
- **Shangazi AI:** "Ask Shangazi how to handle this difficult customer" — passes order context (status history, messages, cancel rate)
- **Tajirika profile:** Avg rating across all sources from `partner_reviews` (feature 11) feeds into partner's public profile score

### Research-informed enhancements

- **30-second accept window with auto-reassign.** Pending order is offered to next-nearest qualified partner if first partner doesn't accept in 30s. Decline and timeout treated identically. *Pattern: Uber Eats / DoorDash.*
- **Auto-pause partner after 3 consecutive missed/declined orders.** Manual unpause required from partner's side. Sticky banner on `tajirika_home_page` reads "Akaunti yako imezuiliwa kupokea oda mpya / Your account is paused for new orders" with "Washa tena / Resume" button. *Pattern: DoorDash.*
- **"Busy" vs "Closed" mode toggles** as separate states. "Busy" extends declared ETA by configurable minutes (e.g. +20m) without de-listing partner. "Closed" hides listing entirely. Per-skill toggles for multi-skill partners (e.g. baker can be "Busy" on cakes but "Open" on carpentry). *Pattern: Talabat partner tablet "indicate busy".*
- **Stock toggle per partner_product / per appointment slot** for instant in/out-of-stock. Greys out the card on customer rails immediately. *Pattern: Swiggy / Zomato dish toggle.*
- **Daily M-Pesa payout** as competitive moat. Display "Pesa zako, leo / Your money, today" badge in partner onboarding. Talabat T+45 then bi-weekly is global norm — daily wins partners. Auto-payout at 23:00 nightly via M-Pesa B2C.
- **Lead-expiring countdown push** for quote-bid sources (mafundi, events, engagement, listing inquiry): "Quote ya [job] inakwisha kwa dakika 30 — washindani 3 wamejibu / Quote for [job] expires in 30 min — 3 competitors have responded". *Pattern: Thumbtack, Bark.*
- **Partner KPI score** on inbox header (composite, 0–100): response time (40%) + completion rate (30%) + rating (20%) + recency (10%). Tier badge derived from this: 0–60 New, 60–75 Verified, 75–90 Top Pro, 90+ Elite. *Pattern: Thumbtack Top Pro composite.*
- **Bulk action support** (flagged as gap above): multi-select pending orders → "Kubali zote / Accept all" or "Tuma kiwango cha kawaida / Send standard quote" from a saved template. Critical for bakers on party days and consultants with multiple inquiry-week leads. *Pattern: Honeybook bulk responses.*
- **Voice-note / canned-message library** for partner replies: pre-recorded greetings, "Nakuja sasa / On my way", "Tafadhali nipe picha zaidi / Send more photos". Faster than typing in Swahili on the road. *Pattern: Airtasker, Urban Company partner app.*
- **Partner side weekly competitive benchmark email/in-app card:** "Wenzio wa [skill] wamefanya oda [X] wiki hii. Wewe umefanya [Y]. / Other [skill] partners completed [X] orders this week. You completed [Y]." Compare on volume, response time, rating, accept rate. *Pattern: Uber Eats Manager benchmark dashboards.*
- **Service-history lookup per customer** ("This customer has booked you 3 times in 6 months — ABCD pattern"): when a repeat customer creates a new order, partner sees a `Mteja wa kawaida / Repeat customer` chip and one-tap access to past orders + ratings. *Pattern: Honeybook contact history, GlossGenius client cards.*

---

## 4. SERVICE REQUEST — MAFUNDI SITE VISITS

**Entry:** Customer side: `lib/mafundi/pages/mafundi_home_page.dart` → "Ita Fundi" / "Request a Pro" FAB → `lib/mafundi/pages/request_service_page.dart` → `lib/mafundi/pages/service_request_status_page.dart`. Partner side: unified inbox + `lib/tajirika/pages/incoming_service_requests_page.dart` (list) + `lib/tajirika/pages/service_request_detail_page.dart` (with quote dialog).
**Stage/Context:** When customer has a problem at home (broken pipe, dead socket, leaking roof) and needs a `plumbing`/`electrical`/`painting`/`roofing`/`solarInstallation` partner to come to them.

### User Journey (Customer)
1. Customer taps "Ita Fundi" in mafundi home.
2. Multi-step form `request_service_page.dart`:
   - **Step 1 — Skill picker:** ChoiceChips for `plumbing`/`electrical`/`painting`/`roofing`/`solarInstallation`
   - **Step 2 — Problem summary:** TextArea (required, 20–500 chars), placeholder "e.g. Bomba inavuja chini ya sinki jikoni"
   - **Step 3 — Photos:** Upload up to 4 photos (camera or gallery)
   - **Step 4 — Address:** Auto-filled from profile; customer can pick on map or override; `lat`/`lng` captured
   - **Step 5 — Preferred window:** ChoiceChips "Leo asubuhi / Today AM", "Leo jioni / Today PM", "Kesho / Tomorrow", "Wiki hii / This week"
   - **Step 6 — Optional partner pick:** "Toka kwa fundi maalum?" — search box; if blank, request goes to **open marketplace** (multiple partners can quote; product decision in Part E.3)
3. Customer taps "Tuma Ombi" / "Send Request" → `POST /service-requests`.
4. Status page `service_request_status_page.dart` shows timeline; customer waits for partner quote(s).
5. **Partner quotes received:** notification "[Partner] amekuhitajia TZS [callout] kwa kuja, [estimated] kwa jumla / [Partner] quoted TZS [callout] callout, TZS [estimated] estimate". If marketplace mode, customer sees up to 3 quotes side-by-side.
6. Customer taps "Kubali / Accept" on a quote → `POST /service-requests/{id}/accept` → status `accepted`. Other quotes auto-rejected.
7. Partner clicks "Niko Njiani / En Route" → status `en_route`; customer push "[Partner] anakuja sasa — atafika dakika [X] / [Partner] is on the way — ETA [X] min".
8. Partner taps "Nimefika / On Site" → `on_site`; customer notified.
9. Partner taps "Imekamilika / Completed" → `completed`; customer asked to confirm + pay via Wallet.
10. **Customer can cancel** while in `pending` or `quoted` status. After `accepted`, cancel triggers callout-fee charge.

### User Journey (Partner)
1. New service request appears in `lib/tajirika/pages/incoming_service_requests_page.dart` (or unified inbox row).
2. Tap → `lib/tajirika/pages/service_request_detail_page.dart`:
   - Problem photos carousel
   - Customer name + rating + distance from partner location ("Km [X] kutoka kwako")
   - Address with map deeplink ("Fungua Maps")
   - Action bar: "Nukuu / Quote", "Kataa / Reject"
3. **Quote dialog** on tap: callout_fee_tzs (required), estimated_cost_tzs (optional), ETA (`now`, `1h`, `3h`, `tomorrow`) — partner submits → status `quoted`.
4. Once customer accepts: action bar updates to "Niko Njiani", "Imeghairiwa / Cancel".
5. After `on_site`, action bar: "Imekamilika / Completed", "Inahitaji muda zaidi / Need more time".

### CRUD Operations
- **Create:** Customer form → `POST /service-requests`
- **Read:** Both parties via `customer_orders` UNION + source-specific list endpoint
- **Edit (customer):** Edit problem photos / preferred window only while `pending`. After `quoted`, no edits.
- **Edit (partner):** Update quote until customer accepts (resends notification).
- **Delete:** **NOT AVAILABLE** — only `cancelled`/`rejected` with reason

### Notifications & Reminders
- 🔔 **Reminder — Request received:** Customer: "✅ Ombi limewekwa. Mafundi watajibu hivi karibuni / Request posted. Pros will respond shortly"
- 🔔 **Reminder — Request received:** Partners (in marketplace mode): "🛠️ Ombi mpya la [skill] umbali wa km [X] / New [skill] request [X]km away"
- ⚠️ **Alert — No quotes after 1h:** Customer: "Bado hakuna mafundi waliojibu. Panua eneo? / No pros responded yet. Expand area?" → button to widen radius
- 🎉 **Celebration — Quote accepted:** Partner: "🎉 [Customer] amekubali nukuu yako. Anza safari / [Customer] accepted your quote. Head out"
- 🔔 **Reminder — En route ETA:** Customer: 5 min before stated ETA: "[Partner] atafika hivi karibuni / [Partner] arrives soon"
- ⚠️ **Alert — Partner late:** 15 min past ETA, no `on_site` event: customer "[Partner] amechelewa. Ongea naye? / [Partner] is late. Contact?"
- 🔔 **Reminder — Service done:** Customer: "Imekamilika? Lipa na toa nyota / Done? Pay and rate"
- 📊 **Summary — Service history:** Monthly to customer: "Mwezi huu: huduma [X] za nyumbani, gharama TZS [Y] / This month: [X] home services, TZS [Y] spent"
- 💡 **Prompt — Maintenance reminder:** 6 months after a completed `plumbing`/`electrical` service: "Imefika muda wa ukaguzi tena? / Time for another inspection?"

### Reports & Insights
- **Customer dashboard:** Service history per skill, average cost per category, "Average plumber callout: TZS [X]"
- **Partner dashboard:** Acceptance rate per skill, average revenue per visit, distance distribution heatmap
- **Tanzania benchmarks:** "Wastani wa nchi kwa [skill]: TZS [X] / Country average for [skill]: TZS [X]" — built from anonymized aggregates
- **Predicted-failure prompts:** "Bomba lilichuna mara mbili msimu huu — fikiri kubadilisha / Pipe was fixed twice this season — consider replacement"

### Cross-Module Connections
- **Calendar:** Accepted request creates calendar event at `accepted_at` + ETA window
- **Wallet:** Customer pays callout + estimate via mobile money on `completed`
- **Budget:** Charged to customer's `nyumbani` envelope (home maintenance)
- **Chat:** Per-request thread for ETA updates, photos
- **Shop:** "Vifaa vinavyohitajika / Materials needed" — partner can append a Shop list (cement, paint, pipes) that customer can purchase before partner arrives
- **Insurance:** For roofing/solar — "Bima yako inachukua hii? / Does insurance cover this?" link to `lib/insurance/`
- **Doctor:** **N/A** — no health implication (unless sewage/sanitation, then offer Doctor link if customer reports symptoms in chat — Shangazi AI can detect)
- **Shangazi AI:** "Ask Shangazi about plumber pricing in Dar" — gives benchmarks + tips

### Research-informed enhancements (mafundi)

- **Photo-of-problem upload as primary intake** (front of customer flow). Partners bid on photos alone before driving out, drastically reducing wasted site visits. *Pattern: Thumbtack, Airtasker, Fixico (which lets EU body shops bid on car damage photos alone).*
- **AI cost estimation anchor band** before quotes arrive: "Wastani wa kazi kama hii: TZS 45,000–80,000 / Typical range for this work: TZS 45,000–80,000". Built from anonymized completed jobs. Doesn't lock the price, anchors expectations and reduces bid-shock. *Pattern: RepairPal Fair Price Estimator.*
- **Structured intake form per skill** (long guided questionnaire — "How many rooms? What flooring type? Approximate sq ft? Single-storey or multi?") so partners can quote accurately without back-and-forth. *Pattern: Angi, HomeAdvisor.*
- **Diagnostic fee credited toward repair:** TZS 15,000 site-visit fee credited if customer proceeds with the work. Reduces tire-kickers. *Pattern: RepairPal Certified, AAMCO.*
- **Post-diagnosis re-quote with hard customer approval gate:** after on-site inspection, partner submits revised quote in-app; work cannot begin until customer taps "Kubali / Approve". This is the single most important pattern to prevent disputes. *Pattern: YourMechanic, Wrench, Openbay.*
- **No-fix-no-fee** as marketed trust line for diagnostic-only flows. *Pattern: YourMechanic, EU mobile mechanics.*
- **Mandatory before/after photo upload** on every job by partner. Stored on the order ticket; visible to customer; used as dispute evidence. *Pattern: Urban Company, Fixico, RepairSmith.*
- **Geofence-triggered "Arrived" status** instead of manual partner tap. Partner phone GPS crosses customer-address radius → status auto-pings + customer push. *Pattern: Urban Company, Wrench.*
- **Live ETA push with map view** ("Fundi yuko dakika 10 mbali / Pro is 10 min away") triggered when partner taps "Anza safari / Start trip" in their app. Marker rotates to heading; queue-and-burst on 3G reconnect. *Pattern: Swiggy rider tracking, RepairSmith.*
- **30-day redo-work warranty** explicitly marketed. If the same issue recurs within 30 days, return visit is free. *Pattern: Urban Company 30-day service warranty.*
- **Parts pass-through with capped markup** (20–30% above cost, displayed line-item with cost + markup separately). *Pattern: RepairSmith, Wrench.*
- **Partner site-survey fee for big jobs** (renovations, HVAC installs) as a separately scheduled appointment with its own booking flow. *Pattern: Angi, HomeAdvisor.*

---

## 5. GARAGE BOOKING — AUTO DROP-OFF

**Entry:** Customer side: `lib/service_garage/pages/service_garage_home_page.dart` → "Peleka Gari / Drop Off Car" → `lib/service_garage/pages/book_garage_page.dart` → `lib/service_garage/pages/garage_status_page.dart`. Partner side: unified inbox + `lib/tajirika/pages/incoming_garage_bookings_page.dart` + `lib/tajirika/pages/garage_booking_detail_page.dart` (with diagnosis form).
**Stage/Context:** Customer's car has a fault; needs `autoMechanic`/`autoElectrician`/`panelBeating`/`sprayPainting` partner. Multi-stage flow because cost isn't known until diagnosis.

### User Journey (Customer)
1. Tap "Peleka Gari" in service-garage home.
2. Form `book_garage_page.dart`:
   - **Skill** picker (autoMechanic/autoElectrician/panelBeating/sprayPainting)
   - **Vehicle** fields: make, model, plate (TZ format auto-validated, e.g. T123ABC), year
   - **Fault summary** TextArea (required), e.g. "Inalia injini ikianza"
   - **Fault photos** (up to 4)
   - **Drop-off slot** picker — uses partner's `partner_availability` (feature 12) → green/grey grid for next 7 days
   - **Estimated cost cap** (optional) "Sitaki kuzidi TZS [X] bila kuniuliza / Don't exceed TZS [X] without asking"
3. Customer chooses partner from search OR shortlist (cars don't fit open marketplace as well — partner picked upfront).
4. Tap "Tuma / Submit" → `POST /garage-bookings` → status `pending`.
5. Partner accepts → status `confirmed`; customer notified with garage address + drop-off time.
6. Customer drops off car at slot; partner taps "Imefika / Dropped Off" → status `dropped_off`.
7. Partner runs diagnosis (offline) → fills diagnosis text + revised cost → submits → status `diagnosed`. Customer push "Tatizo: [diagnosis]. Gharama mpya: TZS [X]. Kubali? / Issue: [diagnosis]. Revised cost: TZS [X]. Approve?"
8. Customer taps "Kubali / Approve" or "Kataa / Decline" → status `approved` or `cancelled`.
9. After approval, partner works → status flows `in_progress` → `ready_for_pickup` → `completed`.
10. Customer notified at each stage; can pay via Wallet on `ready_for_pickup` or pickup-and-pay.

### CRUD Operations
- **Create:** `POST /garage-bookings`
- **Read:** Customer + partner via UNION; deep view at `garage_booking_detail_page.dart`
- **Edit:** Customer can edit fault summary/photos only while `pending`. Diagnosis editable by partner only until customer approves.
- **Delete:** **NOT AVAILABLE** — `cancelled` only

### Notifications & Reminders
- 🔔 **Reminder — Drop-off slot tomorrow:** 24h before: "Kesho saa [X] peleka gari [plate] kwa [partner] / Tomorrow at [X], drop [plate] at [partner]"
- ⚠️ **Alert — Drop-off slot in 1h:** "Saa moja, peleka gari [plate]. Anwani: [address] / 1h until drop-off. Address: [address]" — with map deeplink
- 🔔 **Reminder — Diagnosis ready:** Customer: "🔧 Tatizo limepatikana: [diagnosis]. Gharama: TZS [X]. Kubali kuendelea? / Issue diagnosed: [diagnosis]. Cost: TZS [X]. Approve?"
- ⚠️ **Alert — Diagnosis pending approval:** 4h after `diagnosed`: nudge customer "Diagnosis ya gari [plate] inasubiri / Diagnosis for [plate] awaiting your approval"
- 🎉 **Celebration — Ready for pickup:** "🚗 Gari [plate] iko tayari kwa [partner]. Lipa na uchukue / [Plate] is ready at [partner]. Pay and pick up"
- 💡 **Prompt — Service reminder:** 6 months after `completed` of `autoMechanic` service: "Service ya gari yako [plate] tena? / Service [plate] again?"
- 📊 **Summary — Annual service log:** January each year: "Mwaka [Y]: huduma za [plate], gharama TZS [Z] / Year [Y]: services for [plate], TZS [Z] total"

### Reports & Insights
- **Vehicle service log:** Per `vehicle_plate`, full chronological history — exportable as PDF for resale
- **Cost-vs-quote variance:** "Wastani wa wenzio: gharama halisi inavuka quote kwa [X]% / Average partner overshoots quote by [X]%" — vs cluster median
- **Failure pattern detection:** "Gari yako imekuwa kwa [partner] mara [3]+ kwa [issue]. Fikiri kuhusu kubadili / Your car has been in [3]+ times for [issue]. Consider deeper repair"
- **Mechanic comparison:** Avg labour rate, avg turnaround time across local mechanics (anonymized)

### Cross-Module Connections
- **Calendar:** Drop-off + ready-for-pickup as calendar events
- **Wallet:** Pay on pickup
- **Budget:** Charged to `usafiri` (transport) envelope
- **Insurance:** "Bima yako inalipa hii? / Insurance covers this?" → `lib/car_insurance/` deep link, esp. for `panelBeating`/`sprayPainting`
- **Shop:** Parts pre-order — "Spare parts inahitajika: [list]. Agiza mapema / Order parts in advance"
- **Shangazi AI:** "Ask Shangazi about car service in Dar" — pricing context
- **Buy Car module:** "Una mpango wa kuuza gari? Ripoti hii ya service inaongeza thamani / Selling soon? Service log boosts resale" — link to `lib/buy_car/sell_my_car`

### Research-informed enhancements (auto / garage)

- **VIN scan via camera** at booking time — scan VIN barcode under windshield or door jamb to auto-populate make/model/year/engine. Removes user error in parts lookup and quote accuracy. *Pattern: RepairPal, CarAdvise, RepairSmith.*
- **Symptom selector wizard** as alternative to free-text fault summary — guided diagnostic tree ("Inalia injini ikianza" → "Wakati gani? Asubuhi tu? Daima?") that maps to likely jobs and price ranges before a partner even sees the request. *Pattern: YourMechanic "I hear a noise" wizard.*
- **OBD2 / dashboard-light photo upload** — customer photographs the dashboard with warning lights on; partner interprets pre-visit. *Pattern: Wrench, RepairPal community Q&A.*
- **Mobile vs. shop drop-off branching at booking** — first question is "Wapi? / Where?": driveway / office / shop. Different SKUs and partner pools per choice; mobile mechanics carry a defined SKU list (oil change, brakes, alternator, battery), complex jobs auto-route to shop partners. *Pattern: Wrench, RepairSmith, YourMechanic.*
- **Persistent vehicle profile / service history book** — `vehicles(plate, vin, make, model, year, owner_user_id)` with all past services attached. Stores parts, mileage, warranties; reminds customer of due intervals. *Pattern: CarAdvise MyCar, RepairPal.*
- **Recall lookup by VIN** — daily check against a recall feed (Tanzania-specific dealership recalls when available; OEM global recall feed otherwise). Surface as alerts in `lib/service_garage/`. *Pattern: RepairPal, CarAdvise.*
- **Mileage-based service reminders** — push at "12,000 km since last service" or "12 months since AC service", computed from `vehicles.last_service_km` + monthly mileage estimate. *Pattern: CarAdvise.*
- **Parts ordering integration with TZ supplier APIs** (NAPA Tanzania, AutoZone if available, local sokoni catalog) — partner pulls parts tied to VIN; price visible to customer at quote time. *Pattern: RepairSmith, AAMCO digital.*
- **Body-shop bidding on photos alone** for `panelBeating` / `sprayPainting`: customer uploads multi-angle damage photos + description; body shops bid based on photos without in-person inspection first. Customer drives in only after acceptance. *Pattern: Fixico (EU). Highly transferable.*
- **Pickup-and-drop courtesy filter** ("Anaweza kuja kuchukua gari? / Can they pick the car up?") for partners who offer it. *Pattern: AAMCO franchise locator, premium dealers via Carwow.*
- **Annual maintenance contract (AMC) for vehicles**: prepaid yearly bundle (3–4 services + priority booking + parts discount) — same `partner_product.kind = 'amc'` infrastructure as feature 1. *Pattern: Urban Company AMC.*
- **Service-due dashboard** in customer-side `lib/service_garage/` showing upcoming services with due dates and estimated costs. *Pattern: CarAdvise MyCar.*
- **12-month / 12,000-km parts+labour warranty** stored on the job ticket; one-tap warranty claim if part fails. *Pattern: RepairSmith, RepairPal Certified.*

---

## 6. APPOINTMENT — SALON / FITNESS

**Entry:** Customer side: `lib/hair_nails/pages/hair_nails_home_page.dart` "Hifadhi Nafasi / Book Slot" → `lib/hair_nails/pages/book_hair_nails_appointment_page.dart`; OR `lib/fitness/pages/fitness_home_page.dart` "Hifadhi Mazoezi / Book Session" → `lib/fitness/pages/book_fitness_session_page.dart`. Partner side: unified inbox + `lib/tajirika/pages/appointment_detail_page.dart` (check-in / start / done actions) + `lib/tajirika/pages/manage_availability_page.dart` (slot calendar — see feature 12). Customer slot picker rendered via shared `lib/tajirika/widgets/slot_picker.dart` (read-only).
**Stage/Context:** Customer wants a haircut, manicure, or training session at a specific time. Partner has set availability via feature 12.

### User Journey (Customer)
1. Customer browses partners in hair_nails or fitness home (filtered by `cluster`).
2. Tap a partner → `partner_profile_page.dart` → "Hifadhi" / "Book" CTA.
3. **Service picker:** ChoiceChips of `service_title` options the partner offers (e.g. "Mens cut + beard — TZS 5,000", "Manicure — TZS 8,000", "PT 1hr — TZS 15,000")
4. **Location kind:** salon / home / virtual (only modes the partner offers)
5. **Slot picker** (`lib/tajirika/widgets/slot_picker.dart`) — 7-day grid:
   - Open slots (green), booked (grey), partner blackout (striped grey), past (faded)
   - Tap an open slot → confirms slot in dialog
6. **Customer address** field (only if `location_kind == 'home'`) — auto-fills from profile
7. **Notes** TextArea (optional) — e.g. "Allergic to certain hair dye"
8. Customer taps "Hifadhi / Book" → `POST /appointments` → status `pending`.
9. Partner accepts → status `confirmed`; customer push "[Partner] amekubali. Tutaonana [date] saa [time] / [Partner] confirmed. See you [date] at [time]"
10. **Day of:**
    - 24h before: customer reminder
    - 2h before: customer reminder + add to calendar
    - On arrival: partner taps "Amefika / Checked In" → status `checked_in`
    - Service start: partner "Anza / Start" → `in_progress`
    - End: "Imeisha / Done" → `completed` → customer paid via Wallet
11. **No-show flow:** 15 min after `starts_at`, partner can mark `no_show` → cancellation fee may apply per partner's settings.

### Recurring Sessions (Fitness)
1. On the booking sheet, customer toggles "Mazoezi ya kawaida / Recurring".
2. Pattern picker: weekday chips (Mon–Sun) + "Hadi / Until" date.
3. On confirmation, server auto-generates child appointments for first 30 days; daily cron extends.
4. Customer sees "Mazoezi 12 yamehifadhiwa / 12 sessions booked" in confirmation.
5. Each child appointment is independently cancellable from the recurring detail view.

### CRUD Operations
- **Create:** `POST /appointments` (single or recurring)
- **Read:** Both via UNION; per-day calendar view at partner side
- **Edit:** Customer can reschedule (`PATCH /appointments/{id}/reschedule`) up to 4h before `starts_at` — picks new slot from same partner's availability. Partner accepts new slot.
- **Delete:** Customer cancels — full refund if >24h before; partner-set cancellation fee within 24h. Partner cancels — full refund + apology auto-message + 5% rating-impact warning shown to partner.

### Notifications & Reminders
- 🔔 **Reminder — Booking received:** Customer: "✅ Hifadhi imewekwa. [Partner] atajulishwa / Booking placed. [Partner] will be notified"
- 🔔 **Reminder — Booking confirmed:** Customer: "🎉 [Partner] amekubali. [Date] saa [time] / [Partner] confirmed. [Date] at [time]"
- 📅 **Reminder — 24h before:** "Kesho saa [time] una miadi na [partner] / Tomorrow at [time] you have an appointment with [partner]"
- 📅 **Reminder — 2h before:** "Saa 2, miadi na [partner] kwa [service] / 2h until [service] with [partner]"
- 🔔 **Reminder — On the way (home visits):** Partner-triggered: "[Partner] anakuja sasa / [Partner] is on the way"
- ⚠️ **Alert — Customer late:** 10 min after `starts_at`: partner sees "Mteja amechelewa. Tuma SMS? / Customer late. Send SMS?"
- ⚠️ **Alert — No-show charged:** Customer: "Hukuhudhuria miadi. Ada ya TZS [X] imechukuliwa / You missed the appointment. TZS [X] no-show fee charged"
- 🎉 **Celebration — Streak (recurring):** Customer: "🏋️ Umemaliza wiki [X] mfululizo wa mazoezi / [X] weeks straight of training"
- 💡 **Prompt — Re-book:** 4 weeks after a hair cut: "Imefika muda wa kukata tena? / Time for another cut?"
- 📊 **Summary — Monthly fitness summary:** "Mwezi huu: vipindi [X] vya mazoezi, masaa [Y] / This month: [X] sessions, [Y] hours"

### Reports & Insights
- **Customer self-care log:** Frequency of haircuts, manicures, training — patterns over time
- **Partner utilization:** % of slots booked vs available per week
- **Fitness progress (cross with `lib/fitness/`):** Weight/measurements at start of recurring plan vs current
- **Best-time-to-book:** "Saa za asubuhi zinapatikana zaidi / Morning slots are easier to book"
- **No-show stats:** Customer's no-show rate over 90d; partners with high no-show rate flagged

### Cross-Module Connections
- **Calendar:** Every confirmed appointment auto-syncs as event with reminders (24h, 2h)
- **Wallet:** Pay on `completed` or pre-pay on `confirmed` (partner setting)
- **Budget:** `urembo` envelope for hair/nails; `afya` for fitness
- **Family:** Family members can book on each other's behalf — link from `lib/my_family/`
- **Photos/Community:** Post-appointment "Pamoja na [partner]" share template
- **Shangazi AI:** "Ask Shangazi for hair care tips between cuts"
- **Health Log (`lib/my_children/`):** Children's appointments link to child's record
- **Pharmacy:** "Bidhaa za baada ya mazoezi / Post-workout supplements" → Pharmacy
- **Shop:** "Bidhaa za nyumbani kwa [service] / Home kit for [service]" → Shop

### Research-informed enhancements (salon / hair_nails / skincare / fitness)

- **Hair-type taxonomy filter on customer rail**: ChoiceChip multi-select `1A 1B 1C 2A 2B 2C 3A 3B 3C 4A 4B 4C` + `Locs`, `Braids`, `Natural`, `Relaxed`. The 4C-specialist filter is a defining differentiator — most apps are texture-agnostic. *Pattern: StyleSeat.*
- **Service Variants UX** (covered in feature 1): partner picks "Box Braids" → variants small/medium/jumbo each with own price + duration. Customer picks variant in booking sheet. *Pattern: Booksy.*
- **Multi-staff bookings in one cart** (cut by Maria + nails by Asha) — booking sheet supports `slots[]: [{service_id, staff_id}]`. Single checkout. *Pattern: Fresha group bookings.*
- **"Any professional" vs specific staff toggle** at booking time. Default = "Any" with auto-assignment by load-balancing across qualified staff. *Pattern: Fresha, Vagaro.*
- **Pre-buffer + processing time + post-buffer** per service variant, configured by partner. Processing time during color development becomes a bookable slot for someone else — capacity multiplier. *Pattern: Square Appointments, Booksy.*
- **Travel buffer for mobile services** as a fixed per-appointment block, plus a separate **mobile-service surcharge** as its own line item (TZS 5,000–15,000 by distance band). Parking fees pass-through. After-hours surcharge (~TZS 20,000), holiday premium (~TZS 30,000) — all clearly labeled, never hidden. *Pattern: Glamsquad, Priv, Blys; Urban Company carries platform-level liability insurance for mobile pros — model worth replicating.*
- **Patch-test as a separate bookable service with dependency** for color, lash extensions, microblading. Main booking can't confirm without patch-test in last 30 days. Gates are stored as `service_dependencies(parent_service_id, prerequisite_service_id, valid_days)`. *Pattern: industry norm.*
- **Pre-appointment intake form auto-sent on booking** for skincare/spa: medical history, allergies, current products, photos. Allergy red flags surfaced at top of partner's appointment view. *Pattern: Pabau, Jotform integrations with Booksy.*
- **Skin-type quiz + AI selfie analysis** in `lib/skincare/`: 30-sec quiz outputs Baumann-style skin type and matches a routine; partner sees the result on the appointment view. *Pattern: La Roche-Posay MyRoutine.*
- **Loyalty stamps with progress bar** (1–15 stamps configurable per partner; expiry optional). Visible in customer app with progress visualization. *Pattern: Booksy Loyalty Cards.*
- **Prepaid bundle SKUs** (5-session bundles redeemable per session; reduces no-shows because customer has skin in the game). *Pattern: Booksy Packages.*
- **Auto-add waitlist (FIFO) and First-to-Claim SMS blast** as configurable per partner. First-to-Claim has higher fill rate per case studies; FIFO is fairer. *Pattern: Booksy auto-add, MindBody First-to-Claim.*
- **Cancellation policy tiers** displayed at booking and on confirmation:
  - Free cancel >24h
  - Partial fee 4–24h (50% of service price)
  - Full charge <4h or no-show
  *Pattern: Vagaro tiered enforcement, ClassPass 12-hr.*
- **Two-way SMS YES/NO confirmation** alongside push (pattern from §C). Reply NO triggers waitlist promotion immediately. *Pattern: Booksy, Schedulicity.*
- **Rebook cadence per service** configurable by partner ("cuts every 4–6 weeks", "color every 8–10 weeks", "facial every 4 weeks"). Used to schedule the rebook nudge push. *Pattern: Booksy, StyleSeat.*
- **Photo consent toggle on appointment** (covered in foundational §A; relevant here): customer chooses whether before/after may appear in partner's public portfolio. Default OFF for identifiable customer photos. *Pattern: GlossGenius.*
- **Recurring booking with daily/weekly/biweekly/monthly cadences** and `skip_week` for holidays. Auto-block on partner calendar. VIP standing-slot retention lever. *Pattern: Booksy.*

### Research-informed enhancements (fitness — class + 1:1 training)

- **Capacity-bounded class booking with waitlist** for group fitness — `class_sessions(id, partner_id, starts_at, capacity, booked_count, waitlist_capacity)`. *Pattern: MindBody, Mariana Tek, Glofox.*
- **Pick-a-spot floor plan** for reformer / cycling studios — customer picks bike #4 or reformer #2 from a visual grid; persists as "favorite spot" across recurring bookings. *Pattern: Mariana Tek.*
- **Drop-in vs membership distinction** — drop-in always costs more than membership-derived booking. Tiered credits per city/time/equipment if needed. *Pattern: ClassPass.*
- **Recurring training plans + check-ins** for 1:1 trainers — coach pushes weekly programming inside chat thread; client logs sets/reps/weight. *Pattern: Trainerize, TrueCoach, Future.*
- **Progress photos + body measurements + training journal** stored under customer's `lib/fitness/` profile (with photo consent toggle). Auto-graphs over time. *Pattern: TrueCoach, Trainerize.*
- **PR (personal record) auto-detection + celebration push**: "🏆 PR mpya! Squat 80kg / New PR! Squat 80kg" on entry. *Pattern: Trainerize, Future.*
- **Heart-rate live integration** via Bluetooth HRM / Apple Watch / Pixel Watch — real-time HR-zone overlay during live class, post-class breakdown. *Pattern: Peloton.*
- **Live + on-demand coexistence** — live class with leaderboard + recorded library viewable any time. *Pattern: Peloton.*

---

## 7. CONSULTATION — LAWYER / DOCTOR / BUSINESS

**Entry:** Customer side: `lib/legal_gpt/pages/book_legal_consultation_page.dart` / `lib/doctor/pages/book_medical_consultation_page.dart` / `lib/business/pages/book_business_consultation_page.dart` → after booking, status read from `lib/<vertical>/pages/consultation_status_page.dart` (per vertical). Partner side: unified inbox + `lib/tajirika/pages/consultation_detail_page.dart` (NDA-gated, partner-only — opens encrypted intake; partner submits follow-up notes / prescription here). Shared widgets `lib/tajirika/widgets/consultation_intake_form.dart` (rendered inside customer booking pages) and `lib/tajirika/widgets/nda_acceptance_gate.dart` are pulled by both sides.
**Stage/Context:** Customer needs confidential 1:1 advice. Skills: `legal`, `medical`, `nursing`, `pharmacy`, `accounting`, `taxAdvisory`, `businessConsulting`, `hrConsulting`, `careerCoaching`. Sensitive content; field-level encryption.

### User Journey (Customer)
1. Customer enters from a vertical home or Shangazi AI's "Talk to a real human" handoff.
2. Browse partners filtered by skill — see avatar, name, credentials, rating, base fee per 30 min.
3. Tap partner → `partner_profile_page.dart` → "Hifadhi Ushauri / Book Consultation".
4. Multi-step intake form `consultation_intake_form.dart`:
   - **Step 1 — NDA gate:** Plain-language NDA "Mahojiano haya ni ya siri. [Partner] hatashiriki habari yako bila ruhusa. / This consultation is confidential. [Partner] won't share your info without consent." → checkbox "Nakubali / I agree" + signature line.
   - **Step 2 — Mode:** in_person / phone / video
   - **Step 3 — Slot picker** (uses `partner_availability`)
   - **Step 4 — Duration:** 15 / 30 / 45 / 60 min (price scales)
   - **Step 5 — Intake summary:** TextArea (required, 50–2000 chars) "Eleza tatizo / Describe your case" — encrypted at rest
   - **Step 6 — Attachments:** Optional photos/PDFs (medical reports, contracts, payslips) — encrypted, stored under `consultations/attachments/`
   - **Step 7 — Total + payment hold:** Wallet pre-authorizes fee; held until `confirmed`
5. Customer taps "Hifadhi / Book" → `POST /consultations` → status `pending`.
6. Partner reviews intake, accepts → status `confirmed`; customer push "Mahojiano yamekubaliwa. Anza saa [time] / Consultation confirmed. Begins at [time]"
7. **At start time:**
   - For `video`: button "Jiunge / Join" launches WebRTC room (existing `lib/calls/` infra) with end-to-end encrypted signaling
   - For `phone`: tap-to-call button reveals partner's number (only at start time, not before)
   - For `in_person`: address shown; partner can mark `arrived`
8. Partner taps "Anza / Start" → `in_progress`.
9. After session, partner taps "Imeisha / Done" → `completed`. May attach `follow_up_notes` (encrypted, customer-only) and (for doctor) `prescription`.
10. Customer can review and (separately) request a follow-up.

### Special: Doctor Consultations
- Prescription field flows to `lib/pharmacy/` "Order this prescription" deep-link with medication names pre-filled
- Customer's `lib/my_children/` health log can auto-pull the diagnosis

### CRUD Operations
- **Create:** `POST /consultations` with encrypted intake fields
- **Read:** Both parties via authenticated endpoint that decrypts only for `partner_user_id` or `customer_user_id`. UNION exposes title + status + fee only — never intake content.
- **Edit:** **NOT AVAILABLE** for intake_summary post-submission (legal/medical record integrity). Partner can append `follow_up_notes` after `completed` via append-only endpoint.
- **Delete:** **NOT AVAILABLE** — `cancelled`/`rejected` only. Hard delete restricted to data-protection requests (right-to-erasure flow, separate ticket).

### Notifications & Reminders
- 🔔 **Reminder — Booking received:** Customer: "✅ Mahojiano yamewekwa. [Partner] atayasoma / Booking placed. [Partner] will review"
- 🔔 **Reminder — Confirmed:** Customer: "🩺 Mahojiano yamekubaliwa: [date] saa [time] kwa [mode] / Consultation confirmed: [date] at [time] via [mode]"
- 📅 **Reminder — 24h before:** "Kesho [time]: mahojiano na [partner] / Tomorrow at [time]: consultation with [partner]"
- 📅 **Reminder — 30 min before:** "Saa nusu: mahojiano na [partner]. Hakiki vifaa vyako / 30 min until consultation. Check your setup"
- 🔔 **Reminder — Join now:** At `starts_at`: "🟢 Jiunge sasa kwa mahojiano / Join now for your consultation"
- ⚠️ **Alert — Partner late (video):** 5 min into session, no `in_progress` flag: "[Partner] hajajiunga. Tuma ujumbe? / [Partner] hasn't joined. Send a message?"
- 🔔 **Reminder — Notes ready:** Customer: After `completed` with `follow_up_notes`: "📋 [Partner] ametuma maelezo ya mahojiano. Soma sasa / [Partner] sent follow-up notes. Read now"
- 🎉 **Celebration — Prescription ready (doctor):** "💊 Dawa zako ziko tayari kuagiza. Tuma kwa pharmacy? / Prescription ready. Send to pharmacy?"
- 💡 **Prompt — Follow-up suggestion:** Doctor: 7 days after a consultation: "Hali yako iko vipi? Mahojiano ya kufuatilia? / How are you feeling? Schedule a follow-up?"
- 📊 **Summary — Health spending:** Monthly: "Mwezi huu: mahojiano [X] ya afya, gharama TZS [Y] / This month: [X] health consultations, TZS [Y] spent"

### Reports & Insights
- **Customer health timeline (cross with `lib/my_children/health_log/`):** Consultations + prescriptions + follow-ups in one view
- **Customer legal log:** Past consultations + outcome status — exportable for case files
- **Partner stats:** Avg consultation duration vs paid duration (overrun pattern), repeat-customer rate, follow-up rate
- **Insurance utilization:** "Bima yako imelipa TZS [X] kati ya TZS [Y]. Bado ina TZS [Z] / Insurance has paid TZS [X] of TZS [Y]. TZS [Z] left in coverage"

### Cross-Module Connections
- **Doctor module (`lib/doctor/`):** Doctor consultations show inside `lib/doctor/` consultation list; medical record syncs to `lib/my_children/health_log` if patient is a child
- **Pharmacy:** Prescription → "Agiza dawa hizi / Order these meds" → `lib/pharmacy/` with pre-filled cart
- **Insurance:** "Wasilisha madai / Submit claim" after `completed` → `lib/insurance/` with consultation receipt + diagnosis
- **Calendar:** Confirmed consultations as calendar events with auto-reminders
- **Wallet:** Pre-auth on book, capture on `completed`. Refund on `cancelled` per policy
- **Budget:** `afya` (doctor/nursing/pharmacy), `kazi` (legal/business), `mafunzo` (career)
- **Chat:** Pre-consultation thread for clarifying questions (ends 15 min before slot to keep partner focused)
- **Shangazi AI:** "Ask Shangazi to summarize this consultation note" — passes follow-up notes (with customer consent) for plain-language summary
- **Family:** Family members can read shared health consultations if permission granted in `lib/my_family/`

### Research-informed enhancements (consultation)

- **Three-tier SKU** for any consultation skill: text/async chat (cheapest, e.g. TZS 5,000) → video (mid, TZS 25,000) → in-person (full, TZS 60,000). Same partner, three productized offerings — matches Tanzania's affordability spread. *Pattern: Practo three-tier consult, K Health monthly subscription.*
- **NHIF / AAR / Jubilee accepted as a hard filter** at customer search, not a soft one. Mirrors Zocdoc's insurance-first discovery. *Pattern: Zocdoc.*
- **Symptom checker with specialty mapping** — free-text "Inaumiza kifua" → predicted specialty "Cardiologist" before showing providers. Reduces specialty-knowledge burden on patients. *Pattern: Practo.*
- **Conversational AI triage** in chat UI for low-bandwidth context: chat-style symptom checker compares user data to a population health graph; severity routing recommends self-care / async chat / video / ER. *Pattern: K Health, Babylon Health — fits Swahili chat UI.*
- **Bilingual symptom + intent capture (Swahili/English) at parity** — non-negotiable. *Pattern: Vezeeta Arabic/English parity.*
- **Waiting-time badge** on each provider card in `lib/doctor/` ("Wastani: dakika 18 kusubiri / Avg wait: 18 min") derived from check-in data. Strong trust signal in markets with notorious clinic queues. *Pattern: Vezeeta.*
- **"Available today / tomorrow / this week" sort** as primary ranking signal, not a side filter. *Pattern: Doctolib first-available sort.*
- **Persistent customer health profile** with allergies, chronic conditions, past prescriptions, lab uploads — reused across every booking, not re-collected. *Pattern: Practo health profile, Vezeeta document vault.*
- **Pre-visit intake forms pushed at T-24h with reminder** — no-show rate drops measurably when completed. Specialty-specific intake (cardiology vs pediatrics vs derm) — different forms per specialty rather than one mega-form. *Pattern: Zocdoc, Mobihealth.*
- **K Health-style derm photo intake** with structured photo prompts ("affected area, well-lit, ruler if possible").
- **Pre-call mic/camera/bandwidth test** at the booking page, hours before the call. Reduces call-start failures on intermittent 3G. *Pattern: Doctor on Demand.*
- **Virtual waiting room** with provider photo + estimated wait; provider sees patient + intake summary on join. *Pattern: Amwell.*
- **Explicit consent screens** captured before video starts: location-of-residence, recording (off by default), prescription delivery. *Pattern: Teladoc.*
- **Screen-share for showing lab reports** during the call — patient shares lab PDF/photo, doctor annotates. *Pattern: Practo.*
- **Auto-generated visit notes + care plan delivered in-app immediately after** the call (not later). Patient never asks "what did the doctor say?". *Pattern: Babylon post-visit summary.*
- **eRx dispatch** — prescription sent to a chosen pharmacy or made redeemable via QR. Integrate with `lib/pharmacy/` networks; QR-redeemable codes for off-network pharmacies. *Pattern: Practo, Teladoc.*
- **Follow-up CTA pre-filled on visit summary** — "Hifadhi follow-up baada ya wiki 2 / Book follow-up in 14 days" — single tap re-books. *Pattern: industry standard.*
- **Condition-specific follow-up cadence:** diabetic 90-day, hypertension 30-day, post-op 7/14/30, antenatal monthly. Encode disease-specific automation. *Pattern: Maven Clinic, K Health.*
- **In-person flow extras** — clinic-authored "what to expect" + parking guidance, queue position display ("Wewe ni #4, dakika 22 / You're #4, ~22 min"), check-in QR at reception. *Pattern: Zocdoc, Vezeeta, Practo.*
- **SMS reminder + reply STOP/CONFIRM** as fallback for non-app users. *Pattern: Doctolib, Mediclinic.*
- **Conflict-of-interest check (legal)**: intake captures opposing party name; system flags conflicts before lawyer accepts. *Pattern: Avvo, Lexoo.*
- **NDA-on-intake auto-signed** before any document upload to legal/business consultations. *Pattern: Rocket Lawyer.*
- **Persistent privilege flag** on legal threads: UI label "Mawasiliano ya Wakili-Mteja / Attorney-Client Privileged Communication" never disappears from chat header. *Pattern: Lexoo, Avvo.*
- **Productized legal SKUs** — `Will TZS 80,000`, `Lease review TZS 60,000`, `Divorce filing TZS 200,000` — checklist-driven workflow rather than billable hours. *Pattern: LegalZoom flat-fee menu.*
- **Draft-generation + lawyer-review upsell**: customer fills wizard, gets draft, can pay extra for human review. Two-tier monetization. *Pattern: LawDepot, Rocket Lawyer.*
- **Pay-per-question (legal)** for one-off Q&A with optional follow-up window. *Pattern: JustAnswer.*
- **Retainer subscription** (legal/business): monthly fee includes documents + N attorney consultations. *Pattern: Rocket Lawyer subscription.*
- **HIPAA-grade architecture** — encryption at rest + in transit, audit logs of every record access. Tanzania equivalent: Personal Data Protection Act 2022. *Pattern: Teladoc, Amwell.*
- **Screenshot blocking** (`FLAG_SECURE`) on prescription, NDA-gated chat, ID upload screens. *Pattern: Practo.*
- **Consent receipts** — every data-share generates a logged, user-visible receipt. *Pattern: Maven.*
- **In-app data deletion path** with confirmation email. *Pattern: Babylon, Maven.*
- **Compliance verification with public badges:**
  - Doctor: MCT registration number + specialty board (cardio, gyno, etc.)
  - Lawyer: TLS bar admission + disciplinary history surfaced
  - Accountant/business: NBAA / TIN + business reg + insurance proof
  *Pattern: Practo / Vezeeta medical-license verification, Avvo bar lookup.*

---

## 8. ENGAGEMENT — LONG-RUNNING BUSINESS WORK

**Entry:** Customer browses business partners (`lib/business/pages/business_partners_page.dart`) → tap partner → opens partner profile → "Omba Pendekezo / Request Proposal" routes to chat. Partner sends proposal from `lib/tajirika/pages/propose_engagement_page.dart` (Tajirika home → "Pendekezo Mpya / New Proposal"). Customer reviews at `lib/business/pages/engagement_proposal_review_page.dart`. Once accepted, both parties open `lib/business/pages/engagement_workspace_page.dart` (shared workspace serving customer-business owner; partner deeplinks in via `lib/tajirika/pages/engagement_dashboard_page.dart` which embeds the same workspace widget).
**Stage/Context:** Customer hires accountant, tax advisor, business consultant, HR consultant, or career coach for ongoing work — not a one-shot consultation. Skills: `accounting`, `taxAdvisory`, `businessConsulting`, `hrConsulting`, `careerCoaching`.

### User Journey (Partner-driven proposal)
1. Partner opens Tajirika home → "Pendekezo Mpya / New Proposal" (or in-chat shortcut "Tengeneza Pendekezo" while messaging a prospect).
2. Form `lib/tajirika/pages/propose_engagement_page.dart`:
   - **Title** "e.g. Monthly bookkeeping for Mama Mboga"
   - **Scope brief** TextArea (required) — what's in scope, what's not, deliverables
   - **Pricing model** ChoiceChips: hourly / retainer / fixed
   - **Rate fields** (only the relevant one): hourly_rate_tzs, retainer_tzs (per month), fixed_total_tzs
   - **Start date** (date picker), **End date** (optional — null for open-ended)
   - **NDA toggle** — if confidential, attach NDA form
   - **Milestones** (optional, repeatable):
     - Milestone title, due_date, amount_tzs
3. Partner taps "Tuma / Send" → `POST /engagements` with status `proposed` → customer push "[Partner] amependekeza kazi: [title]. Soma na ujibu / [Partner] sent a proposal: [title]. Read and reply"
4. Customer opens `lib/business/pages/engagement_proposal_review_page.dart`:
   - Full scope brief + pricing + milestones table
   - Compare-with-market footer "Wenzio wenye [skill] hutoza TZS [X] / Other [skill] partners charge TZS [X]"
   - Action: "Kubali / Accept", "Pendekeza Mabadiliko / Counter-propose", "Kataa / Reject"
5. Counter-proposal opens edit form; partner sees diff and accepts/counters.
6. On accept → status `accepted` → customer pre-authorizes first invoice (retainer) or escrow (fixed).
7. Status flips `accepted` → `active` automatically on `start_date`.
8. Both parties access the shared workspace (customer from `lib/business/pages/engagement_workspace_page.dart`; partner from `lib/tajirika/pages/engagement_dashboard_page.dart` which embeds the same workspace widget):
   - **Milestones tab:** list with status badges (pending → submitted → approved → paid). Partner submits a milestone (deliverables + invoice URL); customer approves; payment captured.
   - **Time entries tab:** Partner logs time per day (date, minutes, description, billable). For hourly engagements, monthly invoice auto-rolls up billable minutes.
   - **Invoices tab:** Auto-generated per period (monthly for retainer, per-milestone for fixed, monthly for hourly).
   - **Files tab:** Shared encrypted attachments (financial statements, contracts).
   - **Chat tab:** Per-engagement thread.
9. Status transitions: `active` → `paused` (either party) → `active` again, OR → `ended` (graceful close), OR → `cancelled`.

### CRUD Operations
- **Create:** `POST /engagements`, `POST /engagements/{id}/milestones`, `POST /engagements/{id}/time-entries`
- **Read:** Workspace
- **Edit:** Scope brief and pricing model are locked after `accepted` — change requires "Sasisha Mkataba / Amend Contract" flow with both parties approving. Milestones can be added/edited only while `pending`/`active` and not yet submitted. Time entries editable until invoice generated.
- **Delete:** Time entries deletable while `active` and unbilled. Milestones not deletable after submitted (only `cancelled`). Engagement itself never deleted — `ended`/`cancelled`.

### Notifications & Reminders
- 🔔 **Reminder — Proposal received:** Customer: "📑 [Partner] amependekeza kazi: [title]. Soma / [Partner] sent a proposal: [title]"
- ⚠️ **Alert — Proposal expiring:** 7 days unread: "Pendekezo la [partner] linaisha kesho / [Partner]'s proposal expires tomorrow"
- 🎉 **Celebration — Engagement starts:** Customer + partner: "🎉 Kazi imeanza: [title]. Karibu kwa workspace / Engagement started: [title]. Welcome to the workspace"
- 🔔 **Reminder — Time-log nudge:** Partner, daily 6pm if no time entry today: "Saa za leo zimerekodiwa? / Logged today's hours?"
- 🔔 **Reminder — Milestone due:** 3 days before `due_date`: "[Milestone] inaisha siku 3 / [Milestone] due in 3 days"
- ⚠️ **Alert — Milestone overdue:** 1 day after `due_date` if not submitted: "[Milestone] imechelewa / [Milestone] is overdue"
- 🔔 **Reminder — Milestone submitted:** Customer: "📦 [Partner] amewasilisha [milestone]. Hakiki na ukubali / [Partner] submitted [milestone]. Review and approve"
- ⚠️ **Alert — Approval pending:** 3 days after `submitted`: "Milestone ya [partner] inasubiri jibu lako / [Partner]'s milestone awaiting your approval"
- 📊 **Summary — Monthly invoice:** Both: "Ankra ya [month]: TZS [X] kwa [hours] saa / Invoice for [month]: TZS [X] for [hours] hours"
- 🎉 **Celebration — Engagement complete:** "✅ Kazi imekamilika. Toa nyota na pendekeza? / Engagement complete. Rate and refer?"
- 💡 **Prompt — Renewal:** 14 days before `end_date`: "Kazi inaisha [date]. Endeleza? / Engagement ends [date]. Renew?"

### Reports & Insights
- **Engagement P&L (customer):** Total spent vs initial estimate, deviation %, milestone slippage chart
- **Engagement P&L (partner):** Hours logged vs billed, effective hourly rate, time-by-task heatmap
- **Cross-engagement portfolio (partner):** All active engagements with revenue projection, utilization %
- **Tax-readiness export:** Annual summary for TRA — total billings, expenses, withholding, net

### Cross-Module Connections
- **Wallet:** Each invoice triggers Wallet payment with escrow on fixed engagements
- **Budget:** `kazi` envelope (customer); income to partner's Tajirika earnings
- **COA/Accounting:** Each milestone payment writes journal lines `accounts_payable → professional_services_revenue`. Time entries write WIP balance.
- **Calendar:** Milestone due dates as events; recurring weekly check-ins as recurring events
- **Chat:** Per-engagement thread, plus all milestone/file activity auto-posts as system messages
- **Insurance:** "E&O insurance / Bima ya makosa" — for high-fixed engagements, prompt partner to attach proof
- **Documents:** All deliverables stored encrypted, exportable as zip on engagement close
- **Shangazi AI:** "Ask Shangazi to draft a scope statement" — for both sides; "Summarize this engagement's status" — quick recap
- **Career (cross with `lib/career/`):** `careerCoaching` engagements feed into customer's career timeline

### Research-informed enhancements (engagement)

- **Upwork-style escrow + milestone release** — client funds a milestone → work delivered → client approves → funds released. Dispute window with mediation if rejected. The gold-standard pattern. Add `engagement_milestones.escrow_status: unfunded | funded | submitted | approved | released | disputed`. *Pattern: Upwork — the only pattern that scales trust for freelance/consulting without prior relationship.*
- **Work Diary / time-tracker with screenshots** for hourly contracts — screenshots taken at random intervals; client only billed for tracked time. Builds trust on remote hourly work. New table `engagement_time_screenshots(time_entry_id, photo_url, taken_at)`. *Pattern: Upwork.*
- **Job Success Score** — outcome-weighted composite (long-term clients, completion rate, rejection rate, dispute count). Punishes contract abandonment. Visible to other clients but disputes hidden. *Pattern: Upwork.*
- **Length-of-relationship signal** ("Working with [client] since 2024", "5 repeat clients") on partner profile — durability beats raw rating. *Pattern: Honeybook, Upwork.*
- **Proposal → contract → invoice as one morphing object** in the same chat thread (same `engagements.id`). Proposal becomes contract on signature, contract becomes invoice on milestone completion. *Pattern: Honeybook — beautiful UX for solo consultants.*
- **Retainer subscription with hour ledger** for "retain me 10 hours/month" pattern — auto-recurring billing with monthly hour bucket; rolls or expires per partner config. *Pattern: Dubsado, Bonsai.*
- **Lead-credit model option** for low-margin verticals — partners pay credits (e.g. TZS 5,000 each) to unlock leads. Alternative to commission for consulting. *Pattern: Bark.com.*
- **AI hiring-brief generator** on the customer side — one-line goal ("I need a logo redesign") → AI drafts the structured engagement post (scope, deliverables, milestones, timeline, budget band). Lowers posting friction. *Pattern: Upwork AI job-post wizard.*
- **Optional portfolio for ranking, never required to publish.** Consultants can attach sample work or past-engagement summaries to their `lib/tajirika/skills/business` profile to lift their composite ranking score. Identity, bio, contact info are reused from the existing TAJIRI user profile — no separate consultant signup. *Pattern: Honeybook public profile reuses primary account.*
- **Three engagement contract types** at proposal time: `fixed_price` (milestones), `hourly` (time-tracker), `productized` (catalog SKU). Maps cleanly onto consulting work. *Pattern: Upwork contract types, Clarity.fm by-the-minute.*
- **Statement-of-work (SoW) templates** for senior consultants — RFP-style with structured fields (scope, deliverables, timeline, dependencies, payment schedule, IP terms). *Pattern: Catalant.*
- **Dispute window with platform mediation** — client rejects milestone → 7-day customer↔partner mediation chat → escalation to platform mediator → release decision based on submitted artefact + chat log. *Pattern: Upwork.*
- **Auto-recurring weekly invoice** on hourly contracts with billed-time summary; immediate dispute window. *Pattern: Upwork.*
- **Toptal-style talent matching layer** as an optional curated path: customer fills brief → human matchers + algorithmic shortlist deliver 3–5 candidates within 48h. Higher commission, no marketplace search. *Pattern: Toptal.* Implementation: feature flag, manual ops in v1.
- **Five-event milestone notification fan-out** to both sides: `milestone_funded` / `milestone_submitted` / `approved` / `changes_requested` / `released`. Push + email + WhatsApp on each. *Pattern: Upwork.*
- **Public profile pages** — single shareable URL per partner (`tajiri.com/p/asha-cakes`) with photo, intro video, services menu, package pricing, testimonials, response time. Pushed via WhatsApp. *Pattern: Honeybook public profile pages — fits Tanzania referral culture.*
- **Honeybook-style questionnaires bundled with contracts** — intake form auto-routes to contract template; same pattern for legal/accounting onboarding.

---

## 9. LISTING INQUIRY — REAL ESTATE

**Entry:** Customer side: `lib/housing/pages/housing_home_page.dart` → "Mali Inayouzwa / Properties for Sale" tab → `lib/housing/pages/property_listing_detail_page.dart` → "Uliza / Inquire" CTA → `lib/housing/pages/property_inquiry_page.dart`. Partner side: `lib/tajirika/pages/post_property_listing_page.dart` (post + manage listings) + `lib/tajirika/pages/incoming_property_inquiries_page.dart` (inquiry inbox per listing) + unified `customer_orders` inbox row.
**Stage/Context:** Customer browses property listings; requests viewing, makes offer, or asks question. Skills: `realEstate`, `propertyManagement`, `homeInspection`. Two tables: `property_listings` (public catalogue) + `listing_inquiries` (per-buyer thread).

### User Journey (Customer)
1. Customer browses housing home — list/grid of `property_listings` filterable by:
   - Region, district, ward
   - Listing kind: sale / rent
   - Price range
   - Bedrooms, bathrooms, area_sqm
   - Property type: apartment, house, land, office, shop
2. Tap card → `property_listing_detail_page.dart`:
   - Photo carousel
   - Title + price (formatted "TZS 250,000,000" or "TZS 800,000/mwezi")
   - Map view + neighborhood description
   - Stats grid: bedrooms, bathrooms, area, plot size
   - Amenities chips (parking, garden, security, water tank, generator, etc.)
   - Partner card (agent name, agency, license number, rating)
   - "Uliza / Inquire" + "Hifadhi / Save" + "Shiriki / Share"
3. Tap "Uliza / Inquire" → `property_inquiry_page.dart`:
   - **Inquiry kind:** ChoiceChips: "Ona / Viewing", "Toa Bei / Make Offer", "Uliza Swali / Ask Question"
   - **Message** TextArea
   - **Preferred viewing date** (only if kind = viewing)
   - **Offer price** (only if kind = offer; numeric, default to listing price)
4. Tap "Tuma / Send" → `POST /listing-inquiries` → status `pending`.
5. Partner receives notification, opens `lib/tajirika/pages/incoming_property_inquiries_page.dart`:
   - Per-listing tabs (multiple inquiries on one listing in one place)
   - Action: "Kubali / Acknowledge", "Panga / Schedule", "Toa Sababu / Reject"
6. **Viewing flow:** Partner taps "Panga" → confirms slot → status `scheduled` → customer push "[Partner] amepanga kuonana siku [date] saa [time]"
7. After viewing, partner taps "Imeona / Viewed" → `viewed`. Customer can "Toa Bei / Make Offer" from same thread → status `offer_made`.
8. **Offer flow:** Partner accepts/rejects/counters. Counter offer is a new inquiry row referencing the previous.
9. On accepted offer → status `accepted` → off-platform legal flow begins; system tracks transaction outcome via partner-marked `commission_recorded_at`.

### CRUD Operations
- **Listings (partner):**
  - **Create:** `lib/tajirika/pages/post_property_listing_page.dart` → `POST /property-listings`. Fields: title, description, photos (up to 12), all stats, amenities, location.
  - **Read (partner-side):** `lib/tajirika/pages/my_listings_page.dart` "Mali Zangu / My Listings"
  - **Read (customer-side):** Public catalogue at `lib/housing/pages/housing_home_page.dart`
  - **Edit:** Full update via `PATCH /property-listings/{id}` from `lib/tajirika/pages/post_property_listing_page.dart` (re-used as edit form) while `is_active=true`
  - **Delete:** Soft delete (`deleted_at`), removes from public; existing inquiries preserved
  - **Pause/Activate:** Toggle `is_active` from partner-side listing card
- **Inquiries:**
  - **Create:** `POST /listing-inquiries` (customer only)
  - **Read:** Both parties via thread + unified inbox
  - **Edit:** **NOT AVAILABLE** — append new inquiry instead (immutable history)
  - **Delete:** **NOT AVAILABLE** — `cancelled` only

### Notifications & Reminders
- 🔔 **Reminder — Inquiry received:** Customer: "✅ Swali lako limefika kwa [partner] / Your inquiry sent to [partner]"
- 🔔 **Reminder — Inquiry received:** Partner: "🏠 Swali jipya kuhusu [listing title] kutoka [customer] / New inquiry on [listing title] from [customer]"
- 🎉 **Celebration — Viewing scheduled:** Customer: "📅 Kuonana kumepangwa: [date] saa [time]. Anwani: [address] / Viewing scheduled: [date] at [time]. Address: [address]"
- 📅 **Reminder — Viewing 24h before:** Customer + partner
- 📅 **Reminder — Viewing 1h before:** Customer
- ⚠️ **Alert — Inquiry idle:** Partner, 24h after `pending`: "[X] maswali yanasubiri majibu / [X] inquiries awaiting your response"
- 🔔 **Reminder — Offer received:** Partner: "💰 Bei mpya: [customer] ametoa TZS [X] kwa [listing] / New offer: [customer] offered TZS [X] for [listing]"
- 💡 **Prompt — Price drop suggestion:** Listing with views >50, inquiries 0, age >30 days: "[Listing] imeonwa mara [X] bila ombi. Punguza bei? / [Listing] has [X] views with no inquiries. Lower price?"
- 📊 **Summary — Listing performance:** Weekly to partner: "[Listing]: views [X], inquiries [Y], saved [Z]"
- 🎉 **Celebration — Offer accepted:** Customer + partner: "🏆 Bei imekubaliwa! Anza utaratibu wa kisheria / Offer accepted! Begin legal process"

### Reports & Insights
- **Customer save list:** Saved properties + price history alerts when listings change
- **Customer comp report:** "Maeneo unayopenda / Areas you like — average price TZS [X], average price/sqm TZS [Y]"
- **Partner listing performance:** Views vs inquiries vs viewings vs offers funnel; per-listing conversion
- **Market data (anonymized aggregates):** Per ward, average price, days-on-market, accepted price vs listed price
- **Partner pipeline:** Inquiries by status, expected commissions

### Cross-Module Connections
- **Calendar:** Scheduled viewings as calendar events for both parties
- **Wallet:** Reservation deposit (optional), commission settlement on accepted offer
- **Budget:** Property is a major expense; integrates to `lib/budget/` long-term goal tracking
- **VICOBA/Kikoba:** "Hifadhi pamoja kwa nyumba / Save together for a house" — group savings link from listing detail
- **Loans (`lib/loans/`):** Mortgage / pre-qualification calculator on listing detail
- **Shop:** "Furnish your new home" — Shop with home-furniture filter on `accepted` status
- **Insurance:** "Bima ya nyumba / Home insurance" → `lib/insurance/` for new homeowners
- **Doctor:** **N/A**
- **Shangazi AI:** "Ask Shangazi about Kinondoni neighborhood" — passes ward/district for advice (schools, security, transit)
- **Community:** Neighborhood groups in `lib/community/` link from listing's ward

### Research-informed enhancements (real estate)

- **Photo-count gating + watermarking + photo verification** — listings with <4 original photos are deprioritized; AI similarity check against public stock libraries to suppress fake/copied listings; agent-branding watermark baked into every uploaded image (visible to buyer). *Pattern: Lamudi photo verification, Property24 watermarking.*
- **HDR / wide-angle / drone photo tiers** at upload time; "Drone shots" tagged separately and gated to "Premium" listing tier (fee or subscription). *Pattern: Zillow Listing Photographer service, Property24 premium drone gating.*
- **Floor plan upload accepted as image** (no CAD), shown in a separate carousel tab on detail page. *Pattern: Lamudi.*
- **Walk Score / Bike Score / Transit Score auto-resolution by address** — agent doesn't input it; the address resolves to neighborhood scores via API (or computed from `lib/community/` density + `lib/transport/` coverage). *Pattern: Realtor.com.*
- **Energy Performance Certificate (EPC) equivalent** — for premium long-term rentals, capture electricity/water reliability rating per ward as colored band. *Pattern: Zoopla / Rightmove EPC.*
- **Location obfuscation by default** — circle approximation shown on map until inquiry confirmed; exact pin revealed post-inquiry. Critical privacy pattern for Tanzania. *Pattern: Airbnb.*
- **Polygon "draw your own area" search** + commute-time isochrone filter ("show homes within 30 min by car/daladala from this address"). *Pattern: Redfin polygon, Rightmove draw-a-search.*
- **Filter chips at top** (Beds, Baths, Price, Property Type) collapse into a sticky bar when scrolling; "neighborhood lens" overlays crime-risk, school-rating, commute on the map. *Pattern: Trulia.*
- **List-first default on mobile** (data-saving for slow connections); map is a secondary tab. *Pattern: PropertyPro Africa, Property24 mobile.*
- **Save-search → daily email/push digest** with new matches; price-drop push within minutes of agent edit. *Pattern: 99acres, Zillow.*
- **Commute-time calculator on detail page** — enter work address, get isochrone overlay. *Pattern: Apartments.com.*
- **WhatsApp deep-link as primary contact CTA** alongside in-app chat — phone/email secondary. Critical for Tanzania referral culture. *Pattern: Lamudi.*
- **"Request a tour" with agent calendar slots** — date picker shows agent's actual `partner_availability` (feature 12) with 30-min slots; "Tour with another agent" auto-routes if listing agent is unresponsive >24h. *Pattern: Zillow Premier Agent rerouting.*
- **Pre-qualification soft-asked at inquiry** — move-in timeframe, financing status, working with agent y/n. Increases lead quality for the agent. *Pattern: Trulia, Realtor.com.*
- **3D Matterport tour + virtual open house** as premium upsell (paid by agent). Inline dollhouse view + measure tool; scheduled "virtual open house" events with multiple buyers in a Zoom-like room. *Pattern: Zillow 3D Home, Matterport.*
- **Open-house RSVP** as a separate flow (multi-buyer, public time slot) distinct from private tour booking. *Pattern: Realtor.com.*
- **"Back on market" alert** when a `pending` listing reverts to `active` (deal fell through) — high-conversion notification. *Pattern: Zillow signature feature.*
- **Pre-approval flow (long-term rental)** — landlord can pre-approve a guest before guest commits, reducing inquiry-to-booking friction. *Pattern: Airbnb long-term.*
- **"Similar home just listed" cross-sell** push when an inquiry doesn't convert. *Pattern: Realtor.com.*

---

## 10. EVENT BOOKING — TRAVEL / DJ / MC / SAFARI

**Entry:** Customer side: `lib/events/pages/events_home_page.dart` → tap a `partner_product` of cluster=events → `lib/events/pages/partner_product_detail_page.dart` (per-vertical, see feature 2) → "Hifadhi / Book" → `lib/events/pages/book_event_package_page.dart`; OR `lib/travel/pages/travel_home_page.dart` → "Hifadhi Safari / Book Safari" → `lib/travel/pages/book_safari_page.dart`. Partner side: package authoring uses `lib/tajirika/pages/post_partner_product_page.dart` (feature 1; pakeji = partner_product); booking inbox is unified `customer_orders` + `lib/tajirika/pages/event_booking_detail_page.dart` (with deposit + day-of timeline).
**Stage/Context:** Date-locked, deposit-required services. Skills: `tourGuide`, `travelAgent`, `safariOperator`, `djing`, `mc`. May tie to a `partner_product` package (the `package_id` FK).

### User Journey (Customer)
1. Customer scrolls events home → sees "Pakeji za Hafla" rail with packages.
2. Tap package → `partner_product_detail_page.dart` (feature 2 reuse).
3. Tap "Hifadhi / Book" → `book_event_package_page.dart`:
   - **Event title** (e.g. "Asha & John wedding")
   - **Event kind** ChoiceChips: wedding / birthday / safari / corporate / other
   - **Event date + time range** picker
   - **Event address** + map pin (or itinerary for safari)
   - **Party size** stepper
   - **Add-ons** (optional) — e.g. extra hours, extra equipment, transport
   - **Total + deposit** breakdown shown ("Jumla TZS [X], Hifadhi TZS [Y] (50%) sasa")
4. Customer taps "Hifadhi Tarehe / Lock the Date" → `POST /event-bookings` → status `pending` → partner notified.
5. Partner accepts → status `held` (soft hold for 48h, default) → customer push "[Partner] amehifadhi tarehe yako. Lipa amana saa 48 / [Partner] held your date. Pay deposit within 48h"
6. Customer taps "Lipa Amana / Pay Deposit" → Wallet flow → on success status `deposit_paid` → confirmed.
7. Status `confirmed` until `event_starts_at`, when it auto-flips to `day_of`. Day-of: partner + customer can chat in-app, share live updates.
8. After event, partner taps "Imekamilika / Done" → `completed`; balance auto-charged from Wallet (or invoice for off-platform balance settle).
9. **Hold timeout:** if deposit not paid in 48h → `held` → `cancelled`; date released.

### Travel/Safari Variant
1. `book_safari_page.dart` adds itinerary builder:
   - Day-by-day rows: location, activity, accommodation, included meals
   - Inclusions/exclusions checklist
   - Travelers list (name, NIDA/passport — encrypted)
2. Status flow same as events.
3. Notification timeline includes "Tayari kwa safari kesho / Ready for safari tomorrow" with packing checklist.

### CRUD Operations
- **Create:** `POST /event-bookings`
- **Read:** Both via UNION + dedicated detail page with full timeline
- **Edit:** Customer can edit add-ons until `confirmed`. After `confirmed`, changes need partner approval (re-quote flow). Date change → cancel + re-book.
- **Delete:** **NOT AVAILABLE** — `cancelled` with refund per partner's policy (typically: full refund >30 days out, 50% within 14 days, 0% within 7 days)

### Notifications & Reminders
- 🔔 **Reminder — Booking placed:** "✅ Tarehe imewekwa kwa [partner]. Subiri kuhakikisha / Date placed with [partner]. Awaiting confirmation"
- 🔔 **Reminder — Date held:** "[Partner] amehifadhi [date]. Lipa amana TZS [X] saa 48 / [Partner] held [date]. Pay TZS [X] deposit within 48h"
- ⚠️ **Alert — Deposit due in 12h:** "Tahadhari: amana inahitajika kabla ya saa [time] / Deposit due before [time]"
- ⚠️ **Alert — Hold expired:** "Hifadhi imekwisha. Tarehe iko huru / Hold expired. Date released"
- 🎉 **Celebration — Confirmed:** "🎉 Hafla imekubaliwa! [Date] saa [time] / Event confirmed! [Date] at [time]"
- 📅 **Reminder — 30 days before:** "Mwezi mmoja kabla ya [event title]. Lipa salio? / 1 month before [event title]. Pay balance?"
- 📅 **Reminder — 7 days before:** Both parties: "Wiki moja kabla ya [event title]. Hakiki orodha / 1 week before [event title]. Confirm checklist"
- 📅 **Reminder — 24h before:** Both: with packing/setup checklist
- 🔔 **Reminder — Day of:** Morning of: "Leo ni siku ya [event title]! Mafanikio / Today's the day for [event title]! Good luck"
- 🎉 **Celebration — Completed:** "💃 [Event title] imekamilika! Toa nyota / [Event title] complete! Rate"
- 💡 **Prompt — Future booking:** Customer, 6 months after a wedding-related booking: "Tukio lako linakuja? / Got another event coming?"

### Reports & Insights
- **Customer event log:** All past events with photos, costs, partners — emotional + financial archive
- **Partner pipeline:** Calendar view of `held` + `confirmed` events, capacity utilization (so partner can avoid double-booking adjacent events)
- **Cancellation analysis:** Partner: cancellation rate, reasons word cloud, refund total
- **Seasonality heat map:** Partner sees which months are busiest — can adjust pricing or offer discounts
- **Pre-event checklist completion:** % of items checked, flags missing items 7 days out

### Cross-Module Connections
- **Calendar:** Confirmed event creates calendar block (entire event window) with reminders at 30d/7d/1d/0d
- **Wallet:** Deposit + balance flow; refunds per cancellation policy
- **Budget:** `tukio` (events) envelope for customer; income for partner
- **Family:** Multi-traveler safari → traveler list pulled from `lib/my_family/`
- **Insurance:** "Bima ya kusafiri / Travel insurance" → `lib/insurance/` for safaris and weddings
- **Photos/Community:** Auto-create event album on `confirmed`; post-event share template
- **Shop:** "Vifaa vya hafla / Event supplies" — decor, candles, tents — Shop deeplink with event-kind filter
- **Wedding planner cross:** If event_kind = wedding, link to `lib/events/wedding_planner_page.dart` for full multi-vendor coordination
- **Shangazi AI:** "Ask Shangazi about wedding budgets in Tanzania" — pre-booking advice
- **Career:** Travel for tourGuide / safariOperator partners feeds into Tajirika earnings + tax record

### Research-informed enhancements (events / travel)

- **GigSalad-style quote-bidding broadcast** as a third entry option alongside browsing packages: customer posts an event brief (date, location, guest count, budget band, vibe tags) → platform notifies matching partners in radius → partners send quotes within 24–48h → customer reviews quotes side-by-side with each partner's video reel and reviews → message thread per quote → select → contract → deposit. Customer never sees partner contact details until booking confirmed (platform protects against disintermediation). *Pattern: GigSalad, The Bash — maps directly to TAJIRI's event_booking model.*
- **Travel radius slider with auto-pricing per km** for DJ/MC/photography — base rate within 30km, +TZS X/km after; partner sets a "willing to travel up to" cap. Clearly displayed at customer booking. *Pattern: GigSalad.*
- **Package builder with add-ons** (DJ + sound + lights + extra hour + photo booth + fog machine), each priced individually. `partner_products.add_ons[] {label, price_tzs, duration_minutes}`. *Pattern: GigSalad packages, Booksy add-ons.*
- **Refund policy tiers as standard contract terms:**
  - Full refund 60+ days out
  - 50% refund 30–60 days
  - 0% refund <30 days
  *Plus force-majeure clauses (weather, government restriction) added post-COVID — reschedule without penalty. Display these tiers as expandable card on booking. Pattern: GigSalad / The Bash industry default.*
- **50% deposit at booking + balance due 14 days pre-event or day-of** as default schedule (partner-configurable per package). Two payment-due notifications: T-14d ("Balance ya TZS [X] inadaiwa") and T-1d. *Pattern: GigSalad, The Bash.*
- **Backup-performer guarantee** — if booked partner cancels last-minute (<7 days), platform auto-sources replacement of equal or higher tier; sponsored by platform reputation fund (max payout TZS 200k). Marketed prominently as trust signal. *Pattern: The Bash GigMasters Guarantee.*
- **Auto-generated contract from package selection** with both parties e-signing in-app. Contract bundles: package, add-ons, schedule, cancellation tiers, force-majeure, IP / photo-rights. *Pattern: WeddingWire, The Knot, Honeybook.*
- **Song-request / do-not-play form** sent to DJ pre-event; sample setlist visible on partner profile. *Pattern: The Bash.*
- **"Real Events" social-proof gallery** — couples/customers post their actual event with partner tags, becoming social proof for those partners. Auto-prompted post-event with photo upload nudge. *Pattern: The Knot Real Weddings.*
- **Day-by-day itinerary card layout for safari/multi-day tours**: Day 1: arrive Arusha → Day 2: Lake Manyara → Day 3: Serengeti — with included/excluded explicit per day (park fees in/out, tips, visas). *Pattern: SafariBookings, Intrepid Travel.*
- **TALA license badge required on every safari/tour-operator listing** (Tanzania Tourist Agents Licensing Authority); insurance certificate uploaded and verified — both displayed publicly. *Pattern: SafariBookings.*
- **Migration-season pricing overlay** on safari listings — peak (July–Oct), shoulder, low (April–May green season) — calendar with per-month price band visible. *Pattern: SafariBookings wildebeest migration calendar.*
- **Tier offerings on multi-day packages** (Basix / Original / Comfort / Premium): same itinerary, different accommodation grade. *Pattern: Intrepid, Tourradar.*
- **QR-voucher confirmation** on shorter tours / day trips: scanned at venue/pickup. Strong instant-confirmation UX. *Pattern: Klook, KKday.*
- **Multi-traveler intake** at booking — name, passport (number, expiry, nationality), dietary restrictions, medical conditions, emergency contact for each traveler. Stored encrypted. *Pattern: Tourradar, Intrepid.*
- **Payment plan**: 20–30% deposit at booking, balance 60–90 days pre-departure. *Pattern: SafariBookings standard.*
- **Travel insurance upsell** at checkout via `lib/insurance/` (World Nomads-equivalent partnership). *Pattern: GetYourGuide cross-sell.*
- **Trip-prep checklist push** at T-30d, T-14d, T-7d — visa, vaccinations (yellow fever for Tanzania), packing list, currency tip. *Pattern: Intrepid, Tourradar.*
- **Day-before reminder** — pickup point + time, guide name + photo + phone, weather forecast for area. *Pattern: industry standard.*
- **On-tour live updates** — `lib/travel/pages/my_trip_page.dart` timeline with in-app messaging with guide. *Pattern: Tourradar MyTrip.*
- **Per-stop reviews** on multi-day tours, not just a single tour-level review. Customer rates each lodge / each park visit. *Pattern: SafariBookings, TripAdvisor.*
- **Last-minute discount auto-applied** if event/tour starts <48h from booking with empty seats (10–30% off, fills empty seats). *Pattern: GetYourGuide.*
- **Group discount tiered** (5% for 4+ travelers, 10% for 8+). *Pattern: Tourradar.*
- **Early-bird discount** (book 12+ months out for 10% off — applies to wedding-season packages). *Pattern: Intrepid.*
- **Promo-code infrastructure** at platform level (TZS off, %, free upgrade). *Pattern: GetYourGuide, Klook.*
- **Mobile-money-first payment** (M-Pesa, Tigo Pesa, Airtel Money) as primary; card secondary. *Pattern: Jumia Travel — essential in Tanzania.*

---

## 11. PARTNER REVIEWS

**Entry:** Customer side: from any completed order's customer detail page (per-vertical) → "Toa Nyota / Rate" CTA → `lib/customer_orders/pages/rate_partner_page.dart` (shared customer page since reviews span all sources). Partner side: read-only aggregated view on `lib/tajirika/pages/partner_profile_page.dart` (own profile) and review-management at `lib/tajirika/pages/my_reviews_page.dart` (where partner can post one public reply per review).
**Stage/Context:** Cross-cutting — reviews land on `partner_reviews` shared table, scoped per `(source, source_id)`. Writable only when order is in terminal positive state. v1 default: one-way (customer rates partner). Two-way deferred (Part E.6).

### User Journey
1. After an order completes (any of features 2/4/5/6/7/8/9/10), customer sees push "Toa nyota kwa [partner]" + in-app card on `customer_order_detail_page.dart`.
2. Tap card → `lib/customer_orders/pages/rate_partner_page.dart`:
   - **Stars** (1–5, required)
   - **Comment** TextArea (optional, max 500 chars)
   - **Tags** (multi-select positive/negative chips, e.g. "On time", "Friendly", "Quality work", "Price fair", "Late", "Communication", "Cleanliness")
   - **Anonymous toggle** (default OFF; if ON, name shown as "Customer")
3. Tap "Tuma / Submit" → `POST /partner-reviews` (idempotent on `(source, source_id, reviewer_user_id)` unique key).
4. Partner notified "Umepata nyota [N] kutoka [customer] kwa [item title]"
5. Partner can post **one** public reply per review from `lib/tajirika/pages/my_reviews_page.dart`.
6. Reviews visible on partner's `lib/tajirika/pages/partner_profile_page.dart` (and the same page used as a public partner profile when opened by buyers from a vertical) with filter by source/skill, recency sort, and anonymized aggregates.

### CRUD Operations
- **Create:** `POST /partner-reviews` once per order. Locked after submission.
- **Read:** Partner profile + each order detail.
- **Edit:** Within 24h only — `PATCH /partner-reviews/{id}`. After 24h, immutable to preserve trust.
- **Delete:** **NOT AVAILABLE** to user; admin-only via reports flow (offensive content, fake reviews — handled server-side, no Flutter admin UI per `feedback_admin_actions_are_backend_only`).

### Notifications & Reminders
- 🔔 **Reminder — Rate the partner:** Customer, on `completed`: "🌟 Toa nyota kwa [partner] kwa [item title] / Rate [partner] for [item title]" + 24h follow-up if not done
- 💡 **Prompt — Re-prompt at 7d:** "Bado hujatoa nyota? Maoni yako yanasaidia wengine / Haven't rated yet? Your review helps others"
- 🎉 **Celebration — 5-star streak (partner):** When partner gets 5 consecutive 5-star reviews: "🏆 Mfululizo wa nyota tano! Pongezi / 5-star streak!"
- ⚠️ **Alert — Low rating (partner):** When new review is ≤2: "⭐ Nyota mbili kutoka [customer]. Soma maoni na ujifunze / 2-star review from [customer]. Read and learn"
- 📊 **Summary — Monthly rating digest (partner):** "Mwezi huu: nyota [X.X], maoni [Y]. Kuongezeka kwa [Z] kuliko mwezi uliopita / This month: [X.X] stars, [Y] reviews. [Z] vs last month"

### Reports & Insights
- **Aggregate rating:** Partner profile shows average star + count + distribution histogram + per-source breakdown
- **Tag cloud:** Most-used positive vs negative tags
- **Trend chart:** 30/60/90 day rating moving average
- **Comparison:** "Cheo chako kwa wenzio wa [skill]: top [N]% / Your rank vs [skill] peers: top [N]%"
- **Review velocity:** Reviews per completed order — flags partners with low review-collection rate to prompt customers

### Cross-Module Connections
- **Tajirika profile:** Rating feeds into partner's discovery score (higher rating = higher in rails)
- **Search:** Search results boost high-rated partners
- **Chat:** "Wasiliana na [partner]" if customer's review is mid-tier (3 stars) — give them a chance to respond before public posting (anti-trolling cushion)
- **Shangazi AI:** "Ask Shangazi to summarize my recent reviews" — partner-side; "Help me write a balanced review" — customer-side
- **Community:** Top-rated partners surface in cluster community feeds

### Research-informed enhancements (reviews)

- **Multi-dimensional rating, not single star** — capture per-aspect scores rather than collapsing everything to one number. Per-source aspects:
  - Food: taste, portion, packaging, on-time
  - Mafundi: quality, price-fairness, cleanliness, on-time
  - Doctor: bedside manner, wait time accuracy, "Did the treatment help?", clarity of explanation
  - Hair/skincare: result vs expectation, hygiene, communication
  - Engagement: communication, deliverable quality, on-time milestones, would re-hire
  *Pattern: Practo / Vezeeta multi-dimensional outcome rating, Uber Eats per-item thumbs.*
- **Per-item thumbs up/down + global star** for orders with multiple line items (food orders with 4 dishes, salon with cut+color+nails). Partner sees per-dish/per-service sentiment in dashboard. *Pattern: Uber Eats Manager.*
- **New vs returning customer flag on each review** — partners weigh feedback differently when they see "first-time buyer" vs "12 prior orders". Display visibly on review card. *Pattern: Uber Eats Manager.*
- **Review weighting by recency** — last 6–12 months weighted heavier than lifetime when computing partner ranking. Combats "old 5-stars carrying lazy partners". *Pattern: Angi, Thumbtack.*
- **7-day partner response window** — partner can post one public reply per review within 7 days of posting. Lifts customer return-rate by ~23% per Uber Eats data. Optional discount-offer affordance ("Toa pungufu ya 10% kwa oda ijayo / Offer 10% off next order") attached to a reply. *Pattern: Uber Eats Manager response.*
- **Photo + video reviews** with verified-booking badge — only customers who completed a real order can post; eliminates competitor-sabotage fake reviews. Photo reviews mandatory for ≤2 star reviews to reduce frivolous complaints. *Pattern: Airbnb, Viator, Zomato.*
- **Helpfulness vote** ("Maoni haya yalikusaidia? / Was this review helpful?") drives sort order. *Pattern: TripAdvisor.*
- **Length-of-relationship signal** auto-rendered ("12 prior orders with this partner", "Working together since 2024"). *Pattern: Honeybook, Upwork.*
- **Avvo-style peer endorsements** for legal/medical/business-consulting partners — other verified partners can endorse a peer's expertise; community-graph signal distinct from customer reviews. Visible separately on profile. *Pattern: Avvo peer endorsements.*
- **Job Success Score (engagement-only)** as a reputation overlay (covered in feature 8) — outcome-weighted, hides dispute counts from customers but uses them in ranking. *Pattern: Upwork.*
- **Disease-specific outcome tracking (medical only)** — for chronic-condition follow-ups, ask the customer "Hali yako imeboresha? Imezidi? / Has your condition improved?" 14/30 days post-consult. Drives a separate "Outcome Score" alongside star rating. *Pattern: Maven Clinic outcome tracking.*
- **AI-generated review summary** on partner profile ("Wateja wengi husifia ladha na uharaka. Wachache wanasema usafiri ulichelewa / Most customers praise taste and speed. A few mention late delivery") — auto-generated weekly from last 30d reviews. *Pattern: emerging on Booking.com / Amazon.*
- **Anti-troll cushion** (already in doc) — for 3-star reviews, encourage chat first; for ≤2-star, mandatory photo evidence to publish. *Pattern: industry hybrid.*
- **Verified-booking-only enforcement** — review write-row fails if `customer_orders.status != 'completed'`. *Pattern: Airbnb, Viator.*

---

## 12. PARTNER AVAILABILITY MANAGEMENT

**Entry:** Partner side: Tajirika home → "Muda Wangu / My Availability" → `lib/tajirika/pages/manage_availability_page.dart`. Affects appointments (feature 6), consultations (feature 7), event bookings (feature 10). Customer-side slot picker is a read-only render of the same data via `lib/tajirika/widgets/slot_picker.dart` embedded in each vertical's booking page.
**Stage/Context:** Partners offering time-slotted services need to publish weekly hours and set blackouts. Drives the slot picker shown to customers.

### User Journey
1. Partner taps "Muda Wangu" tile.
2. **Skill scope picker** at top (only when partner has 2+ time-slotted skills): "Kawaida / Default" + per-skill chips (e.g. "🎂 Baking" + "🪚 Carpentry"). The Default scope applies to any skill that doesn't have its own schedule. Per-skill scope overrides Default for that skill only. Reason: a baker-carpenter is happy to take cake orders any time but only does carpentry Tue–Thu mornings; they need separate weekly hours per skill, not a single calendar.
3. `lib/tajirika/pages/manage_availability_page.dart` two tabs: **Weekly hours** + **Blackouts**, both scoped to the selected skill (or Default).
4. **Weekly hours tab:**
   - 7 day rows (Mon–Sun)
   - Each row: ON/OFF toggle, `open_time` picker, `close_time` picker, `slot_minutes` dropdown (15/30/45/60). `slot_minutes` is per-skill because cake consultations need 60 min while a pickup confirmation only needs 15.
   - Save button per row → `POST /partner-availability` with `skill_category` from the scope picker (or null for Default)
5. **Blackouts tab:**
   - List of upcoming blackouts (date range + reason + skill badge if scoped)
   - + FAB → "Ongeza Likizo / Add Blackout":
     - **Start** (date+time), **End** (date+time)
     - **Reason** (optional, e.g. "Likizo ya familia")
     - **All day** toggle
     - **Apply to** ChoiceChips (multi-skill only): "Kazi zote / All skills" (default — full block) or specific skills (e.g. only carpentry — partner can still bake during the blackout). Family-vacation blackouts use "all skills"; trade-show absences for carpentry alone use the specific scope.
   - Tap row → edit; long-press → delete
6. **Auto-blackout for accepted appointments/consultations/events:** server marks the slot range busy automatically; partner sees them in grey on the slot picker but cannot edit them as blackouts (they're real bookings).
7. **Recurring blackout** option: e.g. "Kila Jumapili / Every Sunday" without setting individual dates.
8. **Save → Live update:** Customer-facing slot picker refreshes via `LiveUpdateService` so blocked slots disappear immediately. The customer slot picker for "Useremala" only respects carpentry hours + carpentry blackouts; the picker for "Mkate" only respects baking hours + baking blackouts. Both inherit the "all skills" blackout (e.g. family vacation hides slots in both pickers).

### CRUD Operations
- **Create:**
  - Weekly hours: `POST /partner-availability` (one row per `(weekday, skill_category|null)`); the `skill_category` column is added to the existing `partner_availability` table from spec B.3
  - Blackouts: `POST /partner-blackouts` with optional `skill_categories JSONB` (array of skill names; null = applies to all)
- **Read:** Partner's own + customer-facing slot picker (read-only filtered view, scoped to the skill_category being booked)
- **Edit:** Both updatable; weekly hours change applies forward (existing accepted appointments preserved)
- **Delete:** Blackouts deletable (only future-dated ones); weekly hours rows toggled OFF (not deleted) to preserve history

### Notifications & Reminders
- 🔔 **Reminder — Set hours first time:** New partner, 24h after registration: "Weka muda wako wa kazi ili wateja waone slot zako / Set your hours so customers see your slots"
- 🎉 **Celebration — First booking after publishing hours:** "Kazi! Mteja wa kwanza amehifadhi slot / Nice! First customer booked a slot"
- ⚠️ **Alert — Blackout overlap:** When adding a blackout that overlaps confirmed bookings: dialog "Una hifadhi [X] ndani ya muda huu. Ghairi kwanza? / You have [X] bookings in this window. Cancel them first?"
- 💡 **Prompt — Extend hours:** If partner is fully booked 3 days running: "Slot zako zote zimejaa. Ongeza saa? / All slots booked. Extend hours?"
- 💡 **Prompt — Reduce hours:** If utilization <20% for 14 days: "Wateja wachache. Punguza saa? / Few customers. Reduce hours?"
- 📊 **Summary — Weekly utilization:** Sunday: "Wiki hii: matumizi [X]% (slot [Y] kati ya [Z]) / This week: [X]% utilization ([Y] of [Z] slots)"

### Reports & Insights
- **Utilization heatmap:** Day × hour grid showing % of times each slot was booked over last 30/90 days
- **Peak vs trough analysis:** "Slot zako zinazohitajika zaidi: Jumamosi 10am–12pm / Most-demanded: Saturday 10am–12pm"
- **Blackout impact:** "Likizo zako za mwezi huu zimekupotezea TZS [X] / This month's blackouts cost ~TZS [X] in potential revenue"
- **Slot length tuning:** "Mahojiano yako halisi ni dakika [X], lakini umetenga [Y]. Sasisha? / Your actual sessions average [X] min, but slots are [Y]. Update?"

### Cross-Module Connections
- **Calendar:** Each weekly-hours row creates recurring calendar block (rest days are off); blackouts as one-off events
- **Appointments / Consultations / Event Bookings:** Drive the slot picker UI (`lib/tajirika/widgets/slot_picker.dart`)
- **Tajirika profile:** "Hours" displayed publicly (e.g. "Mon–Fri 9am–6pm")
- **Family:** "Likizo ya familia / Family vacation" auto-blocks based on `lib/my_family/` shared trips
- **Shangazi AI:** "Ask Shangazi about my pricing strategy for peak hours" — passes utilization data
- **Notifications/FCM:** All slot changes broadcast via Firestore so customer slot pickers stay current

### Research-informed enhancements (availability)

- **Configurable reminder timing options** for confirmation reminders: 1 / 2 / 4 / 8 / 24 / 48 / 72 hours pre-slot, partner-selected per service. Push for app users, SMS for non-app — with two-way YES/NO reply. *Pattern: Schedulicity 1/2/4/8/24/48/72-hour options, Booksy reminders.*
- **Partner-side schedule reminder push at T-2hr** for scheduled (non-ASAP) orders so prep starts on time. Critical for home cooks who batch-cook. *Pattern: Zomato Scheduled Order partner reminder.*
- **Booking lead time + horizon configuration** per service: minimum notice (immediate to 2 weeks) and maximum advance window (e.g. 3 months). Prevents 5-minute-from-now bookings the partner can't honour or year-out speculative holds. *Pattern: Fresha online-bookings settings.*
- **Buffer / processing time / travel time configuration per service** (covered in feature 6 enhancements; relevant here): pre-buffer + post-buffer + processing time fields on `services` table. *Pattern: Square Appointments, Booksy.*
- **Peak / shoulder / low season pricing overlay** as part of availability (not just events): hair on Friday afternoon priced higher than Tuesday morning; safari July–Oct vs April–May. Stored as `availability_pricing_modifiers(weekday, hour_band, multiplier)`. *Pattern: SafariBookings, Airbnb dynamic pricing.*
- **Last-minute discount auto-applied if slot empty <48h** (configurable per partner): system marks the slot with -10% to -30% to fill empty seats. Customer sees "🔥 Slot ya bei nafuu / Last-minute deal". *Pattern: GetYourGuide.*
- **Recurring schedule with skip-week** for holidays / Ramadan / school terms — partner can pre-set a summer break or skip Eid; remainder of recurring series stays intact. *Pattern: Booksy recurring + skip-week.*
- **VIP standing-slot reservation** — partner can grant a specific repeat customer a "VIP" tag that holds their preferred recurring slot before public booking opens each week. Pattern: high-end salon retention.
- **Auto-add waitlist (FIFO) vs First-to-Claim SMS blast** as configurable per partner. First-to-Claim has higher fill rate per case studies; FIFO is fairer. *Pattern: Booksy auto-add, MindBody First-to-Claim.*
- **"Any professional" auto-assignment** for multi-staff partners — when customer books "Any" instead of a specific staff, system load-balances among qualified staff with travel-time + skill-fit weighting. *Pattern: Fresha.*
- **Two-week booking horizon for fitness classes** with auto-add waitlist when full. *Pattern: MindBody.*
- **Pick-a-spot floor plan** for studio-based fitness (covered in feature 6) — bike #4 / reformer #2 grid persists as "favorite spot". *Pattern: Mariana Tek.*

---

## 13. MULTI-SKILL PARTNER HUB

**Entry:** Tajirika home (`lib/tajirika/pages/tajirika_home_page.dart`) — top of page when partner has 2+ registered skills. Skill management at `lib/tajirika/pages/manage_skills_page.dart`. Per-skill identity at `lib/tajirika/pages/skill_persona_page.dart`.
**Stage/Context:** Partners frequently combine skills — a stay-home mom is often a baker AND a tailor; a fundi is often plumbing AND solar; a business consultant is often accounting AND tax. Tajirika treats each skill as a **persona**: a distinct customer-facing identity (display name, photo, bio, pricing band, hours, tags) under one underlying user account. This feature is the hub that lets the partner switch personas, see cross-persona aggregates, and configure per-skill identity.

**Worked example throughout this feature:** Asha is registered as both `baking` and `carpentry`. Buyers in `lib/food/` see "Asha's Cakes 🎂" with Saturday-only hours and TZS 25k–80k cakes. Buyers in `lib/mafundi/` see "Asha Furniture Works 🪚" with Tue–Thu morning hours and TZS 200k–600k builds. To Asha, both are accessible from one Tajirika app under one login.

### User Journey
1. Asha opens the app → Tajirika home loads.
2. **Skill switcher** — horizontal pill row at the top of `tajirika_home_page.dart` (only renders when `partner.skills.length > 1`):
   - "Zote / All" (default — aggregated dashboard view)
   - "🎂 Baking"
   - "🪚 Carpentry"
   - "+ Ongeza / Add" — opens `manage_skills_page.dart`
3. **All-skills view (default):**
   - Cross-persona stats card: total revenue this month, total orders this month, average rating across all sources, total active customers, response time
   - Per-skill mini-cards (one per skill): pending orders, today's revenue, slot utilization
   - Tap a per-skill card → switches the active scope to that skill and refreshes the home page
   - Activity feed mixes orders from all skills with skill badges per row
4. **Per-skill view (e.g. "Baking" selected):**
   - Header swaps to that persona's display name + photo + skill icon
   - All tiles below ("Bidhaa Zangu / My Products", "Oda Zangu / My Orders", "Muda Wangu / My Hours", "Hakiki Zangu / My Reviews") filter their data to `skill_category = 'baking'`
   - Posting CTA changes from generic "Post Bidhaa" to "Post Keki Mpya / Post New Cake"
   - Notifications surface a banner: "Sasa unaona shughuli za 🎂 Baking pekee. Bofya Zote uone vyote / Showing only 🎂 Baking. Tap All to see everything"
5. **Skill management (`manage_skills_page.dart`):**
   - List of all registered skills with status badge (Active / Paused / Pending verification for regulated skills like `legal`/`medical`)
   - + FAB → "Ongeza Ujuzi / Add Skill" → searchable picker over `SkillCategory` enum → registration form (different per cluster — regulated skills require credential upload)
   - Tap a skill → opens `skill_persona_page.dart`
   - Long-press → "Sitisha / Pause" (hides from customer search, in-flight orders unaffected) or "Ondoa / Remove" (only allowed if zero active/historical orders for that skill)
6. **Skill persona configuration (`skill_persona_page.dart`):**
   - Display name override (default: partner's legal name + skill — Asha → "Asha's Cakes" / "Asha Furniture Works")
   - Profile photo override (cake on plate vs sawdust workshop — Asha picks two different photos)
   - Bio (markdown, 200 chars) — different bios for different personas
   - Pricing band hint shown to customers ("TZS 25k–80k") — auto-derived from posted products but partner can override
   - Tag preset (locks the suggested tag list — see Feature 1)
   - Auto-reply message when first contacted ("Habari! Asante kwa kupendezwa na keki zangu...")
   - Save → `PATCH /partner-skill-personas/{skill_category}`
7. **Switching personas mid-task:** when partner is in the inbox with skill chip "Baking" active and taps a carpentry order from the cross-source notification, the app routes to that order's detail page WITHOUT changing the home-page persona — the persona switcher is purely for the partner's own scoped dashboard, not for routing into specific orders.

### CRUD Operations
- **Create skill registration:** `POST /partner-skills` with `{skill_category, credentials_url?}` — for regulated clusters (legal, medical, accounting), backend marks `pending_verification` until admin reviews (admin verification is backend-only per `feedback_admin_actions_are_backend_only` — no Flutter admin screens)
- **Read skills:** `GET /partner-skills?partner_id=` returns each skill with persona config + status + verification state
- **Edit persona:** `PATCH /partner-skill-personas/{skill_category}` — display name, photo, bio, auto-reply
- **Pause skill:** `POST /partner-skills/{skill_category}/pause` — hides from customer rails/search; in-flight orders unaffected; partner notified after 30 days "Bado ujuzi huu umesimamishwa? Endelea au uondoe? / Still paused? Resume or remove?"
- **Resume skill:** `POST /partner-skills/{skill_category}/resume`
- **Remove skill:** `DELETE /partner-skills/{skill_category}` — server-validates zero active orders; rejects with explanation if not. Removed personas keep order history attached (audit trail) but disappear from public-facing surfaces.

### Notifications & Reminders
- 🎉 **Celebration — Skill verified:** "✅ Ujuzi wa [skill] umethibitishwa. Anza kupokea wateja / [skill] verified. Start receiving customers"
- ⚠️ **Alert — Verification rejected:** "Ujuzi wa [skill] haujapitishwa. Sababu: [reason]. Pakia tena / [skill] verification rejected: [reason]. Re-upload"
- 🔔 **Reminder — Configure persona:** 24h after skill registration if `display_name` is still default: "Toa jina la kupendeza kwa shughuli yako ya [skill] / Pick a catchy display name for your [skill] persona"
- ⚠️ **Alert — Persona conflict:** When partner posts a product to skill A but persona is configured for skill B's tone (e.g. accidentally posts a wedding cake under carpentry): "Una uhakika? Ukurasa wa [skill A] hauonyeshi keki / Are you sure? [skill A] persona doesn't show cakes"
- 📊 **Summary — Cross-persona digest:** Sunday 7pm to multi-skill partners: "Wiki hii: 🎂 Baking TZS [X] (oda [a]); 🪚 Carpentry TZS [Y] (oda [b]). [Skill] inakua zaidi / This week: 🎂 Baking TZS [X] ([a] orders); 🪚 Carpentry TZS [Y] ([b] orders). [Skill] is growing"
- 💡 **Prompt — Add complementary skill:** When >70% of partner's orders include a tag from a related skill (e.g. baker frequently asked for cake stands → suggest `carpentry` or `eventPlanning`): "Wateja wengi wanauliza [tag]. Sajili pia [skill]? / Customers often ask for [tag]. Add [skill]?"
- 💡 **Prompt — Drop underperforming skill:** When one skill brings <5% of revenue 90 days running: "Ujuzi wa [skill] umeleta kidogo. Lenga zaidi [other skill]? / [skill] earned little. Focus more on [other skill]?"
- 🎉 **Celebration — Two-skill milestone:** First time partner completes 10+ orders in EACH of two skills in the same month: "Maajabu! Umemaliza oda 10+ kwa 🎂 Baking na 🪚 Carpentry mwezi huu / Amazing! 10+ orders in two skills this month"
- 🔔 **Reminder — Hours not set per skill:** When new skill registered but no per-skill availability published: "Weka muda wa [skill] ili wateja wahifadhi / Set hours for [skill] so customers can book"

### Reports & Insights
- **Cross-persona P&L:** Each skill as a row, columns: revenue, orders, avg ticket, rating, response time, utilization. Side-by-side comparison teaches partner where to invest energy.
- **Skill-vs-skill margin:** "Faida yako kwa keki ni TZS [X]/saa. Useremala TZS [Y]/saa. Useremala unalipa zaidi / Cake margin is TZS [X]/hr; carpentry TZS [Y]/hr. Carpentry pays more"
- **Time allocation tracker:** From accepted-to-completed timestamps, estimate total minutes spent on each skill this month → "Umetumia 60% ya muda kwa baking lakini umepata 35% ya pesa. Pendekezo: punguza orders za chini / 60% of your time on baking but only 35% of revenue. Suggestion: trim low-ticket cakes"
- **Customer overlap:** "Wateja [X] wameagiza kutoka pande zote mbili (keki + samani) / [X] customers ordered from both your personas" — cross-sell signal
- **Persona discoverability:** Profile views per skill, search appearances, conversion to inquiry — helps tune photos/bio
- **Skill-mix recommendation engine:** Based on Tanzania market data, suggest the 3 most synergistic skills to add (e.g. baking → eventPlanning has 40% revenue lift in cohort)

### Cross-Module Connections
- **Tajirika profile:** Each persona surfaces as its own card on the public partner profile — buyers tapping into "Asha's Cakes" see only baking products; tapping into "Asha Furniture Works" see only carpentry. Reviews are filterable per persona.
- **Search (`lib/screens/search/`):** A single partner appears as multiple cards in search results (one per skill matching the query), each linking to its persona's product list
- **Shop:** Each persona can attach a partner-owned Shop catalog (e.g. baker sells cake stands as physical Shop products separate from custom cake orders)
- **Wallet:** Earnings dashboard splits per skill, but settlement is to one Wallet account (legal entity is the partner, not the persona)
- **COA/Accounting:** Journal lines tagged with `skill_category` so monthly reports separate baking revenue from carpentry revenue automatically; same TIN for tax purposes
- **Calendar:** All bookings across skills land on one calendar but with skill-tagged events ("🎂 Asha's Cakes — Wedding cake delivery 14:00")
- **Chat:** Inbound DMs auto-tag the originating persona; reply auto-signs with that persona's display name
- **Shangazi AI:** "Ask Shangazi which of my skills to grow" — passes the cross-persona P&L for personalized advice
- **Community:** Posts can be cross-posted to multiple personas' followers OR scoped to one (e.g. baking giveaway only goes to cake customers)
- **Notifications:** All FCM payloads include `skill_category` so the OS notification can show the correct icon (🎂 vs 🪚) and opens to the correct persona view

### Research-informed enhancements (multi-skill)

- **Add-a-skill is one screen, not a re-onboarding.** Partner taps "+ Ongeza Ujuzi / Add Skill" → picks `SkillCategory` chip → uploads only the cluster-specific add-on (TFDA cert for baking, nothing for carpentry). All shared identity (NIDA, name, phone, photo, address, M-Pesa) carries over from the user's first skill. Each registered skill carries its own verification badge state — Asha's `baking` can show "Verified" while `carpentry` shows "Mpya / New" — but neither blocks publishing. *Pattern: Stripe Connect add-account-type, Honeybook add-service.*
- **Per-skill Job Success Score / KPI** — composite score computed independently per `skill_category` from orders tagged to that skill. Asha can be a Top Pro baker (95) and a Standard carpenter (72). Surfaces in customer search ranking per skill. *Pattern: Upwork Job Success Score scoped to category.*
- **Optional per-skill portfolio for ranking lift, not a publish gate.** Sample photos boost the per-skill ranking score; partner can list and accept orders from day one without them. *Pattern: Booksy / Vagaro optional gallery.*
- **Cross-persona time-allocation vs revenue-mix dashboard** (already in doc): visualize "60% of your time on baking but 35% of revenue" — drives the persona-level "Drop or invest more?" recommendations. Layer in **opportunity cost** ("Carpentry generated TZS 3,200/hr vs baking TZS 1,800/hr"). *Pattern: Upwork analytics, Honeybook reporting.*
- **Persona-level pricing tier badges** ("Bei nafuu / Budget", "Wastani / Standard", "Premium") auto-assigned from price band relative to cluster median, displayed on customer cards. *Pattern: Tourradar Basix/Original/Comfort/Premium tiers.*
- **Persona-level public profile pages** (`tajiri.com/p/asha-cakes` and `tajiri.com/p/asha-furniture`) — separate WhatsApp-shareable URLs per persona despite same underlying user. *Pattern: Honeybook public profile pages.*
- **Cross-persona activity-feed unified inbox** with skill-icon prefix on every row (already in doc) — researched-pattern alignment confirmed: Honeybook contact-history pattern adapted to multi-skill scope.
- **"Save my partner" works per persona** — customer who favorited "Asha's Cakes" doesn't auto-see "Asha Furniture Works" in their favorites. Each persona builds its own customer-base. *Pattern: Urban Company "save my pro" scoped to service category.*
- **Skill-pause without affecting other skills** — "Sitisha 🎂 / Pause Baking" leaves carpentry active. Pause is a `partner_skill.is_active = false`, not user-level deactivation. *Pattern: Booksy / Vagaro per-service availability toggle.*
- **AMC packages can be persona-specific** — Asha can sell a yearly carpentry-maintenance bundle (3 visits to fix any wood-furniture wear) without polluting her cake catalog. *Pattern: Urban Company AMC scoped to service category.*

---

## NOTIFICATION CHANNELS SUMMARY

| Channel | Trigger | Frequency |
|---|---|---|
| **partner_orders** | New order across any source, action required | Per event |
| **partner_orders** | State transitions on accepted orders (en_route, ready, completed) | Per transition |
| **customer_orders** | Order accepted, in progress, ready, completed | Per transition |
| **customer_orders** | Daily digest of active orders | Daily 7am |
| **partner_summaries** | Weekly revenue & rating digest | Sunday 7pm |
| **partner_summaries** | End-of-day digest | Daily 8pm |
| **customer_summaries** | Monthly cluster spending breakdown | 1st of month |
| **appointments** | 24h before, 2h before, on day | Per booking |
| **consultations** | 24h before, 30m before, join now, follow-up notes ready | Per consultation |
| **events** | 30d / 7d / 24h / day-of reminders | Per booking |
| **engagements** | Daily time-log nudge (partner), milestone due/overdue, monthly invoice | Daily / per milestone |
| **reviews** | Rate partner prompt + 7d follow-up; low/high-rating alerts | Per completed order |
| **availability** | Set hours first time, utilization summary, extend/reduce prompts | One-shot or weekly |
| **system** | Hold expired, deposit due, blackout overlap, refund processed | Per event |

## CROSS-MODULE INTEGRATION MAP

| From Partner C2B | To Module | Trigger |
|---|---|---|
| Any completed order | **Wallet** (lib/my_wallet/) | Capture payment, write journal lines |
| Any expense to customer | **Budget** (lib/budget/) | Per-cluster envelope (chakula/nyumbani/tukio/usafiri/afya/urembo/mafunzo/kazi) |
| Any time-locked order | **Calendar** (lib/calendar/) | Auto-create event with reminders |
| Per-order chat | **Messages** (lib/screens/messages/) | Conversation thread per order |
| Doctor consultation completed | **Pharmacy** (lib/pharmacy/) | Order prescription with pre-filled meds |
| Doctor consultation completed | **Insurance** (lib/insurance/) | Submit claim with diagnosis |
| Mafundi service | **Shop** (lib/screens/shop/) | Pre-order materials before partner arrives |
| Auto service log | **Buy Car** (lib/buy_car/) | Service history boosts resale value |
| Property accepted offer | **Loans** (lib/loans/) | Mortgage pre-qual |
| Property accepted offer | **Insurance** (lib/insurance/) | Home insurance |
| Property listing | **VICOBA/Kikoba** (lib/vicoba/) | Group savings goal for down payment |
| Wedding event booking | **Events** (lib/events/) | Wedding planner full coordination |
| Safari booking | **Insurance** (lib/insurance/) | Travel insurance |
| Safari booking | **Family** (lib/my_family/) | Traveler list from family members |
| Engagement (career coaching) | **Career** (lib/career/) | Customer career timeline |
| Doctor consultation child patient | **My Children** (lib/my_children/) | Health log auto-update |
| Salon/fitness appointment | **Photos** (lib/screens/feed/) | Post-appointment share template |
| Any partner | **Tajirika profile** (lib/tajirika/) | Rating + utilization feeds discovery score |
| All cluster activity | **Shangazi AI** | Context for advice ("Ask Shangazi about [topic]") |
| All terminal transitions | **COA / Accounting** (lib/business/accounting/) | Journal lines per source |
| Cross-vertical search | **Search** (lib/screens/search/) | partner_offerings index |
| New listing or product | **Community** (lib/community/) | Cluster + ward community feed |

## MODULE OWNERSHIP MATRIX (audit table)

This table validates every page in the 13 features against the food/tajirika split rule. Partner management pages live in `lib/tajirika/pages/`; customer browse/book/read pages live in their consumer vertical.

| Feature | Partner pages (lib/tajirika/pages/) | Customer pages (lib/<vertical>/pages/) | Shared (lib/customer_orders/, lib/tajirika/widgets/) |
|---|---|---|---|
| 1. Partner posting | `post_partner_product_page.dart`, `tajirika_home_page.dart` | — | — |
| 2. Buyer order | — | `lib/<vertical>/pages/partner_product_detail_page.dart` (one per vertical) | `lib/tajirika/widgets/partner_product_card.dart`, shared booking-sheet widget |
| 3. Unified inbox | (source-specific detail pages — see below) | — | `lib/customer_orders/incoming_customer_orders_page.dart`, `customer_order_detail_page.dart` (dispatcher) |
| 4. Service request | `incoming_service_requests_page.dart`, `service_request_detail_page.dart` | `lib/mafundi/pages/request_service_page.dart`, `service_request_status_page.dart` | — |
| 5. Garage booking | `incoming_garage_bookings_page.dart`, `garage_booking_detail_page.dart` | `lib/service_garage/pages/book_garage_page.dart`, `garage_status_page.dart` | — |
| 6. Appointment | `appointment_detail_page.dart`, `manage_availability_page.dart` | `lib/hair_nails/pages/book_hair_nails_appointment_page.dart`, `lib/fitness/pages/book_fitness_session_page.dart` | `lib/tajirika/widgets/slot_picker.dart` (read-only customer render) |
| 7. Consultation | `consultation_detail_page.dart` (NDA-gated, partner intake view) | `lib/legal_gpt/pages/book_legal_consultation_page.dart`, `lib/doctor/pages/book_medical_consultation_page.dart`, `lib/business/pages/book_business_consultation_page.dart`, `lib/<vertical>/pages/consultation_status_page.dart` | `lib/tajirika/widgets/consultation_intake_form.dart`, `nda_acceptance_gate.dart` |
| 8. Engagement | `propose_engagement_page.dart`, `engagement_dashboard_page.dart` | `lib/business/pages/engagement_proposal_review_page.dart`, `lib/business/pages/engagement_workspace_page.dart` | Workspace widget shared between partner dashboard + customer page |
| 9. Listing inquiry | `post_property_listing_page.dart`, `my_listings_page.dart`, `incoming_property_inquiries_page.dart` | `lib/housing/pages/housing_home_page.dart`, `property_listing_detail_page.dart`, `property_inquiry_page.dart` | — |
| 10. Event booking | `event_booking_detail_page.dart` (uses `post_partner_product_page.dart` for package authoring) | `lib/events/pages/events_home_page.dart`, `book_event_package_page.dart`, `lib/travel/pages/travel_home_page.dart`, `book_safari_page.dart` | — |
| 11. Reviews | `partner_profile_page.dart` (own + public), `my_reviews_page.dart` (reply UI) | `lib/customer_orders/pages/rate_partner_page.dart` (cross-source customer page) | — |
| 12. Availability | `manage_availability_page.dart` | (no dedicated customer page; customer sees slots embedded inside booking pages) | `lib/tajirika/widgets/slot_picker.dart` |
| 13. Multi-skill hub | `tajirika_home_page.dart` (skill switcher pill row), `manage_skills_page.dart`, `skill_persona_page.dart` | (no dedicated customer page; per-skill personas surface as separate cards on the public partner profile) | `lib/tajirika/widgets/skill_switcher.dart`, `skill_chip.dart` |

**Invariants enforced by the table above:**

1. Every partner action (post, accept, quote, diagnose, complete, cancel, reply to review, set hours) opens a page rooted at `lib/tajirika/pages/`.
2. Every customer action (browse, book, place order, request inquiry, rate) opens a page rooted at `lib/<vertical>/pages/` matching the cluster — never `lib/tajirika/`.
3. The unified inbox (`lib/customer_orders/`) is the only cross-cutting customer-facing module and dispatches to `lib/tajirika/pages/` for partner role and to per-vertical pages for customer role.
4. Shared widgets (cards, slot pickers, intake forms) live in `lib/tajirika/widgets/` and are imported by both sides — but pages themselves are never shared across the partner/customer boundary.

---

## RESEARCH SOURCES

This appendix maps each research-informed pattern in this document back to the international apps it was sourced from. Each app is grouped by cluster, with the headline patterns it contributed. Use this as a citation index when implementing any "Research-informed enhancements" subsection above.

### Food & home-kitchen delivery

| App | Country | Headline patterns adopted |
|---|---|---|
| **Uber Eats** | Global | List-first discovery with map secondary; ETA narrowing on driver-pickup; surge label transparency; "Top eats near you" carousel; in-app live chat with photo evidence |
| **DoorDash** | US/Canada | Tip-after-delivery up to 30 days post-order; auto-credit on detected partner error; per-component refund (item missing vs cold vs wrong) |
| **Swiggy** | India | "Bolt" 15-min express badge; cuisine + price + rating composite ranking; subscription (Swiggy One) fee waiver |
| **Zomato** | India | Restaurant-tier badges (Pure-Veg / Hygiene Rated); review-with-photo gating; reorder shortcut from chat |
| **Glovo / Bolt Food** | EU/Africa | Live courier ETA with marker rotation; daily payout to courier wallet; pause-store toggle |
| **Jumia Food** | Africa | M-Pesa/Airtel/Tigo as primary tender; ward-based delivery zones; vendor analytics dashboard |
| **Shef** | US | Home-cook verification with kitchen photo + food-safety quiz; menu publishing window (cook-day calendar); pre-order lead times displayed prominently |
| **Cookpad** | Global | Recipe-driven discovery; cuisine taxonomy; commercial-kitchen / shared-workshop fallback for partners without licensed premises |

### Mafundi / handyman / on-demand services

| App | Country | Headline patterns adopted |
|---|---|---|
| **TaskRabbit** | US/EU | Hourly rate + minimum-hours model; tasker self-quote; reuse primary account on partner activation |
| **Thumbtack** | US | Lead-credit pricing alternative to commission; quote-bidding broadcast; saved-search push |
| **Angi** (Angie's List) | US | Tiered partner badges (Verified / Top Pro / Elite); insurance-backed property guarantee; redo-work warranty |
| **Urban Company** | India/MENA | Standardized service SKUs; photo-of-problem upload at booking; AMC packages |
| **Handy** | US | Auto-pause partner after 3 missed leads; 30-second accept window with auto-reassign; recurring schedules |
| **Airtasker** | AU | Bid-based marketplace; review-then-release escrow; tasker portfolio |
| **Bark.com** | UK/Global | Lead-credit per inquiry; AI hiring-brief generator; quote-bidding broadcast |

### Auto / garage / vehicle service

| App | Country | Headline patterns adopted |
|---|---|---|
| **YourMechanic** | US | Mobile mechanic dispatch; persistent vehicle profile keyed by VIN; transparent diagnostic-fee credit toward repair |
| **RepairSmith** | US | Symptom-selector wizard; pre-quote then on-site re-quote with hard customer approval gate |
| **RepairPal** | US | Repair price-range estimator (low/median/high) per ZIP; certified-shop badge; recall lookup |
| **Fixico** | EU | Body-shop photo-bidding model; multi-shop quote comparison |
| **Wrench** | US | Mileage-based service reminders; service-history export (boosts resale) |

### Beauty / salon / hair / nails

| App | Country | Headline patterns adopted |
|---|---|---|
| **Booksy** | Global | Multi-staff bookings; rebook-prompt at recommended cadence; waiting-time badge; bio-link "Book with me" share |
| **Fresha** | EU/UK | Calendar-first partner dashboard; tip pooling + commission tiers; loyalty stamps |
| **StyleSeat** | US | Patch-test dependency between services; portfolio gallery; auto-watermarked portfolio cross-post |
| **Vagaro** | US | Pause/Busy mode; recurring schedules; AMC-style packages for hair maintenance |
| **Treatwell** | EU | Last-minute discount auto-applied if slot empty <48h; gift vouchers; service-variant SKUs (small/medium/jumbo) |
| **GlossGenius** | US | Hair-type taxonomy chips (1A-4C + Locs/Braids); deposit-required toggle; no-show fee policy |

### Fitness / coaching / wellness

| App | Country | Headline patterns adopted |
|---|---|---|
| **MindBody** | US/Global | Class capacity + waitlist; punch-card credits; instructor profile gating |
| **ClassPass** | Global | Multi-studio pass; class-pack pricing tiers |
| **Mariana Tek** | US | Pick-a-spot floor-plan booking; auto-cancellation with credit return |
| **Trainerize / TrueCoach** | US | Programmed workout plans; PR auto-detection; client check-in cadence |
| **Future** | US | 1:1 video coaching tier (text/video/in-person three-tier SKU model) |
| **Peloton** | Global | Live + on-demand split; instructor leaderboard; achievement celebrations |

### Doctor / telemedicine / health

| App | Country | Headline patterns adopted |
|---|---|---|
| **Practo** | India/SEA | Specialty mapping from symptom selector; insurance-network filter (NHIF analog); doctor verification with MCT-equivalent license |
| **Vezeeta** | MENA | Three-tier consultation SKU (text/video/in-person); persistent customer health profile; pharmacy hand-off after consultation |
| **Mobihealth** | Africa | Multi-country licensing; price localization in TZS/KES/NGN; mobile-money checkout |
| **Doctolib** | EU | Calendar-first booking; pre-appointment intake form; auto-reminder with confirm/cancel SMS |
| **Zocdoc** | US | Doctor reviews with bedside-manner / wait-time / "did it help" multi-dimensional rating; insurance pre-check |
| **Babylon Health / K Health** | UK/US | Conversational AI triage at intake; symptom checker funneling to specialty |
| **Teladoc** | US | NDA-on-intake auto-sign; persistent privilege flag for legal/medical |
| **Maven** | US | Women's-health and fertility specialty hub; persistent care plan |

### Lawyer / legal / professional services

| App | Country | Headline patterns adopted |
|---|---|---|
| **LegalZoom** | US | Productized fixed-fee SKU menu (will / company registration / NDA); document-as-a-service |
| **Avvo** | US | Lawyer reviews + peer endorsements; specialty rating; Q&A public forum |
| **Rocket Lawyer** | US | Subscription retainer with hour ledger; document templates; ask-a-lawyer chat |
| **Lexoo** | UK | Lawyer marketplace with quote-comparison; budget-bracket filter |
| **JustAnswer** | US | Pay-per-question with rating-then-release; expert response SLA |

### Business consulting / freelance / engagements

| App | Country | Headline patterns adopted |
|---|---|---|
| **Upwork** | Global | Escrow + milestone release; Work Diary screenshots; Job Success Score; three contract types (fixed_price / hourly / productized) |
| **Toptal** | Global | Curated talent-matching layer (optional path alongside open marketplace); engagement workspace |
| **Catalant** | US | Senior consultant marketplace; engagement workspace; deliverable milestones |
| **Clarity.fm** | Global | Pay-per-minute call; expert availability calendar; post-call rating |
| **Honeybook** | US | Proposal → contract → invoice morphing object; client portal; auto-status pings on transitions |
| **Dubsado / Bonsai** | US | Retainer + hour-ledger; auto-invoicing; tax form generation |

### Real estate / housing / property

| App | Country | Headline patterns adopted |
|---|---|---|
| **Zillow** | US | List-first + map-toggle discovery; saved-search push notifications; Zestimate price estimate |
| **Redfin** | US | In-app tour scheduling; price-history per listing |
| **Realtor.com / Trulia** | US | Neighborhood profile (schools, crime, transit); "what's nearby" overlay |
| **Rightmove** | UK | Listing-photo-count gating (min 6 photos); chain-status disclosure |
| **Lamudi / Property24 / PropertyPro** | Africa | Verified-agent badge; WhatsApp deep-link CTA; daladala-distance / commute filter; multi-currency display |
| **Airbnb (long-term)** | Global | Calendar-blocking + instant-book toggle; hold-then-deposit flow; cleaning-fee transparency |

### Events / weddings / entertainment

| App | Country | Headline patterns adopted |
|---|---|---|
| **GigSalad** | US | Quote-bidding broadcast model; backup-performer guarantee; event-date calendar lock |
| **The Bash** | US | Performer marketplace with portfolio; deposit-then-balance T-14d schedule |
| **WeddingWire / The Knot** | US | Vendor categorization (caterer / florist / DJ); package-comparison; review-with-photo |
| **Peerspace** | US | Hourly-venue booking; deposit + balance; cancellation tier (60+/30-60/<30 days) |

### Travel / tours / safari / experiences

| App | Country | Headline patterns adopted |
|---|---|---|
| **SafariBookings** | Africa (TZ-relevant) | Tour-operator verification; itinerary-day breakdown; multi-park route map; TALA license badge |
| **Viator (Tripadvisor)** | Global | Experience taxonomy; cancellation-refund tiers; mobile-voucher with QR |
| **GetYourGuide** | EU/Global | Last-minute booking; instant-confirmation badge; multi-language tour-guide filter |
| **Airbnb Experiences** | Global | Host verification with police-check analog; small-group cap; meet-here pin |
| **Tourradar / Intrepid Travel** | Global | Multi-day itinerary builder; group-tour roster; pre-trip briefing |
| **Klook / KKday** | APAC | Activity bundle pricing; loyalty stamps; cross-sell ("travelers also booked") |
| **Withlocals** | EU | Local-host model (one-on-one tour); bilingual tour-guide filter |
| **Jumia Travel** | Africa | Hotel + activity bundle; mobile-money checkout; ward-level results |

### Cross-cluster operating-model sources

| App | Country | Headline patterns adopted |
|---|---|---|
| **WhatsApp Business** | Global | Deep-link CTA from any listing; structured catalog; quick-reply templates |
| **Twilio Conversations** | Global | SMS+WhatsApp fallback with YES/NO replies; in-app chat with masked phone numbers |
| **Stripe Connect** | Global | Daily payout model; fee-disclosure line-by-line; surge-pricing labels |
| **M-Pesa Daraja API** | Tanzania/Kenya | STK push; daily settlement; refund flow |

### Pattern → source quick-reference (selected)

| Pattern | Primary source(s) |
|---|---|
| Tiered partner badges (New / Verified / Top Pro / Elite) | Angi, Booksy, Urban Company |
| Short partner onboarding that reuses existing user-profile data | Uber, Airbnb, Honeybook, Stripe Connect |
| Composite ranking with published factor weights | Uber Eats, Zomato, Practo |
| Hard filters that never reverse-expand (halal, NHIF) | Swiggy (Pure-Veg), Practo (insurance) |
| Three-tier consultation SKU (text / video / in-person) | Future, Vezeeta |
| Productized fixed-fee professional services | LegalZoom, Honeybook |
| Diagnostic fee credited toward repair | YourMechanic, RepairSmith |
| 30-day redo-work warranty | Angi, Handy |
| Photo-of-problem upload at booking | Urban Company, Fixico |
| Re-quote with hard customer approval gate | RepairSmith, Fixico |
| Persistent vehicle profile keyed by VIN | YourMechanic, Wrench |
| Multi-staff bookings (slots[]) | Booksy, Fresha |
| Patch-test dependency between services | StyleSeat, Treatwell |
| Pick-a-spot floor-plan booking | Mariana Tek |
| Conversational AI triage at intake | Babylon Health, K Health |
| NDA-on-intake auto-sign + persistent privilege flag | Teladoc, Rocket Lawyer |
| Escrow + milestone release with Work Diary | Upwork |
| Honeybook proposal→contract→invoice morphing object | Honeybook |
| Lead-credit pricing alternative to commission | Thumbtack, Bark.com |
| Quote-bidding broadcast | Thumbtack, Bark.com, GigSalad |
| Multi-dimensional ratings (taste/portion/packaging/on-time) | Uber Eats, Zocdoc |
| Photo+video reviews mandatory for ≤2-star | Uber Eats, Glovo |
| Peer endorsements | Avvo |
| 7-day partner reply window with discount-offer affordance | Yelp, TripAdvisor |
| Configurable reminder timing per service-type | Doctolib, Booksy |
| Last-minute discount auto-applied <48h | Treatwell |
| Per-skill verification gating for multi-skill partners | Upwork (per-category JSS) |
| Persona-level public profile pages with separate URLs | Upwork, Fiverr |
| Daily M-Pesa payout ("Pesa zako, leo") | Bolt Food, Glovo, Stripe Connect |
| 30-second partner accept window with auto-reassign | Handy, Uber Eats |
| Auto-pause after 3 missed leads | Handy, Thumbtack |
| Bio-link "Book with me" share | Booksy |
| Auto-watermarked portfolio cross-post | StyleSeat |
| Pre-call tech check before video consultation | Doctolib, Teladoc |
| Photo-proof + 4-digit handoff PIN at delivery | DoorDash, Glovo |

**Sourcing notes:**

- Patterns marked above are adapted, not copied. Tanzania-specific constraints (M-Pesa instead of Stripe Connect; daladala distance instead of subway map; NIDA instead of SSN; TFDA/TBS/TLS/MCT/TALA instead of FDA/Bar/AMA/IATA) are layered on top of every adopted pattern.
- Where a pattern conflicts with a Tanzania regulatory or cultural reality, the Tanzania reality wins. For example, no surge pricing is applied to medical consultations regardless of demand (cultural — health is not a luxury) even though ride-hail apps surge freely.
- COA tagging by `skill_category` is non-negotiable per the `feedback_coa_source_of_truth` user-memory rule and applies to every revenue line, refund, and payout described in this document.
