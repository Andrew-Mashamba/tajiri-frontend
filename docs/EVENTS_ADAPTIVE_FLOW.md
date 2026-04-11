# TAJIRI Events — Adaptive Flow by Event Type

> The event creation and management flow changes dynamically based on the selected event type.
> Three universal systems (Kamati, Michango, Bajeti) toggle on/off per event type.
> Wedding flow is the most complete — the gold standard from `docs/EVENTS_WEDDING_GAP_ANALYSIS.md`.
> All other types derive from `docs/EVENTS_ALL_TYPES_GAP_ANALYSIS.md`.

---

## Master Flow Architecture

```
User taps "Create Event"
       │
       ▼
┌──────────────────────────┐
│  Step 0: SELECT TYPE     │ ← This choice determines the ENTIRE flow
│                          │
│  ● Harusi (Wedding)      │ → FULL FLOW (all 3 pillars + 15 features)
│  ● Msiba (Funeral)       │ → EMERGENCY FLOW (rapid setup)
│  ● Harambee (Fundraiser) │ → CONTRIBUTION-HEAVY FLOW
│  ● Sherehe (Party)       │ → SIMPLE FLOW (birthday, baby shower, etc.)
│  ● Mkutano (Conference)  │ → PROFESSIONAL FLOW
│  ● Tamasha (Concert)     │ → TICKETED FLOW
│  ● Ibada (Church/Mosque) │ → COMMUNITY FLOW
│  ● Michezo (Sports)      │ → TICKETED FLOW
│  ● Shule (School Event)  │ → COMMITTEE + CONTRIBUTION FLOW
│  ● AGM / SACCOS          │ → GOVERNANCE FLOW
│  ● Nyingine (Other)      │ → BASIC FLOW
│                          │
└──────────┬───────────────┘
           │
           ▼
   Flow adapts based on type
```

---

## Event Type → Feature Activation Map

When a user selects an event type, these systems activate:

| Event Type | Kamati (Committee) | Michango (Contributions) | Bajeti (Budget) | Tiketi (Ticketing) | Wageni (Guest Mgmt) | Zawadi (Gifts) | Linked Events | Emergency |
|---|---|---|---|---|---|---|---|---|
| **Harusi (Wedding)** | FULL (10 sub-committees) | FULL (categories, pledges, M-Pesa) | FULL (13 categories) | Optional | FULL (VIP/Family/Regular + cards) | Optional | YES (4-6 events) | No |
| **Msiba (Funeral)** | AUTO (3 roles) | FULL (urgent) | BASIC (6 categories) | No | BASIC | No | YES (3-day, 7-day, 40-day) | **YES** |
| **Harambee (Fundraiser)** | BASIC (3-5 roles) | FULL (goal, progress bar) | BASIC (4 categories) | No | BASIC | No | No | No |
| **Uchumba (Engagement)** | BASIC (family-based) | FULL (mahari tracking) | BASIC | No | FULL (family hierarchy) | YES | YES (→ Wedding) | No |
| **Birthday (Kuzaliwa)** | No | Optional (cash gifts) | Optional | Optional | BASIC (RSVP only) | YES (wishlist) | No | No |
| **Baby Shower** | No | YES (diaper fund) | Optional | No | BASIC | YES (registry) | No | No |
| **Graduation (Kuhitimu)** | No | Optional | Optional | No | BASIC (categories) | YES | No | No |
| **Send-off (Kuaga)** | Optional | YES (farewell gift) | Optional | No | BASIC | YES | No | No |
| **Reunion (Kukutana)** | YES (organizing team) | YES (reunion fund) | YES | No | YES (family directory) | No | No | No |
| **Retirement (Kustaafu)** | Optional | YES (gift fund) | Optional | No | BASIC | YES | No | No |
| **Housewarming** | No | Optional | No | No | BASIC | YES | No | No |
| **Church Event** | YES (ministry team) | YES (sadaka/offering) | YES | Optional | BASIC | No | No | No |
| **Mosque Event** | YES | YES (zakat/sadaka) | YES | No | BASIC | No | No | No |
| **Baptism (Ubatizo)** | No | No | No | No | BASIC | YES | No | No |
| **Conference (Mkutano)** | YES (organizing committee) | No | YES (8 categories) | YES (registration) | YES (VIP/Speaker/Regular) | No | YES (multi-day) | No |
| **Workshop (Mafunzo)** | No | No | YES | YES (registration) | BASIC | No | No | No |
| **Product Launch** | No | No | No | Optional | YES (media/VIP/public) | No | No | No |
| **Networking Event** | No | No | YES (tickets) | YES | BASIC | No | No | No |
| **AGM (Mkutano Mkuu)** | YES (board) | No | No | No | YES (member verification) | No | No | No |
| **Concert (Tamasha)** | Optional | No | YES | YES (VIP/VVIP/Regular) | No | No | No | No |
| **Festival (Tamasha)** | YES | No | YES | YES | No | No | YES (multi-day) | No |
| **Sports (Michezo)** | YES | No | YES | YES | No | No | No | No |
| **School Event** | YES (PTA) | YES (school fund) | YES | No | BASIC | No | No | No |
| **Political Rally** | YES | No | No | No | YES (categories) | No | No | No |
| **Village Meeting** | YES | No | No | No | BASIC | No | No | No |
| **SACCOS/VICOBA** | YES | YES (savings) | YES | No | YES (member registry) | No | No | No |
| **Trade Show (Maonyesho)** | YES | No | YES | YES (exhibitor/visitor) | YES | No | YES (multi-day) | No |

---

## Detailed Flows Per Event Type

### 1. HARUSI (Wedding) — Full Flow

> Source of truth: `docs/EVENTS_WEDDING_GAP_ANALYSIS.md`

This is the most complex flow. All 3 pillars are at maximum capacity.

