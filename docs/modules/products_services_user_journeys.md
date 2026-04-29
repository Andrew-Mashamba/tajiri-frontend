# Products & Services Modules — Complete User Journeys

**Module:** lib/products/ and lib/biz_services/
**Source spec:** docs/superpowers/specs/2026-04-21-products-services-modules-design.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, suppliers, budget, calendar, wallet, Shangazi AI), and **Insightful** (reports, trends, recommendations).

---

## 1. PRODUCTS CATALOG (VIEW)

**Entry:** Profile → Business tab → [Business name] → "Products" / "Bidhaa"
**Stage/Context:** Any business owner who wants to manage what they sell

### User Journey
1. User opens Profile → navigates to Business section
2. Taps "Products" / "Bidhaa" entry in the Business section menu
3. Page loads: `AppBar` title "Products" / "Bidhaa", `RefreshIndicator` wrapping a `ListView`
4. **If default-shop business:** products fetched from existing Shop seller API (`GET /seller/products`) — same products visible in the marketplace Shop tab
5. **If non-shop business:** products fetched from `GET /business/{id}/catalog/products`
6. Each product card shows: thumbnail (or grey placeholder icon), title, price (TZS formatted with commas), status badge (Active / Draft / Nje ya Stoki)
7. **Empty state:** store icon + "No products yet" / "Bado hakuna bidhaa" + "Add your first product to let buyers find you" + "Add Product" / "Ongeza Bidhaa" button
8. User taps a product card → detail `BottomSheet` slides up showing: full image gallery (swipeable), title, price, compare-at price (if set), stock quantity, status, type, condition, description, delivery options
9. Detail sheet has two action buttons: "Edit" / "Hariri" and "Delete" / "Futa"
10. Pull-to-refresh reloads list from API
11. `FloatingActionButton` (+ icon) → navigates to `ProductFormPage` in add mode

### CRUD Operations
- **Create:** Tap FAB → `ProductFormPage` opens (full form, see Feature 2)
- **Read:** `ListView` of product cards with thumbnail, title, price, status badge. Tap → detail `BottomSheet`
- **Edit:** Tap "Edit" in detail sheet → `ProductFormPage` opens in edit mode with all fields pre-filled
- **Delete:** Tap "Delete" in detail sheet → `AlertDialog` confirmation: "Delete [title]? This cannot be undone" / "Futa [title]? Haiwezi kurudishwa" → confirm → `DELETE` API call → snackbar "Product deleted" / "Bidhaa imefutwa" → list refreshes

### Notifications & Reminders
- 💡 **First product prompt:** When business has zero products for 7 days: "📦 Add your first product to [Business name] — buyers searching for suppliers won't find you without a catalog"
- ⚠️ **Out of stock alert:** When `stock_quantity` reaches 0: "⚠️ [Product title] at [Business name] is out of stock. Update your listing"
- 📊 **Weekly catalog summary:** "📊 [Business name] has [N] products listed. [X] are active, [Y] are out of stock"
- 💡 **Draft products nudge:** If products in draft status for >3 days: "💡 You have [N] draft products at [Business name]. Publish them so buyers can find you"

### Reports & Insights
- **Catalog health score:** % of products that are active vs draft vs out of stock
- **Most viewed products:** Top 3 products by view count (for default-shop products where views are tracked)
- **Price distribution:** Average, min, max price across catalog
- **Stock warnings panel:** All products with stock_quantity < 5 listed together

### Cross-Module Connections
- **Shop:** For default-shop businesses, this page IS the seller product management. Changes made here reflect immediately in the marketplace. "View in Shop" link on each product card opens `ProductDetailScreen` in marketplace mode
- **Supplier Search:** When other users search for suppliers, products listed here make this business discoverable. Badge on each product: "Visible to buyers searching for [category]"
- **Budget:** "Catalog has [N] active products with combined value TZS [X]" — tap to see revenue potential estimate
- **Shangazi AI:** "Ask Shangazi: How should I price my products competitively in Tanzania?" — passes business sector + current price range as context

