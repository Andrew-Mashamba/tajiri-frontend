# Hair & Nails — Complete User Journeys

**Module:** `lib/hair_nails/`  
**Source spec:** `docs/modules/hair_nails.md`

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget, Tajirika), and **Insightful** (reports, trends, recommendations).

---

## 1. HAIR & NAILS HOME (DASHBOARD)

**Entry:** Profile → **Hair & Nails** tab (`ProfileTabConfig` id `hair_nails`) → `HairNailsModule` → `HairNailsHomePage`  
**Stage/Context:** First visit (no profile) and returning user (profile, bookings, discovery). User must be logged in; APIs use `Authorization: Bearer` via `HairNailsService`.

### User Journey

1. User opens **Profile**, scrolls to module tabs, taps **"Hair & Nails"** / **"Nywele"** (`AppStrings` key `hair_nails`).
2. **Loading:** Full-screen `CircularProgressIndicator` (stroke 2, primary `#1A1A1A`) while **four parallel** requests run: `getHairProfile(userId)`, `getMyBookings(userId)`, `getStyleGallery(page: 1)`, `findSalons(page: 1)`.
3. **Empty profile — first time:** Card shows icon `face_rounded`, title **"Create Hair Profile"**, subtitle **"Know your hair type and get tailored advice"** → tap → `Navigator.push` → `HairProfilePage(userId)` **without** `existingProfile`.
4. **Profile exists:** Card shows circle icon for `hairType`, title **"Your Hair: [HairType.displayName]"** (e.g. Swahili curl label), subtitle **"[currentState] · [porosity]"**, optional **goal** chips as small capsules → tap **or** edit affordance → `HairProfilePage(..., existingProfile: profile)`.
5. **Quick actions row (4 equal columns):**
   - **"Find Salon"** / target Swahili: *"Tafuta Saluni"* → `SalonBrowsePage(userId)`.
   - **"Styles"** / *"Mitindo"* → `StyleGalleryPage(userId)`.
   - **"Growth"** / *"Ukuaji"* → `GrowthTrackerPage(userId)`.
   - **"Bookings"** / *"Miadi"* → `MyBookingsPage(userId)`.
6. **Upcoming bookings (if list non-empty):** Section title **"Upcoming Bookings"**, link **"All"** → `MyBookingsPage`. Up to **3** bookings where `status` is pending or confirmed (`Booking.isUpcoming`). Each row is `BookingCard` → tap → **today** navigates to `MyBookingsPage` (**gap:** open single-booking detail).
7. **Traction alopecia card:** Orange warning icon, title **"Traction Alopecia — Protect Your Hair"**, body copy on tight braids, pain, hairline thinning → **today:** read-only (**target:** "Learn more" → article or `DoctorModule`).
8. **Trending styles:** Title **"Trending Styles"**, **"All"** → `StyleGalleryPage`. Horizontal `ListView` of `StyleCard` (width ~150): image, title, category, estimated price/duration → tap → bottom sheet `_showStyleDetail(style)`; **Save** icon → `saveStyle(userId, styleId)` → **target:** snackbar "Saved" / *"Imehifadhiwa"*.
9. **Nearby salons:** Title **"Nearby Salons"**, **"All"** → `SalonBrowsePage`. Vertical list of `SalonCard` (image, name, rating, distance if present) → tap → `SalonDetailPage(userId, salon)`.
10. **Doctor CTA card:** Row: `medical_services_rounded`, title **"Scalp Problem?"**, subtitle **"Contact a dermatologist"** → `Navigator.pushNamed(context, '/doctor')` — **verify** `main.dart` route; **target:** `FindDoctorPage` with dermatology / scalp filter.
11. **Pull-to-refresh:** `RefreshIndicator` → `_loadData()` repeats step 2.
12. **Error path:** Failed API leaves section empty; **target:** per-section **Retry** + message; **today:** silent empty state (**gap**).
13. **Return path:** Back from sub-pages pops to Profile or previous stack; home does not use named route for module root.

### CRUD Operations

- **Create:** Not on home — delegated to `HairProfilePage`, `BookingPage`, `GrowthTrackerPage`, `saveStyle`.
- **Read:** Dashboard reads profile, bookings (upcoming filter), style gallery slice (6), salons slice (4).
- **Edit:** Not on home — user taps profile card → profile screen.
- **Delete:** Not on home.