```
CREATE FLOW (7 steps + 3 pillar setup):

Step 0: Select Type → "Harusi (Wedding)"
  ↓ Activates: Kamati FULL, Michango FULL, Bajeti FULL, Wageni FULL, Linked Events YES

Step 1: Basics
  - Jina la Harusi (Wedding title, e.g., "Harusi ya John na Amina")
  - Tarehe (Date)
  - Mahali (Venue)
  - Picha ya Jalada (Cover photo — couple's photo)
  - Aina: Harusi ya Kanisa / Nikah / Traditional / Civil

Step 2: Kamati ya Harusi (Wedding Committee)
  - Auto-creates committee template with 10 sub-committees:
    ┌─────────────────────────────────────────────┐
    │ KAMATI KUU (Main Committee)                 │
    │  Mwenyekiti: [Assign person]                │
    │  Katibu: [Assign person]                    │
    │  Mhazini: [Assign person]                   │
    │  Washauri: [Add advisors]                   │
    ├─────────────────────────────────────────────┤
    │ KAMATI NDOGO (Sub-Committees)               │
    │  □ Chakula (Food)          [Assign chair]   │
    │  □ Mapambo (Decoration)    [Assign chair]   │
    │  □ Burudani (Entertainment)[Assign chair]   │
    │  □ Usafiri (Transport)     [Assign chair]   │
    │  □ Usalama (Security)      [Assign chair]   │
    │  □ Mapokezi (Reception)    [Assign chair]   │
    │  □ Picha/Video (Photo)     [Assign chair]   │
    │  □ Michango (Contributions) [Assign chair]  │
    │  □ Kadi/Mwaliko (Cards)    [Assign chair]   │
    │  □ Mavazi (Attire)         [Assign chair]   │
    └─────────────────────────────────────────────┘
  - Add committee members from TAJIRI contacts
  - Each member gets role-based permissions
  - Committee WhatsApp-style chat auto-created

Step 3: Bajeti (Budget)
  - Auto-loads wedding budget template:
    ┌─────────────────────────────────────────────┐
    │ BAJETI YA HARUSI                            │
    │                                             │
    │ Chakula na Vinywaji    TZS [________] (40%) │
    │ Ukumbi / Hema          TZS [________] (12%) │
    │ Mapambo                TZS [________] (10%) │
    │ Picha na Video         TZS [________] (7%)  │
    │ Burudani (DJ/Band)     TZS [________] (7%)  │
    │ Usafiri                TZS [________] (4%)  │
    │ Mavazi                 TZS [________] (7%)  │
    │ Keki                   TZS [________] (4%)  │
    │ Kadi za Mwaliko        TZS [________] (2%)  │
    │ Ada ya Kanisa/Msikiti  TZS [________] (2%)  │
    │ Mshereheshaji (MC)     TZS [________] (2%)  │
    │ Usalama                TZS [________] (1%)  │
    │ Hifadhi (Contingency)  TZS [________] (5%)  │
    │ ─────────────────────────────────────────── │
    │ JUMLA                  TZS [________]       │
    └─────────────────────────────────────────────┘
  - Allocate sub-budgets to each sub-committee
  - Set target based on expected contributions

Step 4: Michango (Contributions Setup)
  - Set contribution goal (lengo)
  - Set contributor categories with suggested amounts:
    ┌─────────────────────────────────────────────┐
    │ MAKUNDI YA WACHANGA                         │
    │                                             │
    │ Ndugu wa karibu (Close family)              │
    │   Kiwango: TZS 500,000 - 5,000,000        │
    │                                             │
    │ Ndugu wa mbali (Extended family)            │
    │   Kiwango: TZS 100,000 - 500,000          │
    │                                             │
    │ Marafiki wa karibu (Close friends)          │
    │   Kiwango: TZS 50,000 - 200,000           │
    │                                             │
    │ Wafanyakazi wenza (Work colleagues)         │
    │   Kiwango: TZS 20,000 - 100,000           │
    │                                             │
    │ Waumini (Church/mosque community)           │
    │   Kiwango: TZS 10,000 - 50,000            │
    │                                             │
    │ Majirani (Neighbors)                        │
    │   Kiwango: TZS 10,000 - 50,000            │
    └─────────────────────────────────────────────┘
  - Enable M-Pesa collection (auto-reconciliation)
  - Set up contribution cards (Kadi ya Mchango)
  - Assign follow-up ambassadors (wajumbe)

Step 5: Wageni (Guest Management)
  - Set guest categories:
    - Wageni wa Heshima (VIP) — High table, served food
    - Ndugu (Family) — Family section
    - Wageni wa Kawaida (Regular) — General seating, buffet
  - Import guest list from contacts
  - Set estimated guest count (with +30% buffer for walk-ins)
  - Enable invitation card tracking:
    - Card status: Printed → Assigned to deliverer → Delivered → Confirmed
    - Assign delivery zones to committee members

Step 6: Matukio Yanayohusiana (Linked Events)
  - Auto-suggests related events:
    □ Kitchen Party — [Date picker] [Location]
    □ Kupamba / Kupambisha — [Date: 2 days before]
    □ Send-off Party — [Date picker]
    □ Kesha (Night vigil) — [Date: night before]
    □ Uchumba (Engagement) — [Already happened? Link existing]
  - Each linked event shares the same committee (optional)
  - Separate RSVP per event, shared guest list

Step 7: Review & Publish
  - Summary of everything
  - Publish → Sends invitations, enables contributions
  - Save as Draft → Continue setting up later

POST-CREATE MANAGEMENT FLOW:

Weekly cycle for 3-6 months:
  ┌─────────────────────────────────────────────┐
  │ WEEKLY COMMITTEE WORKFLOW                   │
  │                                             │
  │ 1. Schedule meeting (Kikao)                 │
  │    → Set agenda                             │
  │    → Send notifications to all members      │
  │                                             │
  │ 2. During meeting:                          │
  │    → Mhazini reads financial report         │
  │      (auto-generated: total in, total out)  │
  │    → Outstanding pledges reviewed           │
  │    → Sub-committees report progress         │
  │    → Decisions recorded as minutes          │
  │                                             │
  │ 3. Between meetings:                        │
  │    → Contributions collected (M-Pesa auto)  │
  │    → Follow-up on pledges (automated SMS)   │
  │    → Sub-committees log expenses + receipts │
  │    → Vendors booked and paid (tracked)      │
  │    → Invitation cards distributed (tracked) │
  │                                             │
  │ 4. Dashboard shows real-time:               │
  │    → Contributions vs Goal progress bar     │
  │    → Budget vs Actual per category          │
  │    → Guest RSVP count vs estimate           │
  │    → Task completion per sub-committee      │
  │    → Days until wedding countdown           │
  └─────────────────────────────────────────────┘

POST-WEDDING:
  1. Final Taarifa ya Fedha (auto-generated)
  2. Surplus/deficit declared
  3. Committee members thanked
  4. Photo album shared
  5. Reviews collected
  6. Reciprocity ledger updated for all contributors
```

---

### 2. MSIBA (Funeral) — Emergency Flow

```
CREATE FLOW (2 minutes, minimal input):

Step 0: Select Type → "Msiba (Funeral)"
  ↓ EMERGENCY MODE ACTIVATED — skip all optional steps

Step 1: Essentials Only (single screen)
  ┌─────────────────────────────────────────────┐
  │ 🕯️ TAARIFA YA MSIBA                         │
  │                                             │
  │ Jina la Marehemu: [________________]        │
  │ Tarehe ya Mazishi: [Today/Tomorrow picker]  │
  │ Mahali pa Mazishi: [________________]       │
  │ Mahali pa Maombolezo: [________________]    │
  │ Picha (hiari): [📷]                         │
  │                                             │
  │ [CHAPISHA SASA / PUBLISH NOW]               │
  └─────────────────────────────────────────────┘

AUTO-SETUP (happens immediately on publish):
  ✓ Committee created: Mwenyekiti + Katibu + Mhazini (creator assigned all 3, reassign later)
  ✓ M-Pesa contribution enabled with link
  ✓ Announcement broadcast to creator's contacts
  ✓ Food coordination signup list created
  ✓ Transport coordination list created
  ✓ Budget template loaded (6 categories: Jeneza/Coffin, Chakula, Usafiri, Kanisa/Msikiti, Mazishi, Mengineyo)
  ✓ Memorial dates auto-scheduled:
    - Siku ya 3 (3-day memorial)
    - Siku ya 7 (7-day memorial)
    - Siku ya 40 (40-day memorial)
    - Mwaka 1 (1-year anniversary)

MANAGEMENT FLOW (3-7 days, urgent pace):
  - Contributions pour in via M-Pesa (auto-tracked)
  - Committee expanded as people volunteer
  - Expenses logged (coffin, transport, food, venue)
  - Day-of: guest check-in optional
  - Post-funeral: Taarifa ya Fedha shared with family
  - Memorial events auto-created as linked events
```

---

### 3. HARAMBEE (Fundraiser) — Contribution-Heavy Flow

```
CREATE FLOW:

Step 0: Select Type → "Harambee (Fundraiser)"
  ↓ Activates: Kamati BASIC, Michango FULL, Bajeti BASIC

Step 1: Harambee Details
  - Sababu (Cause): Medical / School fees / Disaster / Building / Other
  - Jina (Title)
  - Maelezo (Description — why funds are needed)
  - Lengo la Fedha (Fundraising goal): TZS [________]
  - Tarehe (Date of harambee event, if physical gathering)
  - Supporting documents: medical reports, receipts, photos
  - Picha ya Jalada (Cover photo)

Step 2: Committee (simplified)
  - Mwenyekiti, Katibu, Mhazini only
  - Add a few committee members
  - No sub-committees needed

Step 3: Contributions Setup
  - Enable M-Pesa collection
  - Set contributor categories (or skip — open to all)
  - Enable pledge tracking
  - Set follow-up reminders
  - Goal progress bar prominent on event page

Step 4: Review & Publish
  - Publish → Event page live with:
    - Progress bar (TZS 0 / TZS 5,000,000)
    - Contribute button (→ M-Pesa STK push)
    - Contributor list (names + amounts, optionally public)
    - Updates feed (organizer posts progress)
    - Share to WhatsApp button

POST-HARAMBEE:
  - Expense reporting (how funds were used)
  - Update posts showing impact (e.g., hospital discharge photo)
  - Taarifa ya Fedha shared
```

---

### 4. SHEREHE (Party) — Simple Flow

Covers: Birthday, Baby Shower, Graduation, Send-off, Housewarming, Retirement

```
CREATE FLOW:

Step 0: Select Type → "Sherehe (Party)"
  → Sub-type: Birthday / Baby Shower / Graduation / Send-off / Housewarming / Retirement
  ↓ Activates: Michango OPTIONAL, Zawadi YES, simple setup

Step 1: Party Details (single screen)
  - Jina (Title)
  - Aina ndogo (Sub-type — determines defaults)
  - Tarehe na Muda (Date & time)
  - Mahali (Venue)
  - Maelezo (Description)
  - Picha ya Jalada (Cover photo)
  - Faragha: Public / Private / Invite Only

Step 2: Guests & Invitations
  - Invite from contacts / TAJIRI friends
  - RSVP enabled (Going / Maybe / Not Going)
  - Optional: Dress code / Theme

Step 3: Extras (all optional, based on sub-type)
  ┌───────────────────────────────────────────────────────────────┐
  │ Sub-type        │ Extra features shown                       │
  ├───────────────────────────────────────────────────────────────┤
  │ Birthday        │ Gift wishlist, cake preferences             │
  │ Baby Shower     │ Gift registry, diaper fund (michango)       │
  │ Graduation      │ Gift wishlist, cash gift collection         │
  │ Send-off        │ Farewell gift fund, message board           │
  │ Housewarming    │ Gift wishlist (household items)             │
  │ Retirement      │ Gift fund, digital tribute book             │
  └───────────────────────────────────────────────────────────────┘

Step 4: Publish
  - No committee, no budget, no complex setup
  - Publish → Invite sent, RSVP tracking starts

MANAGEMENT:
  - Track RSVPs
  - Event wall for discussion
  - Photo sharing during/after event
  - Gift tracking (who gave what — for thank-yous)
  - If contribution enabled: simple M-Pesa collection with total display
```

