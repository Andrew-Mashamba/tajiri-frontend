# Hair & Nails — Personal hair health, style, and booking (TAJIRI)

## Document status

This document is the **module spec** for Hair & Nails: who it serves, what problems we want to solve (including **product insights** grounded in Tanzania context), an honest snapshot of **today’s** code under `lib/hair_nails/`, and the gap between **target experience** and **current implementation**. It complements **`hair_nails_user_journeys.md`** for journey-level detail. It is **not** a single-PR checklist.

---

## Primary persona & user wants

**Persona:** Someone in Tanzania who wears, maintains, or cares about **hair and nails** — often women, but not only. They may juggle **budget**, **time**, **salon vs home-based vs mobile** services, **protective styles**, **traction and scalp health**, and **social pressure** around appearance. They want **trust**, **clarity**, and **respect** — not generic Western hair typing alone, not shame about texture or budget.

The table below maps **wants** → **target product behavior** → **codebase today** (snapshot).

| Want | Target fulfillment (product) | Codebase today (snapshot) |
|------|------------------------------|---------------------------|
| **Local realism** — Advice that fits **African textures**, **humidity**, **salon culture** (home salon, mobile, walk-in) | Region-aware copy; filter salons by `home_based` / `mobile` / `walk_in`; short “what this means here” blurbs | `HairType` uses 1–4 curl scale + Swahili; salon filters exist in `findSalons`; **no** weather/humidity-driven tips |
| **Trust** — Know who is legit before paying | Verified badges, reviews, real photos; clear cancellation | `Salon`, `SalonReview`, ratings on cards; **backend must enforce** verification |
| **Safety (hair)** — Avoid traction damage, bad installs | Education on tight styles; **traction alopecia** awareness | **Static** alopecia card on home — good start; **no** personalized risk from profile |
| **Safety (nails)** — Hygiene, ventilation, damage | Future: aftercare, “when to take a break” from extensions/gel | **Not** a dedicated nails-health screen; `StyleCategory.nails` + service category only |
| **Money & time** — No surprise prices or 4-hour waits | Price bands, duration, deposit rules | Model supports services/prices via API; **UI** depends on backend payload |
| **Confidence** — Hair loss / breakage without shame | Neutral copy; optional private growth log | Growth tracker exists; tone not fully audited for `AppStrings` |
| **Progress** — Slow hair goals | Length log + optional photo | `GrowthLog` + `growth_tracker_page`; **no** strong charts/insights |
| **Discovery → action** — Save style → find stylist → book | Style save + salon browse + booking flow | `saveStyle`, `StyleGalleryPage`, `BookingPage`; **cross-link** “find this style near me” is **partial** |
| **Language** — Swahili-first, natural | All copy via `AppStrings` | **Many** English strings on `HairNailsHomePage` and sub-pages — **gap** |
| **Auth & API** — Works with Sanctum | Bearer on all requests | `HairNailsService` uses `AuthService.getValidAccessToken()` + `ApiConfig.authHeaders` (aligned with Skin Care) |
| **Offline** — Saved styles / profile when network dies | Hive home snapshot + **pending profile queue** (retries `POST .../profile`) | **Partial** — profile queue implemented; full offline styles list not required for v1 |

---

## Product insights (why this module exists)

These principles should guide backlog ordering and copy:

1. **Texture-first, not trend-first** — Curl type (1–4), porosity, density, and **current state** (natural, relaxed, locs, etc.) drive expectations; recommendations should **say why** they match (target).
2. **Protective styles are healthcare** — Braids, weaves, and tension are normalized; **education** on traction and scalp pain is non-negotiable (partially met by the alopecia card).
3. **Nails are identity + care** — Inspo and art matter; **nail health** (breakage, soak-off, breaks between sets) belongs in the same module long-term, not only `ServiceCategory.nails`.
4. **Economic dignity** — Price transparency and “good enough” options reduce anxiety; avoid prestige-only framing.
5. **Community without exposure** — Optional anonymity for “is this tension normal?” style questions fits TAJIRI social layers (future: groups / Shangazi).
6. **Platform synergy** — Tajirika partners (`hair_nails` skill routing), Shop, Calendar, and Doctor should be **one tap** from relevant screens. **Today:** home surfaces **Shop**, **Tajirika** partners, **dermatologist** (`FindDoctorPage`), post-booking **Events** + **expenditure**, and **Tea** assistant; see **`hair_nails_backend_directive.md` §10**.

---

## Tanzania & regional context

- **Salon economy:** Many stylists work from home or visit clients; **location and trust** matter as much as star ratings.
- **Hair:** Wide use of protective styles, extensions, and chemical services; **traction alopecia** and scalp conditions are common — dermatology handoff is appropriate for persistent issues.
- **Nails:** Gel/acrylic popularity grows; **hygiene** and **ventilation** matter for worker and client health.
- **Language:** Swahili-first UI is the default for TAJIRI; English should stay in parity via `AppStrings`.

---

## Placement in the app

| Item | Location |
|------|----------|
| Profile tab | `ProfileTabConfig` id `hair_nails`, label "Hair & Nails" / l10n key `hair_nails` |
| Entry | `HairNailsModule(userId)` → `HairNailsHomePage` |
| Profile screen | `case 'hair_nails':` in `lib/screens/profile/profile_screen.dart` |
| Tajirika | Skill routing includes `hair_nails` → partner discovery (`lib/tajirika/models/tajirika_models.dart`) |

---

