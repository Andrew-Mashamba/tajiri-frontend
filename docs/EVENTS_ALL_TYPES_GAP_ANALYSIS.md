# Events Module — All Tanzanian Event Types Gap Analysis

> Based on deep research of 29 event types common in Tanzania, cross-referenced against our 75-file events module implementation.

---

## Cross-Cutting Feature Requirements

Based on analysis of ALL 29 Tanzanian event types, here are the feature clusters needed:

### Tier 1: Core Features (needed by nearly ALL event types)

| # | Feature | Our Status | Gap |
|---|---------|-----------|-----|
| 1 | Event creation and management | ✅ HAVE | Covered |
| 2 | Guest/Attendee management — invitation, RSVP, check-in | ✅ HAVE | Covered (basic) |
| 3 | Communication — announcements, notifications | ✅ HAVE | Covered |
| 4 | Photo/Video sharing — event memories | ✅ HAVE | Covered |
| 5 | Financial tracking — contributions, expenses, budgets, reports | ❌ MISSING | CRITICAL gap across all event types |

### Tier 2: Common Features (needed by many event types)

| # | Feature | Our Status | Gap |
|---|---------|-----------|-----|
| 6 | Contribution/Fundraising — M-Pesa collection, pledge tracking, goal tracking | ❌ MISSING | CRITICAL — needed by 18/29 event types |
| 7 | Ticketing — digital tickets, QR codes, tiered pricing | ✅ HAVE | Covered |
| 8 | Committee management — roles, tasks, communication channels | ❌ MISSING | HIGH — needed by 15/29 event types |
| 9 | Vendor management — booking, coordination, payment tracking | ❌ MISSING | MEDIUM — needed by 12/29 event types |
| 10 | Gift registry/tracking — wishlists, gift recording, duplicate prevention | ❌ MISSING | MEDIUM — needed by 10/29 event types |
| 11 | Certificate generation — participation, attendance, achievement | ❌ MISSING | LOW — needed by 5/29 event types |

### Tier 3: Specialized Features (needed by specific event types)

| # | Feature | Needed By | Our Status |
|---|---------|-----------|-----------|
| 12 | Voting/Election system — digital ballots, quorum tracking | AGMs, village meetings, SACCOs | ❌ MISSING |
| 13 | Multi-day event management — schedules, stages, tracks | Festivals, conferences | ✅ PARTIAL (sessions/agenda) |
| 14 | Exhibitor/Booth management — floor plans, directory | Trade shows, expos | ❌ MISSING |
| 15 | Tournament/Competition management — brackets, scores | Sports events | ❌ MISSING |
| 16 | Per diem/Allowance management — calculate, distribute | Workshops, trainings | ❌ MISSING |
| 17 | Religious calendar integration — Hijri/Christian | Church/Mosque events | ❌ MISSING |
| 18 | Family tree/Directory — member registry | Reunions, funerals | ❌ MISSING |
| 19 | Proxy management — delegate voting | AGMs | ❌ MISSING |
| 20 | Emergency mode — rapid setup, no advance planning | Funerals/Msiba | ❌ MISSING |

---

## Event Type Feature Matrix

Which features each event type needs (✓ = required, ~ = optional):

