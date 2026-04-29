# Skin Care — Personal Skincare & Safety (TAJIRI)

## Document status

This document is the **module spec** for Skin Care: primary user wants (persona-led), how we intend to fulfill them in product, an honest snapshot of **today’s** code under `lib/skincare/` (folder name is `skincare`, not `skin_care`), and the backlog until the experience matches the wants. **It is not an implementation checklist for a single PR** — engineering work is tracked against the sections below.

---

## Primary persona & user wants

**Persona:** A young woman in Tanzania who wants healthy, comfortable skin — not shame, not unsafe bleaching, not guesswork. She may be a student or early-career, time-poor, price-conscious, and exposed to **misleading creams** and **strong sun / humidity** depending on region.

The following **wants** drive requirements. Each row states **how we fulfill it in product** (target experience) and **where the codebase stands today** (snapshot — not claiming done until verified in app).

| Want | Target fulfillment (product) | Codebase today (snapshot) |
|------|------------------------------|---------------------------|
| **Clarity** — Understand my skin type and issues in plain language | Onboarding copy + profile: type, concerns, climate, budget; short “what this means for you” blurbs | Profile + enums + Swahili descriptions exist; **no** dedicated “explain my routine” / education layer beyond cards |
| **Trust** — Short, honest explanations (what to expect, how long) | Product detail + “realistic timeline” note; recommendations with “why” (profile match) | Product sheet has description; **no** timeline copy; recs list **without** transparency |
| **Safety** — Avoid mercury, steroids, bad bleachers | Ingredient checker + TMDA-aware lists + **unknown ≠ safe**; optional report path | Checker + local/banned maps exist; **unknown treated as safe** is a **gap**; TMDA “report” is **placeholder** |
| **Routine fits life** — Finishable AM/PM, not another job | Short default routines; guided mode; optional reminders (later) | Guided mode + timers exist; **no** push reminders; **no** “quick 3-step” presets |
| **Patterns** — Hormones, stress, cycle | Diary tags + optional period/stress notes; later charts | Tags include hedhi/stress; **no** structured cycle link or insights |
| **Confidence** — Acne / dark marks without shame | Neutral, supportive copy; care, not “fix your face” | Copy is mostly functional; **no** dedicated tone pass / `AppStrings` parity |
| **Sun & climate** — Advice for *my* environment | Banner + tips from **climate zone** (and later UV/weather) | Climate on profile; banner is **static**, not tied to profile |
| **Money** — Options in my budget | Budget band on profile; products filterable by price bands (future) | Budget bands in profile; catalog **no** price band filter yet |
| **Access** — Local / realistic products | Catalog + TMDA flag; shop integration later | List + TMDA badge in UI; **no** storefront guarantee |
| **Tone & skin color** — No lightening pressure; natural tone is valid | Explicit pro-healthy-skin messaging; **no** skin-lightening as a goal | Ingredient checker educates on bleaching risks; **no** home-level “your tone is beautiful” module line |
| **Professional help** — Dermatologist when needed | Entry to telehealth with **dermatology** context | Link targets **`/doctor`**; **not** dermatology-filtered in this flow; **note:** `/doctor` route may not be registered in `main.dart` — verify routing |
| **Language** — Natural Swahili + English | All strings via `AppStrings` | Mostly **hardcoded Swahili** in skincare screens |

---

## Tanzania context

- **Unregulated cosmetics and skin-lightening products** are common; many creams contain mercury, high-dose hydroquinone, or potent steroids. The **Tanzania Medicines and Medical Devices Authority (TMDA)** regulates medicines and has flagged or banned specific ingredients in cosmetic contexts.
- **Climate varies** by region (coastal humidity vs inland dryness vs highland/lake milder conditions), which changes how skin behaves and how users should think about sun protection and hydration.
- Users need **practical, low-literacy-friendly** guidance in **Swahili first**, with optional English aligned to the rest of TAJIRI (`AppStrings`).

---

## Placement in the app

| Item | Location |
|------|----------|
| Profile tab | `ProfileTabConfig` id `skincare`, label "Skin Care" / l10n key `skincare` → `AppStrings` |
| Entry widget | `SkincareModule(userId)` → `SkincareHomePage` |
| Profile screen switch | `case 'skincare':` in `lib/screens/profile/profile_screen.dart` |

---

## International reference apps (patterns to borrow)

1. **Think Dirty / INCI Decoder** — Ingredient list parsing and hazard flags; **lesson**: tie scanning to a **canonical** ingredient database, not only substring search.
2. **Skin Bliss / Skincare Routine** — Step-by-step routines with timers; **lesson**: the app already has a guided mode; needs **completion persistence** and **reminders**.
3. **TroveSkin / similar** — Photo + tracking over time; **lesson**: diary should support **photo attachments** and **trend views**, not only mood + text.
4. **Regional safety apps** — Any product that surfaces **regulator warnings**; **lesson**: TMDA report flow must be **real** (endpoint or deep link), not a placeholder snackbar.

---

## Code map (current)

