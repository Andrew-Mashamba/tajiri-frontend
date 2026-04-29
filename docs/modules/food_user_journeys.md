# Food Module — Complete User Journeys

**Module:** lib/food/
**Source spec:** docs/modules/food.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget, zaka, fungu la kumi, michango, jumuiya), and **Insightful** (reports, trends, recommendations).

---

## 1. RESTAURANT DISCOVERY

**Entry:** Home → Food tab → FoodHomePage
**Stage/Context:** Anyone hungry, wants a restaurant meal

### User Journey
1. User opens Food module → lands on `FoodHomePage`
2. Sees five rails in order: **Active Orders**, **Wapishi wa Nyumbani**, **Chakula cha Leo**, **Saidia Sasa**, **Mikahawa ya Karibu** ("Restaurants Near You")
3. Mikahawa rail shows up to 10 `RestaurantCard` widgets sorted by distance from user's ward
4. Each card: photo, name, cuisine tags, "15–25 min" delivery estimate, rating badge, "Wazi" / "Closed" status pill
5. Tap "See all" / "Ona zote" → navigates to full restaurant list with filters (cuisine, price band, open-now, free-delivery)
6. Pull-to-refresh re-runs `_loadData` parallel fetch
7. Empty state: "No restaurants serving your ward yet" / "Hakuna mikahawa inayohudumia eneo lako bado" + "Suggest one" / "Pendekeza mkahawa" button → opens chat to Shangazi

### CRUD Operations
- **Create:** NOT APPLICABLE (restaurants onboard via backend / partner flow)
- **Read:** `GET /api/food/restaurants?ward=&cuisine=&open=` — paginated list; `GET /api/food/restaurants/{id}` for detail
- **Edit:** NOT APPLICABLE (owner-side only, not in this module)
- **Delete:** NOT APPLICABLE

### Notifications & Reminders
- 💡 **Lunch prompt:** Daily 11:30am: "Hungry for lunch? [top restaurant in ward] has [cuisine] ready" (opt-in)
- 💡 **Dinner prompt:** Daily 6:00pm: "Dinner idea: [restaurant] — 20 min to your door"
- 🎉 **New restaurant:** When a new restaurant opens in user's ward: "🍽️ New in [ward]: [restaurant name] just opened. Tap to browse"
- ⚠️ **Favourite unavailable:** If a saved restaurant goes offline: "[restaurant] is closed today. Try [similar nearby]"
- 📊 **Weekly digest:** Friday 5pm: "This week in [ward]: 3 new restaurants, [name] had the fastest delivery (avg 18 min)"