---

## 2. ADD PRODUCT

**Entry:** Products page → FAB (+) → `ProductFormPage` in add mode
**Stage/Context:** Business owner adding a new product listing

### User Journey
1. `ProductFormPage` opens: `AppBar` title "Add Product" / "Ongeza Bidhaa", "Save" / "Hifadhi" action button (disabled until required fields filled)
2. Page is scrollable `SingleChildScrollView` with collapsible sections

**Section: Basic Info**
3. **Title** (required) — `TextField` placeholder "e.g. Maize Flour 2kg"
4. **Description** — multi-line `TextField`, placeholder "Describe your product..."
5. **Type** — `DropdownButtonFormField`: Physical / Digital / Service (default: Physical)
6. **Condition** — `DropdownButtonFormField`: Brand New / Used / Refurbished (hidden when type = Service)
7. **Category** — `DropdownButtonFormField` fetched from categories API
8. **Tags** — `TextField` with chip input (comma-separated), placeholder "e.g. organic, wholesale"

**Section: Pricing**
9. **Price (TZS)** (required) — number `TextField` with TZS prefix
10. **Compare At Price** — number `TextField`, shows "TZS [price] was TZS [compare]" preview when both filled
11. **Currency** — defaults to TZS, dropdown for USD/KES/EUR

**Section: Images**
12. Image picker grid (up to 10 images): tap "+" card → `ImagePicker.pickMultiImage()` → shows selected images in grid with × to remove
13. First image auto-set as thumbnail
14. Reorder by drag-and-drop

**Section: Stock**
15. **Stock Quantity** — number field (hidden when type = Digital or Service)
16. **Status** — chips: Active / Draft / Out of Stock

**Section: Delivery**
17. Three toggle switches: "Pickup available" / "Delivery available" / "Shipping available"
18. **Delivery Fee** — number field (shown when delivery toggle is on)
19. **Pickup Address** — `TextField` (shown when pickup toggle is on)
20. **Delivery Notes** — `TextField` for delivery instructions

**Section: Digital Product** (shown when type = Digital)
21. **Download URL** — `TextField`
22. **Download Limit** — number field

**Section: Location** (shown when type = Physical)
23. **Location Name** — `TextField` for approximate area

24. User taps "Save" / "Hifadhi" → validation runs:
    - Title required
    - Price required and > 0
    - At least one image required
25. On validation pass → images uploaded via `Dio` (chunked, 10-min timeout) with progress indicator
26. After upload → `POST /business/{id}/catalog/products` (or `POST /products` for default shop)
27. Success → snackbar "Product saved" / "Bidhaa imehifadhiwa" → navigate back to Products page → list refreshes
28. API failure → snackbar "Failed to save product. Try again" / "Imeshindikana. Jaribu tena" (red background) → form stays open

### CRUD Operations
- **Create:** Full form as described above
- **Read:** NOT AVAILABLE on this page — view via Products list
- **Edit:** NOT AVAILABLE — this is add-only; edit opens same form pre-filled
- **Delete:** NOT AVAILABLE — delete from Products list detail sheet

### Notifications & Reminders
- 🎉 **First product celebration:** On first-ever product saved: "🎉 Your first product is live on TAJIRI! Buyers searching for suppliers in [sector] can now find you"
- 💡 **Completeness prompt after save:** If description is empty: "💡 Products with descriptions get 3× more views. Add one now?"
- 💡 **Image prompt:** If saved with only 1 image: "💡 Products with 3+ photos get more buyer attention. Add more images?"

### Reports & Insights
- **Real-time price comparison:** While typing price, show "Similar products in [category] are priced TZS [min]–[max]"
- **Category suggestion:** Based on title keywords, suggest category before user selects

### Cross-Module Connections
- **Shop:** Default-shop saves go to `/products` and appear in marketplace immediately
- **Budget:** First product save triggers: "Set a revenue goal for this product? Link to Budget"
- **Shangazi AI:** "Ask Shangazi about pricing [product title] in Tanzania"