---

### 5. MKUTANO (Conference/Professional) — Professional Flow

Covers: Conference, Workshop, Seminar, Product Launch, Networking Event

```
CREATE FLOW:

Step 0: Select Type → "Mkutano (Conference)"
  → Sub-type: Conference / Workshop / Seminar / Product Launch / Networking
  ↓ Activates: Kamati YES, Bajeti YES, Tiketi YES, Wageni YES (categories)

Step 1: Event Details
  - Jina, Maelezo, Tarehe, Mahali
  - Aina: In-person / Virtual / Hybrid
  - Multi-day toggle (for conferences/festivals)
  - Cover photo + gallery

Step 2: Registration & Ticketing
  - Ticket tiers: Early Bird / Regular / VIP / Student
  - Pricing per tier
  - Registration form (custom fields: company, job title, dietary)
  - Group discounts
  - Promo codes

Step 3: Program / Agenda
  - Sessions with time slots
  - Speakers (name, bio, photo, topic)
  - Tracks (for multi-track conferences)
  - Breaks, networking sessions

Step 4: Organizing Committee
  - Roles: Organizing chair, Program chair, Logistics, Registration, Sponsorship
  - Task assignment per role
  - No sub-committees (simpler than wedding)

Step 5: Budget & Sponsors
  - Budget categories: Venue, Catering, Speakers, Materials, Marketing, Tech, Contingency
  - Sponsor tiers: Platinum / Gold / Silver / Bronze
  - Sponsor logos on event page

Step 6: Review & Publish

MANAGEMENT:
  - Registration dashboard (sign-ups over time)
  - QR check-in at the door
  - Live agenda view for attendees
  - Speaker coordination
  - Post-event: certificates, feedback survey, recording links
  - Sponsor ROI report
```

---

### 6. TAMASHA (Concert/Entertainment) — Ticketed Flow

Covers: Concert, Festival, Sports Event, Comedy Show

```
CREATE FLOW:

Step 0: Select Type → "Tamasha (Concert/Entertainment)"
  → Sub-type: Concert / Festival / Sports / Comedy
  ↓ Activates: Tiketi FULL, Bajeti YES, Wageni (categories)

Step 1: Event Details
  - Jina, Maelezo, Tarehe, Mahali
  - Wasanii / Performers / Teams
  - Cover photo + gallery + video trailer
  - Multi-day toggle (for festivals)

Step 2: Ticketing (primary focus)
  - Tiers: Regular / VIP / VVIP / Table
  - Pricing, quantities, sale dates
  - Early bird pricing
  - Group packages
  - Promo codes
  - Anti-scalping: non-transferable toggle

Step 3: Budget (organizer)
  - Venue, Artists/performers, Sound/lighting, Security, Marketing, Permits, Contingency

Step 4: Publish

MANAGEMENT:
  - Real-time ticket sales dashboard
  - QR check-in
  - Social sharing / viral features
  - Post-event: reviews, photos, next event announcement
```

---

### 7. IBADA (Church/Mosque) — Community Flow

```
CREATE FLOW:

Step 0: Select Type → "Ibada (Church/Mosque)"
  → Sub-type: Sunday Service / Crusade / Revival / Choir Concert / Eid / Maulid / Iftar
  ↓ Activates: Kamati YES, Michango YES (sadaka/offering), Bajeti YES

Step 1: Event Details
  - Jina, Maelezo, Tarehe, Mahali (church/mosque name)
  - Recurring toggle (weekly services)
  - Speaker/preacher

Step 2: Committee (ministry team)
  - Roles: Pastor/Imam, Worship leader, Ushers coordinator, Youth leader
  - Volunteer scheduling

Step 3: Offerings & Contributions
  - Sadaka / Zakat / Tithe collection via M-Pesa
  - Pledge tracking (building fund, missions, etc.)
  - Real-time collection dashboard
  - Receipt generation for tax purposes

Step 4: Budget
  - Categories: Venue, Sound, Decorations, Guest preacher, Transport, Catering
  - Financial transparency report for congregation

Step 5: Publish

MANAGEMENT:
  - Attendance tracking
  - Offering dashboard
  - Volunteer scheduling
  - Recurring event management
  - Announcement broadcasts to congregation
```

---

### 8. SHULE (School Event) — Committee + Contribution Flow

```
CREATE FLOW:

Step 0: Select Type → "Shule (School Event)"
  → Sub-type: Parents Day / Sports Day / Graduation / Fundraiser
  ↓ Activates: Kamati YES (PTA), Michango YES, Bajeti YES

Step 1: Event Details
  - School name, Event title, Date, Venue

Step 2: PTA Committee
  - Mwenyekiti wa Wazazi, Katibu, Mhazini
  - Sub-committees: Food, Logistics, Program, Finance

Step 3: Contributions (if fundraiser)
  - Per-student amount or voluntary
  - M-Pesa collection
  - Contribution tracking per class/grade

Step 4: Budget
  - Categories per sub-type

Step 5: Publish
```

---

### 9. AGM / SACCOS / VICOBA — Governance Flow

```
CREATE FLOW:

Step 0: Select Type → "AGM / SACCOS"
  ↓ Activates: Kamati YES (board), Wageni YES (member verification)
  ↓ Special: Voting system, Quorum tracking

Step 1: Meeting Details
  - Organization name, Date, Venue
  - Required quorum (number or %)
  - Agenda items

Step 2: Members & Attendance
  - Import member list
  - Member verification (active/inactive)
  - Proxy registration
  - Quorum tracking (real-time count)

Step 3: Agenda & Voting
  - Agenda items with time allocation
  - Votable items flagged
  - Voting method: show of hands / secret ballot / digital
  - Financial reports attached

Step 4: Publish (notice to members)

MANAGEMENT:
  - Check-in / attendance tracking
  - Real-time quorum display
  - Digital voting with results
  - Minutes recording
  - Resolution tracking
  - Financial report presentation
```

---

### 10. MAONYESHO (Trade Show/Exhibition) — Exhibitor Flow

```
CREATE FLOW:

Step 0: Select Type → "Maonyesho (Trade Show)"
  ↓ Activates: Kamati YES, Bajeti YES, Tiketi YES (exhibitor + visitor)

Step 1: Event Details
  - Jina, Maelezo, Tarehe (multi-day), Mahali

Step 2: Exhibitor Management
  - Booth/stall categories and pricing
  - Exhibitor registration form
  - Floor plan / booth assignment
  - Exhibitor directory

Step 3: Visitor Ticketing
  - Visitor ticket tiers
  - Day passes vs full-event passes
  - Group/school discounts

Step 4: Budget & Sponsors
  - Similar to conference

Step 5: Publish
```

---

## How the UI Adapts

### Create Event Page — Step 0 (Type Selector)

```
┌─────────────────────────────────────────┐
│ ← Unda Tukio / Create Event            │
├─────────────────────────────────────────┤
│                                         │
│  Chagua Aina ya Tukio                   │
│  Select Event Type                      │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  💍     │ │  🕯️     │ │  🤝     │  │
│  │ Harusi  │ │ Msiba   │ │Harambee │  │
│  │ Wedding │ │ Funeral │ │Fundraise│  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  🎉     │ │  💼     │ │  🎵     │  │
│  │ Sherehe │ │Mkutano  │ │ Tamasha │  │
│  │ Party   │ │Confernce│ │ Concert │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  ⛪     │ │  🏫     │ │  📋     │  │
│  │ Ibada   │ │ Shule   │ │AGM/SACCO│  │
│  │ Worship │ │ School  │ │ Meeting │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
│  ┌─────────┐ ┌─────────┐              │
│  │  🎪     │ │  📦     │              │
│  │Maonyesho│ │Nyingine │              │
│  │ExhibiTon│ │ Other   │              │
│  └─────────┘ └─────────┘              │
│                                         │
└─────────────────────────────────────────┘
```

### After Type Selection — Steps Shown

```
Type Selected    → Steps in Create Wizard
─────────────────────────────────────────────────────────────
Harusi (Wedding) → Basics → Kamati(10) → Bajeti(13) → Michango → Wageni(VIP) → Linked Events → Review
Msiba (Funeral)  → [Single emergency screen] → AUTO-PUBLISH
Harambee         → Details → Kamati(3) → Michango(goal) → Review
Sherehe (Party)  → Details → Guests → Extras(gifts) → Review
Mkutano (Conf)   → Details → Tickets → Agenda → Committee → Budget+Sponsors → Review
Tamasha (Concert)→ Details → Tickets(tiers) → Budget → Review
Ibada (Church)   → Details → Committee → Offerings → Budget → Review
Shule (School)   → Details → PTA Committee → Contributions → Budget → Review
AGM/SACCOS       → Details → Members → Agenda+Voting → Review
Maonyesho (Expo) → Details → Exhibitors → Visitor Tickets → Budget → Review
Nyingine (Other) → Details → [Optional: Committee] → [Optional: Contributions] → Review
```

