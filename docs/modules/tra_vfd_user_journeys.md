# TRA VFD Module — Complete User Journeys

**Module:** `lib/vfd/` (standalone) + invoice integration hooks
**Source spec:** `docs/modules/tra_vfd.md`

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget), and **Insightful** (reports, trends, recommendations).

---

## 1. INVOICE FULL-PAYMENT → AUTO FISCAL RECEIPT

**Entry:** Profile → Businesses → VFD Receipts → Invoice Detail → "Mark Paid" / wallet payment success event
**Stage/Context:** Invoice transitions to fully paid

### User Journey
1. User records final payment via "Mark as Paid" / "Weka Ime lipwa" or customer completes wallet payment.
2. System updates invoice payment state.
3. If balance reaches 0:
   - fiscalization job is queued immediately
   - status chip changes to "Fiscalizing..." / "Inatengeneza risiti ya VFD..."
4. Backend composes XML payload with counters and signature, then posts to TRA receipt endpoint.
5. Success path:
   - invoice shows "VFD Receipt Generated" / "Risiti ya VFD Imetengenezwa"
   - verification code/link appears
   - user can tap "View Receipt" / "Angalia Risiti"
6. Failure path:
   - invoice shows "Fiscal receipt pending" warning
   - action buttons: "Retry Now", "View Error", "Contact Support"
7. Unknown response path (timeout/no ACK):
   - system keeps original XML immutable
   - retries background in sequence
   - UI shows "Pending TRA response"

### CRUD Operations
- **Create:** fiscal receipt record auto-created when invoice is fully paid.
- **Read:** invoice detail + VFD tab show receipt metadata (RCTVNUM, ACK status, verification link).
- **Edit:** NOT AVAILABLE — fiscal payload/receipt must remain immutable for compliance.
- **Delete:** NOT AVAILABLE — only reversal/credit-note path allowed; hard delete is compliance gap and disallowed.

### Notifications & Reminders
- 🎉 **Receipt generated (push immediate):** "VFD receipt generated for invoice [invoice_number]."
- ⚠️ **Fiscalization failed (push immediate):** "Failed to fiscalize invoice [invoice_number]: [ack_message]."
- 🔔 **Pending retry (push every 2h, max 3/day):** "Invoice [invoice_number] is still pending TRA response."
- 💡 **Prompt (in-app):** "Share VFD receipt link with customer now."
- 📊 **Daily fiscal summary (push 7pm):** "Today: [success_count] fiscal receipts generated, [pending_count] pending."

### Reports & Insights
- **Fiscalization Success Trend:** daily/weekly success vs failure rate.
- **Time-to-Fiscalization:** median time from paid event to ACK success.
- **Failure Heatmap:** by ACK code, time of day, network condition.

### Cross-Module Connections
- **Wallet:** successful wallet payment triggers fiscalization workflow.
- **Budget:** paid invoice amount recorded as income; fiscal status appended for audit.
- **Notifications:** customer/business receive status updates.
- **Calendar:** add due date reminder before payment; close event when paid and fiscalized.
- **Shangazi AI:** "Explain this fiscal failure" contextual helper for non-technical users.

---

## 2. VFD RECEIPT VIEW, SHARE, AND VERIFICATION

**Entry:** Profile → Businesses → VFD Receipts → Invoice Detail → VFD section → "View VFD Receipt"
**Stage/Context:** After receipt generation

### User Journey
1. User opens VFD receipt detail card.
2. Screen shows:
   - Invoice number
   - RCTNUM / GC / DC / ZNUM
   - Verification code
   - "Verify on TRA" link
   - Created timestamp
3. User taps "Copy Verification Code" / "Nakili Msimbo".
4. User taps "Share Receipt" / "Shiriki Risiti":
   - options: WhatsApp, SMS, Email
   - shared template includes amount, invoice no., verification code/link
5. User taps "Open TRA Verify" to validate authenticity.
6. Empty state: if no receipt yet, page shows "No VFD receipt available" and retry CTA.