---

## 3. EDIT PRODUCT

**Entry:** Products page → tap product card → detail sheet → "Edit" / "Hariri"
**Stage/Context:** Updating price, stock, images, or status on an existing product

### User Journey
1. Detail `BottomSheet` is open showing product info
2. User taps "Edit" / "Hariri"
3. `ProductFormPage` opens in edit mode: `AppBar` title "Edit Product" / "Hariri Bidhaa"
4. All fields pre-filled with existing values
5. Existing images shown in grid with × to remove; user can add more images (up to 10 total)
6. User changes desired fields → taps "Save" / "Hifadhi"
7. New images (if any) uploaded via `Dio` first
8. `PUT /business/{id}/catalog/products/{pid}` (or `PUT /products/{id}` for default shop)
9. Success → snackbar "Product updated" / "Bidhaa imesasishwa" → navigate back → list refreshes
10. **Optimistic UI:** If only status or stock changed (no new images), update happens in <500ms; show inline loading indicator on Save button

### CRUD Operations
- **Create:** NOT AVAILABLE — add-only form for new products
- **Read:** Pre-filled form serves as read
- **Edit:** Full form pre-filled, all fields editable including images
- **Delete:** NOT AVAILABLE from edit form — delete from detail sheet

### Notifications & Reminders
- ⚠️ **Price drop detection:** If price reduced by >20%: "💡 You reduced [Product title] price by [X]%. Consider posting about this deal on your feed"
- ⚠️ **Out of stock after edit:** If stock_quantity set to 0: "⚠️ [Product title] is now marked as out of stock. It will be hidden from buyers"

### Cross-Module Connections
- **Shop:** Price/stock changes for default-shop products instantly reflected in marketplace
- **Feed/Posts:** "Share price update as a post?" prompt after significant price change → pre-fills a post with product photo and new price

---

## 4. PRODUCT STATUS MANAGEMENT

**Entry:** Products page → tap product card → detail sheet → status action, OR via Edit form
**Stage/Context:** Toggling between Active, Draft, and Out of Stock

### User Journey
1. Detail `BottomSheet` shows current status badge
2. Three quick-action chips below product info: "Active" / "Amilifu", "Draft" / "Rasimu", "Out of Stock" / "Nje ya Stoki"
3. User taps a different chip → confirmation for Out of Stock only ("Mark as out of stock? Buyers won't see this product")
4. `PATCH /business/{id}/catalog/products/{pid}` with `{ "status": "..." }`
5. Snackbar confirms change → badge on product card updates immediately

### Notifications & Reminders
- ⚠️ **Draft for too long:** "💡 [Product title] has been in Draft for [X] days. Publish it so buyers can find you?"
- 💡 **Restock prompt:** 3 days after Out of Stock: "📦 Did you restock [Product title]? Update your listing so buyers can order again"

### Cross-Module Connections
- **Shop:** Status sync: Out of Stock in Products → `status = 'inactive'` in Shop marketplace
- **Suppliers module:** Buyers who have added this business as a supplier are notified when key products go out of stock (future feature flag)

---

## 5. MULTI-IMAGE GALLERY MANAGEMENT

**Entry:** ProductFormPage (add or edit) → Images section
**Stage/Context:** Managing the visual presentation of a product

