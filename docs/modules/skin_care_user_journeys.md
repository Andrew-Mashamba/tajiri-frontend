# Skin Care — Complete User Journeys

**Audit date:** 2026-04-12  
**Module:** `lib/skincare/`  
**Source spec:** `docs/modules/skin_care.md`

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget), and **Insightful** (reports, trends, recommendations).

---

## 1. SKINCARE HOME (DASHBOARD)

**Entry:** Profile → "Skin Care" / "Ngozi" tab → `SkincareModule` → `SkincareHomePage`  
**Stage/Context:** First visit (empty profile) and daily return (established user)

### User Journey

1. User opens own profile, taps **Skin Care** tab (`ProfileTabConfig` id `skincare`).
2. **Loading:** Center `CircularProgressIndicator` while parallel API calls run: skin profile, routines, diary (current month), recommendations.
3. **Empty profile — first time:** User sees **"Start Your Skin Journey"** / dark card: subtitle *"Answer a few questions so we can help you care for your skin"* → tap opens `SkinProfilePage` without `existingProfile`.
4. **With profile:** `SkinProfileCard` shows type, concerns, climate, score chip; tap card or settings icon → `SkinProfilePage` with `existingProfile`.
5. **Sunscreen banner (top):** Target: climate-aware copy; **today’s code:** static *"Strong sun today — use sunscreen!"* / *"SPF 30+ every day..."* — user taps nowhere (informational only).
6. **Quick actions row (4 tiles):**
   - **Write Diary** / *"Write Diary"* → `SkinDiaryPage`
   - **My Routine** / *"My Routine"* → `RoutinePage` with cached `routines`
   - **Products** / *"Products"* → `ProductsPage` with optional `skinProfile`
   - **Check Ingredients** / *"Check Ingredients"* → `IngredientCheckerPage`
7. **TMDA warning strip:** *"Check dangerous products"* → tap → `IngredientCheckerPage`.
8. **Active routines (if any):** Up to 2 previews; tap → `RoutinePage`.
9. **Recent diary:** Up to 5 rows; **"All"** → full diary.
10. **Recommended products:** Up to 6 `ProductTile`s; tap currently opens `ProductsPage` (not product detail) — **gap:** should open detail or same product.
11. **Dermatologist card:** *"Contact a Dermatologist"* / *"Get professional advice about your skin"* → **target:** `FindDoctorPage` with `MedicalSpecialty.dermatology`; **today’s code:** `Navigator.pushNamed(context, '/doctor')` — route registration must be verified; not dermatology-filtered.
12. **Pull-to-refresh:** Reloads all home data.
13. **Error path:** If any API fails silently, section may be empty; **target:** inline error + Retry per section.

### CRUD Operations

- **Create:** Indirect — profile created on `SkinProfilePage`; diary/routines created on sub-pages.
- **Read:** Dashboard reads profile, routines, diary, recommendations; **no** delete from home.
- **Edit:** Tap profile card or settings → profile edit.
- **Delete:** Not on home.

### Notifications & Reminders

- 🔔 **Reminder:** "Evening routine — did you cleanse and moisturize? Tap to log." / *"Jioni: umesafisha na uka moisturizer?"* — **target:** 20:30 local, max 1/day; **today:** not implemented.
- ⚠️ **Alert:** "Your skin profile is incomplete — add concerns for better tips." / *"Profaili haijakamilika..."* — in-app card if concerns empty; **today:** not implemented.
- ⚠️ **Alert:** "Dangerous ingredient detected in a product you saved — open Ingredient Checker." / *"Kemikali hatari..."* — **target:** when product linked to diary matches ban list; **today:** not implemented.
- 📊 **Summary (weekly):** "This week: [X] diary days, [Y] routines completed. Mood trend: [up/down]." / *"Wiki hii..."* — **target:** Sunday 18:00; **today:** not implemented.
- 💡 **Prompt:** "SPF 30+ even on cloudy days — your climate: [Pwani/Bara/Ziwa]." / *"Tumia SPF..."* — **target:** morning; **today:** static banner only, not tied to profile.

### Reports & Insights

- **Home summary (target):** Streak of diary days; routine completion rate; **today:** list previews only, no aggregate KPIs.
- **Comparison (target):** This week vs last week mood average; **today:** not shown.

### Cross-Module Connections