### Reports & Insights
- **Ward heatmap:** Which cuisines dominate this ward (user's) — pie chart
- **Open-now count:** Live count of open restaurants updated every 10 min
- **Your top cuisines:** Based on last 30 days of orders — top 3 cuisines with order count
- **Delivery-time benchmarks:** "Average delivery in your ward: 22 min. [restaurant] is faster (15 min)."

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi what's good for dinner in [ward]" — passes ward + recent cuisine history
- **Calendar:** If user has a scheduled event (e.g., birthday), suggest "Order dinner for [X] people for [date]" 2 days ahead
- **Budget:** Each order recorded as `food` / `chakula` expenditure line on checkout
- **Wallet:** Pays from wallet balance or tops up via M-Pesa on demand

---

## 2. RESTAURANT STOREFRONT & MENU

**Entry:** FoodHomePage → tap `RestaurantCard` → `RestaurantPage`
**Stage/Context:** Browsing what a specific restaurant offers

### User Journey
1. User taps a restaurant card
2. `RestaurantPage` loads: hero image, name, cuisine, rating, distance, delivery estimate, working hours, halal / vegetarian / no-pork tags
3. Sticky category chips: "Popular", "Starters", "Mains", "Desserts", "Drinks" — horizontal scroll, tap to jump
4. Menu list: each `MenuItemCard` shows photo, name, short description, price in TZS, "+" button to add to cart
5. Out-of-stock items: greyed out with "Imeisha" / "Out" badge
6. Bottom sheet persists cart total: "3 items • TZS 18,500 • View Cart" / "Ona Kikapu"
7. Reviews accordion at bottom: star breakdown, 5 most recent reviews
8. "Call restaurant" / "Piga simu" quick-action for questions
9. Back navigates with cart preserved

### CRUD Operations
- **Create (cart line):** Tap "+" on menu item → local cart state mutated; "-" and quantity editor once added
- **Read:** `GET /api/food/restaurants/{id}/menu` — categorised menu with availability; `GET /api/food/restaurants/{id}/reviews`
- **Edit:** Quantity and customisations per menu item in cart (see #3)
- **Delete:** Swipe cart line → remove

### Notifications & Reminders
- 🔔 **Restaurant opens:** If user opened a restaurant that was closed: "[restaurant] is now open. Ready to order?"
- 💡 **Menu item back in stock:** Daily at 11am if a favourite item returns: "[item] is back at [restaurant] today!"
- 🎉 **First order at new restaurant:** "🎉 Karibu to [restaurant]! Rate your meal when it arrives"
- ⚠️ **Price changed:** If a saved favourite's price went up >15%: "[item] is now TZS [new] (was TZS [old]) at [restaurant]"

### Reports & Insights
- **Dish-level popularity:** "Most ordered in [ward]: [dish] — 42 orders this week"
- **Personal history:** "You've ordered from [restaurant] [X] times. Your usual: [dishes]"
- **Nutritional tag summary** (if menu tagged): vegetarian %, halal %, allergen overview

### Cross-Module Connections
- **Pharmacy:** If user's profile has an allergen flag and a menu item contains it → red warning: "Contains [nuts] — may trigger your allergy. Need antihistamines? Open Pharmacy"
- **Shangazi AI:** "Ask Shangazi: is this dish healthy for me?" — passes dish tags + user health context
- **Doctor:** If health profile includes diabetes / hypertension → inline tag "Watch sugar" on dessert items with "Book nutrition consult" link → DoctorModule

---

## 3. CART & CUSTOMISATION

**Entry:** RestaurantPage → bottom bar "View Cart" / "Ona Kikapu"
**Stage/Context:** Building an order before checkout

### User Journey
1. Tap "View Cart" → `CartPage` opens
2. Shows line items grouped by restaurant, each with: photo, name, unit price, quantity (+/-), customisations (e.g. "No onions"), line total
3. "Add special instructions" / "Ongeza maagizo" textfield per item (max 120 chars)
4. Subtotal, delivery fee, service fee, total in TZS
5. Delivery vs Pickup toggle: **"Deliver" / "Leta nyumbani"** vs **"Pickup" / "Nichukue mwenyewe"** — delivery fee hidden when pickup
6. Coupon field: "Code / Kodi" → apply → validation → discount shows as negative line
7. Delivery address: auto-filled from profile ward + house number; tap to edit on a mini-map
8. Payment method selector: Wallet balance / M-Pesa / Tigo Pesa / Airtel Money — shows balance inline
9. "Place Order" / "Weka Oda" primary button → API call → on success, navigates to order tracking
10. Error paths: empty cart → button disabled; network fail → snackbar "Retry" / "Jaribu tena"; insufficient wallet → prompts top-up

### CRUD Operations
- **Create:** `POST /api/food/orders` with `{restaurant_id, items:[{menu_item_id, qty, notes}], delivery|pickup, address, payment_method}`
- **Read:** Cart is local until placed; `GET /api/food/orders/{id}` after placement
- **Edit:** Quantity +/- inline; remove line; update instructions — all local until placed
- **Delete:** "Clear cart" / "Futa kikapu" button with confirmation

### Notifications & Reminders
- 🔔 **Abandoned cart:** 2 hours later if unplaced: "You left [X] items in your cart at [restaurant]. Still hungry?"
- ⚠️ **Restaurant closing soon:** If restaurant closes in <30 min while cart is open: "⚠️ [restaurant] closes at [time]. Place your order now"
- ⚠️ **Item sold out while browsing:** "[item] just sold out at [restaurant]. Swap for [similar]?"
- 💡 **Free delivery threshold:** "Add TZS [X] more for free delivery"

### Reports & Insights
- **Cart analytics:** Average cart value per restaurant, typical item count
- **Promotion yield:** "You saved TZS [X] with promos in the last 30 days"
- **Best-value combos:** "Order combo [X] — saves TZS 2,500 vs separate items"

### Cross-Module Connections
- **Wallet:** Debits balance on "Place Order"; returns to Wallet on top-up flow
- **Budget:** `chakula` expenditure line posted on successful order via `ExpenditureService.log({category:'chakula', amount, source:'food_module', ref:order_id})`
- **Calendar:** If order is scheduled for future pickup, drop event on Calendar with pickup time
- **Family:** "Ordering for the family?" quick toggle — splits the bill reminder across parents in same household via MyFamilyService
- **Shangazi AI:** "Ask Shangazi: is this too much food for [X] people?" — passes cart items + headcount

---

## 4. ORDER TRACKING

**Entry:** After placing order OR FoodHomePage → "Active Orders" rail → tap order card OR `FoodOrdersPage`
**Stage/Context:** Waiting for food to arrive

### User Journey
1. `OrderTrackingPage` opens with stepper: **Placed → Accepted → Preparing → Out for Delivery → Delivered** (pickup flow collapses to **Placed → Ready for Pickup → Picked Up**)
2. Top card: restaurant name, order number, ETA countdown ("Arrives in 18 min" / "Inafika baada ya dakika 18")
3. Live map when `out_for_delivery` — courier marker + route polyline to the destination
4. Courier info card once assigned: name, photo, plate / bicycle, phone button, chat button
5. Item list collapse: what was ordered, customisations
6. "Call restaurant" and "Chat courier" secondary actions
7. "Cancel order" / "Ghairi oda" visible only until `accepted`; after that, contact support link
8. On `delivered`: auto-prompt "Rate your meal" modal — 1–5 stars + optional photo + comment
9. Past orders below: scrollable history

### CRUD Operations
- **Create:** See #3
- **Read:** `GET /api/food/orders/{id}` (polling every 15s) + FCM push for status changes
- **Edit:** Limited — "Call restaurant to request change" link only
- **Delete/Cancel:** `POST /api/food/orders/{id}/cancel` within window; refund to wallet

### Notifications & Reminders
- 🔔 **Accepted:** "✅ [restaurant] accepted your order. Preparing now..."
- 🔔 **Cooking:** "👩‍🍳 [name from restaurant] is preparing your order"
- 🔔 **Courier assigned:** "🛵 [courier] is picking up your order (ETA [X] min)"
- 🔔 **Out for delivery:** "🚴 [courier] is on the way — arriving in [X] min"
- 🔔 **Arriving:** "📍 [courier] is 2 min away. Please be ready"
- 🎉 **Delivered:** "🎉 Your order has arrived! Rate [restaurant] and earn 10 Tajiri points"
- ⚠️ **Delayed:** "⚠️ Order is running [X] min late. [Restaurant] is working on it"
- ⚠️ **Cancelled by restaurant:** "[restaurant] cancelled your order. Full refund issued to your wallet"

### Reports & Insights
- **Per-order timeline:** Each step stamped with actual timestamp — compare with ETA
- **Courier performance:** Your last 10 deliveries — avg ETA vs actual
- **On-time rate by restaurant:** "[restaurant] is on-time 94% of the time"

### Cross-Module Connections
- **Calendar:** Delivery ETA surfaced as a short-lived calendar tile
- **Wallet:** Refunds on cancellation write back via WalletService
- **Notifications:** Each status change → FCM push + local notification; stepper updates in-app
- **Doctor:** "Food not arrived on time and you have a clinic appointment? Reschedule" → DoctorModule
- **Shangazi AI:** "Ask Shangazi what to cook if delivery fails"

---

## 5. ORDER HISTORY & REORDER

**Entry:** FoodHomePage → "Orders" tab OR Profile → "My orders" → `FoodOrdersPage`
**Stage/Context:** Looking back / repeating a past order

### User Journey
1. `FoodOrdersPage` shows tabs: **Active**, **Past**, **Cancelled**
2. Each `OrderCard`: restaurant, date/time, total, status badge, primary CTA depending on status: "Track" / "Reorder" / "Rate"
3. Tap card → order detail (items, receipt, delivery address, courier contact if available)
4. **Reorder** / "Agiza tena" → pre-fills cart with original items → jumps to `CartPage` (prices refreshed, out-of-stock items flagged)
5. **Rate & Review** → 1–5 stars, photo upload, text; posts back to `POST /api/food/reviews`
6. **Report issue** / "Ripoti tatizo" → categorised form: missing item, cold food, wrong item, hygiene → opens ticket in support
7. Filter: by restaurant, by date range, by minimum amount

### CRUD Operations
- **Create (reorder / review / report):** `POST /api/food/orders` (new), `POST /api/food/reviews`, `POST /api/food/support-tickets`
- **Read:** `GET /api/food/orders/mine?status=&from=&to=`
- **Edit:** Edit review within 24h; otherwise read-only
- **Delete:** Delete own review → `DELETE /api/food/reviews/{id}`

### Notifications & Reminders
- 🔔 **Rate nudge:** 2h after delivery if unrated: "How was your meal from [restaurant]?"
- 💡 **Reorder prompt:** If user ordered the same dish 3x in 30 days: "Craving [dish] again? One-tap reorder"
- 📊 **Monthly summary:** Last day of month: "📊 You spent TZS [X] on food in [month]. [Y] orders from [Z] restaurants"
- 🎉 **Loyalty milestone:** "🎉 10th order from [restaurant]! You've earned a 15% off coupon"

### Reports & Insights
- **Spending breakdown:** Chart by month — dine-in, delivery, pickup, home-chef, donation (imputed)
- **Cuisine preferences:** Top 5 cuisines by count and spend
- **Restaurant loyalty:** Which restaurants get repeat orders
- **Waste alert:** "You ordered and refunded [X] meals this month — try smaller portions?"

### Cross-Module Connections
- **Budget:** Monthly food spend pushed to Budget as a `chakula` envelope insight
- **Wallet:** Spend totals flow into Wallet's monthly report
- **Shop:** "Liked the sauces from [restaurant]? Shop similar" → Shop
- **Shangazi AI:** "Ask Shangazi to plan cheaper weekly meals" — passes 30-day order history

---

## 6. HOME CHEF DISCOVERY — "WAPISHI WA NYUMBANI"

**Entry:** FoodHomePage → "Wapishi wa Nyumbani" rail → "See all" → `FoodChefsPage`
**Stage/Context:** Wants a home-cooked meal, not a restaurant

### User Journey
1. FoodHomePage rail: top 5 `ChefCard`s, rating-sorted
2. "See all" / "Ona wote" → `FoodChefsPage`
3. Search bar: "Tafuta mpishi, mahali..." — filters by name, bio, service area
4. Client-side search live-filters current list (already shipped)
5. Each card: photo (or initials fallback), name, "Wazi" badge if active, skill pills (cooking / catering / baking), bio preview, rating + jobs-completed OR "Mpya" badge, location
6. Tap card → Chef storefront (#7)
7. Empty state: "No chefs in your ward yet" / "Hakuna wapishi katika eneo lako" + "Invite a friend to join as a chef" CTA → share link
8. Pull-to-refresh re-runs `fetchFoodChefs()` (three parallel skill queries, deduped, rating-sorted)

### CRUD Operations
- **Create (chef):** NOT IN THIS FLOW — chefs onboard via Tajirika partner registration (cooking / catering / baking skills)
- **Read:** `fetchFoodChefs()` → three parallel `TajirikaService.searchPartners(skills:[...])` calls, dedup by `partner.id`
- **Edit:** NOT APPLICABLE (buyer-side)
- **Delete:** NOT APPLICABLE

### Notifications & Reminders
- 🎉 **New chef in ward:** "🍲 [chef name] just joined [ward]! Known for [top skill]. Say hello"
- 💡 **Chef availability:** If a favourited chef posts `today_extra`: "🔥 [chef] has [dish] at ⅓ off — 2h to pick up"
- 📊 **Weekly chef digest:** Sunday 6pm: "This week: [N] chefs active in [ward], top dish: [dish]"
- ⚠️ **Chef deactivated:** If a favourited chef toggles off: "[chef] is taking a break. We'll let you know when they're back"

### Reports & Insights
- **Ward chef density:** "[N] active chefs within [km] of you"
- **Top rated this month:** Leaderboard in ward
- **Your chef activity:** Orders placed, reviews written, amount spent at home chefs

### Cross-Module Connections
- **Tajirika:** Chef card tap opens `PartnerProfilePage` today; once storefront ships (step 4 of roadmap), replaces it
- **Shangazi AI:** "Ask Shangazi to recommend a chef for [event/diet]" — passes ward + occasion
- **Calendar:** Tap "Book [chef] for Saturday" from card → CalendarService event with chef linked
- **Chat:** Message chef directly → opens conversation via MessageService

---

## 7. CHEF STOREFRONT (scheduled + on-today)

**Entry:** FoodChefsPage / ChefCard / deep-link → `ChefStorefrontPage` (planned, roadmap step 4)
**Stage/Context:** Deciding whether to order from a specific chef

### User Journey
1. Hero: chef photo, name, bio, verified badge (NIDA/TIN), service area
2. Trust strip: rating + job count, donations given (count + total portions — surfaces charitable activity as trust signal), response time, cancellation rate
3. "Available now" strip: today's `today_extra` + public `giveaway` listings — horizontal cards with portions remaining and pickup window countdown
4. **Scheduled menu** grouped by day: "Today", "Tomorrow", next 5 days
5. Each listing card: photo, title, price (or "Bure"), portions remaining, pickup window
6. Tap listing → Listing detail (#8)
7. **Reviews** section below: 5 newest, "See all" paginated
8. Primary CTAs: "Book for an event" / "Agiza kwa hafla" (for catering), "Message chef" / "Tuma ujumbe", "Favourite" heart toggle
9. Empty listings: "[chef] has no menus posted this week. Tap 'Notify me' to hear when they post"

### CRUD Operations
- **Create (favourite):** `POST /api/food/chef-favourites` with chef id
- **Read:** `GET /api/food/chef-listings?partner_id=&mode=&from=&to=` — lists grouped client-side by day
- **Edit:** NOT APPLICABLE (buyer-side)
- **Delete (unfavourite):** `DELETE /api/food/chef-favourites/{chef_id}`

### Notifications & Reminders
- 🔔 **Favourited chef posts:** "🍛 [chef] just posted [dish] for [day]. [X] portions left"
- 🔔 **Chef goes live with extras:** "🔥 [chef] has extras today — [dish] at TZS [discount] (pickup by [time])"
- 💡 **Chef recommendation:** Weekly: "💡 Chefs you might like: [3 chefs] based on your past orders"
- 🎉 **Chef milestone:** "🎉 [chef] just hit 50 orders. Celebrate with a reorder?"

### Reports & Insights
- **Your history with chef:** Orders, spend, top dishes, last order date
- **Chef performance:** On-time rate, cancellation rate, re-order rate (trust score explanation)
- **Chef's giving:** "This chef has donated [X] portions to [N] organisations" — small card

### Cross-Module Connections
- **Tajirika:** Storefront is the food-specialised replacement for `PartnerProfilePage` when a partner has cooking/catering/baking skills
- **Calendar:** "Book [chef] for [date]" → CalendarService event; auto-reminds 1 day before
- **Chat:** "Message chef" → MessageService conversation
- **Shangazi AI:** "Ask Shangazi about this chef" — passes chef skills + ward
- **Community:** "Share chef with a friend" → CommunityModule post / share sheet

---

## 8. LISTING DETAIL & RESERVE

**Entry:** Any listing card (storefront, Chakula cha Leo strip, Saidia rail) → `ListingDetailPage`
**Stage/Context:** Deciding on a single dish/portion

### User Journey
1. Hero photo; below: title, chef strip, mode badge, dietary tags (halal / no-pork / vegetarian)
2. **Pickup window** with live countdown: "Chukua kabla ya 5:30pm" (colour turns orange at <60 min, red at <15 min)
3. Portions remaining: "4 ya 6 bado zipo"
4. Price breakdown: for `scheduled`/`today_extra` — original + discount + final; for `giveaway` — "Bure"
5. Description; map pin of pickup address; chef phone (masked until reserve)
6. Portions stepper: "How many portions?" (1 → portions_remaining)
7. Pickup confirmation: "I can pick up at [address] by [time]" checkbox
8. Primary CTA:
   - `scheduled` / `today_extra`: "Reserve" / "Hifadhi" — payment flow (wallet / M-Pesa / Tigo / Airtel)
   - `giveaway (community)`: "Claim" / "Dai" — first come, no payment
   - `giveaway (organisation)`: buyer-side is invisible; only coordinator sees with "Accept donation" CTA
9. On success → toast "Reserved!" + portion count decremented + navigates to reservation detail / tracking
10. Cancellation within 30 min frees the portion back

### CRUD Operations
- **Create:** `POST /api/food/chef-listings/{id}/reserve` with `{portions, pickup_confirmed:true, payment_method}`
- **Read:** `GET /api/food/chef-listings/{id}`
- **Edit:** Cannot edit reservation; cancel and re-reserve
- **Delete/Cancel:** `POST /api/food/chef-listings/{id}/cancel` — frees portions if inside grace window

### Notifications & Reminders
- 🔔 **Reservation confirmed:** "✅ Reserved [X] portions of [dish] from [chef]. Pick up by [time]. Address: [ward + landmark]"
- 🔔 **Pickup reminder (−60 min):** "⏰ Pick up [dish] in 1 hour at [chef]'s"
- 🔔 **Pickup reminder (−15 min):** "⚠️ 15 min to pick up [dish]! Don't forget"
- ⚠️ **Expired reservation:** "Your reservation for [dish] expired. Wallet refunded TZS [X]"
- 🎉 **Pickup confirmed:** "🎉 Enjoy your [dish]! Rate [chef] when you're done"
- 💡 **Running low:** "🔥 Only 1 portion of [dish] left at [chef]"

### Reports & Insights
- **Your home-chef consumption:** Count, spend, cuisines, avg portion cost vs restaurants
- **Pickup compliance:** % of reservations you actually collected
- **Waste saved:** "You've rescued [X] meals from going to waste this year" (for `today_extra`)

### Cross-Module Connections
- **Wallet:** Payment debited on reserve; refund on cancel
- **Budget:** `chakula` expenditure logged; for `today_extra` also tagged `bargain` for savings report
- **Calendar:** Pickup time surfaced as calendar tile for the day
- **Chat:** "Message [chef]" button → MessageService
- **Shop:** "Need containers to collect? Shop" → Shop ("containers" query)
- **Doctor:** Allergen warning if dietary tags collide with user's allergy profile

---

## 9. "PANGA MENU YANGU" — SCHEDULED LISTING (seller)

**Entry:** Chef's partner page → "Panga Menu Yangu" / Tajirika profile → "My food menu"
**Stage/Context:** Chef plans upcoming cooking sessions

### User Journey
1. Chef taps "Panga Menu Yangu" CTA
2. Form page: **Photo** (camera / gallery), **Dish title** / "Jina la chakula" (required, 60 char), **Description** / "Maelezo" (optional, 300 char), **Portions** / "Sahani" (number), **Price per portion (TZS)** / "Bei ya sahani" (required), **Dietary tags** (halal / no-pork / vegetarian / vegan — multi-chip)
3. **Scheduling panel:** multi-slot picker — chef selects one or more dates + pickup windows
4. **Pickup address**: defaults to chef's registered service address; editable; map pin
5. **Delivery option toggle**: "I'll deliver" → extra fields for delivery fee + radius km (optional, v2)
6. Preview card rendered live as chef types
7. **Publish** / "Chapisha" → `POST /api/food/chef-listings` with `mode=scheduled, recipient_type=public`
8. On success → listing appears on storefront and chef sees it under "My listings"
9. Chef can duplicate a past listing for a new date in 2 taps

### CRUD Operations
- **Create:** `POST /api/food/chef-listings` with `{mode:'scheduled', recipient_type:'public', ...}`
- **Read:** `GET /api/food/chef-listings/mine` grouped by status
- **Edit:** Tap listing → edit fields (only portions and pickup window editable once a reservation exists, to protect buyers)
- **Delete:** Tap listing → "End listing" / "Funga" → confirmation → `DELETE /api/food/chef-listings/{id}` (existing reservations preserved)

### Notifications & Reminders
- 🔔 **First reservation:** "🎉 [buyer] reserved [X] portions of [dish]! Pickup [time]"
- 🔔 **Sold out:** "📢 [dish] is sold out. Want to post another?"
- 🔔 **Pickup countdown:** 1h before window: "⏰ [X] pickups starting in 1 hour for [dish]"
- 💡 **Menu idea:** Weekly Monday: "💡 Ideas: chefs in [ward] are posting [top dish]. Try it?"
- 📊 **Weekly seller digest:** Sunday: "📊 This week: [X] listings, [Y] portions sold, TZS [Z] earned"
- ⚠️ **Low demand:** "[dish] has 0 reservations 2h before pickup — want to convert to `today_extra` at discount?"

### Reports & Insights
- **Revenue dashboard:** Daily / weekly / monthly earnings, settled-to-wallet vs pending
- **Top dishes:** By orders, by revenue, by repeat rate
- **Demand heatmap:** Which days/times sell fastest in chef's ward
- **Cancellation rate:** Both self-cancels and buyer-cancels
- **Chef ranking:** "You're the #[N] home chef in [ward] this week"

### Cross-Module Connections
- **Wallet:** Settled earnings credited on `picked_up`; reflected in Wallet balance
- **Calendar:** Each listing's pickup window drops as an event on chef's Calendar
- **Budget (chef-as-business):** If partner is registered business, revenue posts to Income via IncomeService, tagged `chef_sales`; ingredient expenses tagged `chakula_cogs` via ExpenditureService
- **Shop:** "Shop ingredients" shortcut → Shop pre-filtered to staple foods for top listing
- **Tajirika:** Listing stats roll into partner's aggregate rating / jobs completed
- **Shangazi AI:** "Ask Shangazi to price [dish] competitively" — passes ward + past sales

---

## 10. "NINA CHAKULA ZAIDI LEO" — TODAY-EXTRA QUICK POST (seller)

**Entry:** Chef's dashboard → big primary CTA "Nina Chakula Zaidi Leo"
**Stage/Context:** Chef cooked more than they need, wants to sell now at a discount

### User Journey
1. **Target: under 45 seconds to post.** One scroll, minimum fields.
2. Tap CTA → form opens with keyboard auto-focused on photo
3. Fields: **Photo** (prompt: "Piga picha sasa"), **Title** (required), **Portions** (number, default 2), **Price per portion** (required; auto-suggests ⅓ off a "typical" price band), **Original price** (optional, shows strikethrough to buyers)
4. **Pickup window** defaults to "Next 3 hours" — editable slider (1h / 2h / 3h / 4h)
5. Dietary tag chips
6. Preview card + "Chapisha" button
7. Backend call → listing appears on the `Chakula cha Leo` buyer strip within seconds
8. "Want to boost this?" option → "Send to favourites first" (free push to users who favourited the chef — buyers get first crack before public strip)
9. Empty state if first time: 90-second onboarding: 3 screens explaining the flow, then the form

### CRUD Operations
- **Create:** `POST /api/food/chef-listings` with `{mode:'today_extra', recipient_type:'public', pickup_window_start:now(), pickup_window_end:now()+3h}`
- **Read:** Same listings endpoint, filtered `mode=today_extra`
- **Edit:** Can extend the window by up to 1h once; can drop price but not raise
- **Delete:** "Close early" / "Funga mapema" — marks `is_active=false`; reservations already made are honoured

### Notifications & Reminders
- 🔔 **First reservation:** "🔥 [buyer] grabbed [X] portions of [dish]!"
- 🔔 **Window closing:** 30 min before expiry, if portions remain: "⏰ 30 min left — [X] portions unclaimed. Extend? Drop price? Convert to giveaway?"
- 🔔 **Sold out:** "🎉 [dish] cleared out! TZS [X] earned"
- 💡 **Post-window coaching:** If portions expired unclaimed: "💡 Next time try posting earlier or dropping price. Or tap 'Toa Bure' to donate leftovers"

### Reports & Insights
- **Post-to-sell time:** Average minutes from post to sell-out
- **Rescue rate:** % of posts that sell out vs expire
- **Waste diverted:** Total portions saved from waste this month
- **Earnings from extras:** Revenue split: scheduled vs today-extra vs delivery fees

### Cross-Module Connections
- **Wallet:** Same settlement path as scheduled
- **Budget:** If chef is a business, `today_extra` revenue tagged separately as `chakula_surplus` so reports can show waste-diversion value
- **Calendar:** Pickup window drops as a same-day tile
- **Michango:** If expired unclaimed, one-tap option "Toa kwa mchango" — posts to a currently active michango food-drive if any in ward
- **Shangazi AI:** "Ask Shangazi if this is a good price for [dish] right now" — passes ward + history

---

## 11. "CHAKULA CHA LEO" — BUYER SAME-DAY STRIP

**Entry:** FoodHomePage → "Chakula cha Leo" rail
**Stage/Context:** Buyer wants food in the next 1–3h, discounted or free

### User Journey
1. Horizontal strip on FoodHomePage: `today_extra` + community `giveaway` listings with pickup window still open
2. Sorted by window-end-time ascending (most-urgent first)
3. Each card: photo, title, chef name strip, portions remaining, **pickup countdown badge** (red <15 min, orange <60 min), price or "Bure"
4. Tap → Listing detail (#8)
5. "See all" → dedicated `ChakulaChaLeoPage` with filters: all / discounted / free / halal / no-pork / vegetarian / within [km]
6. Empty state: "No extras near you right now. Be the first to get notified when chefs post" + "Turn on alerts" CTA
7. "Going fast" pulse badge for listings with <2 portions remaining

### CRUD Operations
- **Create:** NOT APPLICABLE (buyer surface)
- **Read:** `GET /api/food/chef-listings?mode=today_extra,giveaway&recipient_type=community,public&ward=&lat=&lng=&radius=&active=true`
- **Edit:** NOT APPLICABLE
- **Delete:** NOT APPLICABLE

### Notifications & Reminders
- 🔔 **New extra in ward:** "🔥 [chef] has [dish] at TZS [price] ([X]% off). 2h to pick up"
- 🔔 **Favourite chef posted:** "❤️ Your favourite [chef] has extras today"
- 💡 **Daily digest (optional):** 4pm: "💡 5 extras available in [ward] today. Tap to browse"
- ⚠️ **Last portion:** "⚠️ Last portion of [dish] at [chef] — 30 min left"
- 🎉 **Rescue milestone:** "🎉 You've rescued 10 meals from waste — TZS [X] saved"

### Reports & Insights
- **Your rescue stats:** Meals rescued, money saved, CO2 saved (rough estimate)
- **Ward rescue dashboard:** Total meals rescued in ward this week
- **Best times:** Which hours have the most `today_extra` posts in your ward

### Cross-Module Connections
- **Calendar:** Tap any listing → one-tap "Add pickup to calendar"
- **Wallet:** Fast-pay default; top-up prompt if balance insufficient
- **Shangazi AI:** "Ask Shangazi what to cook with [ingredient]" if the rescued meal inspires a recipe
- **Community:** "Share rescue" post — small post in local community: "Just rescued a meal from [chef]!" (opt-in)

---

## 12. "TOA BURE (JIRANI)" — COMMUNITY GIVEAWAY (seller)

**Entry:** Chef's dashboard → "Toa Bure" CTA OR from expired `today_extra` "Convert to giveaway"
**Stage/Context:** Chef has leftovers they want to give to a neighbour free

### User Journey
1. Same quick form as `today_extra` but no price fields
2. Recipient mode chips: **"Jirani yeyote"** (first come, first served) vs **"Nichague mwenyewe"** (chef reviews requests and picks)
3. Photo + title + portions + pickup window + dietary tags
4. "Chapisha" → listing published with `mode=giveaway, recipient_type=community`
5. "Jirani yeyote" flow: first user to claim locks the portion
6. "Nichague mwenyewe" flow: users send a short "Why me?" message (max 80 chars); chef sees a list, picks recipient
7. Chef can send a parallel push to `jumuiya` members of the same local jumuiya if they've linked the two modules
8. After pickup marked → chef gets a "🤝 Asante kwa kuwa mkarimu" celebration, plus a small karma-dot next to their name

### CRUD Operations
- **Create:** `POST /api/food/chef-listings` with `{mode:'giveaway', recipient_type:'community', price_tzs:null}`
- **Read:** Same listings endpoint
- **Edit:** Extend window; change recipient mode
- **Delete:** Close early

### Notifications & Reminders
- 🔔 **First claim:** "✅ [user] claimed [dish]. Pickup by [time]"
- 🔔 **Pickup complete:** "🤝 [user] picked up the food. Asante kwa kuwa mkarimu"
- 🎉 **Karma milestone:** "🎉 10 meals given away! You're one of [ward]'s most generous chefs"
- 💡 **Ubuntu prompt:** If a chef has expired `today_extra` posts: "💡 [X] portions went unclaimed. Next time try Toa Bure — feed a neighbour"

### Reports & Insights
- **Generosity dashboard:** Total portions given, recipients, running streak
- **Impact badge:** "Karimu wa [ward]" if given ≥20 portions
- **Monthly giving summary:** Shared-publicly option on profile

### Cross-Module Connections
- **Community:** Giveaway activity surfaces on chef's Community feed (opt-in)
- **Jumuiya:** Giveaway broadcast to local jumuiya members when enabled
- **Shangazi AI:** "Ask Shangazi how to reduce food waste"
- **Profile:** Generosity stat appears on Tajirika partner profile

---

## 13. "TOA KWA YATIMA / JUMUIYA / NGO" — INSTITUTIONAL DONATION (seller)

**Entry:** Chef's dashboard → "Toa kwa Yatima / Jumuiya / NGO" CTA OR from expired listing "Donate to an org" OR from Browse Needs (#14) → "Fulfil this need"
**Stage/Context:** Chef wants to donate to a specific verified beneficiary

### User Journey
1. CTA opens a flow
2. **Beneficiary picker** — searchable list filterable by type chips: `Yatima` (orphanage) / `Jumuiya` / `Msikiti` / `Kanisa` / `NGO` / `Kikundi` / `Shule ya kula` (school feeding)
3. Ward pre-filter (buyer's ward first, expandable)
4. Each result: org name, type, ward, population served, recurring schedule tag ("Feeds 20 children every Friday"), verified badge, running "portions received" count
5. Tap beneficiary → public org profile (#17) with "Select this beneficiary" CTA
6. On selection → returns to form
7. Form: **Photo**, **Dish title**, **Portions** (pre-filled from beneficiary need if any), **Pickup window**, **Dietary tags**, **Delivery vs beneficiary collects** toggle
8. **Special toggles** (important):
   - ☑ "Tag this as zakat / zaka" (Muslim chefs)
   - ☑ "Tag this as fungu la kumi / tithe" (Christian chefs)
   - ☑ "Add imputed value for receipt" — chef enters what this would have sold for; used in the PDF receipt
9. "Toa Sasa" / "Donate now" → `POST /api/food/chef-listings` with `{mode:'giveaway', recipient_type:'organisation', beneficiary_org_id, zaka_tagged, fungu_la_kumi_tagged, imputed_value_tzs}`
10. Immediately: pending `donation_receipts` row created, beneficiary coordinator pushed, chef sees "Donation pending pickup/delivery" status
11. On `picked_up` or `delivered` → receipt PDF generated + emailed + posted to donor's giving log
12. Not posted to public `Chakula cha Leo` strip

### CRUD Operations
- **Create:** `POST /api/food/chef-listings` (as above) + pending `donation_receipts` row
- **Read:** `GET /api/food/donations/mine` (donor), `GET /api/food/beneficiary-orgs/{id}/incoming` (coordinator)
- **Edit:** Cannot edit beneficiary once set; can edit portions / window until coordinator accepts
- **Delete:** Cancel before pickup; beneficiary notified; receipt pre-row deleted

### Notifications & Reminders
- 🔔 **Coordinator confirmed receipt:** "✅ [org] confirmed receipt of your [X] portions. Receipt PDF ready"
- 🎉 **Zakat / fungu la kumi tag:** "🤝 Donation counted toward your [Ramadan zakat / yearly tithe]. See running total in [zaka / fungu_la_kumi] module"
- 🔔 **Pickup reminder:** If chef is delivering: "🕐 Drop off [X] portions at [org address] by [time]"
- 💡 **Monthly giving:** "💡 You donated [X] portions to [N] orgs this month. Share your contribution?"
- 🎉 **Milestone:** "🎉 100 portions donated — you fed [N] meals this year. Download annual giving certificate"
- ⚠️ **No receipt confirmed:** If coordinator hasn't confirmed 48h after window: "⚠️ [org] hasn't confirmed receipt. Contact coordinator?"

### Reports & Insights
- **Giving dashboard:** Portions, imputed value, split by org, split by zaka / fungu la kumi / untagged
- **Annual giving certificate:** PDF with TZS total, breakdown, org names — for religious or tax records
- **Your top beneficiaries:** Which orgs you've given to most
- **Ward giving ranking:** "You're #[N] giving chef in [ward] this year"

### Cross-Module Connections
- **zaka module:** Tagged donations surface in the zaka ledger with running Ramadan/yearly total
- **fungu_la_kumi module:** Same for tithing ledger
- **michango / Campaigns:** If beneficiary has an active food michango, donation is auto-linked to the campaign so the progress bar moves
- **jumuiya:** Donations to jumuiya beneficiaries show on jumuiya group feed (opt-in)
- **kanisa_langu / tafuta_msikiti / tafuta_kanisa:** Church/mosque beneficiary profiles link to registries
- **ramadan:** During Ramadan, home screen banner nudges iftar donations; donations logged auto-tag as zakat by default (user toggleable)
- **Wallet:** Imputed value does not debit wallet; it's logged for reporting only
- **Budget:** For business chefs, CSR expense line optional (tag: `hisani`)
- **Shangazi AI:** "Ask Shangazi how much zakat to give this year" — passes donation ledger

---

## 14. BROWSE NEEDS — CHEF ADJUNCT FLOW

**Entry:** Any seller flow → "Kuna mahitaji gani?" / "What do they need?" link
**Stage/Context:** Chef has surplus or spare cooking time and wants to match a real need

### User Journey
1. Tap "Kuna mahitaji gani?" → `BeneficiaryNeedsPage`
2. Filters: type, ward, day-of-week, portion size
3. Each need card: org name + type + verified badge, population served, need description ("Need 20 lunch portions every Friday"), recurring schedule, portions required, current fulfilment progress
4. Tap need → detail page with org public profile + "Fulfil this need" / "Nitakifanya" primary CTA
5. Fulfil flow branches into either:
   - "Toa kwa ..." flow (#13) with beneficiary pre-selected and portions pre-filled
   - "Commit to recurring" — chef commits to a recurring donation schedule (e.g., "Every Friday for 4 weeks")
6. Empty state: "No active needs in your ward" / "Hakuna mahitaji katika eneo lako" + "Browse all wards" toggle

### CRUD Operations
- **Create (commit):** `POST /api/food/beneficiary-needs/{id}/commit` with `{partner_id, weeks, schedule_days, portions_per_slot}`
- **Read:** `GET /api/food/beneficiary-needs?ward=&type=&when=`
- **Edit (commitment):** Pause, resume, change portions, end early
- **Delete (commitment):** Cancel → notifies coordinator

### Notifications & Reminders
- 🔔 **New need in ward:** "🤝 [org] in [ward] needs [X] portions [every Friday]. Can you help?"
- 🔔 **Your commitment coming up:** Day before: "Reminder: Tomorrow you promised [X] portions for [org]"
- 🔔 **Missed commitment:** "⚠️ You missed [date]'s commitment to [org]. Reschedule or cancel?"
- 🎉 **Commitment complete:** "🎉 4-week commitment to [org] complete! You fed [total] meals. Continue?"

### Reports & Insights
- **Needs coverage map:** How many needs in ward are covered by chefs vs still open
- **Your commitments:** Active, completed, cancelled — with reliability score
- **Impact estimate:** "Your commitment feeds [X] orphans for [Y] weeks"

### Cross-Module Connections
- **Calendar:** Recurring commitments drop recurring events on chef's Calendar
- **Notifications:** Reminder pipeline per committed slot
- **jumuiya:** Jumuiya needs surface here if jumuiya has registered as a beneficiary
- **michango:** Commitments auto-link to any active food michango for that beneficiary

---

## 15. "SAIDIA SASA" — BUYER UBUNTU RAIL

**Entry:** FoodHomePage → "Saidia Sasa" rail (optional, user-toggleable)
**Stage/Context:** A buyer who might want to donate rather than only consume

### User Journey
1. Small rail on FoodHomePage: 3–5 open beneficiary needs in buyer's ward
2. Each card: org name, need description, progress bar ("12 / 20 portions this week"), "Changia" / "Contribute" CTA
3. Tap "Changia" → buyer flow: either **Buy-and-donate** (buyer picks a chef's listing and gifts it to the beneficiary) OR **Cash contribution** (michango path; out-of-module after first step)
4. Buyer can schedule a one-off or recurring donation
5. Empty state: rail hidden if no open needs in ward
6. Settings → toggle rail off if user finds it intrusive

### CRUD Operations
- **Create (buy-and-donate):** `POST /api/food/chef-listings/{id}/reserve` with `{gift_to_beneficiary_org_id}` — creates reservation where recipient is the org, donor is the buyer
- **Read:** `GET /api/food/beneficiary-needs?ward=&active=true`
- **Edit:** NOT APPLICABLE (donation is one-shot)
- **Delete:** Cancel within grace window

### Notifications & Reminders
- 🔔 **Need alert:** "🤝 [org] in [ward] still needs [X] portions today. Contribute TZS [Y]?"
- 🎉 **Contribution confirmed:** "🎉 Thank you! You fed [X] people at [org]. Receipt in your giving log"
- 💡 **Ramadan prompt:** During Ramadan: "💡 Mosques near you need iftar tonight. Help feed [X] people"
- 📊 **Monthly summary:** "📊 This month you gave [X] portions / TZS [Y] to [N] orgs"

### Reports & Insights
- **Your giving graph:** Month-over-month, by org type, by religious tag
- **Community giving:** "Your ward fed [X] people this week"
- **Leaderboard (opt-in):** Most generous buyers in ward

### Cross-Module Connections
- **zaka / fungu_la_kumi:** Tagged donations feed those ledgers
- **michango:** Buy-and-donate flow optionally also triggers a michango follow
- **Wallet:** Debits buyer wallet on contribution
- **Calendar:** Recurring contributions drop as recurring events
- **Shangazi AI:** "Ask Shangazi about the best time to give food in Ramadan"

---

## 16. BENEFICIARY REGISTRATION (coordinator)

**Entry:** Food → "Register your orphanage / jumuiya / NGO" (hidden unless user profile has not registered; also discoverable via Profile → More)
**Stage/Context:** A coordinator wants to onboard their organisation

### User Journey
1. Tap "Register" → multi-step form
2. **Step 1 — Organisation basics:** Name, Type (`Yatima` / `Jumuiya` / `Msikiti` / `Kanisa` / `NGO` / `Kikundi` / `Shule ya kula`), Short description (300 char)
3. **Step 2 — Legal registration:** Registration number, Authority (BRELA / Social Welfare / NGO Board / Faith council / Local jumuiya), Upload certificate (PDF / JPG)
4. **Step 3 — Location:** Region → District → Ward dropdowns, Street / landmark, map pin (optional GPS)
5. **Step 4 — Programme info:** Population served (number), Meals per week (number), Recurring schedule picker (days + meal type)
6. **Step 5 — Contact:** Phone number (auto-filled from user profile), Alternate phone (optional)
7. **Step 6 — Review & Submit** → preview all fields, "Wasilisha" / "Submit" → `POST /api/food/beneficiary-orgs/register`
8. Status page shows "Pending review" / "Inakaguliwa" with ETA: "We verify within 3 business days"
9. Verification is **backend-only** per admin feedback rule — no in-app review screen
10. On `verified` status → push notification + dashboard unlocks
11. On `rejected` → push with reason + "Resubmit" CTA with editable fields

### CRUD Operations
- **Create:** `POST /api/food/beneficiary-orgs/register`
- **Read:** `GET /api/food/beneficiary-orgs/mine` (returns the coordinator's org)
- **Edit:** Only certain fields editable post-verification (contact phone, population served, schedule); name / type / registration require re-verification
- **Delete:** `POST /api/food/beneficiary-orgs/{id}/close` — soft-close with reason

### Notifications & Reminders
- 🔔 **Submitted:** "📋 Registration submitted. We'll verify within 3 business days"
- 🎉 **Verified:** "🎉 [org name] is verified! You can now receive donations"
- ⚠️ **Rejected:** "❌ Registration needs attention: [reason]. Tap to fix"
- 💡 **Incomplete profile:** "💡 Add a photo and description to your org profile — verified orgs get 3× more donations"
- 💡 **First recurring need prompt:** "💡 Post your first recurring need so chefs know how to help"

### Reports & Insights
- **Verification timeline:** Each step stamped
- **Registration completeness:** % of fields filled

### Cross-Module Connections
- **Notifications:** Push on status change
- **jumuiya / kanisa_langu / tafuta_msikiti / tafuta_kanisa:** If coordinator's jumuiya / mosque / church is already registered in those modules, auto-populate most fields
- **Shangazi AI:** "Ask Shangazi how to run a food donation programme" — passes org type

---

## 17. BENEFICIARY PUBLIC PROFILE

**Entry:** Chef's "Toa kwa ..." picker → tap org OR Saidia Sasa → tap org OR deep link
**Stage/Context:** Donor needs to know who they're donating to

### User Journey
1. Public profile page: hero banner (if provided) + org photo, name, type chip, verified badge, ward, "Feeds ~[X] people"
2. "About" / "Kuhusu" section with description
3. "Programme" / "Mpango" showing recurring feeding schedule
4. "Running totals" / "Kwa ujumla": portions received this month, this year; unique donors count; goals achieved
5. "Current needs" list (active `beneficiary_needs`) with "Nitakifanya" CTAs
6. "Recent donors" with names (with donor consent) and portions
7. Photo gallery of the programme (coordinator-uploaded)
8. "Report this org" / "Ripoti shirika" safety link → submits to support

### CRUD Operations
- **Create:** NOT APPLICABLE (public read)
- **Read:** `GET /api/food/beneficiary-orgs/{id}`
- **Edit:** NOT APPLICABLE (coordinator edits via #18)
- **Delete:** NOT APPLICABLE

### Notifications & Reminders
- 💡 **Follow org:** User can tap "Follow this org" → gets push when they post a new need
- 🔔 **New need from followed org:** "🤝 [org] posted a new need: [X] portions by [day]"
- 🎉 **Org milestone:** If a followed org hits a target: "🎉 [org] just reached 1,000 meals this year thanks to [N] donors. Your contribution counted"

### Reports & Insights
- **Impact timeline:** A month-by-month chart of portions received; visible to public for transparency

### Cross-Module Connections
- **Chat:** "Message coordinator" / "Tuma ujumbe kwa mratibu" button → MessageService
- **jumuiya / kanisa_langu / tafuta_msikiti:** Public profile links back to the org's profile in those modules for deeper info
- **michango:** Shows any active food-michango campaigns for this org
- **Shangazi AI:** "Ask Shangazi about this org" — passes type + description

---

## 18. BENEFICIARY DASHBOARD (coordinator)

**Entry:** Food → "My organisation" (coordinator-only) → `BeneficiaryDashboardPage`
**Stage/Context:** Coordinator managing incoming donations and running the programme

### User Journey
1. Header: org name, verified badge, quick stats chips (portions today / this week / this month)
2. **Today's incoming** section: confirmed donations with donor name, portions, ETA, "Confirm receipt" CTA after pickup
3. **Pending acceptance** section: donations chef has pledged but not yet delivered; "Accept" / "Decline with reason"
4. **Recurring commitments** section: chefs who signed up to recurring schedules — status traffic lights per slot
5. **Current needs** section: list of posted `beneficiary_needs` with "Edit", "Pause", "Close"
6. **30-day summary** card: portions, unique donors, imputed value, receipt downloads
7. Action buttons: "Post a need" (#19), "Download monthly report" PDF, "Message a donor"
8. **Confirm receipt** flow: tap → photo of food received (optional proof), headcount of beneficiaries served that day → `POST /api/food/beneficiary-orgs/{id}/confirm-receipt/{listing_id}` → triggers receipt PDF generation + donor notification

### CRUD Operations
- **Create (need):** See #19
- **Read:** `GET /api/food/beneficiary-orgs/{id}/incoming` + `GET /api/food/beneficiary-orgs/{id}/summary?from=&to=`
- **Edit (org):** Settings → edit allowed fields (contact, schedule, population)
- **Delete (close org):** See #16 delete

### Notifications & Reminders
- 🔔 **New donation pending:** "🍛 [chef] pledged [X] portions of [dish] for [day]. Accept?"
- 🔔 **Pickup reminder:** 1h before donor arrives / 1h before coordinator should pick up
- ⚠️ **Missed donation:** "⚠️ [chef]'s donation is overdue by 2h. Message them?"
- 📊 **Weekly summary:** Sunday: "📊 This week: [X] portions from [Y] donors. Top donor: [chef]"
- 📊 **Monthly summary:** 1st of month: "📊 Monthly report ready for download. [X] portions, [Y] donors, imputed value TZS [Z]"
- 💡 **Need stale:** "💡 Your need [title] has 0 fulfilments in 7 days. Edit or boost?"

### Reports & Insights
- **Donor retention:** % of donors who come back
- **Fulfilment rate per need:** How many of your needs get covered vs go unmet
- **Peak donation days:** Most meals received on [day]
- **Donor mix:** By chef / by buyer-gifted / by michango-driven
- **Monthly trustee report:** One-page PDF with totals, donor list, programme-served headcount — for internal trustees or NGO Board filings

### Cross-Module Connections
- **Chat:** Message donors directly
- **Calendar:** Recurring incoming donations drop as recurring events
- **michango:** Active campaigns show here with progress
- **jumuiya:** If org is a jumuiya, summary posts automatically to jumuiya group feed weekly
- **Notifications:** Pipeline per event
- **Shangazi AI:** "Ask Shangazi how to write a thank-you message to [donor]"

---

## 19. POSTING A RECURRING NEED (coordinator)

**Entry:** Beneficiary Dashboard → "Post a need" / "Tuma hitaji"
**Stage/Context:** Coordinator wants to signal what they need

### User Journey
1. Tap "Post a need" → form
2. **Need type:** One-off vs Recurring
3. **Meal type:** Lunch / Dinner / Breakfast / Snack
4. **Portions:** Number
5. **Days:** Multi-select days of week (recurring) OR single date (one-off)
6. **Pickup / Delivery:** Org collects vs Donor delivers vs Either
7. **Description:** Short context ("20 children, no pork, soft food if possible")
8. **Dietary constraints:** halal / no-pork / vegetarian / soft-food multi-chip
9. **Duration** (recurring only): Weeks to run ("Until [date]" or "Always")
10. Preview card + "Tuma" / "Post"
11. On success → need appears on public profile + chef Browse Needs + optionally boosted via push to all verified chefs in ward
12. Coordinator can pause / resume / close any time

### CRUD Operations
- **Create:** `POST /api/food/beneficiary-orgs/{id}/needs`
- **Read:** `GET /api/food/beneficiary-orgs/{id}/needs?status=`
- **Edit:** Modify any field; history retained for audit
- **Delete/Close:** `POST /api/food/beneficiary-needs/{id}/close` with reason

### Notifications & Reminders
- 🔔 **Chef committed:** "🤝 [chef] committed to your [day] need for [weeks] weeks"
- 🔔 **Fulfilment this week:** Monday: "This week's need: [X] portions for [day]. [Y] chefs committed"
- ⚠️ **Under-covered need:** "⚠️ Your [day] need still has [X] unfilled portions. Boost? Edit?"
- 💡 **Peak-time tip:** "💡 Needs posted on Monday get 2× more chef responses than other days"

### Reports & Insights
- **Need performance:** Which needs get filled, which don't, why
- **Average coverage time:** Days from post to full commitment
- **Seasonal demand:** Ramadan vs non-Ramadan fulfilment rate

### Cross-Module Connections
- **Notifications:** Chef-matching push pipeline
- **Calendar:** Recurring needs create recurring calendar slots for chef commitments
- **michango:** Coordinator can link a need to a michango campaign to crowdfund meals
- **Shangazi AI:** "Ask Shangazi how to write a compelling need description"

---

## 20. DONATION RECEIPT (donor & org view)

**Entry:** Automatic on `confirm_receipt` OR Donor giving log → tap donation → "Download receipt"
**Stage/Context:** Donor needs a record; org needs an audit trail

### User Journey (donor)
1. On coordinator's `confirm_receipt`, donor gets push: "✅ [org] confirmed your donation. Receipt ready"
2. Tap notification → Donation detail page
3. Receipt card: Org name, org registration number, donor name, donor phone, donation date, dish, portions, imputed value, zakat / fungu la kumi tags
4. "Download PDF" → `GET /api/food/donations/{id}/receipt.pdf` — styled with org letterhead (if uploaded) and TAJIRI badge
5. "Share" → share sheet (WhatsApp / email / save)
6. "View in zaka ledger" → jumps into zaka module if tagged
7. "View in fungu la kumi" → jumps into fungu_la_kumi if tagged

### User Journey (coordinator)
1. Monthly / yearly: "Download all receipts" as ZIP
2. Individual receipts accessible from each incoming donation row

### CRUD Operations
- **Create:** Auto-generated on `confirm_receipt`
- **Read:** `GET /api/food/donations/{id}/receipt.pdf`; `GET /api/food/donations/mine`
- **Edit:** NOT APPLICABLE (immutable audit trail); corrections via new receipt + void flag
- **Delete:** NOT APPLICABLE; voiding only

### Notifications & Reminders
- 🔔 **Receipt ready:** "📋 Receipt for your donation to [org] is ready"
- 📊 **Annual giving certificate:** Jan 1: "📊 Your 2026 giving certificate is ready. [X] portions to [N] orgs — TZS [Y] imputed value"
- 💡 **Ramadan zakat reminder:** Ramadan month: "💡 Your zakat total so far: TZS [X]. Target: [calculation]. Download ledger"

### Reports & Insights
- **Annual certificate PDF:** Total, by org, by religious tag, by month
- **Year-over-year comparison:** "You gave 15% more than last year"
- **Breakdown by tag:** Zakat vs fungu la kumi vs untagged

### Cross-Module Connections
- **zaka:** Zakat-tagged receipts feed running zakat ledger
- **fungu_la_kumi:** Tithing-tagged receipts feed fungu la kumi ledger
- **Budget (business chef):** Optional `hisani` CSR expense line
- **Cloud storage:** Receipt PDF can be saved to the user's `my_files` for permanent record

---

## 21. MICHANGO MEAL-PLEDGE CAMPAIGN

**Entry:** Beneficiary profile → active michango campaign OR michango module → food-tagged campaign
**Stage/Context:** A beneficiary org runs a crowdfunded "feed the orphanage" campaign

### User Journey
1. Coordinator creates a michango campaign with goal: "Feed 50 children for Ramadan — 1,500 meals target"
2. Campaign page has two pledge options: **"Pledge money"** (standard michango) and **"Pledge meals"** (food module)
3. Tap "Pledge meals" → opens Food → Toa kwa ... flow with beneficiary pre-selected + campaign linked
4. Each meal pledge increments the campaign portions meter
5. Campaign page shows leaderboard of top donors (money + meal-value combined)
6. On campaign close: summary + all donors thanked in a group message

### CRUD Operations
- **Create:** Campaign via michango module; meal pledges via food module
- **Read:** `GET /api/michango/campaigns/{id}` with `food_pledge_rollup`
- **Edit:** Donor can cancel pledge pre-pickup
- **Delete:** Coordinator closes campaign

### Notifications & Reminders
- 🔔 **Campaign progress:** Daily during campaign: "[campaign] is at [X]% — [Y] meals still needed"
- 🎉 **Campaign hit goal:** "🎉 [campaign] reached its goal! Thank you to [N] donors"
- 💡 **Reminder to fulfil:** If chef pledged a recurring slot but missed: "⚠️ Your pledge to [campaign] for today is overdue"

### Reports & Insights
- **Campaign impact:** Money + meals combined; cost-per-meal comparison
- **Donor leaderboard:** Top contributors by combined value

### Cross-Module Connections
- **michango:** Canonical campaign plumbing; food is a pledge-type plugin
- **zaka / fungu_la_kumi:** Pledged meals flow to religious ledgers if tagged
- **Community / Events:** Campaign pushed to related community / event pages
- **Shangazi AI:** "Ask Shangazi how to run a Ramadan food campaign"

---

## 22. RAMADAN IFTAR FEEDING (seasonal surface)

**Entry:** Ramadan module banner → "Feed iftar tonight" OR Food home during Ramadan
**Stage/Context:** Daily iftar (sunset meal) during Ramadan — a high-volume, time-critical giving window

### User Journey
1. During Ramadan, FoodHomePage shows a seasonal banner: "🌙 Iftar tonight — help feed [N] mosques in [ward]"
2. Tap → Ramadan iftar page
3. Mosques near the user with tonight's iftar need; each shows headcount, current fulfilment, dietary notes
4. Two quick actions per mosque: "Pledge meals" (opens Food → Toa flow with mosque pre-selected, zakat auto-tagged) and "Pledge money" (opens Michango)
5. Countdown to iftar time (calculated from sunset)
6. After iftar, mosque coordinators confirm receipt → donors get notifications with day count ("Day 12 of Ramadan — running zakat: TZS [X]")
7. End-of-Ramadan: summary badge "Ramadan Karim 2026" with total given

### CRUD Operations
- Follows the same donation flow; seasonal UI wrapper only

### Notifications & Reminders
- 🔔 **Daily iftar prompt:** 4pm daily in Ramadan: "🌙 [N] mosques in [ward] need iftar tonight. Pledge a meal or money?"
- 🔔 **Sunset reminder:** 1h before iftar: "🕌 Iftar is in 1 hour. [Mosque] still needs [X] portions"
- 🎉 **Mid-Ramadan milestone:** Day 15: "🎉 Halfway through Ramadan — you've given [X] portions, zakat running total TZS [Y]"
- 🎉 **Ramadan complete:** Eid: "🎉 Ramadan Karim! This Ramadan you fed [X] people at [N] mosques. Download your giving certificate"

### Reports & Insights
- **Ramadan giving calendar:** Daily chart of donations across 30 days
- **Zakat ul-Fitr reminder:** End of Ramadan: "💡 Zakat ul-Fitr due by Eid. Current ledger: TZS [X]"
- **Shareable Ramadan summary card:** Image with totals, for personal sharing (privacy-controlled)

### Cross-Module Connections
- **ramadan module:** Owns the seasonal surface; food supplies the pledge flow
- **sala / qibla:** Prayer-time awareness for iftar timing
- **zaka:** Daily zakat ledger updated automatically
- **tafuta_msikiti:** Mosque picker pulls from the mosque registry
- **wakati_wa_sala:** Sunset time for iftar countdown

---

## 23. CHRISTMAS / EASTER / FUNGU LA KUMI FEEDING (seasonal surface)

**Entry:** my_faith / kanisa_langu → "Feed the community this Christmas" OR Food home during season
**Stage/Context:** Church feeding programmes — Christmas lunch, Easter meals, weekly fungu la kumi meal-giving

### User Journey
1. Seasonal banner: "✝️ Christmas lunch for [N] people — [church] needs meals"
2. Tap → page with churches running feeding programmes; similar layout to Ramadan iftar but without sunset-timing
3. Donor can pledge meals (tag as fungu la kumi) or money
4. Year-round support for weekly church feeding programmes — any Sunday's feeding can be sponsored

### Notifications & Reminders
- 🔔 **Christmas-eve prompt:** Dec 24 11am: "✝️ Tomorrow [church] feeds [X] people. Pledge a meal?"
- 🔔 **Weekly Sunday prompt:** Sunday 9am year-round: "✝️ Your church serves [N] meals today. Contribute one?"
- 🎉 **End-of-year giving:** Dec 31: "🎉 This year you tithed TZS [X]. See your fungu la kumi certificate"

### Reports & Insights
- **Fungu la kumi ledger:** Running yearly total with breakdown
- **Shareable Christmas summary:** For personal use

### Cross-Module Connections
- **kanisa_langu / my_faith / tafuta_kanisa:** Owns seasonal surface
- **fungu_la_kumi:** Tithing ledger updates automatically
- **jumuiya:** Jumuiya Christmas feeding programmes surface here

---

## 24. CHEF DELIVERY LAYER (roadmap step 6)

**Entry:** Seller flow → "I'll deliver" toggle; buyer listing detail shows "Delivery available"
**Stage/Context:** Chef wants to deliver directly; buyer wants the meal brought to them

### User Journey (seller)
1. In any seller flow, toggle "I'll deliver" → fields: delivery fee (TZS) + radius (km)
2. On reserve, chef sees "Prepare + deliver" workflow with stepper: Preparing → Out for delivery → Delivered
3. Chef taps "Mark out for delivery" → GPS updates; buyer sees live tracking
4. On "Mark delivered" → handover

### User Journey (buyer)
1. Listing detail shows delivery fee + estimated time
2. Cart has delivery vs pickup toggle
3. Order tracker same as restaurant tracker (#4)

### CRUD Operations
- Same listing schema; `delivery_enabled` + `delivery_fee_tzs` + `delivery_radius_km` fields

### Notifications & Reminders
- 🔔 **Chef en route:** "🚶 [chef] is on the way — arriving in [X] min"
- 🔔 **Chef arrived:** "📍 [chef] is outside. Please come to collect"
- ⚠️ **Chef delayed:** "⚠️ [chef] is running [X] min late"

### Cross-Module Connections
- Same as restaurant delivery — Calendar, Wallet, Notifications, Budget

---

## 25. VOLUNTEER RUNNER (roadmap step 7)

**Entry:** "Volunteer" hub (Profile → Volunteer) → "Claim a run" / "Chukua safari" → runner dashboard
**Stage/Context:** Food Rescue US pattern — any verified user can pick up a donation and deliver to an org

### User Journey
1. User toggles availability as a runner
2. Sees pending donation runs in their ward (chef → org pickups awaiting a runner)
3. Each run card: chef pickup address, org dropoff address, distance, portions, estimated time
4. Tap "Chukua safari" → claim → status: Picking up → Dropped off → Complete
5. On complete → karma points + optional in-app "Thank you" badge; no payment v1

### CRUD Operations
- **Create (claim):** `POST /api/food/runs/{id}/claim`
- **Read:** `GET /api/food/runs?ward=&status=unclaimed`
- **Edit:** Cannot transfer claim; only release with reason
- **Delete (release):** `POST /api/food/runs/{id}/release` — returns to unclaimed pool

### Notifications & Reminders
- 🔔 **New run in ward:** "🚴 Run available: [chef] → [org], [X] portions, [Y] km"
- 🔔 **Run reminder:** 30 min before pickup: "⏰ Pick up [portions] from [chef] in 30 min"
- 🎉 **Run complete:** "🎉 Thank you for the run! [X] meals delivered to [org]"
- 🎉 **Runner milestone:** "🎉 10 runs completed! Volunteer badge unlocked"

### Reports & Insights
- **Runner dashboard:** Runs, distance, meals delivered, orgs served
- **Community impact:** "Runners in your ward moved [X] meals this week"

### Cross-Module Connections
- **Community:** Runner badge appears on community profile
- **Calendar:** Claimed runs drop as events
- **Notifications:** Run assignment pipeline

---

## 26. FAVOURITES & FOLLOW

**Entry:** Any chef storefront, restaurant page, or beneficiary profile → heart / follow icon
**Stage/Context:** User wants to keep tabs on specific providers / beneficiaries

### User Journey
1. Tap heart on a chef / restaurant / beneficiary → toggles saved state
2. Profile → "Saved" / "Zilizopendekezwa" shows three tabs: Chefs, Restaurants, Orgs
3. Notifications per tab: new postings from followed chefs, new menus from restaurants, new needs from orgs
4. Settings → notification preferences per category

### CRUD Operations
- **Create:** `POST /api/food/favourites` with `{type:'chef|restaurant|org', target_id}`
- **Read:** `GET /api/food/favourites`
- **Edit:** NOT APPLICABLE
- **Delete:** `DELETE /api/food/favourites/{id}`

### Notifications & Reminders
- 🔔 **Favourite posts:** Already covered in #6, #7, #17 — deduped channel
- 💡 **Suggest favourite:** After 3 orders from same chef: "💡 Want to follow [chef]? Get notified when they post"

### Reports & Insights
- **Follow mix:** Chef vs restaurant vs org
- **Engagement:** Which follows actually convert to orders / donations

### Cross-Module Connections
- **Notifications:** Unified FCM channel routing per favourite

---

## 27. REVIEWS & RATINGS

**Entry:** Order tracking / past order → "Rate" CTA, or chef / restaurant page → "Write review"
**Stage/Context:** Post-delivery feedback

### User Journey
1. Trigger: completion of an order or pickup
2. Modal: **Stars** (1–5), **Photo** (optional), **Text** (optional, 500 char), **Tags** chips ("Kwa wakati", "Ladha tamu", "Bei nzuri")
3. "Wasilisha" / "Submit" → `POST /api/food/reviews` with `{target_type:'chef|restaurant', target_id, order_id, stars, text, photo_url, tags}`
4. Review appears on target's profile
5. Seller can respond once (no thread)
6. User can edit within 24h; delete any time
7. Flagging: "Report review" → moderation backend-only

### CRUD Operations
- **Create:** `POST /api/food/reviews`
- **Read:** `GET /api/food/reviews?target_type=&target_id=`
- **Edit:** `PATCH /api/food/reviews/{id}` within 24h
- **Delete:** `DELETE /api/food/reviews/{id}`

### Notifications & Reminders
- 🔔 **Review nudge:** 2h post-delivery: "How was your meal? Rate [chef/restaurant]"
- 🎉 **First review:** "🎉 Thanks for your first review — you earn 20 Tajiri points"
- 🔔 **Seller response:** "[chef/restaurant] responded to your review"

### Reports & Insights
- **Review sentiment:** Trend of ratings over time per target
- **Tag clouds:** Most-used tags per target
- **Response rate:** How often a seller responds to reviews

### Cross-Module Connections
- **Tajirika:** Reviews feed into partner's `aggregateRating`
- **Shangazi AI:** "Ask Shangazi to draft a review" — passes order context

---

## 28. SEARCH & DISCOVERY

**Entry:** FoodHomePage → search bar OR FoodChefsPage → search bar
**Stage/Context:** User looking for a specific cuisine / chef / dish / beneficiary

### User Journey
1. Universal search bar accepts: restaurant name, chef name, dish, cuisine, beneficiary org, tag ("halal")
2. As user types, results group into sections: Chefs, Restaurants, Dishes, Orgs, Needs
3. Filter chips: Ward / radius, cuisine, dietary, open-now, price band
4. Empty query state shows trending this week in ward
5. Recent searches remembered locally
6. Typo tolerance + Swahili ↔ English fuzzy matching ("chicken" ↔ "kuku")

### CRUD Operations
- **Read:** `GET /api/food/search?q=&type=&ward=&filters=`

### Notifications & Reminders
- 💡 **Search → saved alert:** "Save this search" option → get notified when new matches appear

### Reports & Insights
- **Trending searches in ward:** Weekly
- **Zero-result searches:** Surface to backend as demand signal for onboarding

### Cross-Module Connections
- **Shangazi AI:** If no results: "Ask Shangazi where to find [query]"
- **Shop:** Recipe-ingredient flow: "Shop ingredients to cook [query] yourself"

---

## 29. FOOD EMERGENCY / DISASTER RELIEF (future surface)

**Entry:** Notifications → emergency banner OR Food home during declared emergency
**Stage/Context:** Flooding, drought, local crisis — rapid food-sharing window

### User Journey
1. Admin-triggered backend flag (`food_emergency_active` per region) surfaces a red banner on FoodHomePage
2. Emergency page lists affected wards + open needs from beneficiary orgs + mosques + jumuiya in affected zones
3. Special quick-pledge flow: skip the picker, one-tap donate portions to the nearest affected org
4. Donations tagged `emergency` in receipts + reports

### CRUD Operations
- **Read:** `GET /api/food/emergencies?active=true`
- **Create:** Standard donation flow; emergency flag passed through

### Notifications & Reminders
- 🚨 **Emergency declared:** "🚨 Food emergency in [region]. [N] families need meals. Help?"
- 🚨 **Nearest affected:** "🚨 [org] in [nearby ward] is serving displaced families. Tap to donate"

### Reports & Insights
- **Emergency response summary:** Per-event, per-region, per-org — total meals moved

### Cross-Module Connections
- **ofisi_mtaa / ambulance / police:** Civil authorities can mark emergencies
- **jumuiya:** Group broadcast on activation
- **Notifications:** Critical priority channel bypasses quiet hours
- **Shangazi AI:** "Ask Shangazi how to prepare for food emergencies"

---

## 30. SETTINGS & PREFERENCES

**Entry:** FoodHomePage → profile / settings icon → Food settings
**Stage/Context:** User controlling behaviour of food module

### User Journey
1. Settings page with toggles:
   - **Dietary preferences** — halal, no-pork, vegetarian, vegan, allergens (saves to user profile; used to filter listings + warn)
   - **Delivery preferences** — default ward, max delivery radius, default payment method
   - **Notification categories** — reminder / alert / celebration / summary / prompt per rail (Chakula cha Leo / Saidia Sasa / chef posts / etc.)
   - **Quiet hours** — e.g. "No food pushes between 10pm and 6am"
   - **Show Saidia Sasa rail** — opt-in / opt-out
   - **Auto-tag donations as zakat during Ramadan** — yes / no / ask-each-time
   - **Auto-tag donations as fungu la kumi on Sundays** — yes / no / ask-each-time
   - **Privacy:** hide my name on donor leaderboards; hide my giving from community feed

### CRUD Operations
- **Read / Edit:** `GET/PATCH /api/users/me/food-preferences`

### Cross-Module Connections
- **Notifications:** Preferences drive push routing
- **Budget:** Default expenditure category for food spend

---

## NOTIFICATION CHANNELS SUMMARY

| Channel | Trigger | Frequency |
|---|---|---|
| **food_order** | Status changes (accepted / cooking / out / delivered) | Per order, 4–6 pushes |
| **food_order** | Cart abandonment, restaurant closing | Opportunistic |
| **food_chef** | Favourite chef posts, new chef in ward, chef milestone | Multiple/day when active |
| **food_rescue** | New `today_extra` / `giveaway` in ward, last-portion alerts | Daily during active hours |
| **food_rescue** | Pickup reminders (−60 min, −15 min), expired reservation | Per reservation |
| **food_donation** | Pending donation, coordinator confirmation, receipt ready | Per donation |
| **food_donation** | Annual / Ramadan / Christmas giving certificate | Seasonal |
| **food_beneficiary** | Need posted, commitment confirmed, missed commitment | Per event |
| **food_beneficiary** | Weekly / monthly coordinator summary | Weekly / Monthly |
| **food_seasonal** | Ramadan iftar daily prompt, Christmas feeding prompt, Sunday church feeding | Daily in season |
| **food_emergency** | Declared food emergency; bypasses quiet hours | Per event |
| **food_runner** | Run available, run reminder, run complete, milestone | Per claimed run |
| **food_review** | Review nudge, seller response, first-review celebration | Per order / event |
| **system** | Registration verified / rejected, favourite deactivated | As needed |

## CROSS-MODULE INTEGRATION MAP

| From Food | To Module | Trigger |
|---|---|---|
| Any paid order | **Budget (ExpenditureService)** | `chakula` expense line on confirmation |
| Chef revenue (business) | **Budget (IncomeService)** | `chef_sales` income line on `picked_up` |
| Every payment | **Wallet** | Debit on order; top-up fallback to M-Pesa / Tigo / Airtel |
| Every refund | **Wallet** | Credit on cancellation |
| Delivery ETA / pickup window | **Calendar** | Short-lived event; recurring for commitments |
| Chef + restaurant bookings | **Calendar** | Event on the booking day |
| Allergen warnings | **Doctor** | "Book consult" link if persistent allergies |
| Dietary concerns (diabetes / hypertension) | **Doctor** | Inline nutrition-consult link on risky dishes |
| Chef ratings / jobs | **Tajirika** | Rolls into `aggregateRating` and `jobsCompleted` |
| Chef profile / verification | **Tajirika** | NIDA + TIN gating reused |
| Zakat-tagged donation | **zaka** | Adds row to running zakat ledger with TZS + meal value |
| Fungu-la-kumi-tagged donation | **fungu_la_kumi** | Adds row to running tithing ledger |
| Food-pledge on a campaign | **michango** | Increments campaign meal counter |
| Org = jumuiya | **jumuiya** | Donations and needs surface on jumuiya group feed |
| Org = church | **kanisa_langu / tafuta_kanisa** | Church page shows active needs / donations |
| Org = mosque | **tafuta_msikiti** | Mosque page shows active needs / donations |
| Ramadan iftar timing | **ramadan / sala / wakati_wa_sala** | Sunset time drives iftar countdown |
| Food emergency | **ofisi_mtaa / ambulance / police** | Civil authority can mark and surface emergencies |
| Parenting / family dinner ideas | **Shangazi AI** | Every rail has "Ask Shangazi" with ward + context |
| "Shop ingredients" shortcut | **Shop** | Pre-filtered search on ingredients from a dish |
| "Shop containers" prompt | **Shop** | On reservation with pickup |
| Runner / volunteer badge | **Community** | Badge on community profile |
| Share chef / org | **Community / Chat** | Share to group or DM via MessageService |
| Chef ↔ buyer / coordinator ↔ donor | **Chat (MessageService)** | DM from any profile / listing / dashboard |
| Receipt PDF | **my_files** | Optional save to user cloud storage |
| All status pushes | **Notifications (FCM + local)** | Per-channel routing with quiet-hours respect |