## International reference patterns (borrow ideas, not copy)

1. **StyleSeat / marketplace booking** — Discovery + reviews + book; **lesson:** deposits and cancellation rules must be explicit.
2. **Natural hair trackers** — Length over time; **lesson:** photos + metric (cm) build motivation.
3. **Pinterest-style boards** — Save inspo; **lesson:** tie saves to **service search** and **book**.
4. **Health-first messaging** — Traction and scalp; **lesson:** proactive education beats reactive regret.

---

## Code map (current)

```
lib/hair_nails/
├── hair_nails_module.dart          # Shell → HairNailsHomePage
├── models/hair_nails_models.dart   # HairType, HairState, Porosity, Density, Salon, Booking, StyleInspiration, GrowthLog, …
├── services/hair_nails_service.dart # REST client; Bearer auth via AuthService
├── pages/
│   ├── hair_nails_home_page.dart   # Dashboard: profile card, quick actions, bookings, styles, salons, alopecia, doctor CTA
│   ├── hair_profile_page.dart    # Hair profile CRUD
│   ├── salon_browse_page.dart    # Search/filter salons
│   ├── salon_detail_page.dart    # Salon + services
│   ├── booking_page.dart         # Book appointment
│   ├── my_bookings_page.dart     # List/cancel/rate
│   ├── style_gallery_page.dart   # Browse/save styles
│   ├── growth_tracker_page.dart  # Log length / history
│   └── virtual_hair_try_on_page.dart  # Front camera + ML Kit face bbox + style/tint overlays (guidance only)
└── widgets/
    ├── salon_card.dart
    ├── style_card.dart
    └── booking_card.dart
```

---

## API contract (client — `HairNailsService`)

**Prefix:** `/api/hair-nails` (kebab-case under `ApiConfig.baseUrl`).

| Area | Methods (indicative) |
|------|----------------------|
| Profile | `GET .../profile?user_id=`, `POST .../profile` |
| Salons | `GET .../salons` (query: search, category, min_rating, flags, lat/lng, page), `GET .../salons/{id}`, `GET .../salons/{id}/reviews` |
| Bookings | `POST .../bookings`, `GET .../bookings?user_id=`, `POST .../bookings/{id}/cancel`, `POST .../bookings/{id}/rate` |
| Styles | `GET .../styles`, `GET .../styles/saved?user_id=`, `POST .../styles/{id}/save`, `DELETE .../styles/{id}/save?user_id=` (unsave) |
| Growth | `POST .../growth`, `GET .../growth?user_id=` |

**Envelope:** `{ "success": true|false, "data": …, "message": … }` (same convention as Skin Care). **Auth:** Sanctum Bearer on all calls from the app.

Formal **backend contract** for engineers: **`docs/modules/hair_nails_backend_directive.md`** (routes, bodies, enums, QA checklist).

---

## Feature inventory (current code)

### 1. Hair profile

- **Hair type** — Andre-style categories `straight1` … `coily4c` with Swahili labels.
- **Porosity** — `low` | `normal` | `high` with tips in model.
- **Density** — `thin` | `medium` | `thick`.
- **Length** — Optional `length_cm`.
- **Current state** — `natural`, `relaxed`, `transitioning`, `colorTreated`, `locced`.
- **Scalp** — Optional string.
- **Goals** — List of user strings/chips.

### 2. Salons & booking

- Browse with search, category, rating, home/mobile/walk-in, optional geo.
- Salon detail, reviews, book appointment (service, datetime, notes, payment hint, phone).
- My bookings: upcoming highlight on home; cancel and rate.

### 3. Style gallery

- Trending/grid; save style for user; category enum includes **nails**.

### 4. Growth tracker

- Log length (cm), optional photo URL, notes; history list.

### 5. Education & cross-links

- **Traction alopecia** awareness card on home.
- **Doctor** CTA → `Navigator.pushNamed(context, '/doctor')` — **verify** route and ideally **dermatology** / scalp context.

---

## Known gaps (prioritized)

| Priority | Gap |
|----------|-----|
| P0 | **l10n** — Replace hardcoded English on home and key flows with `AppStrings` |
| P0 | **Backend** — Implement `/hair-nails/*` to match client or adjust client to real API |
| P1 | **Nails-specific UX** — Dedicated nails inspo + care tips (not only `StyleCategory.nails`) |
| P1 | **Shangazi / chat** — Contextual “ask about my hair” with profile + last growth log |
| P2 | **Calendar** — Reminders for fill, takedown, growth check-in |
| P2 | **Offline** — Cache profile, saved styles, last salon list |
| P3 | **Shop** — Deep link to vetted products (oils, treatments) from profile porosity tips |

---

## Related documents

| Document | Purpose |
|----------|---------|
| `docs/modules/hair_nails_user_journeys.md` | Full user journeys per `docs/generate_user_journeys.md` (CRUD, notifications, reports, cross-module map) |
| `docs/generate_user_journeys.md` | Template for journey documents |
| `docs/modules/hair_nails_backend_directive.md` | Laravel/API contract: auth, envelopes, all `/hair-nails/*` endpoints, enums, QA |
| `docs/modules/skin_care.md` | Parallel module spec (pattern reference) |
| `docs/DESIGN.md` | UI system (monochrome, Material 3, touch targets) |

---

*Last updated: 2026-04-12 — aligned with `lib/hair_nails/`, integrations, cache, and `docs/modules/hair_nails_backend_directive.md`.*