- **Doctor:** Dermatologist CTA → `DoctorModule` / `FindDoctorPage` with dermatology specialty (target).
- **Shop:** From recommended product → "Buy similar in Shop" with search query = product category + brand (target).
- **Budget:** "Log skincare spend" → ExpenditureService category Urembo / personal care (target).
- **Shangazi AI:** "Ask Shangazi about my skin" with context: skin type, concerns, climate, last diary mood (target).
- **My Circle:** If user tracks cycle, correlate diary tags "Hedhi" with breakouts — insight card (target).

---

## 2. SKIN PROFILE (ONBOARDING & SETTINGS)

**Entry:** Skincare Home → settings icon **or** tap profile/setup card → `SkinProfilePage`  
**Stage/Context:** First-time setup and any time user updates preferences

### User Journey

1. **AppBar:** Back → `Navigator.pop`; title **"Profaili ya Ngozi"** / **target EN:** "Skin Profile".
2. **Skin type (single select):** Cards for **Mafuta / Kavu / Mseto / Nyeti / Kawaida** — each shows icon + short description; tap selects one; selected state: dark fill + check.
3. **Concerns (multi-select):** `FilterChip`s — Chunusi, Madoa Meusi, Mikunjo, … (see `SkinConcern` enum); **validation (target):** allow zero for MVP or require ≥1 — product decision.
4. **Climate zone (single):** Three columns — **Pwani (Humid)** / **Bara (Dry)** / **Ziwa (Temperate)**.
5. **Budget (single):** Radio rows — **Chini (< TZS 20,000/mwezi)** / **Wastani (TZS 20,000 - 50,000)** / **Juu (> TZS 50,000)**.
6. **Skin tone (target):** Optional chips — **today:** not in UI; backend field `skin_tone` unused in form.
7. **Save:** Button **"Hifadhi Profaili"** / **"Save profile"** → `POST /skincare/profile` with `user_id`, `skin_type`, `concerns`, `climate_zone`, `budget`, optional `skin_tone`.
8. **Success:** Snackbar *"Profaili imehifadhiwa"* → pop; **failure:** red snackbar with API message.
9. **Offline/error:** **target:** queue save via Hive; **today:** fails with generic error.

### CRUD Operations

- **Create:** First save creates profile.
- **Read:** Pre-fill from `existingProfile` when editing.
- **Update:** Same form overwrites; **backend:** single POST upsert.
- **Delete:** **NOT AVAILABLE** — no delete profile in UI (flag as gap if product requires account reset).

### Notifications & Reminders

- 🔔 **Reminder:** "Update your skin profile — climate or budget changed?" / *"Sasisha profaili..."* — **target:** quarterly; **today:** not implemented.
- ⚠️ **Alert:** If user selects many "bleaching" adjacent concerns without reading safety — **target:** soft education modal; **today:** not implemented.

### Reports & Insights

- **Profile completeness score (target):** % fields filled; drives recommendation quality.
- **Score chip (today):** Shows `profile.score` from API if present — **explain copy (target):** tooltip "Based on consistency of logging and goals."

### Cross-Module Connections

- **Budget:** Budget band pre-fills suggested Urembo envelope allocation (target).
- **Shop / Products:** Filters on `ProductsPage` use `skinProfile.skinType` and concerns.
- **Shangazi AI:** Profile JSON passed as context for "what should I use?" questions.

---

## 3. ROUTINES (MORNING / EVENING + GUIDED MODE)

**Entry:** Skincare Home → **My Routine** → `RoutinePage`  
**Stage/Context:** Daily AM/PM skincare; users who want structure and timers

### User Journey

1. **AppBar:** Title **"Routine ya Ngozi"** / **"Skin routine"**; tabs **Asubuhi** (sun icon) / **Jioni** (moon icon).
2. **Empty tab:** Icon + *"Hakuna routine ya [Asubuhi/Jioni]"* + **"Unda Routine"** / **"Create routine"** → dialog **"Routine Mpya ([type])"** with `TextField` **"Jina la routine"** → **"Unda"** / **"Create"** → `POST /skincare/routines` with `steps: []`.
3. **Routine row:** Routine name; **"Anza"** / **"Start"** → guided mode; **+** add step; **trash** delete routine.
4. **Add step (bottom sheet):** **"Ongeza Hatua"** — step type `ChoiceChip`s ( cleanser, toner, serum, moisturizer, sunscreen, treatment, mask ); optional **product name**; optional **instructions**; **wait time** dropdown (0, 15, 30, … seconds). **"Ongeza"** / **"Add"** → `saveRoutine` with full steps list.
5. **Reorder:** `ReorderableListView` — on reorder, local `SkincareRoutine` updated + **target:** `POST` with `id` for update; **today:** risk of duplicate if backend expects `id` and client omits — **verify contract**.
6. **Guided mode:** Full-screen dark UI; progress segments; current step icon + name + product + instructions; **"Subiri"** timer if `waitTimeSeconds > 0`; **"Nimemaliza — Endelea"** / **"Finish step"**; final step **"Maliza Routine"**; snackbar *"Hongera! Umemaliza routine yako"* / **"Great — routine complete!"**
7. **Exit guided:** Close icon cancels timer.
8. **Delete routine:** Dialog **"Futa Routine?"** / **"Delete routine?"** → **"Futa"** → `DELETE /skincare/routines/:id`.

