# Arifa (Notifications) — Full Redesign

**Status:** draft
**Date:** 2026-05-01
**Owner:** Andrew Mashamba

## Problem

The current `notification_preferences` schema (12 fields, 7 booleans) covers ~5% of what the platform actually emits. Backend scan found:

- ~100 distinct FCM `type` strings dispatched (40+ from Partner C2B alone)
- 7 categories of Reverb broadcasts (messaging, calls, streams, games, service-tracking)
- 3 Mailables + ad-hoc `MailService` (RFQ, invoices, team invites, account-deletion)
- 2 SMS providers (Twilio + Africa's Talking) + WhatsApp
- A Firestore live-update channel
- Per-conversation, per-streamer, per-business override columns scattered across other tables

Most types bypass `isTypeEnabled` entirely — its `$typeMap` only knows ~10 of them. Email/SMS have **no** preference gating today.

## Goal

A single Arifa page that lets a user control **every** dispatch on the platform, broken into a **Category × Channel** grid. Backend honors the prefs across all four channels (Push, Email, SMS, In-app) before any send.

Out of scope for v1 (link out from the page only): per-conversation mute, per-streamer go-live opt-in, per-business RFQ-email opt-in. These already have per-row toggles elsewhere — Arifa is the global default.

## Categories (12)

| Key | Label | Covers |
|---|---|---|
| `messaging` | Direct messages | `new_message` (1:1), typing, recording (broadcast-only) |
| `groups` | Group chats | `new_message` (group), group-call invites |
| `calls` | Calls | `call_incoming`, `call_missed`, `scheduled_call_reminder`, signaling (broadcast-only) |
| `social` | Reactions, comments, mentions, follows | `reaction`, `like`, `comment`, `mention`, `follow`, `friend.*` |
| `marketplace` | Invoices, orders, RFQs | `business_invoice_*`, `incoming_po_received`, `order_status_change`, `rfq.*`, `quote_request.*`, `weekly_invoice` |
| `bookings` | Appointments, services, real-estate, travel, insurance | every Partner C2B `kind` (40+) — appointments, consultations, events, service-requests, garage, inquiries, trip-prep, insurance-expiry, rate-prompts, last-minute-discount, waitlist |
| `clients_crm` | Clients module reminders | `clients_*`, `client_reminder_due` |
| `creator` | Creator economy | `streak_warning`, `weekly_report`, `milestone`, `follower_milestone`, `creator_milestone`, `viral_assist`, `collaboration_suggestion`, `battle_invitation`, `morning_digest`, `evening_digest`, `fomo_push` |
| `streams` | Live streams | `stream_started/scheduled/starting_soon/now_live`, gifts, super-chats |
| `health` | My Circle, pregnancy, baby | `period_*`, `fertile_window`, `ovulation_day`, `contraception_*`, `anc_reminder`, `pregnancy_week`, `kick_decrease`, `vaccination_*`, `feeding_reminder`, `baby_milestone` |
| `money` | Budget, Kikoba | `budget_*`, `kikoba_*` |
| `system` | Security, account, generic | data-deletion, team-invitation, fallback "system" |

12 is the sweet spot. Fewer = users can't disable real-estate while keeping appointments. More = cognitive overload.

## Channels (4)

| Key | What it gates |
|---|---|
| `push` | `FcmNotificationService::sendToUser` |
| `email` | `MailService::send` + `Mail::send(new ...)` |
| `sms` | `SmsNotificationService::send` + `SmsService::send` (channel=sms) |
| `in_app` | the row written to `notifications` table (the bell feed) |

WhatsApp is treated as part of `sms` for v1 (same provider, same opt-in semantics). Reverb broadcasts and Firestore live-updates are **not** user-gated — they drive UI state, not notifications.

## Schema

Add ONE column to `notification_preferences`:

```sql
ALTER TABLE notification_preferences
  ADD COLUMN category_channels jsonb NOT NULL
  DEFAULT '{
    "messaging":   {"push": true, "email": false, "sms": false, "in_app": true},
    "groups":      {"push": true, "email": false, "sms": false, "in_app": true},
    "calls":       {"push": true, "email": false, "sms": true,  "in_app": true},
    "social":      {"push": true, "email": false, "sms": false, "in_app": true},
    "marketplace": {"push": true, "email": true,  "sms": false, "in_app": true},
    "bookings":    {"push": true, "email": true,  "sms": true,  "in_app": true},
    "clients_crm": {"push": true, "email": false, "sms": false, "in_app": true},
    "creator":     {"push": true, "email": false, "sms": false, "in_app": true},
    "streams":     {"push": true, "email": false, "sms": false, "in_app": true},
    "health":      {"push": true, "email": false, "sms": true,  "in_app": true},
    "money":       {"push": true, "email": true,  "sms": true,  "in_app": true},
    "system":      {"push": true, "email": true,  "sms": true,  "in_app": true}
  }'::jsonb;
```

Why JSONB:
- Adding a category later is a no-op (no migration, just app-level enum change).
- Postgres can index per-key; the dispatch path reads one row, no joins.
- Validation lives in the controller's allow-list — silent extra keys get ignored.

The 7 legacy booleans (`messages_enabled`, `groups_enabled`, …) stay as-is. They're treated as the **`push` channel** of their corresponding category (so a user who toggled Arifa today doesn't have their state silently flipped). New code reads `category_channels`; the model migrates legacy values forward on-read.