```
lib/skincare/
├── skincare_module.dart          # Thin shell: SkincareHomePage only
├── models/skincare_models.dart   # Enums + SkinProfile, Routine, Diary, Product, DangerousIngredient
├── services/skincare_service.dart # REST client (http package only)
├── pages/
│   ├── skincare_home_page.dart   # Dashboard: profile, quick actions, diary/routine/recs previews
│   ├── skin_profile_page.dart    # skin type, concerns, climate, budget (Swahili UI)
│   ├── routine_page.dart         # Morning/evening tabs, CRUD-ish routines, guided mode + timers
│   ├── skin_diary_page.dart      # Calendar, mood, tags, products, notes
│   ├── products_page.dart        # Category tabs, filters, search, bottom-sheet detail
│   └── ingredient_checker_page.dart # Paste ingredients → local + backend hazard checks
└── widgets/
    ├── skin_profile_card.dart
    ├── product_tile.dart
    └── routine_step_card.dart
```

---

## Feature inventory (current code — `lib/skincare/`)

The bullets below describe **what is implemented in code today**, not the full target from the persona table above.

### 1. Skin profile

- **Skin type** (enum): oily, dry, combination, sensitive, normal — Swahili labels and descriptions in models.
- **Concerns** (multi-select): acne, dark spots, wrinkles, uneven tone, dryness, oiliness, large pores, dark circles, keloids.
- **Climate zone** (enum): `pwani` (humid), `bara` (dry), `ziwa` (temperate) — Tanzania-oriented framing.
- **Monthly budget band**: `chini` / `wastani` / `juu` with TZS ranges in labels.
- **Backend fields** also include `skin_tone`, `score`, `last_analysis_date` — **UI does not capture skin tone**; score/analysis date are display-only on `SkinProfileCard` if present.

### 2. Routines

- Morning / evening **tabs**; create named routine per type; **add steps** (step type, optional product name, instructions, wait seconds).
- **Reorder** steps locally and trigger `saveRoutine` with new order.
- **Guided mode**: full-screen flow with per-step timer when `waitTimeSeconds` > 0; progress bar; completion snackbar.
- **Delete** routine via API.

### 3. Skin diary

- Month navigator + grid showing days with entries.
- **Log entry** for **today only** (uses `DateTime.now()` for `logDiaryEntry` — no backdating in UI).
- Mood 1–5, tag chips (Swahili), comma-separated products, notes.
- **History** list for selected month.

### 4. Products catalog

- Tabs: cleanser, moisturizer, sunscreen, serum, treatment (hardcoded category keys).
- Filters: skin type, concern; search by query on submit.
- **Detail** in a draggable bottom sheet: image, price (TZS), rating, TMDA badge, description, skin types, concerns, ingredients.
- `SkincareService.getProductDetail` exists but **the UI does not call it** — detail uses list payload only.

### 5. Ingredient checker (TMDA-aware)

- **Offline maps**: TMDA-banned / high-risk strings and “common dangerous” chemicals with Swahili explanations.
- **Backend** list via `GET .../skincare/dangerous-ingredients` merged into checks.
- Results sorted danger → caution → safe; summary badges.
- **“Taarifa kwa TMDA”** button shows a **fake** success snackbar — **no API, no form, no deep link**.

### 6. Home dashboard

- Loads in parallel: profile, routines, diary (current month), recommendations.
- **Sunscreen banner**: static copy (“Strong sun today”) — **not** driven by weather or UV.
- **TMDA warning** banner → ingredient checker.
- **Dermatologist** row navigates to named route **`/doctor`** (general doctor module, not dermatology-specific).

### 7. Cross-module link

- Reuses platform **telehealth** entry via `/doctor` rather than a dedicated dermatology funnel.

---

## API surface (frontend expectations)