### After Creation — Management Dashboard Adapts

```
Type Selected    → Dashboard Tabs Shown
─────────────────────────────────────────────────────────────
Harusi (Wedding) → [Overview] [Kamati] [Michango] [Bajeti] [Wageni] [Vikao] [Matukio] [Picha]
Msiba (Funeral)  → [Overview] [Michango] [Gharama] [Mahudhurio] [Kumbukumbu]
Harambee         → [Overview] [Michango ⭐] [Gharama] [Matangazo]
Sherehe (Party)  → [Overview] [Wageni] [Zawadi] [Picha]
Mkutano (Conf)   → [Overview] [Usajili] [Ratiba] [Wasemaji] [Wadhamini] [Bajeti]
Tamasha (Concert)→ [Overview] [Tiketi ⭐] [Mauzo] [Check-in]
Ibada (Church)   → [Overview] [Sadaka] [Mahudhurio] [Bajeti] [Matangazo]
Shule (School)   → [Overview] [Kamati] [Michango] [Bajeti] [Wageni]
AGM/SACCOS       → [Overview] [Wajumbe] [Kura] [Hatua] [Taarifa]
Maonyesho (Expo) → [Overview] [Vibanda] [Tiketi] [Bajeti] [Wadhamini]
```

---

## Universal Systems (The 3 Pillars)

These are the SAME system code, configured differently per event type:

### Kamati (Committee) System — Single Implementation

```dart
// Configuration per event type:
KamatiConfig {
  bool enabled;
  bool hasSubCommittees;
  List<String> defaultSubCommittees;  // ["Chakula", "Mapambo", ...] for wedding, [] for party
  List<String> defaultRoles;          // ["Mwenyekiti", "Katibu", "Mhazini"] always
  bool hasMeetings;                   // true for wedding, false for party
  bool hasTaskTracking;
  bool autoCreate;                    // true for funeral (emergency mode)
}

// Wedding: KamatiConfig(enabled: true, hasSubCommittees: true, defaultSubCommittees: 10, hasMeetings: true, ...)
// Funeral: KamatiConfig(enabled: true, hasSubCommittees: true, defaultSubCommittees: 5, autoCreate: true, ...)
// Party: KamatiConfig(enabled: false)
// Conference: KamatiConfig(enabled: true, hasSubCommittees: false, hasMeetings: false, ...)
```

### Michango (Contribution) System — Single Implementation

```dart
MichangoConfig {
  bool enabled;
  bool hasGoal;                       // true for harambee (progress bar)
  bool hasPledges;                    // true for wedding
  bool hasCategories;                 // true for wedding (ndugu/marafiki/wafanyakazi)
  bool hasFollowUp;                   // true for wedding/harambee
  bool hasReciprocity;                // true for wedding/funeral
  bool isUrgent;                      // true for funeral (immediate collection)
  String collectionLabel;             // "Michango" or "Sadaka" or "Mchango wa Msiba"
  List<ContributorCategory> defaultCategories;
}

// Wedding: MichangoConfig(enabled: true, hasGoal: true, hasPledges: true, hasCategories: true, hasFollowUp: true, ...)
// Funeral: MichangoConfig(enabled: true, isUrgent: true, hasReciprocity: true, ...)
// Harambee: MichangoConfig(enabled: true, hasGoal: true, ...)
// Church: MichangoConfig(enabled: true, collectionLabel: "Sadaka", ...)
// Party: MichangoConfig(enabled: false) or MichangoConfig(enabled: true, hasGoal: false, simple cash gift)
```

### Bajeti (Budget) System — Single Implementation

```dart
BajetiConfig {
  bool enabled;
  List<String> defaultCategories;     // Pre-filled based on event type
  bool hasSubCommitteeAllocation;     // true only for wedding
  bool hasDisbursement;               // true for wedding/harambee
  bool hasReceiptCapture;
  bool hasFinancialReport;
  String currency;                    // "TZS" default
}

// Wedding: BajetiConfig(enabled: true, defaultCategories: 13, hasSubCommitteeAllocation: true, hasDisbursement: true, ...)
// Funeral: BajetiConfig(enabled: true, defaultCategories: 6, ...)
// Conference: BajetiConfig(enabled: true, defaultCategories: 8, ...)
// Party: BajetiConfig(enabled: false) or BajetiConfig(enabled: true, defaultCategories: 3, simple)
```

---

## Event Type Template Registry

```dart
class EventTemplate {
  final String typeId;
  final String nameSwahili;
  final String nameEnglish;
  final IconData icon;
  final KamatiConfig kamatiConfig;
  final MichangoConfig michangoConfig;
  final BajetiConfig bajetiConfig;
  final bool hasTicketing;
  final bool hasGuestCategories;
  final bool hasGiftRegistry;
  final bool hasLinkedEvents;
  final bool isEmergency;
  final List<String> createSteps;        // Which wizard steps to show
  final List<String> dashboardTabs;      // Which management tabs to show
  final Duration? defaultPlanningWindow; // 6 months for wedding, null for funeral
}

// Registry of all templates — the single source of truth
final eventTemplates = {
  'harusi': EventTemplate(
    typeId: 'harusi',
    nameSwahili: 'Harusi',
    nameEnglish: 'Wedding',
    icon: Icons.favorite_rounded,
    kamatiConfig: KamatiConfig(enabled: true, hasSubCommittees: true, ...),
    michangoConfig: MichangoConfig(enabled: true, hasPledges: true, ...),
    bajetiConfig: BajetiConfig(enabled: true, defaultCategories: weddingBudgetCategories, ...),
    hasTicketing: false,
    hasGuestCategories: true,
    hasGiftRegistry: true,
    hasLinkedEvents: true,
    isEmergency: false,
    createSteps: ['basics', 'kamati', 'bajeti', 'michango', 'wageni', 'linked', 'review'],
    dashboardTabs: ['overview', 'kamati', 'michango', 'bajeti', 'wageni', 'vikao', 'matukio', 'picha'],
    defaultPlanningWindow: Duration(days: 180),
  ),
  'msiba': EventTemplate(
    typeId: 'msiba',
    nameSwahili: 'Msiba',
    nameEnglish: 'Funeral',
    icon: Icons.brightness_low_rounded,
    kamatiConfig: KamatiConfig(enabled: true, autoCreate: true, ...),
    michangoConfig: MichangoConfig(enabled: true, isUrgent: true, ...),
    bajetiConfig: BajetiConfig(enabled: true, defaultCategories: funeralBudgetCategories, ...),
    isEmergency: true,
    createSteps: ['emergency_single_screen'],
    dashboardTabs: ['overview', 'michango', 'gharama', 'kumbukumbu'],
    defaultPlanningWindow: null,  // immediate
  ),
  // ... all other types
};
```

---

---

## TAJIRI Platform Integration Map

Every pillar and flow above wires into existing TAJIRI services — nothing is built in isolation.

### Kamati (Committee) → TAJIRI Groups + Messages + Presence

The committee system is NOT a new silo. A Kamati IS a TAJIRI Group with event-specific metadata.

```
When organizer creates a Kamati:
  │
  ├─ 1. GroupService.createGroup()
  │     → Creates TAJIRI Group (privacy: 'private', requiresApproval: true)
  │     → Group.conversationId auto-links to a Conversation
  │     → Returns group_id stored on Event.groupId
  │
  ├─ 2. MessageService (via conversationId)
  │     → Committee group chat auto-created
  │     → All committee members can message immediately
  │     → Announcements pinned as messages
  │     → Committee decisions recorded in chat history
  │
  ├─ 3. Sub-Committees → Child Groups
  │     → Each sub-committee = another Group linked to parent
  │     → Each gets its own conversationId → own group chat
  │     → Sub-committee chair = Group admin
  │
  ├─ 4. Member Assignment
  │     → GroupService.addMember(groupId, userId, role)
  │     → Roles map: Mwenyekiti=admin, Katibu=moderator, Mhazini=moderator, Wajumbe=member
  │     → GroupService.updateMemberRole() for promotions
  │     → GroupService.removeMember() for removal
  │
  ├─ 5. Member Discovery
  │     → FriendService.getFriends(userId) — suggest friends as committee members
  │     → PeopleSearchService.search(location: sameDistrict) — find local people
  │     → PeopleSearchService.search(employer: sameCompany) — find colleagues
  │     → ProfileService.getProfile(userId) — show member details (photo, bio, location)
  │
  ├─ 6. Online Status
  │     → PresenceService.batchPresence(memberIds) — green dots on committee list
  │     → Shows "Last seen 2h ago" for offline members
  │     → Helps schedule impromptu committee calls
  │
  └─ 7. Notifications
       → FCM channel: 'groups' — committee invite, role change
       → NotificationService — "Umealikwa kwenye Kamati ya Harusi ya John na Amina"
       → LiveUpdateService — real-time member list refresh
```