### CRUD Operations
- **Create:** receipt metadata created automatically post successful fiscalization.
- **Read:** receipt detail page with verification and share actions.
- **Edit:** NOT AVAILABLE — immutable regulatory data.
- **Delete:** NOT AVAILABLE — can only supersede via credit note/reversal records.

### Notifications & Reminders
- 🔔 **Customer delivery reminder (in-app, 10 min after generation if not shared):** "Share receipt [invoice_number] with customer."
- 🎉 **Shared confirmation (in-app):** "VFD receipt shared successfully."
- ⚠️ **Verification link failure (in-app):** "Could not open TRA verification page. Try again."
- 📊 **Weekly sharing summary (in-app):** "Receipts shared: [count], unshared: [count]."

### Reports & Insights
- **Share Compliance Report:** % of generated receipts shared to customers.
- **Verification Click Report:** how often users/customers open verification links.
- **Customer Delivery SLA:** avg time from receipt generation to first share action.

### Cross-Module Connections
- **Notifications:** reminder notifications for unshared receipts.
- **Community:** optional posting template for merchant proof-of-payment support groups.
- **Shangazi AI:** draft concise bilingual share message for customer communication.

---

## 3. DAILY Z REPORT CLOSE

**Entry:** Profile → Businesses → VFD Receipts → "Z Report" panel → "Submit Today's Z Report"
**Stage/Context:** End-of-day closure before next-day sales cycle

### User Journey
1. At closing time, user sees "Z report not submitted for today" banner.
2. User taps "Review Draft Z Report".
3. Pre-submit summary screen:
   - total daily amount
   - payment method breakdown
   - VAT bucket totals
   - void/correction counts
4. User taps "Submit Z Report" / "Tuma Z Report".
5. Backend signs XML and posts to TRA report endpoint.
6. Success:
   - status "Submitted"
   - Z number + ACK details displayed
   - close-day checklist marked complete
7. Failure:
   - error card with ACK message
   - actions: "Retry", "Export Draft", "Contact Admin"

### CRUD Operations
- **Create:** Z report submission record created per business date.
- **Read:** daily/monthly Z report list with status and totals.
- **Edit:** NOT AVAILABLE — historical submitted reports immutable; only draft recalculated before first submit.
- **Delete:** NOT AVAILABLE — compliance records cannot be deleted.

### Notifications & Reminders
- 🔔 **Closing reminder (push daily 8:30pm):** "Submit today's Z report before opening next business day."
- ⚠️ **Missed Z report (push 7:00am next day):** "Yesterday's Z report is still pending."
- 🎉 **Submission success (push immediate):** "Z report [z_number] submitted successfully."
- 📊 **Daily close summary (in-app after submission):** "Sales: TZS [amount], Fiscal receipts: [count], Z status: Submitted."

### Reports & Insights
- **Daily Z Closure Report:** submitted vs missed days.
- **VAT Breakdown Trend:** VAT groups over time.
- **Close Discipline Score:** on-time submission percentage monthly.

### Cross-Module Connections
- **Calendar:** auto-create daily close reminder event and escalation event if missed.
- **Budget:** end-of-day totals reconcile with income ledger.
- **Notifications:** operational reminders + escalation alerts.
- **Shangazi AI:** "Summarize today's fiscal close in plain Swahili."

---

## 4. FAILED QUEUE & RETRY CENTER

**Entry:** Profile → Businesses → VFD Receipts → "Queue & Retries"
**Stage/Context:** Connectivity issues, ACK failures, or unknown submission results

### User Journey
1. User opens queue dashboard with filters:
   - Pending
   - Failed
   - Retrying
   - Success
2. Each row shows:
   - payload type (`receipt`/`z_report`)
   - invoice/date
   - attempts
   - last error
   - next retry countdown
3. User taps a failed row to open detail:
   - immutable original payload hash
   - first attempt timestamp
   - all retry logs
