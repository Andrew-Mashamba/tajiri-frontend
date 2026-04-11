# Events Module — Wedding Gap Analysis

## What's COMPLETELY MISSING

| # | Wedding Feature | Severity | Why It Matters |
|---|---|---|---|
| 1 | **Committee Structure (Kamati)** — Create committee with roles (Mwenyekiti, Katibu, Mhazini), manage members, permissions | CRITICAL | This is how ALL wedding planning is organized |
| 2 | **Sub-Committee System** — Food, Decoration, Transport, Security sub-committees with chairs, budgets, tasks | CRITICAL | 8-10 sub-committees per wedding, each needs its own workspace |
| 3 | **Contribution Tracking (Daftari la Michango)** — Pledge vs payment, contributor categories, M-Pesa auto-reconciliation, follow-up | CRITICAL | This is the #1 pain point — the financial backbone of every wedding |
| 4 | **Budget Management** — Per-event budget with categories, budget vs actual tracking, sub-committee allocation, expense logging with receipt photos | CRITICAL | Families overspend because they can't see real-time budget status |
| 5 | **Disbursement Tracking** — Release funds to sub-committees, track spending per committee, require receipts | HIGH | How money flows from treasury to sub-committees |
| 6 | **Guest Categories** — VIP, Family, Regular, with different seating/food treatment | HIGH | Tanzanian weddings have strict guest hierarchy |
| 7 | **Invitation Card Management** — Track card distribution (who received, who delivered), both physical and digital | HIGH | Physical cards are mandatory; tracking delivery is logistics nightmare |
| 8 | **Multi-Event Linking** — Kitchen Party, Kupamba, Send-off, Main Wedding as linked events | HIGH | A wedding is 4-6 related events, not one |
| 9 | **Meeting Management** — Schedule committee meetings, agenda, minutes, attendance tracking | MEDIUM | Weekly meetings for 3-6 months |
| 10 | **Vendor Directory + Contracts** — Vendor profiles, quotation comparison, digital contracts, payment milestones | MEDIUM | Vendor management is a major pain point |
| 11 | **Expense Tracking with Receipts** — Log expenses, photograph receipts, categorize by sub-committee | HIGH | Critical for post-wedding accountability |
| 12 | **Financial Report Generation** — Auto-generate Taarifa ya Fedha (contributions in, expenses out, surplus/deficit) | HIGH | Currently handwritten, error-prone, causes disputes |
| 13 | **Contribution Follow-up** — Automated reminders for unpaid pledges, follow-up assignment to committee members | HIGH | Pledge-to-payment gap is 30-50% |
| 14 | **Reciprocity Ledger** — Track contributions across events over years | MEDIUM | Social obligation tracking — "I gave 50K at their wedding" |
| 15 | **Wedding Templates** — Pre-built timeline, budget, committee structure for weddings | MEDIUM | Reduces setup time from hours to minutes |

## Verdict

Our current implementation can handle about 25% of a real Tanzanian wedding. It covers basic event creation, RSVP, sharing, and some organizer tools. But it completely lacks the three pillars of Tanzanian wedding planning:

1. **Kamati (Committee) system** — multi-level organizational structure
2. **Michango (Contribution) system** — pledge/payment tracking with M-Pesa reconciliation
3. **Bajeti (Budget) system** — real-time budget tracking with sub-committee allocation

These are not "nice-to-haves" — without them, the module is unusable for the #1 event type in Tanzania.

---

## Key Additions Required

1. **Committee models + service** — EventCommittee, SubCommittee, CommitteeMember with role-based permissions
2. **Contribution system** — Contribution model with pledge/payment states, contributor categories, M-Pesa reconciliation, follow-up tracking
3. **Budget system** — EventBudget, BudgetCategory, Expense with receipt photo support
4. **Disbursement tracking** — Fund allocation to sub-committees with approval workflow
5. **Multi-event linking** — Related events (Kitchen Party → Kupamba → Main Wedding)
6. **Guest categories** — VIP/Family/Regular with seating management
7. **Meeting management** — Agenda, minutes, attendance
8. **Wedding templates** — Pre-built structure for quick setup