**Existing services used:** `GroupService`, `MessageService`, `FriendService`, `PeopleSearchService`, `ProfileService`, `PresenceService`, `NotificationService`, `LiveUpdateService`

---

### Michango (Contributions) → TAJIRI Wallet + Campaigns + Notifications

The contribution system leverages the existing wallet/payment infrastructure and the Michango (campaign/crowdfunding) module.

```
When Michango is enabled for an event:
  │
  ├─ 1. ContributionService.createCampaign()
  │     → Creates a Campaign linked to event_id
  │     → Campaign has: goalAmount, deadline, allowAnonymous, minimumDonation
  │     → Campaign page shows progress bar, contributor list, updates
  │     → Returns campaign_id stored on Event
  │
  ├─ 2. Collection via WalletService
  │     → WalletService.deposit(amount, provider: 'mpesa', phone) — M-Pesa STK push
  │     → WalletService.deposit(provider: 'tigo_pesa') — Tigo Pesa
  │     → WalletService.deposit(provider: 'airtel_money') — Airtel Money
  │     → All transactions auto-recorded with event reference
  │     → Transaction types: deposit → tied to michango_id
  │
  ├─ 3. Pledge Tracking
  │     → Backend stores: contributor, amount_pledged, amount_paid, status
  │     → Status: pledged → partially_paid → paid → overdue
  │     → Dashboard: pledge-to-payment ratio in real-time
  │
  ├─ 4. Follow-up System
  │     → FCM push: "Kumbuka ahadi yako ya TZS 50,000 kwa Harusi ya John"
  │     → SMS via backend: for contributors without the app
  │     → Assign wajumbe (ambassadors): committee member X follows up on group Y
  │     → Auto-reminders: 7 days, 3 days, 1 day before deadline
  │
  ├─ 5. Contributor Categories (from user's social graph)
  │     → Ndugu wa karibu: FriendService.getFriends() + family tag
  │     → Marafiki: FriendService.getFriends() — all friends
  │     → Wafanyakazi: PeopleSearchService.search(employer: same)
  │     → Waumini: GroupService.getMembers(churchGroupId) — church group
  │     → Majirani: PeopleSearchService.search(location: sameWard)
  │     → Import from phone contacts (with permission)
  │
  ├─ 6. Receipt Generation
  │     → Digital receipt with: contributor name, amount, date, M-Pesa ref, event name
  │     → Shareable as image (WhatsApp) or PDF
  │     → Stored in user's contribution history
  │
  ├─ 7. Real-time Dashboard
  │     → LiveUpdateService → ContributionUpdateEvent(eventId)
  │     → Firestore trigger on new contribution → app refetches totals
  │     → Dashboard shows: total, by category, daily trend, goal %
  │
  ├─ 8. Withdrawal / Disbursement
  │     → ContributionService.requestWithdrawal(campaignId, amount, destination)
  │     → Destination: M-Pesa number, bank account, TAJIRI wallet
  │     → Two-signatory approval (Mwenyekiti + Mhazini must both approve in app)
  │     → Withdrawal history visible to all committee members
  │
  └─ 9. Reciprocity Ledger (Cross-Event)
       → When user contributes to someone's event → stored in user's profile
       → When user creates their own event → system suggests: "Amina contributed TZS 50,000 to your friend's wedding"
       → Historical view: all contributions given + received across all events
       → Suggested contribution amounts based on what they gave you
```

**Existing services used:** `ContributionService`, `WalletService`, `FriendService`, `PeopleSearchService`, `GroupService`, `NotificationService`, `FCMService`, `LiveUpdateService`

---

### Bajeti (Budget) → TAJIRI Wallet + Media Upload + Analytics

```
Budget system integrates with:
  │
  ├─ 1. Expense Tracking
  │     → Log expense: amount, category, description, date, sub-committee
  │     → PhotoService.uploadPhoto() — capture receipt photos
  │     → ResumableUploadService — for large receipt documents
  │     → Expenses linked to WalletService transactions where applicable
  │
  ├─ 2. Budget vs Contributions (Real-time Balance)
  │     → Available = Total Contributions (from Michango) - Total Expenses
  │     → ContributionService.getCampaign() → current raised amount
  │     → Expenses sum from event budget API
  │     → LiveUpdateService triggers refresh on new contribution or expense
  │
  ├─ 3. Sub-Committee Budgets
  │     → Each sub-committee Group has a budget allocation
  │     → Sub-committee chair logs expenses against their allocation
  │     → Overspend alerts via FCM: "Kamati ya Chakula imezidi bajeti kwa TZS 200,000"
  │
  ├─ 4. Financial Report (Taarifa ya Fedha)
  │     → Auto-generated from: contributions (ContributionService) + expenses (Budget API)
  │     → Sections: Mapato (Income), Matumizi (Expenses), Bakaa (Surplus/Deficit)
  │     → Shareable: export as image for WhatsApp, PDF for formal records
  │     → Presented during final committee meeting (shared in group chat)
  │
  └─ 5. Analytics Integration
       → AnalyticsService pattern for budget insights
       → Track: spending velocity, category breakdown, forecast
       → Compare to template averages: "Your food spend is 45% — average is 35%"
```

**Existing services used:** `WalletService`, `ContributionService`, `PhotoService`, `ResumableUploadService`, `LiveUpdateService`, `AnalyticsService`

---

### Wageni (Guest Management) → TAJIRI Users + Friends + Contacts

```
Guest system integrates with:
  │
  ├─ 1. Guest List Building
  │     → FriendService.getFriends() — invite from friend list
  │     → PeopleSearchService.search() — find TAJIRI users by name/phone
  │     → Phone contacts import — invite non-TAJIRI users via SMS
  │     → GroupService.getMembers(groupId) — invite entire group/community
  │     → Bulk import from CSV/Excel (phone numbers)
  │
  ├─ 2. Guest Categories Assignment
  │     → VIP: high-profile users (verified, high follower count)
  │     → Family: users tagged as family in contacts or friend graph
  │     → Regular: everyone else
  │     → Custom: organizer-defined categories
  │     → Category determines: seating, food service, invitation card type
  │
  ├─ 3. Invitation Tracking
  │     → Physical card: status flow (Printed → Assigned → Delivered → Confirmed)
  │     → Digital: WhatsApp share with deep link to event page
  │     → SMS invite: for non-smartphone users (backend sends SMS)
  │     → TAJIRI in-app: NotificationService push + event appears in feed
  │     → Track: who delivered each card (assign delivery to committee members)
  │
  ├─ 4. RSVP Integration
  │     → Existing EventService.respondToEvent() — Going/Interested/Not Going
  │     → +1/guest support: RSVP with guestCount and guestNames
  │     → RSVP status synced to guest list in real-time (LiveUpdateService)
  │     → Food estimation: goingCount * 1.3 (30% buffer for walk-ins)
  │
  ├─ 5. "Friends Going" Social Proof
  │     → FriendService cross-referenced with attendee list
  │     → Event card shows: friend avatars + "Amina, John na 12 wengine"
  │     → Feed discovery: events with friends going ranked higher (ContentEngineService)
  │
  ├─ 6. Check-in at Door
  │     → QR code on ticket → scan at venue entrance
  │     → Manual check-in by name lookup
  │     → Guest category visible to ushers (VIP gets escorted to reserved section)
  │     → Real-time attendance count on organizer dashboard
  │
  └─ 7. Gift/Bahasha Tracking
       → Record gifts received at the door (who gave what)
       → Cash in bahasha: amount, giver name
       → Physical gifts: description, giver
       → Thank-you status: tracked per contributor
       → Reciprocity: links to Michango reciprocity ledger
```

**Existing services used:** `FriendService`, `PeopleSearchService`, `GroupService`, `EventService`, `NotificationService`, `LiveUpdateService`, `ContentEngineService`

---

### Matukio Yanayohusiana (Linked Events) → TAJIRI Calendar + Stories

```
Linked events integrate with:
  │
  ├─ 1. Calendar Module (lib/calendar/)
  │     → CalendarService.createEvent() — sync each linked event to personal calendar
  │     → Calendar view shows all linked events on timeline
  │     → Reminders: 1 day, 1 hour before each linked event
  │     → Conflict detection: warn if two linked events overlap
  │
  ├─ 2. Stories (lib/services/story_service.dart)
  │     → StoryService.createStory() — share event updates as stories
  │     → "Countdown to Harusi" story with event details
  │     → "Kitchen Party recap" story with photos
  │     → "Kupamba night" behind-the-scenes story
  │     → Auto-suggest story creation at key milestones
  │
  ├─ 3. Feed Integration (lib/services/post_service.dart)
  │     → PostService.createPost() — auto-post when event published
  │     → Event card appears in friends' feeds
  │     → Engagement (likes, comments, shares) on event post
  │     → HashtagService — #Harusi #HarusiYaJohnNaAmina
  │
  ├─ 4. Shared Resources
  │     → Same committee (Group) manages all linked events
  │     → Same Michango campaign collects for entire wedding series
  │     → Same guest list with per-event RSVP
  │     → Separate budgets per event (Kitchen Party budget vs Main Wedding budget)
  │
  └─ 5. Timeline View
       → All linked events on one scrollable timeline
       → Past events: marked complete with photos
       → Current event: highlighted with countdown
       → Future events: show planning status
```