### Notifications & Reminders

- 🔔 **Reminder (target):** `"Time to refresh your style? It's been [X] weeks since your last [service_name] at [salon_name]. Book again?"` / `"Muda wa kubadili mtindo?..."` — **When:** 6 weeks after completed braids/weave (configurable); **channel:** push + in-app; **max 1/week** for this module.
- 🔔 **Reminder (target):** `"📏 Log your hair length this month — you're [X] cm toward your goal."` / `"Andika urefu wa nywele..."` — **When:** 1st of month if no growth log in 28 days; **channel:** local notification.
- ⚠️ **Alert (target):** `"⚠️ Your booking at [salon_name] on [date] may conflict with another appointment."` — **When:** Calendar sync detects overlap; **channel:** in-app banner.
- 💡 **Prompt (target):** `"💡 For [porosity] hair in [climate], try a heavier sealant on wash day."` — **When:** After profile save or weekly; **channel:** in-app card (not push) to respect 2–3 push/day cap.
- 🎉 **Celebration (target):** `"🎉 First booking confirmed! We'll remind you before [date]."` — **When:** first successful `bookAppointment`; **channel:** in-app + optional push.
- 📊 **Summary (target, weekly):** `"This week: [X] salon visits planned, [Y] cm logged, [Z] styles saved."` — **When:** Sunday 18:00 local; **channel:** push digest.

### Reports & Insights

- **Home summary (target):** Next appointment date, streak of weeks with growth log, saved style count — **today:** not shown as KPI row.
- **Comparison (target):** This month vs last month average length from growth logs — **today:** not on home.

### Cross-Module Connections

- **Doctor:** Scalp CTA → doctor search; **target:** pass `MedicalSpecialty.dermatology` or query `scalp` / `hair loss`.
- **Calendar:** **Target:** sync confirmed booking as event `CalendarService.createEvent` — **today:** not wired.
- **Budget / ExpenditureService:** **Target:** on booking payment confirmed, offer **"Log TZS [amount] under Urembo / hair"** — **today:** not wired.
- **Shop:** **Target:** from porosity tip card → `ShopScreen` search `leave-in conditioner` + user region — **today:** not wired.
- **Wallet:** **Target:** pay deposit via `WalletService` when API supports — **today:** booking sends `payment_method` string only.
- **Shangazi AI:** **Target:** FAB or row **"Ask Shangazi about my hair"** with JSON: `hair_type`, `porosity`, `goals`, last `length_cm` — **today:** not wired.
- **Tajirika:** **Target:** **"Find a verified stylist"** → partner list filtered by skill `hair_nails` — **today:** skill id exists in `tajirika_models`; deep link **gap**.
- **Community (target):** Share style to group **"Natural hair Dar"** — **today:** not implemented.
- **Notifications (FCM):** **Target:** channel id `hair_nails` for module pushes — **today:** not registered separately.

---

## 2. HAIR PROFILE (ONBOARDING & EDIT)

**Entry:** `HairNailsHomePage` → **Create Hair Profile** card **or** tap existing profile card → `HairProfilePage`  
**Stage/Context:** First-time setup and any edit; data drives recommendations and copy tone.

### User Journey