### CRUD Operations

- **Create:** New routine (name + type) + steps appended.
- **Read:** List from `GET /skincare/routines?user_id=`.
- **Edit:** Add steps, reorder — **update** via `saveRoutine` with new steps.
- **Delete:** Confirmed delete.

### Notifications & Reminders

- 🔔 **Reminder:** "Morning routine — 5 min for your skin. Tap to start." / *"Asubuhi: dakika 5 za ngozi..."* — **target:** 07:00; **today:** not implemented.
- 🔔 **Reminder:** "Evening routine — remove makeup/sunscreen before bed." / *"Jioni: ondoa sunscreen..."* — **target:** 21:00; **today:** not implemented.
- 🎉 **Celebration:** "7-day routine streak! Keep it up." / *"Siku 7 za mfululizo!"* — **target:** after streak; **today:** not implemented (completion not persisted).
- ⚠️ **Alert:** "You skipped evening routine 3 days — skin barrier may suffer." / *"Umeacha routine..."* — **target:** gentle push; **today:** not implemented.

### Reports & Insights

- **Weekly:** Completion count per routine; **avg time** to finish guided mode.
- **Insight:** "You never skip sunscreen in morning" / *"Huachi sunscreen asubuhi"* — pattern from logs (target).

### Cross-Module Connections

- **Calendar:** Sync optional "Skincare time" blocks (target).
- **Shop:** Step links to catalog product ID → deep link to Shop product (target).
- **Doctor:** "Persistent acne despite routine — book dermatologist?" after 4 weeks poor mood logs (target).

---

## 4. SKIN DIARY

**Entry:** Skincare Home → **Write Diary** → `SkinDiaryPage`  
**Stage/Context:** Daily reflection; correlating products, stress, cycle with skin

### User Journey

1. **Month header:** Chevron left/right — **"Januari 2026"** etc.; loads `GET /skincare/diary?month=&year=`.
2. **Calendar grid:** Days with entries filled (dark circle); today highlighted; **today’s code:** tap day **does not** open detail — **gap:** tap to view/edit entry.
3. **Section "Andika Leo"** / **"Write today"** (target EN):
   - **Mood row:** 5 icons — Mbaya sana → Nzuri sana; select one.
   - **Tags:** `FilterChip`s — Chunusi, Ukavu, Mafuta, … Hedhi, Msongo, … **target:** add explicit **Stress**, **Mzunguko wa hedhi** chips.
   - **Products used:** `TextField` *"k.m. CeraVe, Nivea sunscreen (tenganisha kwa koma)"* / **"e.g. CeraVe, Nivea sunscreen (comma-separated)"**.
   - **Notes:** multiline *"Andika kuhusu hali ya ngozi yako leo..."*.
4. **Date (target):** Date picker for **past days** — **today:** logs only `DateTime.now()` — **no backdating** — **GAP** flagged in spec.
5. **Save:** **"Hifadhi"** / **"Save"** → `POST /skincare/diary` with `date`, `mood`, `tags`, `products_used`, `notes`; **photo** in service signature **not** sent in JSON — **GAP**.
6. **History:** Cards with date, mood label (getter named `moodEmoji` but returns Swahili words — **rename target**), notes, tags, products.
7. **Error:** Red snackbar *"Imeshindwa"*.

### CRUD Operations

- **Create:** Save form → **one entry per day (target)** or **multiple (today)** — clarify product rule.
- **Read:** List for month + calendar markers.
- **Edit:** **NOT AVAILABLE** — **GAP**; must delete/re-create or add PATCH.
- **Delete:** **NOT AVAILABLE** — **GAP**.

### Notifications & Reminders

