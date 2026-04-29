# Session Checkpoint

**Timestamp**: 2026-04-29T12:29:00Z
**Branch**: main
**Working Directory**: /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND

---

## ⚠️ CRITICAL SAFETY DIRECTIVES — READ BEFORE EVERY SESSION

**Date**: 2026-04-29  
**Incident**: Background coder agents caused catastrophic file deletions.

### Hard Rules (Never Violate)
1. **NEVER delete existing files** without explicit user permission.
2. **NEVER strip methods/fields/enums** from shared models/services without grep-checking all callers.
3. **NEVER launch background coder agents** (`Agent(subagent_type="coder", run_in_background=true)`). All code changes happen in foreground.
4. **ALWAYS run `flutter analyze`** after changes. Fix errors before moving on.
5. **Prefer minimal surgical edits**. One concern per change.
6. **Shared files with >3 dependents** get full-project analyze after editing.
7. **Stop immediately** if analyze shows new errors, if >5 files need changing, or if the user expresses dissatisfaction.

**Reference**: `.claude/skills/safety-guardrails/SKILL.md`  
**Memory**: `.kimi/memory/project/patterns.md` (Safety & Agent Control Pattern)  
**Memory**: `.kimi/memory/project/troubleshooting.md` (Agent Destructive Changes)

---

## Active Task
"Push to the End" — Massive platform expansion initiative (199 enhancements across 13 feature areas)

## Progress Summary
**Shipped**: 41/199 enhancements ✅
**Remaining**: 158 enhancements ▢

## Recently Completed (from git log)
- [x] Enhanced Team + Projects module design spec
- [x] Employment profile update requirement on member registration
- [x] Implementation plans for Enhanced Team and Projects modules
- [x] Reminders SQLite database layer
- [x] Reminders `_parseBool` int check and `copyWith` sentinel pattern fix

## Active Feature Areas (F1–F13)

### F1 — Partner Posting (6/15 shipped)
- ✅ Productized fixed-fee menu, patch-test booking, dietary tags, hair-type taxonomy, light skill activation, AMC/package-bundle SKU
- ▢ Service variants, add-ons, booking sequencing, implicit duration, photo guidelines, photo-quality checks, lead-time honesty score

### F2 — Buyer Order (2/12 shipped)
- ✅ Reorder carousel, hard dietary/safety filter chips
- ▢ Conversion-weighted ranking, schedule vs ASAP, group cart, photo-proof delivery, AI refund check, self-report window, auto-credit, tips, help chat, detail-page norms

### F3 — Partner Inbox (0/11 shipped)
- ▢ 30-sec accept window, auto-pause, busy/closed toggles, stock toggle, daily payout badge, lead countdown, KPI score, bulk actions, voice notes, benchmark card, service history

### F4 — Service Request / Mafundi (2/12 shipped)
- ✅ Photo-of-problem upload, 30-day redo warranty
- ▢ AI cost estimation, structured intake, diagnostic fee, re-quote, no-fix-no-fee, before/after photos, geofence arrival, live ETA, parts pass-through, site-survey fee

### F5 — Garage Booking (5/13 shipped)
- ✅ Persistent vehicle profile, symptom wizard, AMC, recall lookup, mileage-based reminders
- ▢ VIN scan, OBD2 upload, mobile vs shop drop-off, parts ordering, body-shop bidding, pickup-and-drop, service-due dashboard, 12-month warranty

### F6 — Appointment / Salon-Fitness (4/25 shipped)
- ✅ Hair-type taxonomy, patch-test booking, photo consent, pre-appointment intake
- ▢ Service variants, multi-staff bookings, any-professional toggle, buffers, travel surcharge, skin-type quiz, loyalty stamps, prepaid bundles, waitlist, cancellation tiers, SMS confirmation, rebook cadence, recurring booking
- ▢ Fitness: class booking, pick-a-spot, drop-in vs membership, training plans, progress photos, PR detection, heart-rate integration, live + on-demand

### F7 — Consultation / Lawyer-Doctor-Business (6/28 shipped)
- ✅ Productized legal SKUs, NDA-on-intake, privilege flag, HIPAA architecture, compliance badges, last-minute discount
- ▢ Three-tier SKU, NHIF filter, symptom checker, AI triage, waiting-time badge, availability sort, health profile, pre-visit intake, derm photo intake, mic/camera test, virtual waiting room, consent screens, screen-share, visit notes, eRx dispatch, follow-up CTA, condition cadence, in-person extras, SMS reminder, conflict-of-interest check, draft generation, pay-per-question, retainer subscription, screenshot blocking, consent receipts, data deletion

### F8 — Engagement (6/17 shipped)
- ✅ Escrow + milestone release, JSS badge, three contract types, milestone notifications, lead-credit model, proposal→contract→invoice morphing
- ▢ Work diary/time-tracker, length-of-relationship signal, retainer subscription, AI hiring brief, portfolio, SoW templates, dispute window, auto-recurring invoice, talent matching, public profile pages, Honeybook questionnaires