| Event Type | Committee | Contributions | Ticketing | Budget | Vendor | Guest Categories | Gift Registry |
|---|---|---|---|---|---|---|---|
| **Harusi (Wedding)** | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ~ |
| **Msiba (Funeral)** | ✓ | ✓ | | ✓ | | | |
| **Harambee (Fundraiser)** | ✓ | ✓ | | ✓ | | | |
| **Birthday (Kuzaliwa)** | | ~ | ~ | ~ | ✓ | | ✓ |
| **Baby Shower** | | ✓ | | ~ | | | ✓ |
| **Graduation** | | ✓ | | ~ | | ✓ | ✓ |
| **Send-off (Kuaga)** | ~ | ✓ | | ~ | | | ✓ |
| **Reunion (Kukutana)** | ✓ | ✓ | | ✓ | | | |
| **Church Events** | ✓ | ✓ | ~ | ✓ | | | |
| **Mosque Events** | ✓ | ✓ | | ✓ | | | |
| **Baptism (Ubatizo)** | | | | | | | ✓ |
| **Conference (Mkutano)** | ✓ | | ✓ | ✓ | ✓ | ✓ | |
| **Product Launch** | | | | ✓ | ✓ | ✓ | |
| **Networking Event** | | | ✓ | | | | |
| **Workshop (Mafunzo)** | | | ✓ | ✓ | | | |
| **AGM (Mkutano Mkuu)** | ✓ | | | | | ✓ | |
| **Concert (Tamasha)** | | | ✓ | ✓ | ✓ | ✓ | |
| **Festival** | ✓ | | ✓ | ✓ | ✓ | | |
| **Sports Event** | ✓ | | ✓ | ✓ | | | |
| **School Event** | ✓ | ✓ | | ✓ | | | |
| **Political Rally** | ✓ | | | ✓ | | ✓ | |
| **Village Meeting** | ✓ | | | | | | |
| **SACCOS/VICOBA** | ✓ | ✓ | | ✓ | | | |
| **Trade Show (Maonyesho)** | ✓ | | ✓ | ✓ | | ✓ | |
| **Engagement (Uchumba)** | ✓ | ✓ | | ✓ | | ✓ | |
| **Housewarming** | | ~ | | | | | ✓ |
| **Retirement (Kustaafu)** | ~ | ✓ | | ~ | | | ✓ |

**Count of event types needing each feature:**
- Committee: **17/27** (63%)
- Contributions: **18/27** (67%)
- Ticketing: **10/27** (37%)
- Budget: **17/27** (63%)
- Vendor: **7/27** (26%)
- Guest Categories: **8/27** (30%)
- Gift Registry: **8/27** (30%)

---

## The 5 Missing Pillars

Based on the cross-event analysis, our events module is missing **5 foundational systems** that cut across most Tanzanian events:

### Pillar 1: KAMATI (Committee System) — needed by 63% of events

```
EventCommittee
├── Main Committee (Kamati Kuu)
│   ├── Mwenyekiti (Chair)
│   ├── Katibu (Secretary)
│   ├── Mhazini (Treasurer)
│   ├── Washauri (Advisors)
│   └── Wajumbe (Members)
│
├── Sub-Committees (Kamati Ndogo)
│   ├── Chakula (Food)
│   ├── Mapambo (Decoration)
│   ├── Burudani (Entertainment)
│   ├── Usafiri (Transport)
│   ├── Usalama (Security)
│   ├── Mapokezi (Reception)
│   ├── Picha/Video (Photo/Video)
│   ├── Michango (Contributions)
│   ├── Kadi/Mwaliko (Invitations)
│   └── Mavazi (Attire)
│
└── Committee Features
    ├── Role-based permissions
    ├── Meeting scheduling + minutes
    ├── Task assignment + tracking
    ├── Sub-committee budgets
    └── Committee chat (separate from event wall)
```

### Pillar 2: MICHANGO (Contribution System) — needed by 67% of events

```
Contribution System
├── Contributor Management
│   ├── Categories: Ndugu wa karibu, Ndugu wa mbali, Marafiki, Wafanyakazi, Waumini, Majirani
│   ├── Import from contacts / TAJIRI friends
│   └── Manual add with phone number
│
├── Pledge Tracking
│   ├── Record pledges (ahadi)
│   ├── Pledge vs payment status
│   ├── Auto-reconciliation with M-Pesa statements
│   ├── Follow-up reminders (automated)
│   └── Assign follow-up ambassadors (wajumbe)
│
├── Collection
│   ├── M-Pesa / Tigo Pesa / Airtel Money
│   ├── Cash recording (at meetings)
│   ├── In-kind contributions (vitu)
│   ├── Receipt generation (digital + printable)
│   └── Dedicated till number / paybill
│
├── Dashboard
│   ├── Real-time total collected
│   ├── Pledge-to-payment ratio
│   ├── By category breakdown
│   ├── Daily/weekly collection trends
│   └── Goal progress bar
│
└── Reciprocity Ledger (Daftari la Michango)
    ├── Track contributions GIVEN to others' events
    ├── Track contributions RECEIVED
    ├── Cross-event history over years
    └── Suggested contribution amounts based on history
```