- 🔔 **Reminder:** "How’s your skin today? Log in 10 seconds." / *"Ngozi yako leo?"* — **target:** 20:00 if no entry; **today:** not implemented.
- 📊 **Summary:** "This week your mood averaged [X] — best day was [day]." / *"Wiki hii..."* — **target:** Sunday; **today:** not implemented.
- 💡 **Prompt:** "You tagged Hedhi + Chunusi — see My Circle cycle insights?"** — **target:** if My Circle data exists (target).

### Reports & Insights

- **Mood trend line** (target): 30-day graph.
- **Product correlation (target):** "Breakouts more common when tag Msongo selected" — needs ML/rules.
- **Export (target):** PDF for dermatologist visit.

### Cross-Module Connections

- **My Circle:** Period dates → overlay on diary chart (target).
- **Doctor:** "Share last 30 days diary" → PDF attachment to consultation (target).
- **Shop:** Product names in diary → "Restock" links (target).
- **Budget:** "Log spend on products mentioned" (target).

---

## 5. PRODUCTS CATALOG & DETAIL

**Entry:** Skincare Home → **Products** → `ProductsPage`  
**Stage/Context:** Browsing TZS-priced skincare by category

### User Journey

1. **AppBar:** **"Bidhaa za Ngozi"** / **"Skin products"**; filter icon → bottom sheet **"Chuja Bidhaa"** — skin type **Zote** + each type; concern **Zote** + each concern; **"Tafuta"** / **"Apply"** → reload list.
2. **Search field:** **"Tafuta bidhaa..."** / **"Search products..."** — submit triggers `GET /skincare/products` with `search`.
3. **Tabs:** Sabuni, Moisturizer, Sunscreen, Serum, Tiba — switches `category` query.
4. **List:** `ProductTile` — image, name, brand, rating, price **TZS** (formatted), TMDA badge or "Hakuna TMDA" / **"No TMDA"**; tap → **bottom sheet detail**.
5. **Detail sheet:** Image, name, brand, price TZS, rating, **TMDA Imeidhinishwa** badge if verified; description; chips for skin types & concerns; **Viambato** / **Ingredients** list.
6. **Gap:** `GET /skincare/products/:id` **not called** — detail uses list payload only; **target:** fetch detail on open for full ingredients.
7. **Empty:** *"Hakuna bidhaa zilizopatikana"* / **"No products found"**.
8. **Refresh:** Pull-to-refresh.

### CRUD Operations

- **Create/Edit/Delete:** **NOT AVAILABLE** — catalog is admin/backend; user is read-only.

### Notifications & Reminders

- 🔔 **Reminder:** "Sunscreen running low? Restock — SPF you viewed: [brand]." / *"Sunscreen inakaribia kuisha..."* — **target:** 30 days after view; **today:** not implemented.
- 💡 **Prompt:** "New products match your profile: [concern]." / *"Bidhaa mpya..."* — **target:** weekly; **today:** only static recs on home.

### Reports & Insights

- **Spend insight (target):** "You viewed 5 sunscreens; avg price TZS [X] vs your budget [band]." — **today:** not implemented.

### Cross-Module Connections

- **Shop:** **"Buy on TAJIRI Shop"** if product maps to `shop_product_id` (target).
- **Budget:** One-tap log expense = product price + category Urembo (target).
- **Ingredient Checker:** **"Check these ingredients"** pre-fills INCI from product (target).
- **Doctor:** "Show this product to your dermatologist" — share image + name (target).

---

## 6. INGREDIENT CHECKER (TMDA-AWARE)

**Entry:** Skincare Home → **Check Ingredients** or TMDA banner → `IngredientCheckerPage`  
**Stage/Context:** Before buying or when suspicious of bleaching creams

### User Journey

