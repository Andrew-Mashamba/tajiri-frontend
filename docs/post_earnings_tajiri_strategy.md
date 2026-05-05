# Post Earnings — TAJIRI Creator Earnings Strategy

> **North star:** be **9× better for creators and streamers** than YouTube,
> TikTok, Instagram, Twitch, and Kick — while staying financially stable
> and operationally manageable. Pay more, pay faster, pay in mobile
> money, show creators *exactly why* every shilling landed in their
> wallet.

**Status:** v3 — locked 2026-05-03. Phase 1 (Creators Fund as
creator-acquisition spend) is the active mode at ship; Phase 2
(70/30 ad rev-share) ships when advertisers materialize.
**Author/owner:** @andrew
**Replaces:** the read-time formula in
`app/Http/Controllers/Api/PostEarningsController.php` (which only credits
the post author from raw `posts.*_count` columns).

---

## 0. Why we need this

Today's `GET /api/posts/{id}/earnings` is not an engine — it's a
read-time multiplication of `posts.*_count × creator_earnings_rates`.
That's fine for a "pretty number on the post detail screen," but it
doesn't pay anyone, doesn't credit commenters, doesn't survive a
re-count, and doesn't touch the chart of accounts. Meanwhile the
competitive bar in 2026 is:

- Kick pays subscribers' creators 95/5
- YouTube pays Long-form 55/45 and Shorts 45/55
- TikTok Creator Rewards delivers $0.40–$1.00 per 1k qualified views — and excludes Sub-Saharan Africa entirely
- Twitch tops out at 70/30 only after sustained 300+ subs/month
- Patreon takes a flat 10% on memberships
- **No platform pays out natively to M-Pesa / Airtel / MTN MoMo, the only rails most TZ creators actually use**
- **No platform shows creators "this exact view earned you X TSh from advertiser Y"** — provenance is the universal weak point

We have a structural advantage Western platforms can't copy: **we own
Tajiri Pay**, so our marginal payout cost is ~0%. Every cent we don't
spend on Stripe / PayPal / wire-transfer fees can be returned to
creators. That's how we credibly underwrite a 95/5 split on direct
fan-funding without going bankrupt.

**Commercial reality, May 2026.** TAJIRI does not yet have advertisers.
We're building creator supply first — pay creators well from a
TAJIRI-controlled fund (treated as creator-acquisition spend), grow
content quality and audience, and once there's real audience to sell,
advertisers will come. At that point we transition to a 70/30 ad
rev-share. This is **Phase 1 → Phase 2** in the model below (§1.2 +
§1.3); the same plumbing serves both phases — only the fund-size
formula changes.

---

## 1. Revenue model

A creator on TAJIRI earns from **six streams**, organized into two
classes:

- **The TAJIRI Creators Fund** (TAJIRI-controlled) funds the
  engagement-driven stream. TAJIRI commits a defined fund amount per
  settlement period and distributes it across creators based on
  attributed engagement.
- **Direct pass-through streams** flow money from a fan / buyer /
  sponsor / viewer to the creator, with TAJIRI taking a small cut at
  the point of transaction.

### 1.1 The streams

| # | Stream | Class | Funding source | Creator share | Platform share | Comparable |
|---|---|---|---|---|---|---|
| 1 | **Engagement Pool** (views, reactions, comments, shares, saves, watch-time, derivative royalties, sharer credits) | **Creators Fund** | TAJIRI Creators Fund (see §1.2) | full fund, distributed by attributed points | 0 % from creator's allocation; TAJIRI's cost is the fund itself | YouTube Shorts Creator Pool (45 %) |
| 2 | **Direct Fan-Funding** (subscriptions, tips / Coins, Michango) | Pass-through | Fans' Tajiri Pay payments | **95 %** | 5 % | Kick (95 %) |
| 3 | **Marketplace / Storefront** (product sales attached to posts) | Pass-through | Buyers' Tajiri Pay payments | **100 %** first 90 days, then **95 %** | 0 % / 5 % | TikTok Shop (~6 %) |
| 4 | **Brand-Deal Facilitation** (TAJIRI-mediated sponsorships) | Pass-through | Brand spend | **90 %** | 10 % | Meta / TikTok (15 %) |
| 5 | **Live Gifts & Super Chat** (real-time donations during streams) | Pass-through | Viewers' Tajiri Pay payments | **90 %** | 10 % | TikTok LIVE (~25–35 % net); Bigo (~16 %) |
| 6 | **Affiliate / Referral** (driving signups, marketplace conversions) | Pass-through | Platform conversion budget | per-conversion bounty (TZS-denominated) | n/a | TikTok Shop affiliate |

The five pass-through streams are conceptually simple: a fan or buyer
or sponsor pays the creator, TAJIRI takes a cut at the point of
transaction. The Creators Fund (stream 1) is where the real
engineering and policy work lives.

### 1.2 The TAJIRI Creators Fund

Engagement-based earnings (every view, reaction, comment, reply,
share, save, watch-second, derivative-content royalty, and sharer
discovery credit defined in §2) are paid **from a Creators Fund that
TAJIRI controls** — not as a percentage of ad revenue passing through
in real time.

The fund operates in **two phases**, mapped to TAJIRI's commercial
maturity. Both phases use the same accounting plumbing, schemas, and
distribution algorithm — only the fund-size formula changes.

#### Phase 1 — bootstrap (current: no advertisers yet)

TAJIRI has no advertisers yet. The Creators Fund is treasury-funded
and used as a **creator-acquisition incentive**: pay creators well to
attract supply, build content quality, build audience. Once the
audience is real, advertisers come. This is the same playbook TikTok,
Snapchat Spotlight, and Quibi all used to bootstrap supply.

**Phase 1 fund formula:**

```
fund_this_period = phase_1_committed_budget
```

A fixed amount TAJIRI commits each period from treasury, sized
explicitly as creator-acquisition spend:

```
phase_1_committed_budget = target_active_creators × target_avg_payout_per_creator
                         = 5 000 creators × TZS 10 000 / week
                         = TZS 50 000 000 / week  (initial parameter)
```

Funded from: VC capital, founder contribution, marketing /
growth budget. Booked to the COA as a **customer-acquisition
expense**, not as a rev-share liability — because in Phase 1 it
*is* CAC: TAJIRI is buying creator supply. The expected ROI is
content volume, audience growth, and the eventual advertiser
demand that lets us transition to Phase 2.