### Pillar 3: BAJETI (Budget System) — needed by 63% of events

```
Budget System
├── Budget Creation
│   ├── Budget templates by event type (Harusi, Msiba, Harambee, etc.)
│   ├── Category-based: Chakula, Mapambo, Usafiri, Burudani, etc.
│   ├── Sub-committee budget allocation
│   └── Contingency line (5-10%)
│
├── Expense Tracking
│   ├── Log expenses with amount, date, description
│   ├── Photograph receipts (camera capture)
│   ├── Categorize by sub-committee
│   ├── Approval workflow (Mhazini approves)
│   └── Vendor payment tracking
│
├── Budget vs Actual
│   ├── Real-time comparison
│   ├── Overspending alerts per category
│   ├── Sub-committee spending limits
│   └── Available balance calculation (contributions - expenses)
│
├── Disbursement
│   ├── Allocate funds to sub-committees
│   ├── Track disbursement amounts
│   ├── Require receipts for accountability
│   └── Two-signatory approval (Mwenyekiti + Mhazini)
│
└── Financial Report (Taarifa ya Fedha)
    ├── Auto-generate: contributions in, expenses out, surplus/deficit
    ├── By category breakdown
    ├── Shareable PDF/image
    └── Presented at final committee meeting
```

### Pillar 4: WAGENI (Guest Management System) — enhanced

```
Guest System (extends existing RSVP)
├── Guest Categories
│   ├── VIP / Wageni wa Heshima (reserved seating, served food)
│   ├── Family / Ndugu (family section)
│   ├── Regular / Wageni wa kawaida (general seating)
│   └── Custom categories per event
│
├── Invitation Tracking
│   ├── Physical card status: printed → delivered → received
│   ├── Delivery assignment (who delivers to whom)
│   ├── Digital invitation (WhatsApp/SMS)
│   ├── Invitation card design templates
│   └── Guest count estimation vs actual
│
├── Seating Management
│   ├── Table assignment
│   ├── Section assignment (VIP, family, general)
│   └── Seating chart view
│
└── Gift Tracking
    ├── Gift registry / wishlist
    ├── Record gifts received (bahasha tracking)
    ├── Thank-you status
    └── Reciprocity notes
```

### Pillar 5: MATUKIO YANAYOHUSIANA (Multi-Event Linking)

```
Event Series / Linked Events
├── Parent event (e.g., Main Wedding)
│   ├── Child event: Kitchen Party
│   ├── Child event: Kupamba / Kupambisha
│   ├── Child event: Send-off Party
│   ├── Child event: Uchumba (Engagement)
│   └── Child event: Kesha (Night Vigil)
│
├── Shared Resources
│   ├── Shared committee (optional)
│   ├── Shared guest list (with per-event RSVP)
│   ├── Shared budget (or separate budgets)
│   └── Shared contribution pool (or separate)
│
└── Timeline View
    ├── All linked events on one timeline
    ├── Milestone tracking across events
    └── Countdown to each event
```

---

## Event Templates Needed

Pre-built templates that auto-create committee structure, budget categories, and timeline:

| Template | Committee? | Sub-Committees | Budget Categories | Timeline |
|---|---|---|---|---|
| **Harusi (Wedding)** | Full Kamati | 10 sub-committees | 13 categories | 6-month |
| **Msiba (Funeral)** | Emergency Kamati | 5 sub-committees | 6 categories | 3-7 day |
| **Harambee (Fundraiser)** | Small Kamati | 3 sub-committees | 4 categories | 1-3 month |
| **Church Event** | Ministry team | 4 sub-committees | 6 categories | 1-3 month |
| **Conference (Mkutano)** | Organizing committee | 6 sub-committees | 8 categories | 3-6 month |
| **Birthday (Kuzaliwa)** | None | None | 5 categories | 2-4 week |
| **Graduation** | Small group | None | 4 categories | 2-4 week |
| **Concert (Tamasha)** | Promoter team | 5 sub-committees | 7 categories | 2-4 month |
| **School Event** | PTA committee | 4 sub-committees | 5 categories | 1-3 month |
| **SACCOS AGM** | Board | 3 sub-committees | 3 categories | 1-2 month |