**Existing services used:** `CalendarService`, `StoryService`, `PostService`, `HashtagService`, `GroupService`, `ContributionService`

---

### Communication Layer — How Each Pillar Communicates

```
┌────────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION ARCHITECTURE                      │
│                                                                    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐ │
│  │ Push (FCM)   │    │ In-App       │    │ External             │ │
│  │              │    │              │    │                      │ │
│  │ • Event      │    │ • Event Wall │    │ • SMS (via backend)  │ │
│  │   invite     │    │   posts      │    │   for non-app users  │ │
│  │ • RSVP       │    │ • Committee  │    │                      │ │
│  │   reminder   │    │   group chat │    │ • WhatsApp share     │ │
│  │ • Michango   │    │   (Messages) │    │   links (url_launch) │ │
│  │   received   │    │ • Activity   │    │                      │ │
│  │ • Michango   │    │   feed       │    │ • Email (future)     │ │
│  │   milestone  │    │ • Dashboard  │    │                      │ │
│  │ • Event      │    │   metrics    │    │                      │ │
│  │   change     │    │              │    │                      │ │
│  │ • Committee  │    │              │    │                      │ │
│  │   decision   │    │              │    │                      │ │
│  └──────┬───────┘    └──────┬───────┘    └──────────┬───────────┘ │
│         │                   │                       │             │
│         └─────────┬─────────┴───────────────────────┘             │
│                   │                                               │
│         ┌─────────▼──────────┐                                    │
│         │ LiveUpdateService  │ ← Firestore real-time triggers     │
│         │ (updates/{userId}) │                                    │
│         └────────────────────┘                                    │
│                                                                    │
│  New event types to add to LiveUpdateService:                     │
│  • EventUpdateEvent(eventId, type: rsvp|update|cancel)            │
│  • MichangoUpdateEvent(eventId, amount, total)                    │
│  • CommitteeUpdateEvent(groupId, action: member_added|role_change)│
│  • BudgetUpdateEvent(eventId, category, newTotal)                 │
│                                                                    │
│  New FCM channels:                                                │
│  • 'events' — event invites, reminders, changes                   │
│  • 'michango' — contribution received, milestone, pledge reminder │
│  • 'kamati' — committee invite, meeting reminder, task assigned   │
└────────────────────────────────────────────────────────────────────┘
```

---

### Data Flow: Full Wedding Lifecycle Through TAJIRI Services

```
MONTH 1: SETUP
  Creator → EventService.createEvent(type: 'harusi')
       └→ GroupService.createGroup("Kamati ya Harusi ya John na Amina")
            └→ MessageService auto-creates group chat (conversationId)
       └→ ContributionService.createCampaign(goalAmount: 25M TZS)
       └→ CalendarService.createEvent(startDate, endDate)
       └→ PostService.createPost("Tumealikwa! Harusi yetu...") → appears in feed

MONTH 2-5: PLANNING
  Committee members:
       → GroupService.addMember(userId, role: 'moderator')
       → MessageService.sendMessage(conversationId, "Kikao wiki ijayo Jumamosi")
       → Sub-groups created for each sub-committee

  Contributions flow in:
       → WalletService.deposit(amount: 50000, provider: 'mpesa')
       → ContributionService.donateToCampaign(campaignId, amount)
       → LiveUpdateService fires MichangoUpdateEvent → dashboard refreshes
       → FCM push to organizer: "Amina ametoa TZS 50,000!"
       → Auto-follow-up SMS to pledgers at week 8, 10, 12

  Budget tracked:
       → Expenses logged with receipt photos (PhotoService.uploadPhoto)
       → Budget vs actual visible in real-time
       → Sub-committee chairs see their allocation vs spent
       → Overspend alerts via FCM

  Guest management:
       → FriendService.getFriends() → bulk invite
       → PeopleSearchService.search(location: sameDistrict) → discover
       → Physical card tracking: Printed → Delivered → Confirmed
       → RSVP count grows → food estimation updates

MONTH 5-6: FINAL PREP
  Linked events created:
       → Kitchen Party (1 week before)
       → Kupamba (2 days before)
       → Kesha (night before)
       → Each gets own RSVP, shares committee + guest list

  Stories posted:
       → StoryService.createStory("Countdown: 7 siku!")
       → Event feed post with final details

  Final push on contributions:
       → Automated reminders to all unpaid pledges
       → WhatsApp share link with progress bar
       → Committee meeting: Taarifa ya Fedha presented (auto-generated)

WEDDING DAY:
  Check-in:
       → QR scan (TicketService.checkInTicket)
       → Guest category shown to ushers
       → Real-time attendance count
       → VIP guests flagged for escort

  Live coverage:
       → StoryService: behind-the-scenes stories
       → PostService: official event photos to feed
       → EventWallService: live updates from attendees

POST-WEDDING:
  Financial accounting:
       → Auto-generated Taarifa ya Fedha
       → ContributionService totals + Expense totals → Surplus/Deficit
       → Shared in committee group chat (MessageService)
       → PDF exported and shared on WhatsApp

  Surplus handling:
       → ContributionService.requestWithdrawal() to couple's M-Pesa
       → Or WalletService.transfer() to TAJIRI wallet

  Thank-yous:
       → NotificationService: "Asante kwa mchango wako!"
       → Gift tracking complete
       → Reciprocity ledger updated for all contributors

  Memories:
       → Event photo album preserved
       → Event wall posts archived
       → Reviews collected from attendees
```

---

### Service Integration Summary

| TAJIRI Service | Used By | How |
|---|---|---|
| `GroupService` | Kamati | Committee = Group. Sub-committees = child groups. Roles, members, permissions |
| `MessageService` | Kamati | Auto-created group chat per committee/sub-committee via conversationId |
| `FriendService` | Wageni, Kamati | "Friends going", committee member suggestions, invite friends |
| `PeopleSearchService` | Wageni, Kamati | Find people by location/employer/school for invites and committee |
| `ProfileService` | All | Display user profiles (photos, names, bios) for attendees, committee, speakers |
| `PresenceService` | Kamati | Online status dots on committee member list |
| `ContributionService` | Michango | Campaign creation, donation, withdrawal, updates — the financial backbone |
| `WalletService` | Michango, Bajeti | M-Pesa STK push for contributions, expense payments, payouts |
| `NotificationService` | All | Push notifications for invites, RSVPs, contributions, reminders |
| `FCMService` | All | Firebase channels: 'events', 'michango', 'kamati' |
| `LiveUpdateService` | All | Real-time Firestore triggers for RSVP, contribution, budget changes |
| `CalendarService` | Linked Events | Sync events to personal calendar, reminders |
| `StoryService` | Promotion | Share event updates, countdowns, coverage as stories |
| `PostService` | Promotion | Auto-post event to feed, engagement tracking |
| `HashtagService` | Discovery | Event hashtags for search and discovery |
| `ContentEngineService` | Discovery | Rank events in feed based on friends, location, interests |
| `PhotoService` | Bajeti, Media | Receipt photos, event cover, gallery uploads |
| `ResumableUploadService` | Media | Large video/document uploads with pause/resume |
| `LocationService` | Discovery | Tanzania region/district/ward hierarchy for "Events Near Me" |
| `AnalyticsService` | Dashboard | Event performance metrics, audience insights |
| `LocalStorageService` | Caching | Cache events, tickets, QR codes offline via Hive |
| `MediaCacheService` | Offline | Cache cover photos, gallery images for offline viewing |

---

---

## Performance Architecture

> Aligned with `docs/PERFORMANCE_STRATEGY.md`, `docs/PERFORMANCE_IMPLEMENTATION_PLAN.md`, and `docs/SQLITE_ADOPTION_ROADMAP.md`.

Events is a data-heavy module — event lists, contributor lists, committee members, budget entries, guest lists, transactions. Without performance engineering from day 1, it will show spinners everywhere and chew bandwidth on every screen open.

### Strategy: Local-First, Sync-in-Background

Every Events screen follows the TAJIRI stale-while-revalidate pattern:

```
Screen opens
  ├─ Frame 0: Load from local cache (SQLite or Hive) → render instantly
  ├─ Frame 1: BlurHash placeholders for images not yet on disk
  ├─ Background: API fetch for fresh data
  ├─ On response: diff against displayed data → merge silently
  ├─ Save fresh response to cache
  └─ User sees content in <100ms, fresh data arrives in 1-3s
```

---

### 1. EventDatabase — SQLite Local Storage