Base: `ApiConfig.baseUrl` (same as rest of app). Paths used:

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/skincare/profile?user_id=` | Load profile |
| POST | `/skincare/profile` | Create/update profile (JSON body) |
| GET | `/skincare/routines?user_id=` | List routines |
| POST | `/skincare/routines` | Create/update routine (body includes `user_id`, `steps`) |
| DELETE | `/skincare/routines/:id` | Delete |
| GET | `/skincare/diary?user_id=&month=&year=` | Diary entries |
| POST | `/skincare/diary` | New entry |
| GET | `/skincare/products` | List with `page`, `category`, `skin_type`, `concern`, `search` |
| GET | `/skincare/products/:id` | Detail (**unused in UI**) |
| GET | `/skincare/dangerous-ingredients` | Server-side hazard list |
| GET | `/skincare/recommendations?user_id=` | Recommended products |

**Important:** `SkincareService` uses plain `http` calls **without** `ApiConfig.authHeaders(token)`. If skincare endpoints are authenticated (likely for user-bound data), the module may **fail or leak** until headers and error handling match other services.

---

## Key screens (current)

1. **Skincare home** — Profile/setup card, sunscreen banner, four quick actions (diary, routine, products, ingredients), TMDA banner, optional routine previews, recent diary, recommended products, doctor CTA.
2. **Skin profile** — Type, concerns, climate, budget, save.
3. **Routine** — Tabs, list, add/delete routine, add/reorder steps, guided mode.
4. **Diary** — Calendar + form + history.
5. **Products** — Tabs + search + filters + list + sheet detail.
6. **Ingredient checker** — Education blocks + paste list + results + placeholder report.

---

## Gaps and technical debt (prioritized)

Closing these items is required to **match the persona wants** in the table above (trust, safety, bilingual access, routing to care, etc.).

### P0 — Correctness & trust

- **No auth headers** on skincare HTTP calls — align with `LocalStorageService` + `ApiConfig.authHeaders` like other feature services.
- **Routine updates**: `saveRoutine` always POSTs to `/skincare/routines` with no `routine_id` in the typed client; if the backend creates a **new** row each time, edits/reorders will duplicate. Confirm contract and send **update** semantics (PUT/PATCH or body `id`) as required.
- **Ingredient checker**: “unknown” ingredients are labeled **safe** (“Hakuna hatari iliyopatikana”) — that is **misleading**; should be **unknown / verify** tier.
- **TMDA report**: replace snackbar with real workflow (API spec or external link to TMDA channels).

### P1 — Product quality & UX

- **Bilingual parity**: Most strings are hardcoded Swahili; profile tab uses English "Skin Care". Move user-visible strings to **`AppStrings`** (or shared skincare strings) for EN/SW parity.
- **Sunscreen banner**: replace static text with logic (weather API, UV index, user climate, or simple time-of-day + season heuristic), or remove until data exists.
- **Skin diary**: `moodEmoji` getter returns **Swahili words**, not emoji — rename or fix for clarity; support **photo** upload if backend supports `photo_url` (client currently omits `photoPath` from JSON).
- **Products**: call `getProductDetail` when opening detail if list items are partial; add pagination UX if API is paginated.
- **Design system**: `skincare_home_page` uses **orange/red** promotional blocks; reconcile with `docs/DESIGN.md` monochromatic rules (or document intentional exceptions for safety warnings).

### P2 — Feature depth

- **Profile**: capture **skin tone** (Fitzpatrick or simple scale) if backend expects it; surface **score** / “analysis” with explainable copy.
- **Routines**: persist guided completion; optional **notifications** (“evening routine”); link steps to **catalog products** (IDs) not only free text.
- **Dermatologist**: filter or deep-link to **dermatology** in doctor module, or copy that sets expectations.
- **Offline**: cache profile/routines/diary in Hive for read-mostly flows per `mobile-offline-support` skill patterns.

---

## Fulfillment roadmap (persona-aligned milestones)

Order is indicative; some items can run in parallel.

1. **Trust & safety** — Unknown-ingredient tier; disclaimers; real TMDA reporting (API or official web contact); auth headers on all skincare APIs; routine upsert contract documented with backend.
2. **Clarity & tone** — `AppStrings` for EN/SW; supportive copy pass; optional “your natural tone” line on home; product “what to expect” / timeline microcopy.
3. **Climate & sun** — Replace static sunscreen banner with profile-based tips (minimum); document path to UV/weather later.
4. **Diary & patterns** — Backdate entries; optional photo; richer tags for stress/cycle; light insights (weekly summary) later.
5. **Care access** — Dermatology-first entry (e.g. `FindDoctorPage` with `MedicalSpecialty.dermatology` or equivalent); ensure `/doctor` (or replacement) is registered and tested.
6. **Catalog depth** — Use `getProductDetail` in UI; pagination; optional price-band filter aligned with profile budget.

---

## Related docs elsewhere in repo

- **`docs/modules/skin_care_user_journeys.md`** — complete user journeys (interactive, connected, insightful); generated from this spec.
- `docs/modules/budget.md` — mentions Urembo / skin care as a spending category.
- `docs/modules/tajirika.md` — marketplace framing for skin-care professionals (separate from this consumer module).

---

## Performance & storage notes (implementation)

- **Stale-while-revalidate:** `SkincareCacheService` (Hive box `skincare_cache`) persists home snapshot (profile, routines, diary month, recommendations) so the tab can render immediately after a prior visit; network refresh follows (`docs/PERFORMANCE_STRATEGY.md` pattern). TTL ~5 minutes via `isStale`.
- **SQLite:** Per `docs/SQLITE_ADOPTION_ROADMAP.md`, Skin Care is **not** a Phase 1 SQLite candidate; local persistence uses Hive for this module.
- **Images:** Product list/detail use `CachedNetworkImage` with `memCacheWidth` for list thumbnails (memory-friendly decoding per performance plan).
- **Routing:** `/doctor` is registered in `main.dart`; dermatology entry from Skin Care uses `FindDoctorPage` with `MedicalSpecialty.dermatology`.

---

## Revision history

| Date | Notes |
|------|--------|
| 2026-04-12 | Initial document from code review of `lib/skincare/`. |
| 2026-04-12 | Added primary persona (young woman), user-wants table with target vs codebase snapshot, fulfillment roadmap; clarified doc as spec only (no implementation claims). |
| 2026-04-12 | Linked `skin_care_user_journeys.md` (full journeys doc per `docs/generate_user_journeys.md`). |
| 2026-04-12 | Documented Hive cache, CachedNetworkImage, `/doctor` route, non-SQLite choice. |