### User Journey
1. Images section shows a horizontal scrollable grid of existing images + "+" add card
2. Tap "+" → system image picker opens (`ImagePicker.pickMultiImage()`, max 10 total)
3. Selected images previewed in grid with loading indicators during upload
4. Tap × on any image to remove (confirmation if it's the only image)
5. Drag to reorder (first image = thumbnail shown in product list)
6. Images uploaded via `Dio` to `/business/{id}/catalog/products/{pid}/images` before product save
7. Progress indicator: "Uploading 2/4 images..."
8. Upload failure per-image: red border on failed image + retry button ("Retry" / "Jaribu Tena")

### CRUD Operations
- **Create:** Add via image picker from camera or gallery
- **Read:** Grid preview within form
- **Edit:** Add more images or remove existing ones, reorder
- **Delete:** Tap × to remove individual image; confirmation dialog if removing the thumbnail

### Notifications & Reminders
- 💡 **After save with 1 image:** "💡 Add more photos — products with 3+ images get more buyer inquiries"

### Cross-Module Connections
- **Shop:** Product images appear in marketplace listing for default-shop products
- **Feed:** "Use this product image in a post?" shortcut after upload

---

## 6. DEFAULT SHOP INTEGRATION

**Entry:** Products page (when business `isDefaultShop = true`)
**Stage/Context:** Business owner who sells on the TAJIRI marketplace

### User Journey
1. Products page loads with a blue info banner at top: "These are your Shop products — changes here update your marketplace listing" / "Hizi ni bidhaa za Duka lako — mabadiliko yataonekana sokoni"
2. Product list shows all marketplace products fetched from `GET /seller/products`
3. Each product card shows standard info + a "Shop" badge indicating it's live in marketplace
4. Tap product → detail sheet has an extra action: "View in Shop" / "Tazama Sokoni" → opens `ProductDetailScreen` in read-only marketplace view
5. Edit works as normal (PUT /products/{id})
6. Add product creates a real marketplace listing (POST /products) — same flow as shop's seller dashboard but accessible from business profile

### Notifications & Reminders
- 📊 **Weekly shop performance:** "📊 Your Shop had [X] views and [Y] orders this week. Top product: [title]"
- ⚠️ **Low stock marketplace alert:** "⚠️ [title] has only [X] units left in your Shop. Restock soon"
- 🎉 **First Shop order:** "🎉 You have your first Shop order! [Buyer name] ordered [Product title]"

### Reports & Insights
- **Shop performance summary:** Total views, favorites, orders, revenue this month
- **Top products:** Ranked by orders
- **Conversion rate:** Views → orders ratio per product

### Cross-Module Connections
- **Shop:** Full bidirectional sync — changes here appear in marketplace immediately
- **Wallet:** Shop revenue tracked and payable to Wallet
- **Budget:** Record shop sales as business income: "This month's Shop revenue: TZS [X]. Record as income?" → `IncomeService`

---

## 7. SERVICES CATALOG (VIEW)

**Entry:** Profile → Business tab → [Business name] → "Services" / "Huduma"
**Stage/Context:** Any business offering services (contractor, salon, mechanic, consultant, etc.)

### User Journey
1. User taps "Services" / "Huduma" in Business section menu
2. Page loads: `AppBar` title "Services" / "Huduma"
3. `ListView` with service cards: photo thumbnail (or icon placeholder), name, pricing badge (e.g. "TZS 50,000 / hr" or "By Quote"), availability chip (Available / Unavailable / By Request)
4. **Empty state:** clipboard icon + "No services yet" / "Bado hakuna huduma" + "Add your first service so clients can find you" + "Add Service" / "Ongeza Huduma" button
5. Tap service card → detail `BottomSheet`: full photo, name, description, pricing, duration, availability, category
6. Detail sheet: "Edit" / "Hariri" and "Delete" / "Futa" actions
7. Pull-to-refresh → `GET /business/{id}/services`
8. FAB (+) → `BizServiceFormPage` in add mode

### CRUD Operations
- **Create:** FAB → `BizServiceFormPage`
- **Read:** `ListView` cards + detail `BottomSheet`
- **Edit:** "Edit" in detail sheet → `BizServiceFormPage` pre-filled
- **Delete:** "Delete" in detail sheet → `AlertDialog` confirmation → `DELETE /business/{id}/services/{sid}` → snackbar "Service deleted" / "Huduma imefutwa"

### Notifications & Reminders
- 💡 **No services prompt:** After 7 days with no services: "💡 Add your services to [Business name] — clients searching for [sector] providers can find you"
- ⚠️ **All services unavailable:** If all services marked Unavailable: "⚠️ All services at [Business name] are marked unavailable. Clients can't find you"
- 📊 **Weekly services summary:** "📊 [Business name] services: [N] listed, [X] available, [Y] inquiries this week"
- 💡 **No-price services prompt:** If a service has `pricing_type = quoted` for >30 days: "💡 Clients are 2× more likely to contact you when a price is shown. Add a starting price to [Service name]?"

### Reports & Insights
- **Services catalog health:** % available vs unavailable vs by_request
- **Category breakdown:** Services grouped by category
- **Pricing distribution:** Fixed vs hourly vs quoted ratio
- **Average response time:** (future) Time between client inquiry and business response

### Cross-Module Connections
- **Appointments:** "View bookings for this service" → `AppointmentsPage` filtered by service
- **Calendar:** Service availability can block calendar dates — "Mark unavailable on specific dates" → `CalendarService.createEvent()`
- **Tajirika:** If business is a freelancer/partner, services connect to Tajirika gig listings
- **Supplier Search:** Clients searching for suppliers find this business via service names
- **Shangazi AI:** "Ask Shangazi: How should I price my [service category] services in Tanzania?"

---

## 8. ADD SERVICE

**Entry:** Services page → FAB (+) → `BizServiceFormPage` in add mode
**Stage/Context:** Business owner listing a new service offering

### User Journey
1. `BizServiceFormPage` opens: `AppBar` title "Add Service" / "Ongeza Huduma", "Save" / "Hifadhi" action
2. Scrollable form with sections:

**Section: Basic Info**
3. **Service Name** (required) — `TextField`, placeholder "e.g. House Painting, Haircut, Legal Consultation"
4. **Category** — `TextField` with suggestions: Cleaning, Beauty, Construction, Legal, Transport, IT, Health, Education, Other
5. **Description** — multi-line `TextField`, placeholder "Describe what's included in this service..."

**Section: Pricing**
6. **Pricing Type** (required) — segmented control: "Fixed" / "Bei ya kawaida", "Per Hour" / "Kwa Saa", "Quote Only" / "Kwa Makubaliano"
7. **Price (TZS)** — number field (hidden when Pricing Type = Quote Only)
8. Price field label changes: "Per job: TZS" (Fixed) or "Per hour: TZS" (Hourly)

**Section: Photo**
9. Single photo picker: tap image placeholder → `ImagePicker.pickImage()` → preview shown
10. Optional but encouraged — shows "Add a photo — clients trust services with photos" prompt if skipped

**Section: Details**
11. **Duration** — optional number field + unit dropdown: Minutes / Hours / Days (e.g. "2 Hours")
12. **Availability** — `DropdownButtonFormField`: Available / "Inapatikana", Unavailable / "Haipatikani", By Request / "Kwa Ombi"

13. User taps "Save" / "Hifadhi" → validation:
    - Name required
    - Pricing type required
    - Price required if type ≠ Quote Only
14. API call: `POST /business/{id}/services`
15. Success → snackbar "Service added" / "Huduma imeongezwa" → navigate back → list refreshes
16. Failure → snackbar "Failed to save. Try again" (red) → form stays open

### CRUD Operations
- **Create:** Form as described
- **Read:** NOT AVAILABLE on this page
- **Edit:** NOT AVAILABLE on this page
- **Delete:** NOT AVAILABLE on this page

### Notifications & Reminders
- 🎉 **First service:** "🎉 Your first service is listed! Clients searching for [category] services can now find [Business name]"
- 💡 **Add photo nudge:** If saved without photo: "📸 Add a photo to [Service name] — services with photos get more inquiries"

### Cross-Module Connections
- **Calendar:** After adding service: "Block off your availability on Calendar so clients know when you're free"
- **Appointments:** "Set up appointment booking for this service?" → `AppointmentsPage`
- **Tajirika:** If user is a Tajirika partner, option to "Also post this as a Tajirika gig?"
- **Budget:** "Set a monthly revenue goal for this service?" → links to Budget income tracking

---

## 9. EDIT SERVICE

**Entry:** Services page → tap service card → detail sheet → "Edit" / "Hariri"
**Stage/Context:** Updating price, availability, or description

### User Journey
1. Detail sheet open → user taps "Edit" / "Hariri"
2. `BizServiceFormPage` opens in edit mode: `AppBar` "Edit Service" / "Hariri Huduma"
3. All fields pre-filled
4. Existing photo shown — tap to replace (cannot add multiple, single photo only)
5. Changes saved → `PUT /business/{id}/services/{sid}`
6. Success → snackbar "Service updated" / "Huduma imesasishwa" → navigate back → list refreshes

### Notifications & Reminders
- ⚠️ **Price increase detection:** If price raised by >30%: "💡 You raised [Service name] price by [X]%. Consider posting about your updated rates"
- 💡 **Availability change:** When changed to Available from Unavailable: "You're available again! Consider posting on your feed to let followers know"

### Cross-Module Connections
- **Calendar:** If availability changed to Unavailable, offer "Block calendar dates for this period?"
- **Feed:** "Post about your availability update?" → pre-fills post with service photo and new rate

---

## 10. SERVICE AVAILABILITY MANAGEMENT

**Entry:** Services page → tap service card → detail sheet → availability chips
**Stage/Context:** Quickly toggling service availability without opening the full edit form

### User Journey
1. Detail `BottomSheet` shows availability chip prominently
2. Three quick-action chips: "Available" / "Inapatikana" (green), "Unavailable" / "Haipatikani" (grey), "By Request" / "Kwa Ombi" (amber)
3. User taps a different chip → immediate `PATCH /business/{id}/services/{sid}` with `{ "availability": "..." }`
4. Snackbar confirms: "Now showing as Available" / "Sasa inaonekana kuwa inapatikana"
5. Service card in list updates chip color immediately (optimistic UI)

### Notifications & Reminders
- ⚠️ **Unavailable for too long:** After 14 days unavailable: "⚠️ [Service name] has been unavailable for 2 weeks. Are you back? Tap to mark Available"
- 💡 **By Request prompt:** After 7 days on By Request: "💡 You've had [X] inquiries for [Service name]. Consider setting a fixed price and marking it Available"

### Cross-Module Connections
- **Calendar:** Unavailable → "Block these dates on your Calendar?" with date range picker
- **Appointments:** Unavailable → cancels any pending appointment requests for this service (with notification to clients)

---

## 11. SUPPLIER SEARCH — PRODUCT DISCOVERY

**Entry:** Suppliers page → "Add Supplier" sheet → search field
**Stage/Context:** Business owner searching for a supplier by what they sell

### User Journey
1. User opens supplier business picker (search sheet)
2. Types a product name, e.g. "cement", "maize", "laptop"
3. Backend `searchTargets` now matches businesses where:
   - Business name contains "cement"
   - Owner's name/handle contains "cement"
   - **Shop product title** contains "cement" (for default-shop businesses)
   - **Catalog product title** contains "cement" (for non-shop businesses)
   - Business service name contains "cement"
4. Results show: business logo, name, sector + a **match reason chip** under the name
   - "Sells: [matched product name]" (amber chip)
   - "Offers: [matched service name]" (blue chip)
5. User taps result → added as supplier (same `_showBusinessPickerSheet` flow)

### Notifications & Reminders
- 💡 **First supplier found via product search:** "💡 You found [Business name] because they sell [product]. Their catalog has [N] more products"

### Cross-Module Connections
- **Purchase Orders:** When a supplier is added via product search, their matched product can be pre-filled when creating the first PO
- **Supplier Catalog:** Supplier's product list accessible from their supplier profile card

---

## 12. SUPPLIER SEARCH — SERVICE DISCOVERY

**Entry:** Suppliers page → "Add Supplier" sheet → search field
**Stage/Context:** Business owner searching for a service provider as a supplier

### User Journey
1. User types a service, e.g. "cleaning", "accounting", "printing"
2. Backend matches businesses offering that service
3. Results include service-provider businesses alongside product sellers
4. Result card shows: "Offers: [matched service name]" chip in blue
5. Adding a service provider as a supplier follows the same flow

### Notifications & Reminders
- 💡 **After adding service supplier:** "💡 [Business name] offers [service]. Book an appointment directly from their supplier profile?"

### Cross-Module Connections
- **Appointments:** Supplier profile page gains "Book Service" shortcut if the supplier has services listed
- **Quotes (RFQ):** When sending a quote request to a service-provider supplier, service names pre-populate the item description

---

## 13. PRODUCT ANALYTICS & INSIGHTS

**Entry:** Products page → "Analytics" icon in AppBar (future) OR inline stats on each product card
**Stage/Context:** Business owner reviewing product performance

### User Journey
1. Each product card shows lightweight stats row: 👁 [views] ❤️ [favorites] 📦 [orders] (sourced from shop data for default-shop products)
2. Tap product → detail sheet shows full stats section:
   - This week vs last week views
   - Conversion rate (views → orders)
   - Revenue generated: TZS [total orders × price]
3. For catalog products (non-shop): stats are inquiry count only (no order tracking in v1)

### Reports & Insights
- **Top performer:** "Your best-selling product this month: [title] — [N] orders, TZS [revenue]"
- **Dead stock alert:** Products with 0 views in 30 days: "⚠️ [title] has had no views in 30 days. Consider updating the photo or price"
- **Revenue estimate:** Total potential revenue if all in-stock products sell once
- **Category insights:** "Most of your products are in [category]. Consider diversifying"

### Notifications & Reminders
- 📊 **Monthly product report:** "📊 [Business name] product summary: [N] products, [X] orders, TZS [revenue] this month"
- ⚠️ **Dead stock warning:** "⚠️ [Product title] hasn't been viewed in 30 days. Refresh the listing with new photos?"
- 🎉 **Sales milestone:** "🎉 [Product title] just reached [50/100/500] orders!"

### Cross-Module Connections
- **Budget:** "TZS [monthly product revenue] earned from product sales. Record as business income?" → `IncomeService`
- **Wallet:** Revenue from shop orders flows to Wallet — "View earnings in Wallet"
- **Shangazi AI:** "Ask Shangazi: Why might my products not be getting views?" — passes catalog and stats as context

---

## 14. SERVICE ANALYTICS & INSIGHTS

**Entry:** Services page → inline stats on service cards
**Stage/Context:** Business owner reviewing which services attract the most interest

### User Journey
1. Service cards show: inquiry count, availability status
2. Tap service → detail sheet includes: "Inquiries this month: [N]", "Last inquiry: [X] days ago"
3. In v1: analytics are basic (inquiry count). Full analytics (booking rate, revenue) in v2 when booking integration ships.

### Reports & Insights
- **Most popular service:** "Your most-inquired service this month: [name] — [N] inquiries"
- **No-inquiry services:** Services with 0 inquiries in 30 days flagged: "Consider updating your description or pricing"
- **Revenue potential:** Sum of fixed-price service rates × estimated monthly bookings
- **Category demand:** If multiple services in same category, consolidate suggestion

### Notifications & Reminders
- 📊 **Monthly service report:** "📊 [Business name] services: [N] inquiries this month. Most popular: [name]"
- 💡 **Improvement tip:** "💡 Services with photos get 2× more inquiries. [X] of your services are missing photos"
- ⚠️ **Stale service:** "⚠️ You haven't updated [Service name] in [N] months. Is it still offered?"

### Cross-Module Connections
- **Appointments:** "Set up appointment booking for [Service name] to capture these inquiries automatically"
- **Budget:** "Estimated monthly service revenue: TZS [X]. Set as income target?" → Budget
- **Calendar:** Service inquiries create calendar follow-up reminders
- **Shangazi AI:** "Ask Shangazi: How can I get more clients for my [service category] business in Tanzania?"

---

## 15. BUSINESS DISCOVERABILITY SCORE

**Entry:** Products or Services page → "Discoverability" banner card at top of page
**Stage/Context:** Helping business owners understand how findable they are in supplier search

### User Journey
1. A card at the top of both Products and Services pages shows a discoverability score (0–100%)
2. Score calculation: has logo (+20), has 3+ products (+20), has description on products (+15), has services (+20), has sector filled (+15), has phone (+10)
3. Incomplete items listed as actionable suggestions: "Add your business logo (+20 points)", "Add a service offering (+20 points)"
4. Tap suggestion → deep-links to the relevant form

### Notifications & Reminders
- 💡 **Low score prompt (weekly):** "💡 [Business name] discoverability is [X]%. Here's how to improve it: [top suggestion]"
- 🎉 **Score milestone:** "🎉 [Business name] reached 80% discoverability! You're more likely to be found by buyers"

### Reports & Insights
- **Score trend:** Week-over-week discoverability score change
- **Comparison:** "Businesses in [sector] with 80%+ discoverability get [X]× more supplier requests"

### Cross-Module Connections
- **Business Profile:** Missing logo → "Update business profile" → `BusinessProfilePage`
- **Suppliers module:** "See how buyers will find you" → preview of how business appears in search results
- **Shangazi AI:** "Ask Shangazi: How can I make my business more discoverable on TAJIRI?"

---

## NOTIFICATION CHANNELS SUMMARY

| Trigger | Notification Text | Channel | Frequency |
|---------|------------------|---------|-----------|
| No products for 7 days | "📦 Add your first product to [Business] — buyers can't find you" | Push | Once |
| Product out of stock | "⚠️ [Product] is out of stock. Update listing" | Push | Per event |
| Draft product >3 days | "💡 [N] draft products waiting. Publish them?" | In-app card | Every 3 days |
| First product saved | "🎉 Your first product is live on TAJIRI!" | Push | Once |
| All services unavailable | "⚠️ All services unavailable — clients can't find you" | Push | Per event |
| Service unavailable >14 days | "⚠️ [Service] unavailable 2 weeks. Are you back?" | Push | Once at 14 days |
| Weekly catalog summary | "📊 [Business] has [N] products, [X] orders this week" | Push | Weekly |
| Monthly product report | "📊 [N] products, [X] orders, TZS [revenue] this month" | Push | Monthly |
| Dead stock >30 days | "⚠️ [Product] hasn't been viewed in 30 days. Refresh it?" | In-app card | Once at 30 days |
| Sales milestone (50/100/500 orders) | "🎉 [Product] reached [N] orders!" | Push | Per milestone |
| Low discoverability score | "💡 [Business] discoverability is [X]%. Improve it here" | In-app card | Weekly |

---

## CROSS-MODULE INTEGRATION MAP

| From Products/Services | To Module | Trigger | Data Flow |
|-----------------------|-----------|---------|-----------|
| Default shop products | **Shop** | Any product CRUD | Bidirectional — same data, same API |
| Shop sales revenue | **Wallet** | Order completed | Revenue credited to business wallet |
| Product/service revenue | **Budget** | Monthly summary | Offer to record as business income via `IncomeService` |
| Service booking need | **Appointments** | Service added | "Set up appointment booking?" deep-link |
| Service availability | **Calendar** | Unavailable toggle | Offer to block calendar dates via `CalendarService.createEvent()` |
| Supplier found via product | **Suppliers** | Product search result | Product name pre-fills first PO item |
| Supplier service found | **Suppliers** | Service search result | Supplier profile shows bookable services |
| Business improvement tips | **Shangazi AI** | Any feature | Context: sector + product catalog + stats passed to AI |
| Service provider gigs | **Tajirika** | Service added | "Post as Tajirika gig?" option for freelancers |
| Product/service posts | **Feed** | Price change / new listing | "Share update as post?" shortcut with product photo |
| Quote requests | **RFQ / Quotes** | Supplier search | Matched product/service names pre-fill RFQ item descriptions |
| Business discoverability | **Business Profile** | Score gaps | Deep-link to `BusinessProfilePage` for missing fields (logo, sector) |