Per `docs/SQLITE_ADOPTION_ROADMAP.md` item #7, Events should use SQLite (not Hive) for structured queries (time-based filtering, category search, status filtering). Follows the `MessageDatabase` pattern from `lib/services/message_database.dart`.

```dart
// lib/events/services/event_database.dart
class EventDatabase {
  static final EventDatabase instance = EventDatabase._();
  Database? _db;

  // ── Tables ──
  // events        — id, name, slug, category, start_date, status, json_data TEXT, synced_at
  // tickets       — id, event_id, ticket_number, status, qr_code_data, json_data TEXT, synced_at
  // contributions — id, event_id, user_id, amount_pledged, amount_paid, status, json_data TEXT
  // expenses      — id, event_id, category, amount, description, receipt_url, json_data TEXT
  // committee     — id, event_id, user_id, role, json_data TEXT
  // guests        — id, event_id, user_id, category, rsvp_status, card_status, json_data TEXT
  // sync_state    — entity_type, last_synced_id, last_sync_timestamp
  // pending_queue — id, entity_type, action, payload JSON, retry_count, created_at

  // ── Indexed columns for fast queries ──
  // events: start_date, category, status (WHERE start_date > now AND status = 'published')
  // tickets: event_id, status (WHERE event_id = X AND status = 'active')
  // contributions: event_id, status (SUM(amount_paid) WHERE event_id = X)
  // expenses: event_id, category (SUM(amount) WHERE event_id = X GROUP BY category)
  // guests: event_id, rsvp_status, category (COUNT WHERE event_id = X AND rsvp = 'going')

  // ── Key queries (all <5ms on SQLite) ──
  Future<List<Event>> getUpcomingEvents();           // WHERE start_date > now ORDER BY start_date
  Future<List<Event>> getEventsByCategory(String c); // WHERE category = c
  Future<List<EventTicket>> getMyActiveTickets();     // WHERE status = 'active' ORDER BY event.start_date
  Future<double> getTotalContributions(int eventId); // SUM(amount_paid) WHERE event_id = X
  Future<double> getTotalExpenses(int eventId);      // SUM(amount) WHERE event_id = X
  Future<int> getGuestCount(int eventId, String status); // COUNT WHERE event_id = X AND rsvp = status
  Future<Map<String, double>> getBudgetByCategory(int eventId); // GROUP BY category
}
```

**Why SQLite over Hive for Events:**
- Time-based queries: "Show events after today" — SQLite uses index, Hive scans all records
- Aggregation: "Total contributions = SUM(amount_paid)" — SQLite native, Hive requires Dart loop
- Multi-column filtering: "Events in 'music' category + this weekend + free" — SQLite WHERE clause, Hive is O(n) filter
- Contribution tracking: 500+ contributors per wedding — needs indexed lookups, not linear scan
- Budget: GROUP BY category for breakdown charts — SQLite native
- FTS5: full-text search on event names/descriptions for discovery

**json_data column pattern** (from MessageDatabase):
- Store full model JSON in `json_data TEXT` column
- Index only the columns needed for queries (id, event_id, status, dates, category)
- Reconstruct full model via `Event.fromJson(jsonDecode(row['json_data']))`
- Lossless: no field lost on round-trip

---

### 2. Stale-While-Revalidate Per Screen

| Screen | Cache Source | Staleness TTL | Refresh Trigger |
|---|---|---|---|
| **Events Home (Feed)** | SQLite `events` table, sorted by start_date | 5 min | Pull-to-refresh, LiveUpdateEvent |
| **Browse Events** | SQLite `events` with category/date/price filter | 5 min | Category tap, search submit |
| **Event Detail** | SQLite single event by ID | 10 min | RSVP action, LiveUpdateEvent |
| **My Tickets** | SQLite `tickets` table, sorted by event date | 1 hour | Ticket purchase, ticket transfer |
| **Michango Dashboard** | SQLite `contributions` aggregated | 1 min (active collection) | Every MichangoUpdateEvent from Firestore |
| **Budget Dashboard** | SQLite `expenses` + `contributions` | 5 min | Expense logged, contribution received |
| **Committee List** | SQLite `committee` table | 30 min | Member added/removed |
| **Guest List** | SQLite `guests` table | 15 min | RSVP change, invitation tracked |
| **Organizer Dashboard** | API only (analytics are server-computed) | No cache | Manual refresh |

```dart
// Pattern applied to every Events screen:
class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
    _loadCached();   // 1. SQLite → instant render
    _fetchFresh();   // 2. API → background fetch
    _listenLive();   // 3. Firestore → real-time triggers
  }

  Future<void> _loadCached() async {
    final cached = await EventDatabase.instance.getUpcomingEvents();
    if (cached.isNotEmpty && mounted) {
      setState(() => _events = cached); // instant, <5ms
    }
  }

  Future<void> _fetchFresh() async {
    if (!EventDatabase.instance.isStale('events_feed', ttl: Duration(minutes: 5))) return;
    final result = await _service.getEventsFeed();
    if (result.success && mounted) {
      await EventDatabase.instance.upsertEvents(result.items);
      setState(() => _events = result.items);
    }
  }

  void _listenLive() {
    LiveUpdateService.instance.stream.listen((event) {
      if (event is EventUpdateEvent) _fetchFresh(); // re-sync on server change
    });
  }
}
```

---

### 3. Offline Mutations — Pending Queue

When user is offline, actions queue locally and sync when connectivity returns. Follows the `pending_queue` pattern from `SQLITE_ADOPTION_ROADMAP.md`.

```
Offline Action Queue:
  ├── RSVP "Going" → queued in pending_queue → synced on reconnect
  ├── Log expense → queued with receipt photo path → uploaded on reconnect
  ├── Record cash contribution → queued → synced on reconnect
  ├── Add committee member → queued → synced
  └── Track invitation card delivery → queued → synced

Immediately reflected in local UI:
  ├── RSVP button shows "Going" optimistically
  ├── Expense appears in budget breakdown
  ├── Contribution total increments locally
  └── Badge shows "1 pending sync" indicator
```

```dart
// Optimistic RSVP pattern:
Future<void> rsvp(int eventId, RSVPStatus status) async {
  // 1. Update SQLite immediately (optimistic)
  await EventDatabase.instance.updateRSVP(eventId, status);
  setState(() => _event = _event.copyWith(userResponse: status.apiValue));

  // 2. Try API
  try {
    await _service.respondToEvent(eventId: eventId, status: status);
  } catch (e) {
    // 3. Offline → queue for later
    await EventDatabase.instance.addPendingAction(
      entityType: 'rsvp',
      action: 'update',
      payload: {'event_id': eventId, 'status': status.apiValue},
    );
  }
}
```

---

### 4. Delta Sync — Fetch Only Changes

Instead of re-downloading entire event lists, use delta sync with server timestamps:

```dart
// sync_state table tracks last sync per entity
Future<void> syncEvents() async {
  final lastSync = await EventDatabase.instance.getLastSyncTimestamp('events');
  final result = await _dio.get('/events/sync', queryParameters: {
    'since': lastSync?.toIso8601String(),  // server returns only changed events
  });
  // Upsert only changed records — not full replacement
  await EventDatabase.instance.upsertEvents(result.data['data']);
  await EventDatabase.instance.updateSyncTimestamp('events');
}

// For Michango: sync contributions since last known ID
Future<void> syncContributions(int eventId) async {
  final lastId = await EventDatabase.instance.getLastSyncedId('contributions_$eventId');
  final result = await _dio.get('/events/$eventId/contributions', queryParameters: {
    'since_id': lastId,  // server returns only new contributions
  });
  await EventDatabase.instance.insertContributions(result.data['data']);
}
```

---

### 5. Image & Media Performance

Following `docs/PERFORMANCE_STRATEGY.md` Phase 2 (BlurHash) and media cache patterns:

```
Event Cover Photos:
  ├── API response includes blurhash field per event
  ├── EventCard renders BlurHash instantly → full image loads from MediaCacheService
  ├── MediaCacheService (30-day TTL, 1000 files) caches cover photos on disk
  ├── Scroll buffer: preload covers 1500px ahead of viewport
  └── memCacheWidth/Height set on CachedNetworkImage to prevent memory blowup

Receipt Photos (Bajeti):
  ├── Captured via camera → saved to local file
  ├── Thumbnail generated locally for instant display in expense list
  ├── Full-res uploaded via ResumableUploadService in background
  ├── Upload state tracked: pending → uploading → uploaded
  └── Offline: receipt photo stored locally, uploaded when connected

Committee/Attendee Avatars:
  ├── Avatar URLs cached by MediaCacheService
  ├── memCacheWidth: 96px (3x for 32dp avatars) — prevents decoding large profile photos
  ├── BlurHash placeholder from user profile
  └── Batch-prefetch avatars for visible committee list
```

---

### 6. Lazy Loading & Prefetch

Following `docs/PERFORMANCE_STRATEGY.md` Phase 3 (lazy tabs) and Phase 4 (prefetch):