**Phase 1 economics check:**

```
weekly fund out:  TZS 50M  (creator acquisition spend)
weekly platform-take inflows (Phase 1):
  Stream 2 (subs/tips/Michango)       — small, growing
  Stream 5 (live gifts)               — small, growing
  Streams 3, 4, 6 (marketplace, brand-deals, affiliate) — minimal
treasury runway:  18-24 months of TZS 50M / week = TZS 4–5B
```

The fund is sized so that, at the rate creators grow, treasury
runway clears comfortably the time-to-Phase-2 transition.

#### Phase 2 — rev-share (when advertisers come)

Once advertiser demand materializes (criteria in §1.3), the fund
transitions to a **70 / 30 ad rev-share** model — creators keep 70%
of ad revenue their content generates, TAJIRI keeps 30%. The fund
abstraction stays the same; only the formula changes.

**Phase 2 fund formula:**

```
fund_this_period = MAX(
    floor_tsh,                                        // never below floor
    0.70 × ad_revenue_this_period                     // 70/30 ad rev-share
    + 0.10 × pass_through_takes_this_period           // 10 % of streams 2-6 platform takes
                                                      // re-injected to fund
    + treasury_topup_this_period                      // discretionary; usually 0
)
```

where:

- **`floor_tsh`** is preserved from Phase 1 commitment (creators don't
  see income drop on transition); 30-day advance notice required to
  decrease (§11.4).
- **70 / 30 ad split** — TAJIRI takes 30% of ad revenue at the platform
  level; the remaining 70% funds the creator pool. Beats YouTube
  (45/55 on Shorts) by 15 pts and matches the user's directive.
- **10% of pass-through takes** flow back into the fund — i.e., when
  TAJIRI takes 5% of a sub or 10% of a brand deal, 10% of that
  *take* (so 0.5% / 1% of GMV) is re-injected into the fund. This is
  a small but symbolic reinforcement: success of pass-through streams
  partially returns to engagement creators.
- **Treasury top-up** is discretionary and usually zero — used only
  to bridge the floor when ad revenue is temporarily insufficient.

**Phase 2 economics check:**

```
target weekly fund:  ≥ TZS 200M
required weekly ad revenue at 70 / 30:  TZS 285M
required monthly ad revenue:  TZS 1.14B  (~$450k)
required active advertiser count:  ≥ 50  (per §1.3 transition criteria)
```

Both the `floor_tsh` and the 70/30 ad-split coefficient are published
on the public rate card and governed by the rate-change-notice
protections of §11.4 (30-day advance notice on any decrease). The
floor protects creators when ads dip; the rev-share tie ensures the
fund grows with platform success.

#### Distribution algorithm

During the period, every chargeable `earning_events` row earns
**points** using the per-metric base rate × multipliers (B+C
attribution rules from §2):

```
points(creator, period) = SUM over events of (
    base_rate(metric, actor_role)
    × raw_count
    × watch_completion_multiplier
    × originality_multiplier
    × mwanzo_boost_multiplier
    × streak_bonus_multiplier
    × discovery_mode_multiplier
    × tier_boost_multiplier        // Partner = 1.05; others = 1.00
)
```

At settlement time the fund is **fully distributed** proportional to
points:

```
total_points = SUM(points across all eligible creators)
fund_per_point = fund_this_period / total_points
creator_payout = points(creator) × fund_per_point
```

Every shilling TAJIRI commits to the fund reaches some creator. There
is no platform leakage *inside* the fund — the entire fund is
distributed. In Phase 1, TAJIRI's "take" on this stream is *negative*
(treasury subsidizes creator supply). In Phase 2, the 70/30 split
happens *outside* the fund (TAJIRI keeps 30% of ad revenue at the
ad-revenue level, the remaining 70% funds the pool, and the pool is
then fully distributed).

#### How creators see this in real time

Creators see *estimated* per-event earnings in real time using the
current `fund_per_point` projection, marked clearly as estimates:

> "Estimated TZS 0.73 — final amount depends on this week's fund
> distribution, settles Sunday at midnight."

At settlement, estimates resolve to actuals, and the per-event
provenance ledger (§9) updates with the resolved amounts.

#### Why this beats TikTok Creator Fund's failure modes

| TikTok Creator Fund failure | TAJIRI Creators Fund response |
|---|---|
| Pool stayed flat at $200M while creators grew 10× → per-creator collapse | Phase 1 fund tied explicitly to creator-acquisition target (`creators × avg_payout`); reviewed monthly. Phase 2 fund scales with ad revenue (70 / 30 tie); floor preserved across phase transition |
| Per-view rate collapsed to $0.025 / 1k views | Multipliers reward quality; tier system rewards loyalty; floor `floor_tsh` protects everyone in both phases |
| Opaque rate card | Public rate card with `phase_1_committed_budget`, `floor_tsh`, ad rev-share %, and per-metric base rates published; 30-day notice on cuts |
| No tier differentiation | Mwanzo / Standard / Verified / Partner with explicit tier-boost multipliers |
| Sudden cuts without consultation | 30-day rate-change notice; quarterly transparency reports |
| Backed by ad revenue alone (single point of failure) | Phase 1: treasury-funded as CAC. Phase 2: hybrid (70 % of ads + 10 % of pass-through takes + treasury bridge) |

#### Fund replenishment cycle (default: weekly)

```
[Monday 00:00 UTC+3]
1. Close prior period.
2. Compute fund_this_period using the active phase's formula:
     - Phase 1: fund = phase_1_committed_budget
     - Phase 2: fund = MAX(floor, 0.70 × ad_revenue
                                + 0.10 × pass_through_takes
                                + treasury_topup)
3. Move fund_this_period from "TAJIRI Operating Cash" to
   "Creators Fund — Pending Distribution" liability account.
4. Aggregate `earning_events` points across all eligible creators.
5. Compute fund_per_point.
6. For each creator, write an `earning_events` row resolving the
   period into a single "Period Settlement" event with the actual
   TZS amount, and post a journal_lines entry from
   "Creators Fund — Pending Distribution" → "Pending Creator
   Earnings — Engagement" (the existing 30-day pending bucket
   from §5).
7. Reset point counters; start new period.
```

The 30-day pending → cleared sweep (§5) still applies on top of this:
period settlements land in the pending bucket, and clear after the
30-day fraud window.

### 1.3 Phase 1 → Phase 2 transition criteria

Phase 2 is unlocked when **all** of the following hold:

- Monthly ad revenue ≥ TZS 200 000 000 sustained for 3 consecutive
  calendar months
- ≥ 50 active paying advertisers (each spending ≥ TZS 1 000 000 / month)
- Board approval of the transition
- 30-day public notice posted on the rate card and emailed to every
  active creator with a current-vs-projected per-creator earnings
  comparison

Until **all four** are true, Phase 1 stays active. The transition is
intentionally gated and well-telegraphed — creators learn about the
new model 30 days before it takes effect, with clear before / after
numbers.

**Why these specific thresholds:**

- TZS 200M / month ad revenue + 50 advertisers indicates a real
  advertiser market, not one-off deals. At 70 / 30 this funds a TZS
  140M monthly creator pool — comparable to the Phase 1 commitment.
- 3-month sustained requirement guards against a one-month spike
  triggering the switch.
- 30-day notice is the standard rate-change protection (§11.4) — the
  Phase transition is a rate change of significant magnitude.

**Floor preservation across transition.** The `floor_tsh` value at
Phase 1 end carries forward to Phase 2 unchanged. Creators do not
experience an income drop during the transition — only an income
upside if ad revenue exceeds the floor.

**Reversibility.** Phase 2 → Phase 1 reversion is allowed but
requires the same notice period (30 days). Used only if advertiser
demand collapses; the floor would already protect creators in this
scenario, so reversion is an accounting cleanup more than a
creator-impact event.

---

## 2. Engagement attribution model (B + C)

Streams 1 and parts of 5 above use the **B + C attribution model**:
content contributors earn alongside the post author, and sharers earn
discovery credits. The tables below are the canonical attribution
rules.

### 2.1 Earnable engagement events (consume content → credit creators)

| Event | Direct earner | Secondary earners |
|---|---|---|
| View / impression | post author | sharer (if came in via a share) |
| Watch-second (video) | post author | sharer |
| Reaction (any of 6: 👍 ❤️ 😂 😮 😢 😠) | post author | sharer |
| Comment | post author | sharer |
| Reply on comment | post author + comment author | sharer |
| Reply on reply | post author + comment author + reply author | sharer |
| Share | post author | sharer (gets "share initiation" credit) |
| Save / bookmark | post author | sharer |
| Reaction on a comment | comment author + post author (host share) | — |
| Reaction on a reply | reply author + comment author (parent share) + post author (host share) | — |
| Follow that originated from a post | post author (discovery credit) | — |
| Subscribe that originated from a post | post author (discovery credit) | — |

### 2.2 Earnable derivative-content events (new Post created *from* another)