4. User taps "Retry Now" (if policy allows manual retry).
5. If failure is configuration-related, UI suggests "Go to Setup".
6. Bulk action: "Retry All Eligible" with confirmation.

### CRUD Operations
- **Create:** queue record auto-created whenever fiscal payload is queued.
- **Read:** retry center list and detailed attempt history.
- **Edit:** limited edits to priority/notes only; payload content NOT editable.
- **Delete:** NOT AVAILABLE — records archived after retention policy, not user-deleted.

### Notifications & Reminders
- ⚠️ **Queue backlog alert (push when pending > threshold):** "VFD queue has [count] pending items."
- ⚠️ **Stuck item alert (push after 3 failed attempts):** "Invoice [invoice_number] fiscalization needs manual attention."
- 🔔 **Recovery notice (push):** "Connection restored. Retrying pending VFD submissions."
- 📊 **Backlog digest (in-app every morning):** "Pending: [p], Failed: [f], Recovered: [r] in last 24h."

### Reports & Insights
- **Retry Efficiency Report:** success after 1st/2nd/3rd attempt.
- **Downtime Impact Report:** delayed fiscal receipts due to network outages.
- **Top Failure Causes:** ACK and network error ranking with trend lines.

### Cross-Module Connections
- **Notifications:** backlog and stuck-job alerts.
- **Calendar:** schedule admin review task when queue remains failed >24h.
- **Community:** direct link to internal support group template post with error context.
- **Shangazi AI:** convert raw technical errors into action checklist.

---

## 5. COMPLIANCE DASHBOARD & AUDIT EXPORT

**Entry:** Profile → Businesses → VFD Receipts → "Compliance"
**Stage/Context:** Weekly/monthly business review, audit prep, regulator readiness

### User Journey
1. User opens compliance dashboard cards:
   - fiscalization success rate
   - pending count
   - missed Z reports
   - certificate/token health
2. User chooses period (Today, 7 days, 30 days, custom range).
3. User taps "Export Report" / "Pakua Ripoti":
   - options: PDF, CSV
   - include detail logs toggle
4. User taps "Share with Accountant" action.
5. If critical risk detected (e.g., missed Z reports), red alert panel appears with guided actions.

### CRUD Operations
- **Create:** compliance snapshot records generated daily.
- **Read:** dashboard trends and downloadable reports.
- **Edit:** NOT AVAILABLE — computed analytics; user cannot alter source compliance facts.
- **Delete:** NOT AVAILABLE — governed by retention policy.

### Notifications & Reminders
- 📊 **Weekly compliance summary (push Monday 8am):** "Last week: [success_rate]% fiscal success, [missed_z] missed Z reports."
- ⚠️ **Compliance risk alert (push immediate):** "High compliance risk detected: [risk_reason]. Tap to resolve."
- 💡 **Prompt (in-app weekly):** "Export monthly compliance pack for your accountant."

### Reports & Insights
- **Compliance Scorecard:** weighted score from receipt success, queue backlog, Z-report timeliness.
- **Month-over-Month Comparison:** current month vs previous month compliance.
- **Action Recommendations:** specific fixes ("Update certificate", "Clear queue", "Submit missed Z report").

### Cross-Module Connections
- **Budget:** reconciliation insight between invoiced income and fiscalized totals.
- **Calendar:** auto-create month-end audit prep event.
- **Notifications:** schedule and deliver compliance digests/alerts.
- **Shangazi AI:** explain score drops and produce prioritized remediation plan.

---

## 6. VFD SETTINGS, CREDENTIAL ROTATION, AND SAFETY CONTROLS

**Entry:** Profile → Businesses → VFD Receipts → "Settings"
**Stage/Context:** Security hardening, credential change, environment migration

### User Journey
1. User opens settings with sections:
   - Environment (`Test` / `Production`)
   - Certificate serial + key reference
   - Retry policy controls (max attempts, backoff)
   - Alert preferences
2. Sensitive actions require re-auth (PIN/biometric/password).
3. User taps "Rotate Credentials" flow:
   - upload new cert reference
   - validate serial
   - test registration/token call