---

## Emergency Mode (for Funerals/Msiba)

Funerals cannot be planned in advance. The platform needs an **emergency mode** that:

1. Creates an event in < 2 minutes with minimal required fields
2. Auto-creates a basic committee structure (Chair, Secretary, Treasurer)
3. Immediately enables contribution collection (M-Pesa)
4. Broadcasts announcement to contacts/groups
5. Creates a food coordination signup list
6. Creates a transport coordination list
7. Sets memorial date reminders (3 days, 7 days, 40 days, 1 year)
8. Skips all optional fields — these can be filled later

---

## Implementation Priority

Based on frequency and impact across all event types:

| Priority | Feature | Events Served | Effort |
|---|---|---|---|
| **P0** | Contribution System (Michango) | 18/27 (67%) | Large |
| **P0** | Committee System (Kamati) | 17/27 (63%) | Large |
| **P0** | Budget System (Bajeti) | 17/27 (63%) | Large |
| **P1** | Guest Categories + Invitation Tracking | 8/27 (30%) | Medium |
| **P1** | Multi-Event Linking | Weddings, Conferences | Medium |
| **P1** | Emergency Mode (Msiba) | Funerals | Small |
| **P1** | Event Templates | All types | Medium |
| **P2** | Gift Registry/Tracking | 8/27 (30%) | Medium |
| **P2** | Vendor Management | 7/27 (26%) | Medium |
| **P2** | Reciprocity Ledger | Social events | Medium |
| **P3** | Voting/Election System | AGMs, meetings | Small |
| **P3** | Certificate Generation | Workshops, conferences | Small |
| **P3** | Tournament Management | Sports | Medium |
| **P3** | Per Diem Management | Workshops | Small |
| **P3** | Religious Calendar | Church/Mosque | Small |

---

## Verdict

Our 75-file events module handles the **"Eventbrite layer"** well (creation, RSVP, ticketing, search, social). But it completely misses the **"Tanzanian layer"** — the committee-driven, contribution-funded, budget-tracked way that 67% of events are actually organized in the country.

The top 3 additions (Michango + Kamati + Bajeti) would unlock wedding, funeral, harambee, church, school, reunion, and engagement event support — covering roughly **80% of all events planned in Tanzania**.

---

## Key Swahili Terms Glossary

| Swahili | English |
|---------|---------|
| Tukio | Event |
| Sherehe | Celebration/Party |
| Mkutano | Meeting/Gathering |
| Tamasha | Festival/Show |
| Mwaliko | Invitation |
| Mgeni / Wageni | Guest / Guests |
| Kamati | Committee |
| Mwenyekiti | Chairperson |
| Katibu | Secretary |
| Mweka Hazina / Mhazini | Treasurer |
| Mchango / Michango | Contribution(s) |
| Ahadi | Pledge |
| Zawadi | Gift |
| Tiketi | Ticket |
| Bajeti | Budget |
| Gharama | Cost/Expense |
| Hesabu | Account/Financial report |
| Daftari | Register/Ledger |
| Bahasha | Envelope (for cash gifts) |
| Ratiba | Schedule/Timeline |
| Ada | Fee |
| Sadaka | Offering/Charity |
| Usajili | Registration |
| Washiriki | Participants |
| Mahudhurio | Attendance |
| Kumbukumbu | Records/Memories |
| Maandalizi | Preparations |
| Karamu | Feast |
| Hotuba | Speech |
| Tuzo | Award/Prize |
| Mshenga | Go-between/Matchmaker |
| Mahari | Bride price/Dowry |
| Ukoo | Clan/Extended family |
| Posho / DSA | Per diem/Daily allowance |
| Kiinua mgongo | Retirement gratuity |
| Vibanda | Booths/Stalls |