### F9 — Listing Inquiry / Real Estate (5/19 shipped)
- ✅ Save-search digest, open-house RSVP, photo-count gating, walk/bike/transit score, partner response-time chip
- ▢ HDR/drone tiers, floor plan upload, energy cert, location obfuscation, polygon search, filter chips, list-first default, commute calculator, WhatsApp CTA, request tour, pre-qualification, 3D tour, back-on-market alert, pre-approval flow, similar home cross-sell

### F10 — Event Booking / Travel (6/26 shipped)
- ✅ Backup-performer guarantee, promo-code infrastructure, force-majeure clauses, payment plan, song-request form, quote-bidding broadcast
- ▢ Travel radius slider, package builder, refund-policy tiers, 50% deposit, auto-generated contract, social-proof gallery, itinerary card, TALA badge, migration-season pricing, tier offerings, QR voucher, multi-traveler intake, travel insurance, trip-prep checklist, day-before reminder, on-tour live updates, per-stop reviews, last-minute discount, group discount, early-bird discount

### F11 — Partner Reviews (6/14 shipped)
- ✅ Multi-dimensional rating, photo/video reviews, helpfulness vote, verified-booking enforcement, JSS overlay, loyalty bundles
- ▢ Per-item thumbs, new vs returning flag, recency weighting, partner response window, length-of-relationship signal, peer endorsements, disease-specific tracking, AI review summary, anti-troll cushion

### F12 — Partner Availability (3/12 shipped)
- ✅ Configurable reminder timing, peak/shoulder/low pricing, recurring schedule with skip-week
- ▢ Partner-side reminder push, booking lead time/horizon, buffer config, last-minute discount, VIP standing slot, waitlist vs SMS blast, auto-assignment, two-week horizon for fitness, pick-a-spot floor plan

### F13 — Multi-Skill Partner Hub (3/10 shipped)
- ✅ Add-a-skill screen, per-skill JSS, persona-level public_slug
- ▢ Per-skill portfolio, cross-persona dashboard, pricing tier badges, public profile pages, unified inbox, save-per-persona, skill-pause, AMC packages per persona

## New Modules In Progress (uncommitted)
- `lib/accounting/` — Accounting/GL module
- `lib/appointments/` — Appointment booking system
- `lib/biz_services/` — Business services
- `lib/clients/` — Client management
- `lib/consultations/` — Consultation booking
- `lib/crb/` — Credit reference bureau
- `lib/customer_orders/` — Order management
- `lib/debts/` — Debt tracking
- `lib/engagements/` — Engagement/contracts
- `lib/expenses/` — Expense management
- `lib/income/` — Income tracking
- `lib/invoices/` — Invoice generation
- `lib/my_children/` — Child management
- `lib/my_parents/` — Parent management
- `lib/myjob/` — Job/work tracking
- `lib/orders/` — Order processing
- `lib/payroll/` — Payroll module
- `lib/products/` — Product catalog
- `lib/projects/` — Project management
- `lib/recurring/` — Recurring transactions
- `lib/reminders/` — Reminder system (SQLite-backed)
- `lib/revenue/` — Revenue tracking
- `lib/suppliers/` — Supplier management
- `lib/tax/` — Tax calculation
- `lib/team/` — Team management
- `lib/transactions/` — Transaction ledger
- `lib/vfd/` — VFD (Virtual Fiscal Device) integration

## Modified Core Files
- `lib/main.dart` — Updated routing and initialization
- `lib/screens/profile/profile_screen.dart` — Profile updates
- `lib/screens/feed/create_image_post_screen.dart` — Feed updates
- `lib/services/profile_service.dart` — Profile service changes
- `lib/services/live_update_service.dart` — Live updates
- `lib/services/shop_database.dart` — Shop database changes
- `lib/l10n/app_strings.dart` — Localization updates

## Key Decisions
- Platform foundation covers all 158 remaining items — each is bolt-on UI/wiring against existing helpers
- No new infrastructure required for remaining enhancements
- Notifications, wallet, calendar, chat, Firestore, analytics, JSS scoring, COA-backed money flows are the shared foundation

## Backend Access
- **Production API**: `https://tajiri.zimasystems.com/api`
- **Storage URL**: `https://tajiri.zimasystems.com/storage`
- **Server IP**: `172.240.241.180`
- **SSH Access**: `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`
- **Laravel Path**: `/var/www/tajiri.zimasystems.com`
- **Old UAT** (deprecated, still in legacy docs): `zima-uat.site:8003` — not active
- **Config file**: `lib/config/api_config.dart`

## Blockers/Notes
- Large uncommitted working tree (57 files, +10,440/-5,266 lines)
- Many new module directories need backend directives
- Need to ensure all new modules follow existing patterns (Hive, ApiService, LocalStorageService)

## Next Steps
1. Commit current working tree changes
2. Continue shipping remaining F1–F13 enhancements
3. Write backend directives for new modules
4. Ensure test coverage for new SQLite-backed modules (reminders, etc.)
5. Consider grouping enhancements by vertical for focused sprints

---
Migrated from Claude Code CLI on 2026-04-29
Updated with current "Push to the End" initiative status
Updated backend access info on 2026-04-29