1. **Education blocks:** Red **TMDA Tanzania** warning; bullet list mercury, hydroquinone >2%, steroids, lead; second card **"Kuhusu Bidhaa za Kubadilisha Rangi"** — bleaching risks + **"Ngozi yako ya asili ni nzuri"** body-positive line.
2. **Input:** **"Weka Viambato Hapa"** / **"Paste ingredients here"** — multiline; hint lists example INCI.
3. **"Kagua Usalama"** / **"Check safety"** → parses by comma/newline/semicolon; matches `_tmdaBanned`, `_commonDangerous`, backend `dangerous-ingredients`; **sort:** danger → caution → safe/**unknown**.
4. **Unknown (target):** Tier **"Haijulikani — hakikisha na daktari"** — **today:** labeled **safe** — **GAP** (misleading).
5. **Result cards:** Ingredient name, level badge **HATARI / TAHADHARI / SALAMA**, reason text; **TMDA IMEPIGA MARUFUKU** chip for banned.
6. **Summary row:** Counts danger / caution / safe.
7. **If danger:** **"Taarifa kwa TMDA"** / **"Report to TMDA"** — **today:** snackbar only — **GAP**; **target:** deep link to official TMDA reporting or in-app form + API.

### CRUD Operations

- **Create:** N/A (stateless check).
- **Read:** Loads backend list on init.
- **Save history:** **NOT AVAILABLE** — **target:** save last check for revisit.

### Notifications & Reminders

- ⚠️ **Alert:** "You scanned a product with [mercury] — do not use." / *"Usitumie bidhaa hii..."* — **target:** immediate after check; **today:** in-screen only.
- 💡 **Prompt:** "Learn why skin bleaching harms kidneys" — link to article (target).

### Reports & Insights

- **Monthly:** "You checked [N] ingredient lists; [X] dangerous hits." (target)

### Cross-Module Connections

- **Doctor:** After danger result → **"Book dermatologist"** prominent (target).
- **Pharmacy:** "Ask pharmacist about safe alternatives" with product category (target).
- **Shop:** Blocked search for known-banned brands (policy — target).

---

## 7. RECOMMENDED PRODUCTS (HOME SECTION)

**Entry:** Skincare Home → scroll to **"Recommended Products"** / **"Bidhaa Zinazopendekezwa"** (target EN label)  
**Stage/Context:** Personalized upsell after profile exists

### User Journey

1. **Load:** `GET /skincare/recommendations?user_id=` — max 6 tiles.
2. **Tap:** **today:** navigates to `ProductsPage` — **gap:** should open product detail or scroll to match.
3. **Empty:** Section hidden if no recs.

### CRUD Operations

- **Read only.**

### Notifications & Reminders

- 💡 **Prompt:** "New picks for you based on [skin type] + [concern]." / *"Mapendekezo mapya..."* — **target:** weekly push; **today:** not implemented.

### Reports & Insights

- **Transparency (target):** "Because you chose [concern] + [climate]" on each card.

### Cross-Module Connections

- **Shop / Budget / Ingredient Checker:** Same as Products section.

---

## NOTIFICATION CHANNELS SUMMARY

| Channel | Trigger | Frequency (cap) |
|---------|---------|-----------------|
| **local_push** | Morning/evening routine, diary nudge, sunscreen reminder | Max 2/day combined **target** |
| **in_app** | Profile incomplete, dangerous ingredient, TMDA education | As needed |
| **weekly_digest** | Diary + routine summary + product tips | 1/week Sunday **target** |
| **system** | TMDA list updated (backend) — "Ingredient database updated" | Rare |

---

## CROSS-MODULE INTEGRATION MAP

| From Skin Care | To Module | Trigger |
|----------------|-----------|---------|
| Dermatologist CTA | **Doctor** | User taps card; open **FindDoctorPage** with dermatology specialty |
| Product / routine | **Shop** | Buy, compare, restock with search query |
| Topical treatment / concern | **Pharmacy** | Order medicated cream, pharmacist chat |
| Product purchase, salon spend | **Budget** | ExpenditureService — Urembo / personal care |
| Routine times, refill reminders | **Calendar** | Optional recurring events |
| Cycle + diary tags | **My Circle** | Correlation insights |
| Any screen | **Shangazi AI** | "Ask Shangazi" with profile + diary context |
| Bleaching education | **Tajirika** | Find licensed aesthetician (not illegal bleaching) |
| Push delivery | **FCM / local notifications** | Reminders, weekly summary |

---

## CRUD & GAP SUMMARY (HONEST)

| Feature | Create | Read | Edit | Delete | Notes |
|---------|--------|------|------|--------|--------|
| Skin profile | Yes | Yes | Yes (same form) | No | Delete N/A |
| Routine | Yes | Yes | Yes (steps/reorder) | Yes | Upsert `id` must match backend |
| Diary entry | Yes | Yes | **NOT AVAILABLE** | **NOT AVAILABLE** | Backdate **NOT AVAILABLE** in UI |
| Products | N/A | Yes | N/A | N/A | Catalog read-only |
| Ingredient check | N/A | N/A | N/A | N/A | Ephemeral; no history |

---

*End of Skin Care user journeys document.*