| Event | Direct earner | Secondary earners |
|---|---|---|
| Reply post (`reply_to_post_id`) | reply-post author (gets normal post earnings on their reply) | original post author (sample / "inspiration" royalty on the reply post's earnings — like Spotify samples) |
| Stitch (`stitch_from_post_id`) | stitch author | original video author (clip royalty) |
| Quote post | quote author | original post author |
| Battle thread invite | both streamers | — |

### 2.3 Non-earning (recorded for completeness, no `journal_lines`)

Hide • Report (post/comment) • Block/Unblock • Mute • Mention (the
mentioned user doesn't earn from being named — they earn if they then
get followed/subscribed/etc.).

### 2.4 Reaction-rate model — flat ✅

All six reaction types pay at a single `reaction` rate. Tiering would
push creators to harvest ❤️/👍 reactions and avoid 😢/😠, biasing
content. Revisit only if data shows a meaningful signal-to-revenue
delta worth the gameability cost.

---

## 3. Multipliers — quality over volume

Raw engagement counts are noisy. To stop the engagement-bait race to
the bottom (TikTok's content-quality crisis), every chargeable event
gets multiplied by a **quality factor** before crediting.

### 3.1 Watch-completion multiplier (videos only)

| Average view duration | Multiplier |
|---|---|
| < 25 % completion | **0.5×** |
| 25 – 49 % | 1.0× (baseline) |
| 50 – 69 % | 1.5× |
| 70 – 89 % | **2.0×** |
| ≥ 90 % completion | **2.5×** |

Applied to the per-second watch credit and to per-view credits on
videos. Caps at 2.5× to prevent integer overflow / runaway credits.

### 3.2 Mwanzo Boost (new-creator on-ramp) — **first 30 days**

For every creator's first 30 days post-account-creation:

- **2× RPM multiplier** on engagement-pool credits
- **Guaranteed 1 000 first impressions** per original post (algorithmic floor)
- Tier-up eligibility waived (everyone starts as Standard, even before
  meeting Standard gates)

Solves cold-start. TikTok's "fyp gift to new accounts" is the de-facto
killer feature; we make it explicit and time-bounded.

### 3.3 Originality multiplier

| Content type | Multiplier |
|---|---|
| Original post (no `reply_to_post_id` / `stitch_from_post_id` / `quote_from_post_id`) | **1.0×** |
| Stitch / quote / reply post — substantial new content (>50% new bytes) | 0.7× |
| Stitch / quote / reply post — minimal new content | 0.4× |
| Reused / re-uploaded / template-only / pure-AI-voiceover (detected) | **0× (demonetized)** |

The 0× tier is YouTube's "Reused Content" policy translated to our
schema. Detection signals: identical thumbnails across many posts,
slideshow-only video, exclusive AI-voice content, suspiciously rapid
upload cadence with templated output.

### 3.4 Streak bonus (consistency reward)

Creators posting **≥ 5 days in any 7-day rolling window** get a
**+10 %** kicker on engagement-pool credits earned during that window.
Resets on a silent week. Snapchat-style retention loop.

### 3.5 Discovery Mode opt-in (Spotify-style trade)

Creators may opt a specific post into **Discovery Mode** for 30 days:

- Algorithmic-distribution boost (post weighted +50 % in the discover
  ranker)
- Creator's engagement-pool credit reduced **–30 %** during the boost
  window
- Surfaces real-time uplift metrics (`additional impressions credited
  to Discovery Mode`)

Spotify's Discovery Mode reportedly drives +50 % saves and +44 %
playlist adds in the first month. Replicate the trade — creators with
saturated audiences pay TAJIRI distribution by trading royalty share,
not cash.

---

## 4. Creator tier program (Mwanzo / Standard / Verified / Partner)

Tiers gate access to higher-margin streams. They never gate the
**core engagement pool** (everyone earns from view 1, day 1). They
gate the streams that need fan trust or platform investment.

| Tier | Gate | Engagement Pool | Fan-Funding | Marketplace | Brand-Deal Marketplace | Live Gifts | Discovery Mode |
|---|---|---|---|---|---|---|---|
| **Mwanzo** (new) | Day 0 | ✅ 70 / 30 + 2× boost | ✅ 95 / 5 | ✅ 0 % first 90 days | ❌ | ❌ | ❌ |
| **Standard** | 100 followers + 30 days active + clean strikes | ✅ 70 / 30 | ✅ 95 / 5 | ✅ 100 % / 95 % | ❌ | ✅ 90 / 10 | ✅ |
| **Verified** | 1 000 followers + 50 000 views/30d + ID verified + no strikes/90d | ✅ 70 / 30 | ✅ 95 / 5 | ✅ 100 % / 95 % | ✅ 90 / 10 | ✅ 90 / 10 | ✅ |
| **Partner** | 10 000 followers + 500 000 views/30d + 90 days as Verified + manual review | ✅ **75 / 25** (+5 pts) | ✅ 95 / 5 | ✅ 95 % flat | ✅ **92.5 / 7.5** | ✅ **92.5 / 7.5** | ✅ |

**Why this beats YouTube/TikTok eligibility gates:**

- YouTube needs 1 000 subs + 4 000 watch hours before *any* monetization
- TikTok Creator Rewards needs 10 000 followers + 100 000 views/30d
- TAJIRI **monetizes from day 0** — Mwanzo tier pays full engagement +
  fan-funding + marketplace from the first post

The higher tiers aren't gates to *start* earning; they're gates to
*premium* streams that need real fan trust or platform underwriting
(brand deals, top-of-pool engagement uplift).

---

## 5. Settlement model — pending → cleared (30-day window) ✅

Every chargeable event posts to COA / `journal_lines` immediately into a
*Pending Creator Earnings* liability account. A daily job sweeps events
older than 30 days from pending → *Cleared Creator Earnings (Payable)*.
Fraud detected inside the window → reverse the pending entry only.

**Why this over real-time-cleared or nightly-batch:**

- Auditable from t = 0 — every cent has a `journal_lines` row from the
  moment the event fires (project rule).
- Fraud-reversible — 30-day window absorbs sock-puppet/view-inflation
  reversals without rewriting cleared books.
- Industry-standard creator UX — "pending" vs "available" matches
  YouTube AdSense, Patreon, Stripe Connect. Creators understand it
  without explanation.

The window is tunable: chargebacks against a fan transaction (subs,
tips, marketplace) can extend the pending window for *that*
transaction's earnings to **45 days** to cover the chargeback dispute
period.

### 5.1 Settlement events on the COA

```
[Weekly] Fund replenishment (TAJIRI commits the period's fund)
  Dr. TAJIRI Operating Cash                         50 000 000
    Cr. Creators Fund — Pending Distribution        50 000 000

[Weekly] Period distribution (after points aggregation)
  Dr. Creators Fund — Pending Distribution          50 000 000
    Cr. Pending Creator Earnings — engagement       50 000 000
       (split per creator by their share of points)

[Real-time] Direct fan-funding tip (fan tips 1 000 TSh)
  Dr. Tajiri Pay Receivable                          1 000.00
    Cr. Pending Creator Earnings — fan-funding         950.00  (creator)
    Cr. Platform Revenue (Fan-Funding Take)             50.00  (platform — feeds back into Creators Fund formula)

[Daily] Sweep (events ≥30 days old)
  Dr. Pending Creator Earnings (engagement | fan-funding | …)  X
    Cr. Cleared Creator Earnings (Payable)                     X

[Daily] Tax withholding (TZ residents, Section 83B 5 %)
  Dr. Cleared Creator Earnings (Payable)            X
    Cr. TRA WHT Payable                          0.05·X
    Cr. Tajiri Pay Wallet (creator)              0.95·X
```

The crucial difference from the prior model: **engagement credits no
longer derive from a per-event rev-share against platform ad
revenue**. The fund is committed up-front each period, and the
distribution journal entries land at period close with the resolved
per-creator amounts. Real-time per-event entries before period close
are *estimates* tracked outside COA in `earning_events.gross_credit`;
they only hit `journal_lines` at period settlement.

---

## 6. Tajiri Pay-native payout rails

This is our biggest unfair advantage. We own the rail, so:

### 6.1 Default payout: **same-day to mobile money**

Cleared earnings auto-disburse to the creator's chosen mobile money
wallet (M-Pesa / Airtel Money / Tigo Pesa / MTN MoMo) **same day**, no
manual cashout step. Creators can opt into a weekly batch instead if
they prefer fewer transactions.

### 6.2 Minimum payout threshold: **TZS 5 000 (~$2)**

Compare:
- YouTube: $100
- Twitch: $50–100
- OnlyFans: $20
- Snapchat: $100/day cap *up*

A $2 floor is meaningful in TZ; it lets micro-creators reach payout in
a week, not a year.

### 6.3 In-network fees: **0 % under TZS 50 000 / month**

First TZS 50k of monthly payouts to mobile money is **fee-free**.
Above the threshold, mobile-money operator's standard rate passes
through (typically 1–3 %).

### 6.4 Cross-border / non-TZ creators

Wise integration for TZS → USD/EUR/KES bank settlement. Stripe Connect
where supported (KE/NG/ZA — not yet TZ as of 2026). Cross-border
disclosed-FX with 0.5 % spread (vs PayPal's 3–6 %).

---

## 7. Tax compliance — built-in, automatic

### 7.1 Tanzania residents

- **Section 83B WHT — 5 %** on payments to resident digital content
  creators auto-deducted at clear-time and remitted to TRA monthly.
- **18 % VAT on electronic services** — TAJIRI is the registered
  taxpayer; creator never sees a VAT line on engagement-pool credits
  (we account for it on platform side).
- **2 % Digital Service Tax** on gross consumer payments — folded
  into platform-take, never charged to creator.
- Auto-issued **digital tax invoice** on every payout (TRA-format
  PDF in-app, downloadable).

### 7.2 Non-resident creators

- W-8BEN-equivalent self-attestation on signup (international form).
- Withholding rate per double-tax-treaty if applicable (e.g., 0 % to
  Kenyan residents under the EAC treaty, 10 % default for non-treaty
  countries).

### 7.3 Creator tax dashboard

Year-to-date earnings, withholding history, per-month breakdown
exportable as CSV / TRA-format PDF for self-employed creators filing
quarterly. **No competing platform makes its African creators
TRA-compliant by default**; we do.

---

## 8. Anti-abuse rules — v1

All rules act *at event-write*. The event row is still recorded for
audit; just with `is_chargeable = false`. This means anti-abuse changes
never require ledger rewrites.

| Rule | v1 implementation |
|---|---|
| Self-action exclusion | Post author engaging with own content earns 0. Enforced at event-write. |
| Per-viewer view dedupe | 1 chargeable view per `(viewer, post)` per 1 hour for video; 1 per session for non-video. |
| Watch-second cap | Watch-time credited to a max of `1.0 × video_duration` per `(viewer, post, day)` — prevents loop-farming. |
| Reaction churn cap | Repeated react/unreact/react on the same target earns only the first credit per `(actor, target, day)`. |
| Daily per-actor-per-creator cap | Max 50 chargeable engagements from any one actor on any one creator's posts per day. |
| Reused-content demonetization | 0× originality multiplier on detected reused/template/AI-voiceover content (see §3.3). |
| Sock-puppet detection | **v2** — IP/ASN clustering, device-fingerprint deduplication, account-creation-velocity scoring. Out of scope for v1. |
| Engagement-ring detection | **v2** — graph-anomaly detection on like/follow networks. |
| Inactivity rule | After 90 days no posting + no logins, monetization paused (matches YouTube). Creator gets re-activation flow. |

---

## 9. Real-time per-event provenance ledger — our trust moat

**No major platform shows creators "this exact view earned you X
shillings from advertiser Y."** This is free engineering for us and a
material trust upgrade.

Every `earning_events` row carries the full provenance:

```json
{
  "event_id": "evt_01HXYZ…",
  "occurred_at": "2026-05-03T14:33:21Z",
  "post_id": 1234,
  "actor_user_id": 555,        // who did the thing (e.g. the viewer)
  "target_user_id": 42,        // who got credited (e.g. post author)
  "actor_role": "author",      // author | comment_author | sharer | etc.
  "metric": "view",
  "raw_count": 1,
  "applied_multipliers": {
    "watch_completion": 2.0,
    "originality": 1.0,
    "mwanzo_boost": null,
    "streak": 1.10
  },
  "rate_tsh_per_unit": 0.50,
  "gross_credit_tsh": 1.10,
  "platform_take_tsh": 0.33,
  "tra_wht_held_tsh": 0.0385,
  "net_to_creator_tsh": 0.7315,
  "funding_source": "ad_impression_id:imp_…  advertiser:bvm_002",
  "is_chargeable": true,
  "settlement_window_days": 30
}
```

**Surfaced to the creator** as a scrollable per-post earnings ledger:

> _"You earned **TZS 0.73** at 2:33 PM from a view by @userX. **TZS
> 0.50** base × **2.0×** watch-completion (96 % AVD) × **1.10×**
> streak bonus = **TZS 1.10** gross. Funded by ad impression from
> advertiser BVM Insurance. **TZS 0.33** to platform, **TZS 0.04** to
> TRA. Pending until 2026-06-02."_

Every line item from rate to remit is visible. Creator sees exactly why
they earned what they earned. Disputes drop. Trust compounds.

---

## 10. Financial sustainability rails

### 10.1 Fund commitment is the spend ceiling

Engagement-pool spend is structurally capped at the period's Creators
Fund commitment (§1.2). TAJIRI knows the maximum weekly creator
expense exactly, and the distribution algorithm (`fund_per_point ×
points(creator)`) guarantees the fund is fully but not
over-distributed.

This eliminates two simultaneous failure modes:

- **TikTok Creator Fund insolvency** — pool under-funded relative
  to creator growth. We tie Phase 1 fund size to a creator-acquisition
  target (`creators × avg_payout`), reviewed monthly so the fund
  scales with supply. Phase 2 ties to ad revenue so the fund scales
  with demand.
- **YouTube AdSense volatility** — ad-market dips translate directly
  into creator-income drops. We preserve a `floor_tsh` across both
  phases that the fund never falls below.

#### Phase 1: fund commitment is creator-acquisition expense (CAC)

Phase 1 fund commitment is treasury-funded and booked to the COA as
a customer-acquisition expense, not a rev-share liability. The
creator-acquisition logic:

```
phase_1_committed_budget = target_active_creators × avg_payout_per_creator
                         = 5 000 × TZS 10 000 / week
                         = TZS 50 000 000 / week
                         = TZS 2.6B / year (capex-equivalent)
```

The expected ROI: each TZS spent attracts and retains creators who in
turn attract audience that in turn attracts advertisers — closing the
loop to Phase 2. Standard CAC ROI math applies.

```
phase 1 weekly fund job:
  fund      = phase_1_committed_budget   // TZS 50M default
  points    = SUM(points across all eligible creators this period)
  fppoint   = fund / points
  for creator in eligible_creators:
    payout = points(creator) * fppoint
    write_journal_line('Creators Fund — Pending Distribution',
                       'Pending Creator Earnings — engagement', payout)
```

#### Phase 2: fund commitment is rev-share liability

Once the Phase 2 transition criteria (§1.3) are met, the fund formula
switches to ad rev-share at 70 / 30 with the floor preserved:

```
phase 2 weekly fund job:
  fund = MAX(floor_tsh,
             0.70 * ad_revenue_this_period
             + 0.10 * pass_through_takes_this_period
             + treasury_topup_this_period)
  // ... same distribution logic as Phase 1
```

Phase 2 fund expense is booked as a rev-share liability (operating
cost of the engagement stream), not as CAC.

#### Pass-through streams (2–6)

The pass-through streams settle in real time per transaction and
don't share the fund dynamic — each transaction is its own
pass-through, naturally balanced by construction.

### 10.2 Reserve fund — backstop for the floor

5 % of platform-side revenue (across all pass-through streams +
ad revenue once Phase 2) accrues to a **Creator Earnings Reserve
Fund** liability. Drawn down to:

- **Phase 2:** top up the Creators Fund to the `floor_tsh` amount when
  `0.70 × ad_revenue + 0.10 × pass_through_takes < floor_tsh`
- **Both phases:** absorb 30-day fraud reversals on already-settled
  events
- **Both phases:** subsidize Mwanzo Boost period (when new creators
  briefly earn more than the rest of the platform's revenue justifies)

In Phase 1, treasury directly funds the Creators Fund commitment, so
the reserve serves only the latter two purposes. In Phase 2, the
reserve becomes the buffer that lets us promise creators a stable
floor irrespective of week-to-week ad volatility.

Functions like Stripe's reserve mechanism for new merchants. The
reserve balance is published in the quarterly transparency report
(§11.2).

### 10.3 Per-event rate caps

Hard caps prevent any single event from outsized credit:

- View: max TZS 5 / view (after multipliers)
- Like / reaction: max TZS 50 / event
- Comment: max TZS 100 / event
- Share: max TZS 200 / event
- Watch-second: max TZS 1 / second × 2.5× completion multiplier = TZS 2.5 / second
- Subscription: 95 % of subscription price, no separate cap
- Tip / gift: 95 % of tip amount, no separate cap
- Marketplace sale: per-stream split, no separate cap (capped by item price)

### 10.4 Daily per-creator soft ceiling

Single-creator daily earnings from engagement pool are soft-capped at
**TZS 500 000 (~$200)**. Above the cap, the creator's events still
write to the ledger but receive a `is_chargeable=false` flag for that
day. This protects the pool from a single viral hit draining 50 %+ of
nightly ad revenue. Soft-cap is informational — ceiling reviewed and
likely raised at quarterly transparency report time.

### 10.5 Public rate card

`/creators/rate-card` (in-app + on tajiri.zimasystems.com) lists every
metric, rate, and cap, with last-updated timestamps. **Rates only ever
change with 30-day public notice**. This is a hard commitment — it's
what TikTok and Instagram both violated to creator outrage.

---

## 11. Disclosure & trust

### 11.1 Per-event provenance ledger

§9 above. Every credit line item exposed to the earning creator.

### 11.2 Quarterly Creator Transparency Report

Published on tajiri.zimasystems.com on the 15th of each quarter:

- Total creator payouts (TZS) by stream
- Top-earner anonymized bands (Top 1 %, 1–10 %, 10–50 %, 50–100 %)
- Avg / median / p10 / p90 RPM by content niche and region
- Median time from event to payout
- Dispute resolution rate (filed, resolved, reversed)
- Ad pool size + utilization
- Reserve fund balance + outflows

Nothing else in the African creator economy publishes this. Trust
compounds.

### 11.3 Dispute resolution

Per-event disputes filed in-app:

- Resolution SLA: **5 business days** for engagement-pool disputes,
  **48 hours** for fan-funding disputes (subs/tips/gifts)
- Two-tier escalation: AI-pre-screen → human review
- Public stats fed into the quarterly transparency report

### 11.4 Rate-change notice

Any rate cut requires **30-day advance notice** in-app and on the
public rate card. Rate increases ship same-day. This is a one-way
ratchet of trust.

---

## 12. Implementation surface

### 12.1 New schemas

```sql
-- Immutable event log keyed for idempotency.
create table earning_events (
  id              bigserial primary key,
  event_uid       text unique not null, -- deterministic dedupe key
  occurred_at     timestamptz not null default now(),
  post_id         bigint references posts(id),
  comment_id      bigint references comments(id),
  source_type     text not null, -- 'post' | 'comment' | 'reply' | 'live_stream' | 'marketplace_order' | …
  source_id       bigint not null,
  actor_user_id   bigint references users(id),     -- who did the thing
  target_user_id  bigint references users(id),     -- who gets credited
  actor_role      text not null,                   -- 'author' | 'comment_author' | 'reply_author' | 'host' | 'parent_thread' | 'sharer' | 'original_creator_royalty' | 'fan_buyer' | …
  stream          text not null,                   -- 'engagement' | 'fan_funding' | 'marketplace' | 'brand_deal' | 'live_gifts' | 'affiliate'
  metric          text not null,                   -- 'view' | 'reaction' | 'comment' | 'watch_second' | 'subscribe' | …
  raw_count       int  not null default 1,
  rate_tsh        numeric(12,4) not null,
  multipliers     jsonb not null,                  -- {"watch_completion":2.0,"originality":1.0,…}
  gross_credit    numeric(12,2) not null,
  platform_take   numeric(12,2) not null,
  tra_wht_held    numeric(12,2) not null default 0,
  net_to_creator  numeric(12,2) not null,
  is_chargeable   boolean not null default true,   -- false = abuse-rejected; recorded for audit
  charge_reason   text,                            -- when is_chargeable=false, why
  funding_source  text,                            -- ad_impression_id, sponsor_id, fan_user_id, etc.
  settlement_status text not null default 'pending', -- pending | cleared | reversed
  cleared_at      timestamptz,
  reversed_at     timestamptz,
  reversal_reason text,
  journal_line_pending_id bigint references journal_lines(id),
  journal_line_cleared_id bigint references journal_lines(id),
  journal_line_reversal_id bigint references journal_lines(id)
);

create index on earning_events (target_user_id, settlement_status, occurred_at);
create index on earning_events (post_id, occurred_at);
create index on earning_events (occurred_at) where settlement_status = 'pending';

-- Per-(metric, actor_role, stream) rates with effective windows.
alter table creator_earnings_rates
  add column actor_role text not null default 'author',
  add column stream     text not null default 'engagement',
  add column effective_from timestamptz not null default now(),
  add column effective_until timestamptz,
  add column tier_minimum text;     -- 'mwanzo' | 'standard' | 'verified' | 'partner'

-- Creator tier tracking.
create table creator_tiers (
  user_id     bigint primary key references users(id),
  tier        text not null default 'mwanzo',
  promoted_at timestamptz not null default now(),
  next_review_at timestamptz,
  strike_count int not null default 0
);

-- Reserve fund balance.
create table earnings_reserve_ledger (
  id bigserial primary key,
  occurred_at timestamptz not null default now(),
  delta_tsh numeric(14,2) not null,  -- + accrual / – drawdown
  reason text not null,
  journal_line_id bigint references journal_lines(id)
);

-- Creators Fund period — one row per settlement period.
create table creators_fund_periods (
  id              bigserial primary key,
  period_start    timestamptz not null,
  period_end      timestamptz not null,
  status          text not null default 'open',  -- open | distributing | settled | reversed
  phase           text not null,                 -- 'phase_1' | 'phase_2'
  -- Phase 1 inputs
  phase_1_committed_budget_tsh numeric(14,2),
  -- Phase 2 inputs
  ad_revenue_tsh               numeric(14,2),
  fan_funding_take_tsh         numeric(14,2),
  marketplace_take_tsh         numeric(14,2),
  brand_deal_take_tsh          numeric(14,2),
  live_gifts_take_tsh          numeric(14,2),
  ad_share_pct                 numeric(5,4),     -- 0.70 in Phase 2; null in Phase 1
  pass_through_share_pct       numeric(5,4),     -- 0.10 in Phase 2; null in Phase 1
  treasury_topup_tsh           numeric(14,2),
  -- Computed
  floor_tsh           numeric(14,2) not null,
  fund_size_tsh       numeric(14,2) not null,
  reserve_topup_tsh   numeric(14,2) default 0,   -- drawn from reserve to hit floor
  -- Distribution
  total_points        numeric(20,4),
  fund_per_point      numeric(20,8),
  eligible_creator_count int,
  settled_at          timestamptz,
  settlement_journal_batch_id bigint,            -- groups all journal_lines for this period
  unique (period_start, period_end)
);

-- Per-creator points accumulator within the active period.
create table creators_fund_points (
  id              bigserial primary key,
  period_id       bigint not null references creators_fund_periods(id),
  user_id         bigint not null references users(id),
  points          numeric(20,4) not null default 0,
  events_count    int not null default 0,
  last_event_at   timestamptz,
  payout_tsh      numeric(14,2),  -- null until period settled
  unique (period_id, user_id)
);

create index on creators_fund_points (period_id, points desc);
```

### 12.2 New COA accounts

| Code | Name | Type |
|---|---|---|
| 2105 | Creators Fund — Pending Distribution | Liability |
| 2110 | Pending Creator Earnings — Engagement | Liability |
| 2111 | Pending Creator Earnings — Fan-Funding | Liability |
| 2112 | Pending Creator Earnings — Marketplace | Liability |
| 2113 | Pending Creator Earnings — Brand-Deal | Liability |
| 2114 | Pending Creator Earnings — Live-Gifts | Liability |
| 2120 | Cleared Creator Earnings (Payable) | Liability |
| 2130 | Creator Earnings Reserve Fund | Liability |
| 2140 | TRA WHT Payable | Liability |
| 4120 | Platform Revenue — Fan-Funding Take | Revenue |
| 4130 | Platform Revenue — Marketplace Take | Revenue |
| 4140 | Platform Revenue — Brand-Deal Take | Revenue |
| 4150 | Platform Revenue — Live-Gifts Take | Revenue |
| 5110 | Creators Fund Outflow — Phase 1 CAC | Expense — Phase 1 creator-acquisition spend |
| 5111 | Creators Fund Outflow — Phase 2 Rev-Share | Expense — Phase 2 ad rev-share to creators |

Note on engagement-stream economics:

- **Phase 1**: there is no "Platform Revenue — Engagement Take"
  because TAJIRI has no advertiser revenue to share. Account 5110
  captures the treasury-funded creator-acquisition spend.
- **Phase 2**: ad revenue is recorded to a new revenue account
  (e.g. `4115 — Ad Revenue`), 70 % of which flows out via account
  5111 to creators; the residual 30 % stays in revenue. There is no
  separate "Engagement Take" account — the take is implicit in the
  70 / 30 split on ad-revenue posting.

The phase column on `creators_fund_periods` (see §12.1) determines
which expense account a given period's settlement entries hit.

### 12.3 Event hooks at existing endpoints

Wired to fire `EarningsEngine::recordEvent(...)` from:

- `POST /posts/{id}/view`
- `POST /posts/{id}/like` and `DELETE` for unlike
- `POST /posts/{id}/save` / `DELETE`
- `POST /posts/{id}/share`
- `POST /posts/{id}/comments` (and the reply variant via `parent_id`)
- `POST /comments/{id}/like` / `DELETE`
- `POST /posts/` with `reply_to_post_id` / `stitch_from_post_id` /
  `quote_from_post_id` (derivative content)
- `POST /follows` / `POST /subscriptions` (origin-attributed when the
  origin is a post URL)
- `POST /streams/{id}/gifts` / `super-chats` / `reaction`
- `POST /streams/{id}/battles/invite`
- `POST /marketplace/orders` (post-attached storefront check-out)

### 12.4 New endpoints

| Method + path | Purpose |
|---|---|
| `GET /api/posts/{id}/earnings` | Aggregated per-post earnings (rewritten to read `earning_events`, not raw counters) |
| `GET /api/posts/{id}/earnings/events` | Per-event ledger for the post owner — paginated, sortable |
| `GET /api/users/me/earnings` | Cross-stream creator earnings dashboard with pending vs cleared split, per-stream breakdown |
| `GET /api/users/me/earnings/events` | All events crediting the calling user, paginated |
| `GET /api/users/me/earnings/tax` | YTD WHT + per-month breakdown, exportable as CSV/PDF |
| `GET /api/creators/rate-card` | Public rate card |
| `POST /api/users/me/earnings/disputes` | File a dispute on a specific event |
| `POST /api/posts/{id}/discovery-mode` | Opt-in to Discovery Mode for 30 days |

### 12.5 Background jobs

- **`CreatorsFundPeriodSettlementJob`** — weekly (Monday 00:00
  UTC+3); closes prior period, computes fund size, aggregates points,
  computes `fund_per_point`, distributes to creators by writing
  per-creator settlement events and journal lines. Drives the
  Creators Fund cycle.
- **`SettlementSweepJob`** — daily; sweeps pending events ≥30 days
  old to cleared (or 45 days for fan-funding events to absorb
  chargebacks).
- **`AbuseScanJob`** — hourly; flags events for retro-`is_chargeable=false`
  if anti-abuse rules detected post-write.
- **`MwanzoExpiryJob`** — daily; transitions Mwanzo → Standard at
  day 31 if base gates met, else stays Mwanzo until met.
- **`TierReviewJob`** — daily; promotes creators meeting the next
  tier's gates.
- **`PayoutDisbursementJob`** — daily; disburses cleared earnings
  ≥ TZS 5 000 to the creator's mobile money wallet.
- **`TRARemittanceJob`** — monthly; remits accumulated WHT to TRA via
  their digital portal.

---

## 13. Roadmap

### v1 — "Creators Fund (Phase 1) + payouts" (target: 6 weeks)

Ships in **Phase 1 mode**. No advertiser revenue assumed. Creators
paid from the treasury-funded Phase 1 committed budget.

- Schemas (`earning_events`, extended `creator_earnings_rates`,
  `creator_tiers`, `creators_fund_periods`, `creators_fund_points`) —
  with `phase` column on `creators_fund_periods` set to `phase_1`
- COA accounts created (incl. account 5110 — Phase 1 CAC expense)
- Initial fund parameters published on rate card:
  `phase_1_committed_budget = TZS 50 000 000 / week`, `floor_tsh`,
  per-metric base rates
- Event hooks on the 12 most-trafficked engagement endpoints (views,
  reactions, comments, replies, shares, saves, watch-time, follows
  triggered from posts) — writes points to active fund period
- Weekly `CreatorsFundPeriodSettlementJob` running in Phase 1 mode
- Pending → cleared `SettlementSweepJob`
- Rewritten `GET /posts/{id}/earnings` reading from event ledger
  (showing both real-time estimates and last-settled actuals)
- New `GET /users/me/earnings` cross-stream dashboard
- Mwanzo tier active from day 0; Standard / Verified / Partner gates
  in place but no Partner-specific stream features yet (i.e. brand
  deals deferred)
- Per-event provenance ledger surfaced to creators (estimated → final
  amount on settlement)
- TZS 5 000 minimum payout via Tajiri Pay → M-Pesa
- Watch-completion + originality multipliers
- v1 anti-abuse ruleset

### v2 — "Tier features + trust" (target: +4 weeks)

Still in **Phase 1 mode**. No advertiser dependency.

- Brand-deal facilitation marketplace (Verified+)
- Discovery Mode (Spotify-style trade)
- Mwitiko collective tipping events on LIVE streams
- Quarterly transparency report machinery (auto-generates from
  event ledger) — first transparency report makes Phase 1 spend and
  creator payouts public
- Sock-puppet detection v1
- Streak bonuses
- Public rate card UI
- Dispute resolution flow

### v3 — "Optimization + cross-border" (target: +6 weeks)

Still **Phase 1 mode** unless transition criteria met.

- Engagement-ring graph detection
- Wise / Stripe Connect cross-border payouts for non-TZ creators
- Multi-currency display for cross-border earners
- Creator tax dashboard (YTD WHT, per-month breakdown, CSV/PDF)
- Originality detection v2 (perceptual hashes, AI-voice classifier)
- A/B framework for rate experiments (every change gates on creator
  cohort comparisons)

### v4 — Phase 2 transition (timing: when transition criteria met)

Triggered when monthly ad revenue ≥ TZS 200M sustained 3 months,
≥ 50 active advertisers, and board approval (§1.3). Likely 12–18
months after v1 ship if creator + audience growth tracks plan.

- Ad-revenue accounting: new revenue account `4115 — Ad Revenue`,
  expense account `5111 — Creators Fund Outflow — Phase 2 Rev-Share`
- `CreatorsFundPeriodSettlementJob` switches to Phase 2 formula:
  `MAX(floor_tsh, 0.70 × ad_rev + 0.10 × pass_through_takes + treasury_topup)`
- 30-day public notice posted on rate card with current vs projected
  per-creator earnings comparison
- Email to every active creator with personalized projection
- Reserve-fund top-up logic activated (covers gap when ad revenue
  drops below the level needed to fund the floor)
- `floor_tsh` value carried forward unchanged from Phase 1
- First post-transition transparency report includes a side-by-side
  Phase 1 vs Phase 2 retrospective

---

## 14. Open follow-ups

- **Backfill policy**: do we credit historical engagement when v1
  ships, or only forward from cutover? **Recommend forward-only** —
  backfill is an audit nightmare and creators expect the new
  numbers to start "now."
- **Discovery Mode pricing tuning**: the 30 % royalty trade is a
  starting point; A/B against 20 % and 40 % during v2.
- **Soft-cap level** (TZS 500k/day per creator from engagement pool)
  reviewed quarterly with transparency-report data.
- **TikTok-Africa expansion risk**: when TikTok Creator Rewards ships
  in TZ (likely 2026–27), our 9× advantage compresses unless we keep
  shipping. Track via the quarterly report.
- **Cross-platform cross-promotion**: should we credit posts that
  drove off-platform traffic? (Out of scope; flagged for v3.)

---

## 15. Why this is "9× better"

| Dimension | Best competitor | TAJIRI v1 |
|---|---|---|
| Engagement payout source | TikTok / IG Creator Funds (fixed pool that died); YouTube Shorts (45 % rev-share, ad-volatile) | **Phase 1: TAJIRI-funded Creators Fund as creator-acquisition spend (TZS 50M / week from treasury). Phase 2: 70/30 ad rev-share with floor preserved. Two-phase architecture publicly committed.** |
| Engagement RPM (TZ creator, video) | TikTok Creator Rewards $0.40–1 / 1k qualified views (**not even available in TZ**) | Phase 1: estimated TZS 1k–5k / 1k qualified views (**$0.40–2 / 1k**), available day 1, plus tier and quality multipliers — paid from TAJIRI's treasury, not contingent on advertiser revenue |
| Direct fan-funding split | Kick 95/5 | **Match 95/5** |
| Marketplace fee | TikTok Shop 6 % | **0 % for 90 days, 5 % after** |
| Payout latency | YouTube monthly + 30-day hold | **Same-day to mobile money** after 30-day pending |
| Min payout | YouTube $100, OnlyFans $20 | **TZS 5k (~$2)** |
| Mobile money native | none | **M-Pesa / Airtel / Tigo / MTN MoMo native** |
| Per-event provenance | none | **Every credit fully traceable** |
| Tax compliance | none auto | **Section 83B WHT auto-deducted, digital tax invoice issued** |
| Eligibility gate | YouTube 1 000 subs + 4 000 watch hrs; TikTok 10 000 followers | **Day 0 monetization on Mwanzo tier** |
| New-creator boost | TikTok algorithmic (opaque) | **Mwanzo Boost: 2× RPM + 1 000 guaranteed impressions, 30 days, transparent** |
| Quality multiplier | YouTube AVD ranking (no pay multiplier) | **Watch-completion 2.5× cap, paid through** |
| Quarterly transparency | none | **Public quarterly report on tajiri.zimasystems.com** |
| Rate-change notice | TikTok Creator Fund cut overnight 2023 | **30-day advance notice, public rate card** |

Each row is one creator-experience improvement. Together they compose
the 9× promise. The financial sustainability rails (§10) make sure we
can keep that promise through ad-market cycles.