```
Events Home Page (4 tabs: For You / Friends / Nearby / Calendar):
  ├── Only "For You" tab builds on first open (LazyIndexedStack pattern)
  ├── "Friends" tab builds on first tap — not eagerly
  ├── "Nearby" tab builds on first tap — triggers location permission
  └── "Calendar" tab builds on first tap — loads calendar widget

Event Detail Page (4 inner tabs: Wall / Details / Agenda / Photos):
  ├── Only active tab renders content
  ├── Wall posts loaded only when Wall tab selected
  ├── Photos loaded only when Photos tab selected
  └── Agenda rendered from local data (sessions already in Event model)

Michango Dashboard:
  ├── Contribution list: prefetch next page at 60% scroll
  ├── Charts: computed locally from SQLite (no API for chart data)
  └── Contributor avatars: batch prefetch visible 10

Event Feed Scroll:
  ├── Prefetch next page at 60% scroll depth
  ├── Cover images preloaded 1500px ahead
  ├── When page boundary reached → append prefetched, zero spinner
  └── Cache pages 1-3 in SQLite, evict older pages
```

---

### 7. Background Sync for Events

Following `docs/PERFORMANCE_STRATEGY.md` Phase 5 (WorkManager):

```dart
// Background tasks registered in main.dart:
Workmanager().registerPeriodicTask(
  'eventSync', 'syncEvents',
  frequency: Duration(minutes: 15),
  constraints: Constraints(networkType: NetworkType.connected),
);

Workmanager().registerPeriodicTask(
  'ticketQRRefresh', 'refreshTicketQR',
  frequency: Duration(minutes: 10),
  constraints: Constraints(networkType: NetworkType.connected),
);

// Callbacks:
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'syncEvents':
        // Delta sync events modified since last check
        await EventDatabase.instance.deltaSync();
        return true;
      case 'refreshTicketQR':
        // Refresh rotating QR codes for active tickets
        final tickets = await EventDatabase.instance.getMyActiveTickets();
        for (final t in tickets) {
          final qr = await TicketService().getTicketQR(ticketId: t.id);
          if (qr != null) await EventDatabase.instance.cacheTicketQR(t.id, qr);
        }
        return true;
    }
    return true;
  });
}
```

**Critical for ticket QR codes:** Rotating QR codes must be refreshed in background so that at the venue (often with poor connectivity), the QR is already cached and ready to scan.

---

### 8. ETag / 304 Support for Events API

Following `docs/PERFORMANCE_STRATEGY.md` Phase 5:

```dart
// Events endpoints that support ETag:
// GET /events          → ETag on list hash (changes when any event updated)
// GET /events/{id}     → ETag on single event (changes on RSVP, update, comment)
// GET /events/{id}/contributions → ETag on contribution list hash

// Client pattern:
Future<PaginatedResult<Event>> getEventsFeed({int page = 1}) async {
  final etag = await ETagCacheService.instance.getETag('/events/feed?page=$page');
  try {
    final response = await _dio.get('/events/feed',
      queryParameters: {'page': page},
      options: Options(headers: {if (etag != null) 'If-None-Match': etag}),
    );
    if (response.statusCode == 304) {
      // Data unchanged — use cached
      return _parseCachedEvents('/events/feed?page=$page');
    }
    // Save new ETag + response body
    await ETagCacheService.instance.saveETag(
      '/events/feed?page=$page',
      response.headers['etag']?.first,
      response.data,
    );
    return _parsePaginatedEvents(response.data);
  } catch (e) {
    // Offline fallback → return from SQLite
    return _loadFromDatabase(page: page);
  }
}
```

---

### 9. Michango-Specific Performance

Contribution dashboards are the most frequently accessed screen during active planning (checked multiple times daily by committee). They MUST be instant.

```
Michango Dashboard Performance Stack:
  │
  ├── SQLite aggregation (no API needed for totals):
  │   SELECT SUM(amount_paid) FROM contributions WHERE event_id = ?
  │   SELECT COUNT(*) FROM contributions WHERE event_id = ? AND status = 'paid'
  │   SELECT SUM(amount_pledged) - SUM(amount_paid) as outstanding FROM contributions WHERE event_id = ?
  │   → All <2ms on SQLite
  │
  ├── Real-time via Firestore:
  │   LiveUpdateService → MichangoUpdateEvent → triggers delta sync
  │   New contribution arrives → INSERT into SQLite → re-aggregate → update UI
  │   Latency: ~1-3 seconds from M-Pesa payment to dashboard update
  │
  ├── Chart data computed locally:
  │   Daily totals: SELECT date(created_at), SUM(amount) GROUP BY date
  │   Category breakdown: SELECT category, SUM(amount) GROUP BY category
  │   → No separate chart API endpoint needed
  │
  └── Contributor list:
      Paginated from SQLite: SELECT * FROM contributions WHERE event_id = ? ORDER BY created_at DESC LIMIT 20 OFFSET ?
      Avatar prefetch: batch load first 10 contributor avatars
      Scroll prefetch: load next page at 60%
```

---

### 10. Budget-Specific Performance

```
Budget vs Actual — computed entirely from local SQLite:
  │
  ├── Total collected:  SELECT SUM(amount_paid) FROM contributions WHERE event_id = ?
  ├── Total spent:      SELECT SUM(amount) FROM expenses WHERE event_id = ?
  ├── Available:        collected - spent (Dart computation, <1ms)
  ├── Per category:     SELECT category, SUM(amount) FROM expenses GROUP BY category
  ├── Per sub-committee: SELECT committee_id, SUM(amount) FROM expenses GROUP BY committee_id
  └── Overspend check:  WHERE SUM(amount) > budget_allocation → red highlight

  All queries indexed → <5ms total for full dashboard render from SQLite.
  No API call needed except initial sync and delta updates.
```

---

### 11. Offline Capability Matrix

| Feature | Offline Read | Offline Write | Sync Strategy |
|---|---|---|---|
| **Event List** | YES (SQLite) | N/A | Delta sync every 15 min + LiveUpdate trigger |
| **Event Detail** | YES (SQLite) | N/A | Cache on view, refresh on LiveUpdate |
| **My Tickets + QR** | YES (SQLite + cached QR) | N/A | Background QR refresh every 10 min |
| **RSVP** | YES (local state) | YES (pending queue) | Optimistic UI → sync on reconnect |
| **Michango Dashboard** | YES (SQLite aggregation) | N/A | Real-time via Firestore delta |
| **Log Contribution (cash)** | YES (local display) | YES (pending queue) | Queue → sync → update totals |
| **Log Expense** | YES (local display) | YES (pending queue + local receipt) | Queue → upload receipt → sync |
| **Budget View** | YES (SQLite computation) | N/A | Computed from local data |
| **Committee Chat** | YES (MessageDatabase) | YES (pending message) | Existing message sync infrastructure |
| **Guest List** | YES (SQLite) | N/A | Sync on open |
| **QR Check-in** | PARTIAL (cached ticket list) | YES (queue check-in) | Validate against local cache → sync results |

---

### 12. Performance Metrics Targets

| Metric | Target | How |
|---|---|---|
| Time to first event visible (returning) | <100ms | SQLite cache → instant render |
| Time to first event visible (fresh) | <2s | API fetch + render |
| Michango dashboard load | <50ms | SQLite aggregation only |
| Budget breakdown load | <50ms | SQLite GROUP BY |
| Event detail open | <100ms | SQLite single row + cached cover |
| Ticket QR display | <50ms | Cached QR in SQLite |
| Offline event browse | Fully functional | SQLite full dataset |
| Offline ticket display | Fully functional | SQLite + cached QR |
| Offline RSVP | Optimistic + queued | Pending queue |
| Background sync interval | 15 min | WorkManager periodic |
| QR refresh interval | 10 min | WorkManager periodic |
| Media cache size | Up to 1000 items | MediaCacheService config |
| SQLite DB size (1 year of events) | ~5-10 MB | json_data + indexed columns |
| API calls on Events tab open (cached) | 0 | SQLite-first, refresh in background |
| API calls on Events tab open (stale) | 1 (delta sync) | Only fetch changes since last timestamp |

---

## Summary

The adaptive flow means:
1. **One codebase** — 3 universal systems (Kamati, Michango, Bajeti) with configuration
2. **One create wizard** — steps show/hide based on event template
3. **One management dashboard** — tabs show/hide based on event template
4. **Event templates** — pre-built configs that wire the right features to the right event type
5. **Wedding is the superset** — every feature exists because wedding needs it; other types use subsets
6. **Deep TAJIRI integration** — Kamati=Groups, Michango=Campaigns+Wallet, Communication=Messages+FCM+LiveUpdates, Discovery=Friends+ContentEngine+Location, Media=Photos+Stories+Posts
7. **Local-first performance** — SQLite for structured queries, stale-while-revalidate on every screen, delta sync, offline mutations via pending queue, background sync via WorkManager, BlurHash image placeholders, ETag/304 HTTP caching — zero spinners for returning users
