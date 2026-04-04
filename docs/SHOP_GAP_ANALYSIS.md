# TAJIRI Shop — Gap Analysis vs World's Best E-Commerce Platforms

> Benchmarked against: Amazon, Shopee, Shopify, Jumia, AliExpress, Mercado Libre, Etsy, eBay
> Date: 2026-04-04

---

## Scoring Legend

| Score | Meaning |
|-------|---------|
| **--** | Not implemented at all |
| **D** | Stub / broken / incomplete |
| **C** | Basic implementation, functional but minimal |
| **B** | Good implementation, covers main use cases |
| **A** | On par with top global platforms |

---

## 1. PRODUCT DISCOVERY

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Text search with debounce | **C** | Amazon | No autocomplete, no thumbnails in suggestions, no fuzzy/did-you-mean |
| Search history | **--** | Shopee | No recent searches shown on focus, no saved searches |
| Voice search | **--** | Amazon/Shopee | Not implemented |
| Visual/image search | **--** | Amazon StyleSnap | Not implemented |
| Barcode/QR scan | **--** | Amazon/eBay | Not implemented |
| Category browsing | **C** | Shopee/Jumia | Single-level chips only, no subcategory drill-down, no icons |
| Advanced filters (price, condition, rating, type) | **--** | Amazon (50+ filters) | Only category filter exists; no price range, condition, rating, seller, delivery filters |
| Sort options | **C** | Amazon | 4 options (newest, popular, price asc/desc). Missing: rating, relevance, discount%, free shipping |
| Personalized home feed | **--** | Amazon (35% of revenue) | No ML recommendations, no browse history, no "inspired by" |
| Recently viewed products | **--** | Amazon/Shopee | No tracking or display of recently viewed items |
| Flash deals / daily deals | **--** | Shopee/AliExpress | No time-limited deals, no countdown timers, no deal sections |
| Trending / new arrivals sections | **D** | Shopee | API methods exist (`getTrending`, `getRecommended`) but not wired into UI |
| Nearby products (location) | **D** | Jumia | Service method exists but no location permission flow or UI |
| Infinite scroll pagination | **B** | Shopee | Works at 20 items/page; could optimize with prefetch |
| Grid/list view toggle | **--** | eBay/Amazon | Grid only, no list view option |

**Discovery Score: 2/10** — Only basic search + category filter. No personalization, no advanced filters, no engagement hooks.

---