4. User taps "Save Changes":
   - system validates no pending critical queue state before switching env
   - if blocked, show reason + required action
5. Audit trail records who changed what and when.

### CRUD Operations
- **Create:** initial settings profile created during first setup.
- **Read:** current settings and last-changed metadata.
- **Edit:** update non-immutable controls with re-auth and validation.
- **Delete:** NOT AVAILABLE — only disable integration or rotate credentials.

### Notifications & Reminders
- 🔔 **Credential expiry reminder (push at 30/14/7 days):** "VFD certificate expires in [days] days."
- ⚠️ **Unsafe setting alert (push immediate):** "Retry policy is too low; failed submissions may be lost."
- 🎉 **Rotation success (push immediate):** "VFD credentials rotated successfully."
- 📊 **Security summary (monthly in-app):** "Credential age: [days], last rotation: [date], auth incidents: [count]."

### Reports & Insights
- **Credential Health Report:** expiry timeline, last validation result.
- **Configuration Drift Report:** settings changes over time with impact on failures.
- **Security Posture Score:** based on credential freshness and guardrail compliance.

### Cross-Module Connections
- **Notifications:** proactive expiry and risk alerts.
- **Calendar:** create credential-rotation event before expiry date.
- **Wallet/Budget:** track external support/maintenance costs tied to VFD operations.
- **Shangazi AI:** generate safe recommended configuration for business size and volume.

---

## Notification Channel Summary

| Trigger | Message Template | Timing | Channel | Frequency |
|---|---|---|---|---|
| Fiscal receipt success | "VFD receipt generated for invoice [invoice_number]." | Immediate | Push | Per receipt |
| Fiscal receipt failure | "Failed to fiscalize invoice [invoice_number]: [ack_message]." | Immediate | Push | Per failure |
| Pending TRA response | "Invoice [invoice_number] is still pending TRA response." | Retry cycle | Push | Max 3/day |
| Daily Z report reminder | "Submit today's Z report before opening next business day." | 8:30pm | Push | Daily |
| Missed Z report | "Yesterday's Z report is still pending." | Next day 7:00am | Push | Daily until resolved |
| Queue backlog | "VFD queue has [count] pending items." | Threshold breach | Push | Event-based |
| Compliance summary | "Last week: [success_rate]% fiscal success, [missed_z] missed Z reports." | Monday 8:00am | Push | Weekly |
| Certificate expiry | "VFD certificate expires in [days] days." | 30/14/7 day windows | Push + in-app | 3 reminders per cycle |

---

## Cross-Module Integration Map

| Source Feature | Connected Module | Data Flow | User Action |
|---|---|---|---|
| Invoice Fiscalization | Wallet | Payment success event -> trigger fiscal queue | Pay invoice -> auto fiscalize |
| Invoice Fiscalization | Budget | Paid/fiscalized invoice amount -> income ledger | View reconciliation in budget |
| Receipt View | Notifications | Unshared receipt state -> reminder | Tap reminder -> share receipt |
| Z Report | Calendar | Daily close reminders + missed alerts | Tap event -> submit Z report |
| Queue Center | Community | Error summary -> support post template | Open support thread with prefilled issue |
| Compliance Dashboard | Budget | Fiscalized totals vs accounting totals comparison | Export compliance + finance pack |
| Settings | Calendar | Credential expiry date -> rotation reminders | Tap event -> rotate credentials |
| All Features | Shangazi AI | Context bundle (ACK, counters, status) -> advice prompt | "Ask Shangazi" contextual help |

---

## Known CRUD Gaps to Flag

- Fiscal receipt edit/delete is intentionally **NOT AVAILABLE** (compliance immutability).
- Z report edit/delete after submission is **NOT AVAILABLE**.
- Token edit is **NOT AVAILABLE** (system-issued only).
- Queue payload body edit is **NOT AVAILABLE** (must preserve original signed payload).

These are not bugs; they are required controls for TRA compliance integrity.