1. **AppBar:** Back button pops; title **"Profaili ya Nywele"** / **target EN:** `"Hair Profile"` via `AppStrings`.
2. **Hair type (single select):** Scrollable cards for each `HairType` (`straight1` … `coily4c`): **short label** (e.g. **"4A"**), **Swahili `displayName`**, **description** line, **icon** — tap selects one; selected: darker border/fill + check.
3. **Porosity:** Three options **Low / Normal / High** with Swahili subtitles from `Porosity.displayName` — tap one.
4. **Density:** **Thin / Medium / Thick** (`HairDensity`) — tap one.
5. **Current state:** **Natural / Relaxed / Transitioning / Color treated / Dreadlocks** (`HairState`) — tap one.
6. **Scalp condition (optional):** Filter chips: **Nzuri, Kavu, Mafuta mengi, Dandruff, Kuwasha, Ngozi nyeti** — multi-select style or single per product decision (**today:** single-select style from list).
7. **Goals (multi-select):** Chips from fixed list (e.g. **Ukuaji wa nywele**, **Kupunguza kung'oleka**, **Unyevu zaidi**, …) — tap to toggle.
8. **Length (cm):** **NOT AVAILABLE in UI** — API supports `length_cm`; **gap:** add `TextField` (number) + validation 0–200 cm.
9. **Save:** Primary button **"Hifadhi"** / **"Save"** → `saveHairProfile(...)` → `POST /hair-nails/profile` with JSON keys `user_id`, `hair_type`, `porosity`, `density`, `current_state`, optional `scalp_condition`, `goals`, optional `length_cm`.
10. **Success:** `SnackBar` **"Profaili imehifadhiwa"** (green/dark) → `Navigator.pop`.
11. **Failure:** Red `SnackBar` with `result.message` (API validation).
12. **Network error:** Same red snackbar with generic **"Kosa: …"** — **target:** queue to Hive and retry (**gap**).

### CRUD Operations

- **Create:** First successful POST creates server row; same form used.
- **Read:** Pre-fill from `existingProfile` when `HairProfile.fromJson` data present.
- **Edit:** Same form overwrites; upsert semantics server-side.
- **Delete:** **NOT AVAILABLE** — no delete profile in UI (**gap** if product requires account reset).

### Notifications & Reminders

- 🔔 **Reminder (target):** `"Update your hair profile — your goals or routine may have changed."` / `"Sasisha profaili ya nywele..."` — **When:** every 90 days if no edit; **channel:** in-app card.
- 💡 **Prompt (target):** `"💡 You selected [hair_type] + high porosity — see product tips in Shop."` — **When:** after save; **channel:** in-app.
- ⚠️ **Alert (target):** `"⚠️ Tight styles with your current goals may slow growth — see traction tips."` — **When:** goals include growth + user frequently books braids (inferred from bookings); **channel:** in-app.

### Reports & Insights

- **Profile completeness (target):** % of fields filled including optional scalp — drives recommendation quality score.
- **Porosity tip (today):** Static strings in `Porosity.tip` — show on profile or home card (**target:** surface after save).

### Cross-Module Connections

- **Shop:** Deep link search **"porosity [low|high] hair oil TZS"** after profile save — **target.**
- **Shangazi AI:** Context payload: `{ hair_type, porosity, density, current_state, goals[] }` for **"What routine for 4C in Dar humidity?"**
- **Doctor:** If scalp chip **Kuwasha** / persistent dandruff selected → offer **Book dermatologist** — **target.**
- **Budget:** **Target:** tag future product purchases under personal care — **today:** N/A until Shop link.

---

## 3. SALON BROWSE & DISCOVERY

**Entry:** `HairNailsHomePage` → **Find Salon** quick action → `SalonBrowsePage`  
**Stage/Context:** User searches for hair/nails/skin services by text, category, rating, or salon type.

### User Journey

1. **AppBar:** Back; title **"Find Salons"** / target **"Tafuta Saluni"**.
2. **Search field:** `TextField` with hint **Search…** / *"Tafuta…"* → on submit or debounce → `findSalons(search: query, page: 1)`.
3. **Filters (per implementation):** Toggles or chips for **category** (`hair` / `nails` / `skin`), **min rating**, **home based**, **mobile**, **walk in** — map to query params `category`, `min_rating`, `home_based=1`, `mobile=1`, `walk_in=1`.
4. **Location (target):** Pass `latitude`, `longitude` when permission granted → backend returns `distance_km` — **today:** optional if app sets coords.
5. **List:** `SalonCard` per row: `image_url`, **name**, **rating** stars, **distanceKm** if present, **verified** badge — tap → `SalonDetailPage`.
6. **Pagination:** **target:** scroll to load `page++` — **today:** verify `findSalons` page usage in page code.
7. **Empty state:** No salons → illustration or text **"No salons found"** / *"Hakuna saluni"* + clear filters.
8. **Error:** Snackbar or inline error; **target:** Retry button.

### CRUD Operations

- **Create:** **NOT AVAILABLE** — salon records created by admin/partner onboarding, not end user.
- **Read:** List + detail fetched via API.
- **Edit / Delete:** **NOT AVAILABLE** for consumer role.

### Notifications & Reminders

- 💡 **Prompt (target):** `"💡 New highly rated salon near [area]: [salon_name] ([X] km)."` — **When:** weekly if `latitude/longitude` set and new salon in radius; **channel:** in-app.
- 📊 **Summary (target):** `"Salons you viewed: [X] — still interested in [category]?"` — **When:** abandoned browse session; **channel:** in-app only.

### Reports & Insights

- **Search analytics (target):** Top queries, filter usage — product analytics only.
- **Price range insight (target):** **"In your area, braids average TZS [X]–[Y]"** — requires backend aggregation.

### Cross-Module Connections

- **Tajirika:** Button **"Book independent stylist"** → partners with `hair_nails` skill — **target.**
- **Maps / device location:** For distance sort — **target:** `geolocator` or platform location.
- **Community (target):** **"Ask who does [style] in [ward]"** → community post pre-filled — **today:** N/A.

---

## 4. SALON DETAIL

**Entry:** `SalonBrowsePage` or home **Nearby Salons** → tap `SalonCard` → `SalonDetailPage`  
**Stage/Context:** User evaluates trust before booking.

### User Journey

1. **Load:** `getSalonDetail(salonId)` + `getSalonReviews(salonId, page)` — show name, `description`, `opening_hours`, `photos`, `is_verified`, `is_home_based`, `is_mobile`, `is_walk_in`.
2. **Services list:** Each `SalonService`: **name**, **category** (hair/nails/skin), **price** (TZS formatted), **duration_minutes**, **description** — tap **Book** on row → `BookingPage(userId, salon, preselectedService: service)`.
3. **Staff:** Optional `SalonStaff` avatars, names, **specialty**, **experience_years**.
4. **Reviews:** List `SalonReview`: **user_name**, **rating**, **comment**, **created_at** — pagination **target** for more pages.
5. **Primary CTA:** **"Book Now"** / **"Weka Miadi"** → `BookingPage` without preselected service if tapped from header.
6. **Share (target):** Share sheet with salon name + deep link — **today:** **NOT AVAILABLE**.

### CRUD Operations

- **Read:** Salon, services, staff, reviews.
- **Create / Edit / Delete:** **NOT AVAILABLE** for consumer.

### Notifications & Reminders

- ⚠️ **Alert (target):** `"⚠️ [salon_name] has new reviews since your last visit."` — **When:** salon rating changes ±0.3; **channel:** in-app.

### Reports & Insights

- **Salon trust score (target):** Composite: verified + review count + response rate — **backend.**

### Cross-Module Connections

- **Doctor:** If salon flagged for chemical injury reports (future) → warning — **speculative.**
- **Wallet / Budget:** Display **deposit** line item when API exposes — **target.**

---

## 5. BOOK APPOINTMENT

**Entry:** `SalonDetailPage` → **Book** / **Book Now** → `BookingPage`  
**Stage/Context:** User selects service, slot, and payment contact.

### User Journey

1. **Step indicator:** Multi-step UI (`_step` 0–2): **Service** → **Date & time** → **Confirm**.
2. **Step 0 — Service:** List `salon.services`; each row shows **name**, **TZS price**, **duration**; tap selects `_selectedService`. If `preselectedService` passed from detail, **skip** to step 1.
3. **Step 1 — Date:** Tap **Choose date** → `showDatePicker` — **firstDate:** today; **lastDate:** today + 90 days; Swahili weekday labels in `_fmtDate` (Jumatatu, …). **Time:** `showTimePicker` — default e.g. 10:00. Combined into single `DateTime` for API.
4. **Step 2 — Confirm:** **Notes** `TextField` (optional); **Payment method** selector (e.g. **M-Pesa**, **Cash**, **Card**) → `_paymentMethod` string; **Phone** `TextField` for M-Pesa number (normalize **+255** pattern **target**).
5. **Primary button:** **"Confirm Booking"** / **"Thibitisha Miadi"** → `bookAppointment(userId, salonId, serviceId, dateTime, notes, paymentMethod, phoneNumber)` → `POST /hair-nails/bookings`.
6. **Success:** Pop stack or show success dialog; **target:** add to **Calendar**, send push **"Booking confirmed at [salon] on [date_time]"**.
7. **Failure:** Snackbar with API `message`; stay on confirm step for retry.
8. **Validation:** If service null, date in past, or phone invalid → inline error — **target:** `Form` validators.

### CRUD Operations

- **Create:** One booking row per confirmation.
- **Read:** Via My Bookings, not on this screen after leave.
- **Edit:** **NOT AVAILABLE** — reschedule **target** future API — **today:** cancel + rebook (**gap**).
- **Delete:** Cancel from **My Bookings**, not here.

### Notifications & Reminders

- 🔔 **Reminder:** `"Your appointment at [salon_name] is tomorrow at [time]. Tap for directions."` / `"Kesho una miadi..."` — **When:** T-24h; **channel:** push.
- 🔔 **Reminder:** `"In 1 hour: [service_name] at [salon_name]."` — **When:** T-1h; **channel:** local notification.
- 🎉 **Celebration:** `"🎉 Booking confirmed! [salon_name] · [date] · TZS [amount]"` — **When:** HTTP 200 + `success`; **channel:** in-app + push once.

### Reports & Insights

- **Spend (target):** Sum `total_amount` by month for **"Hair & nails spend"** chart in Budget module.

### Cross-Module Connections

- **Calendar:** **Target:** `CalendarService.createEvent(title: "[service] @ [salon]", start: dateTime, duration: durationMinutes)` — **today:** **NOT wired**.
- **Wallet:** **Target:** pay deposit when API returns payment URL — **today:** metadata only.
- **Budget / ExpenditureService:** **Target:** prompt **"Log TZS [amount] as Urembo expense?"** after confirmation — **today:** **NOT wired**.
- **Maps (target):** **"Open in Google Maps"** using salon `latitude`/`longitude` — **today:** **gap** if coords null.

---

## 6. MY BOOKINGS

**Entry:** Home **Bookings** quick action **or** **All** from upcoming **or** tap booking row → `MyBookingsPage`  
**Stage/Context:** View, cancel, or rate past appointments.

### User Journey

1. **Load:** `getMyBookings(userId)` → list of `Booking` sorted by UI (typically newest first — verify implementation).
2. **Card:** Shows **salon_image_url**, **salon_name**, **service_name**, **date_time**, **status** badge (color: pending orange, confirmed green, etc.), **total_amount** TZS, **payment_status**.
3. **Upcoming (pending/confirmed):** Button **"Cancel"** / **"Futa"** → **target:** `AlertDialog` **"Cancel booking? [policy text]"** → `cancelBooking(id)` → `POST .../bookings/{id}/cancel`.
4. **Completed:** Button **"Rate"** / **"Tathmini"** → dialog: **star rating 1–5**, optional **comment** `TextField` → `rateBooking(bookingId, rating, comment)` → `POST .../bookings/{id}/rate`.
5. **Cancelled:** Read-only; **target:** **"Book again"** → `SalonDetailPage` with same salon id — **today:** **gap**.
6. **Empty:** **"No bookings yet"** / *"Huna miadi"* + CTA **Find salon**.
7. **Error:** Failed GET → snackbar; **target:** Retry.

### CRUD Operations

- **Create:** From `BookingPage` only.
- **Read:** Full list for user.
- **Edit:** **NOT AVAILABLE** — reschedule **gap**.
- **Delete:** Cancel maps to **cancelled** status (soft delete semantics).

### Notifications & Reminders

- ⚠️ **Alert:** `"Your booking was cancelled. Reason: [message]"` — **When:** salon cancels server-side; **channel:** push.
- 🎉 **Celebration (target):** `"Thanks for rating [salon_name]! Your review helps others."` — **When:** after successful rate; **channel:** in-app.

### Reports & Insights

- **Year summary (target):** Total spent, visits count, average rating given — **export PDF** for taxes/personal — **today:** **NOT AVAILABLE**.

### Cross-Module Connections

- **Doctor:** If user rates low + comment mentions **burn/itch** → offer **Report to platform** + **Doctor** — **target:** moderation pipeline.
- **Tajirika:** **Target:** stylist sees review on partner dashboard — **backend**.

---

## 7. STYLE GALLERY & SAVED STYLES

**Entry:** Home **Styles** quick action **or** **Trending Styles → All** → `StyleGalleryPage`  
**Stage/Context:** Inspiration for braids, twists, locs, weaves, natural, updos, **nails**.

### User Journey

1. **Load:** `getStyleGallery(category: optional, page: 1)` — grid of `StyleInspiration`.
2. **Category chips (target):** Filter by `StyleCategory` — **Misuko, Twists, Dreadlocks, Weave, Asili, Mtindo wa Juu, Kucha** — **today:** verify chip wiring in page.
3. **Card:** `image_url`, **title**, **category**, **estimated_price** TZS, **estimated_duration_minutes** (`durationLabel` e.g. **"2saa 30dk"**).
4. **Tap:** Detail bottom sheet or full screen — description, **hair_type_recommended** list.
5. **Save:** Heart / save icon → `saveStyle(userId, styleId)` → `POST /hair-nails/styles/{id}/save` with body `{ user_id }`.
6. **Saved list (target):** Tab or screen calling `getSavedStyles(userId)` — **today:** **API exists**; **UI exposure gap** — confirm if gallery has **Saved** tab.
7. **Empty:** **"No styles in this category"** — clear filter CTA.
8. **Share (target):** Share image + title to feed — **today:** **NOT AVAILABLE**.

### CRUD Operations

- **Create:** Save adds row in join table user↔style (server-side).
- **Read:** Gallery + **target** saved list.
- **Edit:** **NOT AVAILABLE**.
- **Delete / Unsave:** **Target:** `DELETE` or `POST .../unsave` — **today:** verify API (**gap** if missing).

### Notifications & Reminders

- 💡 **Prompt:** `"💡 You saved [style_title] — find a stylist who does this near you."` — **When:** 24h after save if no booking; **channel:** in-app.
- 📊 **Summary (target):** `"Your inspo board: [X] styles saved this month."` — **When:** monthly; **channel:** in-app.

### Reports & Insights

- **Trending (target):** Which categories saved most in region — editorial rails on home.

### Cross-Module Connections

- **Salon browse:** **Target:** filter salons offering **similar category** — deep link from style detail.
- **Shop:** **Target:** nail polish / gel matching **nails** category style — product search query.
- **Shangazi AI:** **"Will [style] work for my [hair_type]?"** with profile + style id.
- **Feed / Stories (target):** Post **"Trying [style] this weekend"** — **today:** N/A.

---

## 8. GROWTH TRACKER

**Entry:** Home **Growth** quick action → `GrowthTrackerPage`  
**Stage/Context:** Users tracking **length (cm)** over months; optional photo for motivation.

### User Journey

1. **History:** `getGrowthHistory(userId)` → vertical list of `GrowthLog`: **date**, **length_cm**, **photo** thumbnail, **notes**.
2. **Log new:** **Target fields:** `TextField` **Length (cm)** decimal; **Notes** optional; **Add photo** → camera/gallery → upload → **photo_url** for POST — **today:** verify if photo uses existing file pipeline or manual URL (**gap** vs `FILE_MANAGEMENT` directive).
3. **Submit:** **"Save"** / **"Hifadhi"** → `logGrowth(userId, lengthCm, photoUrl, notes)` → `POST /hair-nails/growth`.
4. **Success:** Snackbar + list refresh; **target:** confetti or gentle **"Nice progress"** without body-shaming.
5. **Chart (target):** Line chart length vs date — **today:** list only (**gap**).
6. **Privacy (target):** Toggle **"Keep growth photos private"** — excludes from feed — **today:** **NOT AVAILABLE**.

### CRUD Operations

- **Create:** New log entry each save (not overwrite unless API defines upsert by date).
- **Read:** History list.
- **Edit:** **NOT AVAILABLE** — **target:** edit log within 24h — **gap**.
- **Delete:** **NOT AVAILABLE** — **gap**.

### Notifications & Reminders

- 🔔 **Reminder:** `"📏 Time to measure — last log was [days] ago."` / `"Ni wakati wa kupima..."` — **When:** 30 days since last log; **channel:** local notification.
- 🎉 **Celebration:** `"🎉 +[X] cm since [month]! Keep protecting those ends."` — **When:** new log increases vs previous by ≥1 cm; **channel:** in-app.
- ⚠️ **Alert (target):** `"Length dropped vs last log — check for breakage or remeasure."` — **When:** new cm < previous −2 cm; **channel:** in-app.

### Reports & Insights

- **Trend:** 3 / 6 / 12 month slope of `length_cm`.
- **Comparison (target):** **"Vs your goal: [X] cm to go"** if goal stored — **today:** goal not in growth model (**gap**).

### Cross-Module Connections

- **Doctor:** Persistent loss → **"Discuss with dermatologist"** — **target:** in-app card.
- **Shangazi AI:** Pass last 3 logs for **"Why is my growth slow?"**
- **My Circle (target):** Optional link if postpartum hair shedding — sensitive copy — **future.**

---

## 9. TRACTION ALOPECIA AWARENESS (HOME EDUCATION)

**Entry:** Visible on `HairNailsHomePage` below bookings / above trending styles  
**Stage/Context:** Prevention messaging for tight styles — **not** a separate route.

### User Journey

1. User reads **title** **"Traction Alopecia — Protect Your Hair"** and **body** on pain, thinning hairline, braids/weaves.
2. **Today:** No **Learn more** button — **target:** navigate to static article route or FAQ.
3. **Target:** **"Check my scalp"** checklist → 3 questions → if high risk, suggest **Doctor** booking.

### CRUD Operations

- **Read:** Static content only.
- **Create / Edit / Delete:** **NOT AVAILABLE** (content is code or remote config **target**).

### Notifications & Reminders

- 💡 **Prompt:** `"💡 Taking a 2-week break between weaves reduces traction risk."` — **When:** after user books weave twice in 6 weeks; **channel:** in-app.
- ⚠️ **Alert (target):** `"⚠️ You reported scalp pain — consider looser braids."` — **When:** future pain tag in diary — **today:** N/A.

### Reports & Insights

- **Awareness (target):** % users who opened article — analytics.

### Cross-Module Connections

- **Doctor:** Primary escalation for persistent symptoms.
- **Shangazi AI:** **"What is traction alopecia?"** one-tap.

---

## NOTIFICATION CHANNELS SUMMARY

| Channel / id | Trigger | Frequency cap |
|--------------|---------|----------------|
| **hair_nails (target)** | Booking T-24h, T-1h; growth monthly; style save follow-up | **Max 2–3 push/day** module-wide; prefer in-app cards for lower priority |
| **Local (flutter_local_notifications)** | Growth measure reminder, booking hour-before | Per user opt-in in Settings |
| **In-app** | Porosity tips, traction prompts, salon new reviews | Unlimited cards; no spam: max 2 visible on home |

---

## CROSS-MODULE INTEGRATION MAP

| From Hair & Nails | To Module | Trigger |
|--------------------|-----------|---------|
| Scalp / hair loss CTA | **Doctor** | Home card, growth drop, traction concern |
| Booking confirmed | **Calendar** | Create event with salon datetime + duration |
| Booking paid / deposit | **Wallet** | Payment URL or M-Pesa flow |
| Booking amount | **Budget / ExpenditureService** | Prompt to log under Urembo / personal care |
| Porosity + goals | **Shop** | Search oils, leave-in, satin bonnet |
| Style saved | **Shop** | Nails category → polish/gel keywords |
| Profile + growth logs | **Shangazi AI** | "Ask Shangazi about my hair" |
| Verified stylist discovery | **Tajirika** | Skill `hair_nails`, book partner |
| Tight-style frequency (target) | **Community** | Optional anonymous question |
| Nail service booked (target) | **Pharmacy** | Aftercare (cuticle oil) — weak link; optional |

---

## Related documents

| Document | Purpose |
|----------|---------|
| `docs/modules/hair_nails.md` | Module spec, persona, API overview, gaps |
| `docs/modules/hair_nails_backend_directive.md` | Laravel contract for `/hair-nails/*` |
| `docs/generate_user_journeys.md` | How this file was structured |
| `docs/DESIGN.md` | UI system |

---

*Document aligned with `docs/generate_user_journeys.md` structure. Update when flows ship (l10n, Calendar, Budget hooks, saved-styles UI, growth charts).*