## 2. PRODUCT DETAIL PAGE

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Image carousel | **C** | Amazon | PageView exists but no pinch-to-zoom, no fullscreen lightbox |
| Image zoom/magnifier | **--** | Amazon/Shopee | Tap/pinch to zoom not implemented |
| Product video | **--** | Amazon/Shopee (+20-30% conversion) | No video field in model, no video player on PDP |
| 360-degree / AR view | **--** | Amazon/IKEA | Not implemented |
| Variant swatches (size/color) | **--** | Amazon/Shopify | No variant system in models or UI |
| Sticky bottom CTA bar | **--** | Shopee/Amazon/Jumia | "Add to Cart" scrolls away; not pinned to bottom |
| Price with discount display | **B** | Amazon | Shows price + compareAtPrice with strikethrough + discount% |
| Delivery estimate ("Get it by Thu") | **--** | Amazon (#3 purchase factor) | No delivery date estimation |
| Stock urgency ("Only 3 left") | **--** | Amazon/Shopee (+5-10% conversion) | `isInStock` is boolean only; no quantity display or urgency |
| Seller card | **C** | Shopee/Etsy | Shows name + rating; missing: response time, follower count, "View Shop" CTA, verified badge display |
| Expandable description | **--** | Amazon | Description shown in full or not at all; no accordion/collapsible sections |
| Specifications table | **--** | Amazon/eBay | No structured specs (key-value pairs) |
| Reviews section | **--** | Amazon/Shopee | Review API exists but **not rendered on PDP at all** |
| Review stats histogram | **--** | Amazon | `ReviewStats` model exists with `ratingDistribution` but unused in UI |
| Review photos/videos | **--** | Amazon/Shopee (trusted 12x more) | No photo reviews gallery |
| Review filters (stars, verified, photos) | **--** | Amazon | Not implemented |
| Q&A section | **--** | Amazon Customer Questions | No Q&A system |
| Size guide / fit info | **--** | ASOS/Amazon Fashion | Not implemented |
| Return policy display | **--** | Amazon/eBay | No return policy section on PDP |
| "Frequently bought together" | **--** | Amazon (+15-25% AOV) | No bundle/cross-sell recommendations |
| Related products | **C** | Amazon | Basic grid by same category; no collaborative filtering |
| Share product | **D** | Universal | `share_plus` imported but share button not visible in PDP UI |
| Coupon/voucher clip | **--** | Shopee/Amazon | No coupon system |
| Pre-order / waitlist | **--** | Amazon | Not implemented |

**PDP Score: 2/10** — Shows images + price + seller. Missing reviews display, zoom, video, urgency, sticky CTA, and trust signals.

---

## 3. CART & CHECKOUT

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Cart with quantity controls | **B** | Amazon | Works: add, remove, update quantity, clear |
| Cart badge on nav | **B** | Universal | Shows item count on Shop tab |
| Cart grouped by seller | **--** | Shopee/AliExpress | Flat list; multi-seller cart not organized by seller |
| "Save for later" / move to wishlist | **--** | Amazon/Shopee | No option to save items from cart |
| Cross-sell recommendations in cart | **--** | Amazon | No "Frequently bought together" or upsell |
| Free shipping threshold nudge | **--** | Amazon/Shopee | No "Add $X more for free shipping" prompt |
| Promo code / coupon input | **--** | Universal | No promo code field in cart or checkout |
| Cart persistence (offline) | **--** | Amazon | Server-side only; no local cache; requires network |
| Saved addresses | **--** | Amazon/Shopify | Manual text input each time; no saved address list |
| Address autocomplete (Google Places) | **--** | Shopify/Amazon | Plain text field; no autocomplete |
| Checkout progress indicator | **--** | Shopify/Amazon | No step indicator (1/2/3) |
| Payment methods | **D** | Jumia (10+ options) | **Only TAJIRI Wallet (PIN)**; no M-Pesa, no card, no COD |
| Express checkout (Apple Pay, Google Pay) | **--** | Shopify (1.72x conversion) | Not implemented |
| Guest checkout | **--** | Shopify/eBay | Must be logged in; 34% abandon at forced registration |
| Buy Now (skip cart) | **--** | Amazon 1-Click | Must go through cart; no instant purchase |
| Order confirmation / receipt | **B** | Amazon | Shows receipt dialog after successful payment |
| Per-item delivery method | **B** | Shopee | Delivery method selectable per cart item |
| Delivery fee calculation | **C** | Shopee | Static fee from product; no distance-based or weight-based calc |
| Installment / BNPL | **--** | Shopee/Mercado Libre (+20-30% on high-ticket) | Not implemented |
| Gift wrapping / message | **--** | Amazon/Etsy | Not implemented |

**Cart & Checkout Score: 3/10** — Functional cart + single payment method. No promo codes, no saved addresses, no alternative payments, no express checkout.

---

## 4. SELLER EXPERIENCE

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Create product listing | **B** | Shopify | Good form: title, description, images, pricing, delivery, category |
| Multi-image upload | **B** | Amazon | Up to 10 images via Dio chunked upload |
| Product variants (size/color) | **--** | Shopify/Amazon | No variant matrix; one listing = one SKU |
| Bulk upload (CSV) | **--** | Amazon/eBay | One-by-one only |
| AI-generated descriptions | **--** | Shopify Magic | Not implemented |
| Background remover for photos | **--** | Shopify/Shopee | Not implemented |
| Draft / auto-save listings | **--** | Amazon/Etsy | No draft saving; lose progress on back |
| SEO tips on listing | **--** | Etsy/eBay | No guidance on title/description quality |
| Order management (status tabs) | **B** | Shopify | 6 status tabs with pagination and action buttons |
| Order search/filter | **--** | Shopify | No search by order number, date range, or buyer name |
| Bulk order actions | **--** | Shopify | Can't confirm/ship multiple orders at once |
| Shipping label generation | **--** | eBay/Amazon/Etsy | Not implemented |
| Analytics dashboard | **--** | Shopify (best mobile) | `getSellerStats()` API exists but NO analytics UI screen |
| Revenue charts/trends | **--** | Shopify | Not implemented |
| Inventory management | **--** | Shopify/Amazon | No inventory screen, no low-stock alerts |
| Performance scorecard | **--** | Shopee/Amazon | No seller quality metrics display |
| In-app messaging with buyers | **D** | Shopee (best) | Chat button exists on order detail but just navigates to general chat |
| Quick reply templates | **--** | Shopee/AliExpress | Not implemented |
| Return management | **--** | Shopify/Jumia | No return handling interface |

**Seller Score: 3/10** — Can create listings and manage orders. No analytics, no inventory management, no bulk tools, no return handling.

---

## 5. USER JOURNEY & RETENTION

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Shop onboarding | **--** | Shopee | No interest selection, no category preference, no first-use tutorial |
| First-purchase incentive | **--** | Shopee/Jumia | No "$X off first order" coupon |
| Daily check-in rewards | **--** | Shopee (best DAU driver) | No coins/points/rewards system |
| Flash sales at fixed times | **--** | Shopee/AliExpress | No scheduled sales events |
| Wishlist with price drop alerts | **--** | Amazon/eBay | Toggle-only favorites; no dedicated wishlist screen; no price alerts |
| Reorder / "Buy Again" | **--** | Amazon (best) | No repeat purchase shortcut |
| Order tracking notifications | **--** | Amazon/Shopee | No push notifications for order status changes |
| Review request post-delivery | **--** | Amazon/Shopee | No automated review prompts |
| Loyalty tiers | **--** | Shopee/AliExpress | No loyalty program |
| Gamification (coins, games, streaks) | **--** | Shopee | No gamification elements |
| Referral rewards | **--** | Shopee/Amazon | No "invite friend" for shop |
| Back-in-stock alerts | **--** | Amazon/eBay | Not implemented |
| Subscription / recurring orders | **--** | Amazon Subscribe & Save | Not implemented |

**Retention Score: 0/10** — No retention mechanics at all. Zero engagement hooks beyond the transaction.

---

## 6. TRUST & SAFETY

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Buyer protection guarantee | **--** | Shopee/AliExpress/eBay | No money-back guarantee badge or program |
| Escrow payment | **--** | Shopee (best) | Direct wallet deduction; no hold-until-confirmed |
| Return/refund flow | **--** | Amazon (best) | Not implemented at all |
| Dispute resolution | **--** | Shopee/AliExpress | No in-app dispute mechanism |
| Seller verification badge | **D** | Jumia/eBay | `isVerified` field exists in model but not displayed prominently |
| Verified purchase on reviews | **D** | Amazon | `isVerifiedPurchase` field exists in model but reviews not displayed |
| Report fake product | **--** | Amazon/AliExpress | No report mechanism |
| Authenticity guarantee | **--** | eBay (luxury) | Not implemented |
| Seller response to reviews | **--** | Amazon/Etsy | Not implemented |
| Purchase protection timer | **--** | AliExpress/Shopee | Not implemented |

**Trust Score: 0.5/10** — No buyer protection, no returns, no disputes, no escrow. Critical gap for marketplace trust.

---

## 7. SOCIAL COMMERCE

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Photo/video reviews | **--** | Amazon/Shopee | Review model supports images but not displayed |
| Review helpful vote | **D** | Amazon | `markReviewHelpful()` API exists but reviews section not in PDP |
| Product sharing | **D** | Universal | share_plus imported but not wired to visible UI button |
| Seller follow / store page | **--** | Etsy/Shopee/Amazon | No follow system for sellers, no brand storefront |
| User-curated lists | **--** | Amazon Lists/Etsy | Not implemented |
| Live stream shopping | **--** | Shopee Live (10x conversion) | Not implemented |
| Group buying / team purchase | **--** | Pinduoduo/Shopee | Not implemented |
| Feed / discover tab with products | **--** | Shopee Feed | No social product discovery feed |
| Affiliate / referral links | **--** | Amazon Associates | Not implemented |

**Social Score: 0.5/10** — Almost no social commerce features despite TAJIRI being a social platform.

---

## 8. PERFORMANCE & UX POLISH

| Feature | TAJIRI | Best-in-Class | Gap |
|---------|--------|---------------|-----|
| Skeleton/shimmer loaders | **C** | Shopee/Amazon | Basic shimmer on product grid; missing on PDP, cart, orders |
| Image lazy loading | **B** | Amazon | CachedMediaImage widget handles caching |
| Progressive image (blur-up) | **--** | Amazon/Shopify | No blurhash or progressive loading |
| Optimistic UI (cart add, favorite) | **--** | Amazon/Shopee | Full API round-trip before UI update; no instant feedback |
| Prefetch next page | **--** | Amazon/AliExpress | Loads on scroll-to-bottom only; no prefetch |
| Pull-to-refresh | **C** | Shopee | RefreshIndicator on some screens, not all |
| Haptic feedback | **--** | Amazon/Apple Store | No vibration on any shop action |
| Add-to-cart animation | **--** | Shopee/AliExpress | No fly-to-cart animation; just a snackbar |
| Page transitions | **--** | Shopify stores | No shared element or hero transitions between grid ↔ PDP |
| Swipe to delete (cart) | **--** | Universal iOS/Android | Tap-based removal only; no swipe gesture |
| Offline mode | **--** | Amazon/Shopee | No offline product browsing; fails on no network |
| Empty states with CTA | **C** | Etsy/Shopify | Cart has good empty state; search/orders less polished |
| Error recovery (retry) | **C** | Amazon | Some retry buttons; no exponential backoff |
| Bottom sheet filters | **--** | Shopee/Amazon | No filter bottom sheet; filters don't exist yet |
| Responsive image sizing | **--** | Amazon/Shopify | Same image size regardless of screen; no CDN transforms |

**Performance/Polish Score: 3/10** — Functional but not delightful. Missing optimistic updates, animations, haptics, and offline support.

---

## 9. TAJIRI UNTAPPED ADVANTAGES — Platform Infrastructure for Commerce

TAJIRI is not a standalone marketplace. It is a **social super-app** with 30+ infrastructure components that, if wired into Shop, would create competitive moats no pure-play marketplace can replicate.

### 9a. Social Graph & Community

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Friends system** (add, accept, block, mutual count) | Active, used for feed/messaging | **Social proof on PDP** ("3 friends bought this"), friend-curated wish lists, "Ask a friend" button |
| **Groups** (create, join, leave, posts, members) | Full-featured | **Group buying / bulk discounts**, group-exclusive deals, community storefronts |
| **Followers / Following** | Functional | **Seller follow** with new-listing notifications, influencer storefronts |
| **People search** (by name, school, employer, location) | Advanced multi-factor | **Find sellers** by location/school/employer affinity — trust signal unique to Tanzania |
| **Engagement levels / gamification** | User engagement tiers exist | **Seller trust badges** based on platform engagement, buyer loyalty tiers, XP for reviews |

### 9b. Messaging & Real-Time Communication

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **1:1 and group chat** (text, media, reactions, replies) | Full-featured with caching | **Buyer-seller chat** with product card embeds, order status updates in-chat |
| **Media messages** (images, video, audio, documents) | Supported | **Share product listings in chat**, receive photos for custom orders |
| **Message reactions** | ❤️ 👍 etc. | Quick confirmations on order negotiations |
| **WebRTC voice/video calls** | Working (just fixed) | **Video product demos**, live haggling, seller consultations |
| **FCM push notifications** | Payload-based routing | **Order status push**, price drop alerts, flash sale notifications, review requests |

### 9c. Content & Media Engine

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Post system** (text, image, video, audio, polls) | Rich, with reactions/comments | **Shoppable posts** — tag products in any post, "Shop this look" |
| **Stories** | Full-featured | **Product story ads**, seller daily stories with product links |
| **Clips / short video** | TikTok-style with stitch/reply | **Product demo clips**, unboxing videos, shoppable short video |
| **Live streaming** (WebSocket chat, gifts, co-hosts) | Working | **Live stream shopping** (Shopee Live generates 10x conversion) — gifts become product purchases |
| **Battle mode** | Head-to-head content battles | **Seller battles** — competing products, audience votes to buy |
| **Content Engine** (personalized feed, recommendations) | ML-powered feed ranking | **Personalized product feed** — same algorithm can rank products by user affinity |
| **Media cache** (30-day disk, 200-file LRU) | Active | **Product image caching** — instant PDP loads, offline product browsing |

### 9d. Payments & Financial Infrastructure

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **TAJIRI Wallet** (balance, deposits, withdrawals) | Working | Already used for Shop — extend to **escrow**, **split payments**, **installments** |
| **M-Pesa integration** (deposit/withdraw) | Working for wallet top-up | **Direct M-Pesa checkout** — skip wallet, pay from M-Pesa directly |
| **P2P transfers** | Working | **Pay seller directly** for C2C marketplace, **gift cards** |
| **Payment requests** | Can request money from users | **Invoice system** for custom orders, **COD confirmation** |
| **Transaction history** | Full ledger | **Purchase history** with reorder, **spending analytics** |
| **Michango (crowdfunding)** | Full campaigns with tiers | **Group buying campaigns** — "10 people commit, everyone gets 20% off" |

### 9e. AI & Intelligence

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Shangazi Tea** (AI chat with 76 MCP tools) | Active, SSE streaming | **AI shopping assistant** — "Find me a dress under 50k", "Compare these phones", product Q&A |
| **Content Engine recommendations** | Feed ranking | **Product recommendations** — "Because you liked X", collaborative filtering |
| **Backend AI Assistant** | Developer tool | **AI product descriptions**, auto-categorization, price suggestions for sellers |

### 9f. Events & Location

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Events system** (create, RSVP, tickets) | Full-featured | **Pop-up shop events**, product launch events, market day scheduling |
| **Location services** (region/district/ward/street) | Granular Tanzania locations | **Hyper-local marketplace** — "Shop your ward", distance-based delivery pricing, nearby sellers |
| **Event ticketing** | Working | **Product pre-orders as events**, flash sale tickets |

### 9g. Creator Economy & Monetization

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Analytics / creator metrics** | Per-post analytics, weekly reports | **Seller analytics dashboard** — views, conversion, revenue trends |
| **Advertising system** (sponsored posts, targeting) | Infrastructure exists | **Sponsored product listings**, seller-funded promotions |
| **Subscriptions / tiers** | Multi-tier subscription model | **Premium seller tiers** — verified badge, priority listing, analytics access |
| **Music streaming** | Full library with playlists | **Seller profile music** (like Etsy shop ambiance), product video soundtracks |

### 9h. Verification & Trust

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Phone verification** | Required at registration | **Verified buyer/seller** — real phone = real person |
| **Profile completeness** (education, employer, location) | Rich profile data | **Trust scoring** — complete profiles get trust badge, school/employer affiliations visible |
| **Face detection** (profile photo with bbox) | ML Kit integration | **Seller identity verification**, anti-fraud for high-value listings |
| **Report system** | Content reporting | **Report fake products**, counterfeit flagging |

### 9i. Background Infrastructure

| Asset | Current State | Shop Leverage Opportunity |
|-------|--------------|--------------------------|
| **Background sync** (WorkManager) | Being implemented | **Order status sync**, inventory alerts, price drop monitoring |
| **ETag caching** | Being implemented | **Product catalog caching** — 304 responses for unchanged listings |
| **Search history** | Being implemented | **Product search history**, personalized search suggestions |
| **Hive local storage** | Used across app | **Cart persistence**, offline wishlist, draft listings |
| **Firebase Firestore live updates** | Real-time event bus | **Real-time inventory updates**, live auction bids, flash sale countdowns |

### Competitive Moat Summary

```
Pure Marketplace (Jumia/Shopee):     Product → Cart → Pay → Ship
TAJIRI Social Commerce:              Discover (feed/stories/clips/live/chat/AI)
                                     → Trust (friends bought it, verified profile, school affinity)
                                     → Negotiate (chat, video call, payment request)
                                     → Pay (wallet, M-Pesa, crowdfund, installments)
                                     → Share (post review, story, clip)
                                     → Retain (notifications, groups, events, loyalty)
```

**No pure marketplace can replicate this without building an entire social platform first.** TAJIRI's advantage is that the social infrastructure already exists — it just needs to be wired into commerce flows.

---

## 10. PERFORMANCE IMPLEMENTATION PLAN FOR SHOP

> Sourced from: `docs/PERFORMANCE_STRATEGY.md` + `docs/PERFORMANCE_IMPLEMENTATION_PLAN.md` + `docs/SQLITE_ADOPTION_ROADMAP.md`

### Current Performance Gaps (Shop-relevant)

| Problem | Impact on Shop | Root Cause |
|---------|---------------|------------|
| Shop loads 4 parallel API calls on every mount | Slow Shop tab open, wasted bandwidth | No product/category cache |
| All 5 tabs load simultaneously | Shop fires API calls even when user is on Feed | `IndexedStack` eager loading |
| Images show grey box + spinner | Products look unpolished, lower trust | No BlurHash placeholders |
| No HTTP-level caching (ETag/304) | Every Shop visit re-downloads full product list | No `If-None-Match` headers |
| No offline product browsing | Shop fails entirely without network | No local persistence |
| Every filter/sort change hits API | Spinner on every interaction, feels sluggish | No local query capability |
| Cart requires network for every action | Add-to-cart fails offline, no persistence across restarts | Cart is API-only, no local state |
| Search is server-side only | No autocomplete, no instant results, no history | No local full-text index |

### Two-Layer Cache Architecture: Hive + SQLite

TAJIRI already has `MessageDatabase` (SQLite) as a proven pattern. The performance plan uses **both** storage engines, each for what it does best:

| Layer | Engine | Best For | Shop Usage |
|-------|--------|----------|------------|
| **Simple SWR cache** | Hive | Key-value, feed pages, conversation lists | Feed cache, ETag store, profile cache |
| **Relational + FTS** | SQLite | Queries, filters, sorts, full-text search, offline mutations | Products, cart, categories, search, wishlist, recently viewed |

**Why SQLite for Shop specifically:**
- Hive can't do `WHERE price BETWEEN 10000 AND 50000 AND category = 'electronics'`
- Hive can't do FTS5 full-text search with ranking
- Hive can't JOIN cart items with product details
- Hive has no pending mutation queue pattern for offline writes
- SQLite's `MessageDatabase` pattern is already proven in this codebase

### SQLite Schema for Shop

```sql
-- Products (cached from API, delta-synced)
CREATE TABLE shop_products (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    price REAL,
    compare_at_price REAL,
    discount_percentage REAL,
    category_id INTEGER,
    category_name TEXT,
    seller_id INTEGER,
    seller_name TEXT,
    seller_rating REAL,
    condition TEXT,
    rating REAL,
    review_count INTEGER,
    is_in_stock INTEGER,
    stock_quantity INTEGER,
    thumbnail_url TEXT,
    blurhash TEXT,
    delivery_fee REAL,
    delivery_method TEXT,
    location_region TEXT,
    location_district TEXT,
    json_data TEXT,           -- full API JSON for lossless reconstruction
    cached_at INTEGER,        -- unix timestamp for staleness check
    viewed_at INTEGER         -- for recently viewed (NULL = never viewed)
);

-- FTS5 virtual table for instant product search
CREATE VIRTUAL TABLE shop_products_fts USING fts5(
    title, description, category_name, seller_name,
    content=shop_products, content_rowid=id
);

-- Indexed columns for fast filter/sort queries
CREATE INDEX idx_shop_products_category ON shop_products(category_id);
CREATE INDEX idx_shop_products_price ON shop_products(price);
CREATE INDEX idx_shop_products_rating ON shop_products(rating);
CREATE INDEX idx_shop_products_seller ON shop_products(seller_id);
CREATE INDEX idx_shop_products_condition ON shop_products(condition);
CREATE INDEX idx_shop_products_cached ON shop_products(cached_at);
CREATE INDEX idx_shop_products_viewed ON shop_products(viewed_at);

-- Categories (full download, rarely change)
CREATE TABLE shop_categories (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    icon_url TEXT,
    parent_id INTEGER,
    product_count INTEGER,
    json_data TEXT,
    cached_at INTEGER
);

-- Cart (local-first, offline-capable, syncs to server)
CREATE TABLE shop_cart (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    delivery_method TEXT,
    selected INTEGER DEFAULT 1,    -- for cart item selection toggle
    added_at INTEGER,
    json_data TEXT,                 -- snapshot of product at add-time (price, title, image)
    sync_state TEXT DEFAULT 'pending'  -- pending | synced | failed
);

-- Wishlist (local-first)
CREATE TABLE shop_wishlist (
    product_id INTEGER PRIMARY KEY,
    added_at INTEGER,
    added_price REAL,              -- track price at save time for "Price dropped!" badge
    json_data TEXT
);

-- Search history (local only)
CREATE TABLE shop_search_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    searched_at INTEGER,
    result_count INTEGER
);

-- Recently viewed (local only, auto-populated)
-- Uses shop_products.viewed_at column — no separate table needed

-- Sync state tracking (delta sync checkpoints)
CREATE TABLE shop_sync_state (
    entity TEXT PRIMARY KEY,        -- 'products', 'categories', 'cart'
    last_synced_at TEXT,            -- ISO timestamp
    last_synced_id INTEGER,         -- highest ID seen
    last_etag TEXT                  -- HTTP ETag for 304 support
);

-- Pending offline mutations (queue for when network returns)
CREATE TABLE shop_pending_mutations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity TEXT NOT NULL,           -- 'cart', 'wishlist', 'review'
    action TEXT NOT NULL,           -- 'add', 'update', 'remove'
    payload TEXT NOT NULL,          -- JSON of the mutation
    created_at INTEGER,
    retry_count INTEGER DEFAULT 0,  -- max 3 retries
    last_error TEXT
);
```

### Delta Sync Strategy (Not Full Download)

```
First Install:
  API: GET /shop/products?page=1&per_page=50  →  INSERT INTO shop_products
  User browses page 2, 3, 4  →  each page cached as they scroll
  Categories: GET /shop/categories  →  full download (~50 rows, ~10KB)
  (NEVER downloads entire catalog — only what user sees)

Return Visit (online):
  1. SELECT * FROM shop_products ORDER BY cached_at DESC  →  show instantly (0ms)
  2. Background: GET /shop/products?updated_since={last_synced_at}
  3. Server returns ONLY products changed since last sync
  4. UPSERT changed rows into shop_products
  5. UI updates silently if visible data changed
  6. UPDATE shop_sync_state SET last_synced_at = NOW()

Return Visit (offline):
  1. SELECT * FROM shop_products  →  show cached products
  2. All filters/sorts work locally (SQL queries)
  3. Cart add/remove → INSERT into shop_cart + shop_pending_mutations
  4. Show subtle "Offline mode" indicator
  5. When network returns → process pending_mutations queue

Periodic Background (WorkManager, 15 min):
  1. Delta sync products: GET /shop/products?updated_since={checkpoint}
  2. Sync pending mutations (cart adds, wishlist changes)
  3. Warm product cache for next app open
```

### Storage Budget

| Data | Strategy | Estimated Size |
|------|----------|---------------|
| Products user has browsed | Cache on view, delta refresh, max ~500 rows | 1-2 MB |
| Categories | Full download, 1-hour TTL, ~50 rows | ~10 KB |
| Cart | Local-first, sync mutations | ~5 KB |
| Wishlist | Local-first, sync mutations | ~20 KB |
| Search history | Local only, max 50 queries | ~2 KB |
| FTS5 index | Auto-maintained by SQLite | ~500 KB |
| **Total** | | **~2-3 MB** |

### What SQLite Enables (Impossible with Hive)

| Feature | SQL Query | UX Impact |
|---------|-----------|-----------|
| **Instant filter by price** | `WHERE price BETWEEN ? AND ?` | No spinner on filter change |
| **Instant filter by category** | `WHERE category_id = ?` | Feels like native app |
| **Instant sort toggle** | `ORDER BY price ASC/DESC/rating DESC` | Sort changes in same frame |
| **Multi-filter combo** | `WHERE category_id = ? AND price < ? AND rating >= ? AND condition = ?` | Amazon-level filter UX |
| **Full-text search** | `SELECT * FROM shop_products_fts WHERE shop_products_fts MATCH ?` | Autocomplete as-you-type (<10ms) |
| **Recently viewed** | `WHERE viewed_at IS NOT NULL ORDER BY viewed_at DESC LIMIT 20` | Personalized, instant |
| **Price drop detection** | `JOIN shop_wishlist ON ... WHERE products.price < wishlist.added_price` | "Price dropped!" badges |
| **Cart with product details** | `JOIN shop_products ON cart.product_id = products.id` | Rich cart without extra API call |
| **Result count** | `SELECT COUNT(*) FROM shop_products WHERE ...` | Instant "X results found" |
| **Offline cart mutations** | `INSERT INTO shop_cart ... + INSERT INTO shop_pending_mutations ...` | Cart works without network |

### Backend Requirement

One new query parameter on existing endpoint:

```
GET /shop/products?updated_since={ISO_timestamp}
```

Returns only products created or modified after that timestamp. Enables delta sync without full re-download. Can be added via:

```bash
./scripts/ask_backend.sh "Add updated_since query parameter to GET /shop/products
that filters by updated_at >= parameter value. Return only products modified after
that timestamp. Used for mobile delta sync."
```

### 5-Phase Performance Strategy (Updated with SQLite)

#### Phase 1: Feed Cache + SQLite Shop Foundation (Week 1)
**Shop benefit:** Instant product display from SQLite, instant filters/sorts, persistent cart.
- **New:** `lib/services/feed_cache_service.dart` — Hive-backed SWR for feed
- **New:** `lib/services/shop_database.dart` — SQLite database (follows `MessageDatabase` pattern)
- **Modify:** `lib/services/shop_service.dart` — read from SQLite first, API in background, UPSERT on response
- **Pattern:** `SELECT FROM shop_products` → show instantly → `GET /shop/products` → UPSERT → update UI silently

#### Phase 2: BlurHash Image Placeholders (Week 2)
**Shop benefit:** Product images show beautiful blurred previews instead of grey boxes.
- **Backend:** Generate BlurHash at image upload, store in DB, return in API responses
- **Frontend:** `flutter_blurhash` package, `CachedMediaImage` renders BlurHash placeholder
- **SQLite:** Store `blurhash` column in `shop_products` for offline BlurHash display

#### Phase 3: Lazy Tab Loading + FTS5 Search (Week 3)
**Shop benefit:** Shop tab doesn't load until tapped; search is instant from local FTS5 index.
- **New:** `lib/widgets/lazy_indexed_stack.dart` — only builds tab on first visit
- **SQLite:** FTS5 search replaces server-side search for cached products — autocomplete in <10ms
- **Impact:** Startup API calls drop from 15+ to 3-5; search feels native

#### Phase 4: Prefetch, Pagination & Offline Cart (Week 4)
**Shop benefit:** Infinite scroll prefetched; cart works offline with mutation queue.
- **Prefetch:** At 60% scroll, fetch next page → INSERT INTO shop_products
- **Cart:** All cart ops are local SQLite writes + pending_mutations queue
- **Wishlist:** Local-first with price-drop tracking
- **Impact:** Zero spinners in scroll, cart works on a plane

#### Phase 5: Background Sync & Delta Refresh (Weeks 5-6)
**Shop benefit:** SQLite cache warmed in background; delta sync minimizes bandwidth.
- **WorkManager:** `GET /shop/products?updated_since=...` every 15 min → UPSERT into SQLite
- **Pending mutations:** Process cart/wishlist queue when network returns
- **Search history:** Persisted in `shop_search_history` table, shown as chips
- **Impact:** 80%+ cache hit rate; offline-first commerce

### Files Summary (Updated)

| File | Phase | Purpose |
|------|-------|---------|
| `lib/services/shop_database.dart` | 1 | **SQLite database** — products, cart, categories, wishlist, search history, sync state, pending mutations |
| `lib/services/feed_cache_service.dart` | 1 | Hive SWR cache for social feed |
| `lib/widgets/lazy_indexed_stack.dart` | 3 | Lazy Shop tab loading |
| `lib/services/shop_service.dart` | 1,3 | SQLite-first reads, API background sync, FTS5 search |
| `lib/services/conversation_cache_service.dart` | 4 | Buyer-seller chat cache (Hive) |
| `lib/services/etag_cache_service.dart` | 5 | HTTP 304 caching (Hive) |
| `lib/services/background_sync_service.dart` | 5 | WorkManager delta sync for Shop SQLite |
| `lib/widgets/cached_media_image.dart` | 2 | BlurHash + avatar memory fix |
| `lib/services/media_cache_service.dart` | 1,4 | Bump to 1000 files, faster stagger |

### Success Metrics (Updated with SQLite)

| Metric | Before | After (Hive only) | After (Hive + SQLite) |
|--------|--------|-------------------|----------------------|
| Time to first product visible | 2-5s | <100ms | <50ms (SQL indexed) |
| Filter/sort change | 1-3s (API) | 1-3s (still API) | **<10ms (local SQL)** |
| Search results | 500ms+ (API) | 500ms+ (still API) | **<10ms (FTS5)** |
| Cart add (offline) | Fails | Fails | **Instant (local write)** |
| Cart persistence across restart | Lost | Lost | **Survives restart** |
| Product browsing offline | Fails | Static cached page | **Full filter/sort/search** |
| Shop tab startup API calls | 4+ | 0 then 1-2 | 0 then **delta only** |
| Bandwidth per session | ~500KB | ~200KB (ETag 304) | **~20KB (delta sync)** |
| Product catalog cache hit rate | 0% | >80% | **>95% (SQLite persists)** |

### Architecture Target State (Shop Flow — SQLite-Powered)

```
Shop Tab First Visit:
  ├── Frame 0: SELECT * FROM shop_categories  →  instant category bar
  ├── Frame 1: SELECT * FROM shop_products LIMIT 20  →  instant grid (or skeleton if empty)
  ├── Frame 2: Product images from MediaCacheManager disk cache + BlurHash
  ├── Background: GET /shop/products?page=1  →  UPSERT into SQLite
  ├── Scroll 60%: Prefetch page 2  →  INSERT INTO shop_products
  └── User sees zero spinners after first install

Shop Tab Return Visit:
  ├── Frame 0: Instant (LazyIndexedStack keeps screen alive)
  ├── Background: GET /shop/products?updated_since=...  →  delta UPSERT
  └── No spinner, no flicker, minimal bandwidth

Filter/Sort Change:
  ├── Frame 0: SELECT ... WHERE category=? AND price BETWEEN ? AND ? ORDER BY rating DESC
  ├── Result: <10ms — no network, no spinner
  └── "42 results" count from SELECT COUNT(*)

Product Search:
  ├── Keystroke 1: SELECT FROM shop_products_fts MATCH 'sam*'  →  instant suggestions
  ├── Keystroke 2: MATCH 'sams*'  →  refined
  ├── Background: API search for results not in local cache
  └── Merge: local results shown first, API results appended

Add to Cart (online or offline):
  ├── INSERT INTO shop_cart (product_id, quantity, sync_state) VALUES (?, 1, 'pending')
  ├── INSERT INTO shop_pending_mutations (entity, action, payload) VALUES ('cart', 'add', ?)
  ├── UI: cart badge +1 instantly, haptic feedback
  ├── Background: POST /shop/cart/add  →  on success: UPDATE sync_state = 'synced'
  └── If offline: mutation queued, processed when network returns

Product Detail Page:
  ├── Frame 0: SELECT * FROM shop_products WHERE id = ?  →  instant (already cached from grid)
  ├── Frame 0: BlurHash placeholder from shop_products.blurhash
  ├── Frame 1: Full-res images from MediaCacheManager
  ├── UPDATE shop_products SET viewed_at = ? WHERE id = ?  (track recently viewed)
  └── Seller profile from ProfileService LRU cache

Background (app minimized, WorkManager every 15 min):
  ├── Delta sync: GET /shop/products?updated_since=...  →  UPSERT
  ├── Process pending_mutations queue (cart, wishlist)
  ├── Warm cache for next app open
  └── ~20KB per sync vs ~500KB full re-download
```

### Projected Score Impact (SQLite + Full Performance Plan)

| Category | Current | With Hive Only | With Hive + SQLite |
|----------|---------|---------------|-------------------|
| Product Discovery | 2/10 | 3/10 | **5/10** (FTS5 search, instant filters, history, recently viewed) |
| Cart & Checkout | 3/10 | 3.5/10 | **5.5/10** (persistent cart, offline cart, instant ops) |
| Performance & UX | 3/10 | 5/10 | **7/10** (instant everything, offline mode, delta sync) |
| **Overall Weighted** | **1.95** | **~2.6** | **~3.5** |

---

## OVERALL SCORECARD

| Category | TAJIRI Score | Weight | Weighted |
|----------|-------------|--------|----------|
| Product Discovery | 2/10 | 20% | 0.4 |
| Product Detail Page | 2/10 | 20% | 0.4 |
| Cart & Checkout | 3/10 | 20% | 0.6 |
| Seller Experience | 3/10 | 10% | 0.3 |
| User Journey & Retention | 0/10 | 10% | 0.0 |
| Trust & Safety | 0.5/10 | 10% | 0.05 |
| Social Commerce | 0.5/10 | 5% | 0.025 |
| Performance & UX Polish | 3/10 | 5% | 0.15 |
| **TOTAL** | | **100%** | **1.95/10** |

---

## PRIORITY ROADMAP

### Phase 1 — Trust & Conversion (Critical)
*Without these, buyers won't trust the platform enough to purchase.*

| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 1 | **Display reviews on PDP** (data already exists) | High | Low |
| 2 | **Sticky "Add to Cart / Buy Now" bottom bar** on PDP | High | Low |
| 3 | **Stock urgency display** ("Only 3 left") | Medium | Low |
| 4 | **Image zoom** (pinch-to-zoom on PDP carousel) | Medium | Low |
| 5 | **Return/refund flow** (initiate, track, resolve) | Critical | High |
| 6 | **Buyer protection badge** (escrow or guarantee) | Critical | High |
| 7 | **M-Pesa / mobile money payment** | Critical | High |

### Phase 2 — Discovery & Engagement
*Helps users find products and keeps them coming back.*

| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 8 | **Advanced filters** (price range, condition, rating, delivery) | High | Medium |
| 9 | **Search autocomplete** with product thumbnails | High | Medium |
| 10 | **Recently viewed products** bar | Medium | Low |
| 11 | **Wishlist screen** (from existing favorites) | Medium | Low |
| 12 | **Promo codes / coupons** system | High | Medium |
| 13 | **Saved addresses** for checkout | Medium | Medium |
| 14 | **Order tracking timeline** with push notifications | High | Medium |

### Phase 3 — Seller Tools & Analytics
*Makes TAJIRI attractive for sellers, which drives supply.*

| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 15 | **Seller analytics dashboard** (wire existing API) | High | Medium |
| 16 | **Product variants** (size/color matrix) | High | High |
| 17 | **Inventory management** with low-stock alerts | Medium | Medium |
| 18 | **Bulk order actions** (confirm/ship multiple) | Medium | Low |
| 19 | **Return management** for sellers | High | Medium |

### Phase 4 — Retention & Social Commerce
*Builds habit loops and viral growth.*

| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 20 | **Daily deals / flash sales** | High | Medium |
| 21 | **Reorder / Buy Again** | Medium | Low |
| 22 | **Product sharing** (WhatsApp deep links) | Medium | Low |
| 23 | **Live stream shopping** (leverage existing streams infra) | Very High | Very High |
| 24 | **Loyalty points / coins** system | High | High |
| 25 | **First-purchase coupon** | High | Low |

### Phase 5 — Polish & Performance
*Makes the experience feel premium.*

| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 26 | **Optimistic UI** (instant cart add, instant favorite) | Medium | Low |
| 27 | **Skeleton loaders** on all shop screens | Medium | Low |
| 28 | **Add-to-cart fly animation** | Low | Low |
| 29 | **Haptic feedback** on key actions | Low | Low |
| 30 | **Hero transitions** (grid → PDP) | Low | Medium |
| 31 | **Offline product browsing** (cache recent) | Medium | Medium |

---

## QUICK WINS (< 1 day each, high impact)

These can be implemented immediately with existing code/data:

1. **Show reviews on PDP** — `getProductReviews()` API + `ReviewStats` model already exist
2. **Sticky bottom CTA bar** — Move "Add to Cart" + "Buy Now" to `bottomNavigationBar`
3. **Show stock count** — Backend likely returns quantity; display "Only X left" when < 5
4. **Wire share button** — `share_plus` already imported; add IconButton to PDP AppBar
5. **Wire seller stats** — `getSellerStats()` API exists; create a simple stats card on seller profile
6. **Recently viewed** — Store product IDs in SharedPreferences; show horizontal scroll on shop home
7. **Wishlist screen** — Wrap existing `getFavorites()` API in a dedicated screen
8. **Optimistic favorite toggle** — Update UI instantly, revert on API failure

---

## COMPETITIVE POSITION SUMMARY

```
TAJIRI Shop Today:  ████░░░░░░░░░░░░░░░░  ~20% of global best
After Phase 1:      ████████░░░░░░░░░░░░  ~40% (trust + conversion)
After Phase 2:      ████████████░░░░░░░░  ~60% (discovery + engagement)
After Phase 3:      ██████████████░░░░░░  ~70% (seller ecosystem)
After Phase 4:      ████████████████░░░░  ~80% (retention + social)
After Phase 5:      ██████████████████░░  ~90% (polish + performance)
```

**Bottom line:** TAJIRI has a functional marketplace MVP. The critical gaps are **trust/safety** (no buyer protection, no returns) and **payment options** (wallet-only). Phase 1 alone would dramatically improve conversion rates.

**The untapped advantage is massive.** TAJIRI has 30+ platform components (social graph, messaging, video calls, live streams, wallet + M-Pesa, AI assistant, content engine, events, crowdfunding, analytics, ads, subscriptions, gamification, location services, verification) that no pure-play marketplace possesses. Wiring these into commerce flows — shoppable posts, live stream shopping, AI product search, friend-based trust signals, in-chat negotiations, group buying via Michango — would create a social commerce experience that Jumia, Shopee, and Amazon cannot replicate without building an entire social platform from scratch.

**Performance is the foundation.** The 5-phase performance plan (feed cache → BlurHash → lazy tabs → prefetch → background sync) combined with **SQLite local-first storage** will bring Shop load times from 2-5s to <50ms, make filter/sort/search instant (<10ms local SQL), enable offline cart and product browsing, and reduce bandwidth per session from ~500KB to ~20KB via delta sync — essential for Tanzania's variable connectivity. SQLite follows the proven `MessageDatabase` pattern already in the codebase and adds FTS5 full-text search, relational queries for advanced filters, and a pending mutation queue for offline-first commerce.