## Type → Category map

Rebuilt `NotificationPreference::CATEGORY_FOR_TYPE` (single source of truth, ~100 entries) lives in the model. `isTypeEnabled($type, $channel = 'push')` resolves type → category → `category_channels[category][channel]`. Unknown types default to `system` (so future producers don't silently bypass prefs).

## Dispatch gates

| Service | Change |
|---|---|
| `FcmNotificationService::sendToUser` | already gates push; switch the gate to `isTypeEnabled($type, 'push')`. Also write the in-app row only if `isTypeEnabled($type, 'in_app')`. |
| `MailService::send` | new optional `category` arg; gate by `isCategoryChannelEnabled('email')` if provided. Loud no-op if disabled (logs `[mail.skipped category=marketplace user=42]`). |
| `BusinessInvoiceMail` / `RfqSentMail` / `TeamInvitationMail` | callers tag with category before `Mail::send`. |
| `SmsNotificationService::send` | gate by `isCategoryChannelEnabled('sms')`. |
| `SmsService::send` | same. |

Calls (`call_incoming`/`call_missed`) remain quiet-hours-exempt (already true). Same for `system` category — security mail/SMS must always go through (account deletion, team invitations).

## API

| Verb | Path | Body |
|---|---|---|
| GET | `/api/notification-preferences?user_id={id}` | — |
| PATCH | `/api/notification-preferences` | `{user_id, ...legacy_booleans, category_channels: {<cat>: {push, email, sms, in_app}, ...}}` (deep-merged into stored JSON; partial keys allowed) |
| POST | `/api/notification-preferences/reset?user_id={id}` | resets to defaults (replaces atomic 12-field PATCH currently in the frontend) |

Validation:
- `category_channels.<cat>` must be one of the 12 enum values
- `category_channels.<cat>.<chan>` must be one of `push|email|sms|in_app`, value boolean

## UI

Top to bottom, scrollable:

1. **Inline error banner** (existing pattern, unchanged)
2. **Globals card** — sound, vibrate, quiet hours start/end (existing, unchanged)
3. **Channel header strip** — sticky labels: ` ` | 🔔 Push | ✉️ Email | 💬 SMS | 📱 In-app
4. **Category rows** — one per category, each row shows:
   - Icon + title (e.g. "Bookings")
   - Subtitle line (e.g. "Appointments, services, real estate")
   - 4 toggles aligned to the channel-strip columns
   - Optional "Show details" caret → expands a description listing the trigger types in that category (read-only, for trust)
5. **Reset to defaults** button (atomic single PATCH against `category_channels` + globals)
6. **Footer link section** — "Manage per-conversation mute" / "Manage stream subscriptions" / "Manage business email overrides" — deeplink to the existing per-row screens.

Each toggle is optimistic-with-revert (existing `_toggle` pattern). The whole row is `MergeSemantics`'d so screen readers announce "Bookings — push on, email on, SMS off, in-app on".

## Migration & rollout

1. Migration adds `category_channels` JSONB with defaults table-wide.
2. Backfill job walks every existing row and copies legacy booleans into `category_channels[<cat>].push`.
3. Deploy backend (gates do nothing yet, but data is consistent).
4. Frontend ships new UI in same release. The legacy booleans are still written by old clients — no break.
5. Two releases later, drop the legacy booleans (separate cleanup PR).

## Bilingual

All 12 category labels + the 4 channel labels need `AppStrings` getters. ~30 new strings. Same `notif*` prefix pattern as today.

## Out of scope (v1)

- Per-conversation mute UI (already exists in chat header — link out)
- Per-streamer go-live (already in stream profile — link out)
- Per-business RFQ-email (already in business settings — link out)
- WhatsApp as separate channel (folded into SMS for v1)
- Per-type granular toggles inside a category (the "Advanced" expansion can come in v2)
- Time-based digests beyond the existing quiet-hours window
- Notification template `max_per_day` exposure (admin-only concept)
