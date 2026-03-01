"""
Map /app/<slug> routes to their proper module paths for PAGES-TO-IMPLEMENT.md.
Each slug is assigned to one of: accounting, teller, hr, procurement, inventory,
contracts, subscriptions, billings, loans, reports, treasury, transactions,
budgets, settings, profile, self-service, approvals.
"""

# Order matters: first matching prefix/keyword wins. More specific first.
ROUTE_TO_MODULE = [
    # Teller / till / vault / strong-room
    ("accept-till-transfer", "teller"),
    ("close-teller-session", "teller"),
    ("open-teller-session", "teller"),
    ("perform-mid-day-till-balance", "teller"),
    ("perform-till-reconciliation", "teller"),
    ("report-till-overage", "teller"),
    ("report-till-shortage", "teller"),
    ("request-till-to-till-transfer", "teller"),
    ("configure-till-limits", "teller"),
    ("exchange-denominations", "teller"),
    ("manage-vault-cash", "teller"),
    ("manage-strong-room-inventory", "teller"),
    ("receive-float-from-strong-room", "teller"),
    ("return-excess-cash-to-strong-room", "teller"),
    ("reconcile-strong-room", "teller"),
    ("process-vault-deposit", "teller"),
    ("process-vault-withdrawal", "teller"),
    ("process-bank-cash-delivery", "teller"),
    ("process-bank-cash-pick-up", "teller"),
    ("track-denomination-inventory", "teller"),
    ("view-till-activity-report", "teller"),
    ("teller-performance-report", "teller"),
    ("process-cash-deposit", "teller"),
    ("process-cash-withdrawal", "teller"),
    ("process-cash-exchange", "teller"),
    # Accounting (reconciliation, expense, GL, provision, depreciation)
    ("complete-bank-reconciliation", "accounting"),
    ("create-reconciliation-adjustment", "accounting"),
    ("reconcile-gl-accounts", "accounting"),
    ("reconcile-payments", "accounting"),
    ("handle-reconciliation-exceptions", "accounting"),
    ("manual-transaction-matching", "accounting"),
    ("auto-match-transactions", "accounting"),
    ("view-reconciliation-history", "accounting"),
    ("view-reconciliation-status-dashboard", "accounting"),
    ("view-parsed-statement-transactions", "accounting"),
    ("upload-bank-statement", "accounting"),
    ("intercompany-reconciliation", "accounting"),
    ("generate-reconciliation-report", "accounting"),
    ("create-expense-with-budget-validation", "accounting"),
    ("process-expense-payment", "accounting"),
    ("final-expense-approval", "accounting"),
    ("review-expense-as-first-checker", "accounting"),
    ("review-expense-as-second-checker", "accounting"),
    ("handle-over-budget-expenses", "accounting"),
    ("retire-expense-with-receipt", "accounting"),
    ("view-expense-analytics", "accounting"),
    ("view-my-expenses", "accounting"),
    ("post-provision-journal-entry", "accounting"),
    ("calculate-loan-provisions", "accounting"),
    ("configure-loan-provision-settings", "accounting"),
    # HR
    ("approve-payroll", "hr"),
    ("process-monthly-payroll", "hr"),
    ("process-payroll-payment", "hr"),
    ("generate-payslips", "hr"),
    ("approve-reject-leave", "hr"),
    ("configure-leave-types", "hr"),
    ("request-leave", "hr"),
    ("submit-leave-request", "hr"),
    ("track-leave-request-status", "hr"),
    ("view-leave-balance", "hr"),
    ("manage-attendance-exceptions", "hr"),
    ("record-daily-attendance", "hr"),
    ("view-attendance-report", "hr"),
    ("complete-employee-onboarding", "hr"),
    ("process-employee-termination", "hr"),
    ("update-employee-information", "hr"),
    ("view-employee-directory", "hr"),
    ("view-employee-profile", "hr"),
    ("manage-departments", "hr"),
    ("manage-positions", "hr"),
    ("create-training-program", "hr"),
    ("enroll-employees-in-training", "hr"),
    ("submit-training-request", "hr"),
    ("track-training-approval", "hr"),
    ("track-training-records", "hr"),
    ("create-job-vacancy", "hr"),
    ("process-job-applications", "hr"),
    ("submit-overtime-request", "hr"),
    ("record-actual-overtime-hours", "hr"),
    ("submit-resignation", "hr"),
    ("track-resignation-and-clearance", "hr"),
    ("submit-travel-request", "hr"),
    ("track-travel-request-and-advance", "hr"),
    ("request-employment-certificate", "hr"),
    ("view-hr-dashboard", "hr"),
    ("approve-team-requests", "approvals"),
    ("view-team-requests-history", "hr"),
    # Procurement
    ("create-purchase-requisition", "procurement"),
    ("edit-pending-requisition", "procurement"),
    ("approve-requisition-and-assign-vendors", "procurement"),
    ("view-my-requisitions", "procurement"),
    ("view-procurement-dashboard", "procurement"),
    ("search-and-filter-procurement-data", "procurement"),
    ("create-tender", "procurement"),
    ("edit-tender", "procurement"),
    ("close-delete-tender", "procurement"),
    ("register-new-vendor", "procurement"),
    ("delete-vendor", "procurement"),
    ("edit-vendor-information", "procurement"),
    ("submit-vendor-quotation", "procurement"),
    ("view-vendor-list", "procurement"),
    ("submit-material-request", "procurement"),
    ("track-material-request", "procurement"),
    ("view-purchase-order-details", "procurement"),
    # Inventory
    ("create-inventory-item", "inventory"),
    ("delete-inventory-item", "inventory"),
    ("edit-inventory-item", "inventory"),
    # Contracts
    ("create-contract", "contracts"),
    ("end-close-contract", "contracts"),
    ("view-contract-details", "contracts"),
    # Subscriptions
    ("create-subscription-plan", "subscriptions"),
    ("cancel-subscription", "subscriptions"),
    ("process-subscription-renewal", "subscriptions"),
    ("subscribe-member-to-plan", "subscriptions"),
    ("upgrade-downgrade-subscription", "subscriptions"),
    ("track-subscription-usage", "subscriptions"),
    ("view-subscriptions", "subscriptions"),
    ("view-subscriptions-dashboard", "subscriptions"),
    ("view-subscription-analytics", "subscriptions"),
    ("view-subscription-payments", "subscriptions"),
    ("manage-plan-features", "subscriptions"),
    # Billings
    ("cancel-bill", "billings"),
    ("generate-bulk-bills", "billings"),
    ("generate-individual-bill", "billings"),
    ("schedule-recurring-bills", "billings"),
    ("send-bill-reminders", "billings"),
    ("handle-failed-payments", "billings"),
    ("view-all-bills", "billings"),
    ("view-pending-bills", "billings"),
    ("view-bill-details", "billings"),
    ("view-billing-dashboard", "billings"),
    ("generate-billing-report", "billings"),
    # Loans
    ("apply-for-loan-online", "loans"),
    ("track-loan-application", "loans"),
    ("view-loan-summary", "loans"),
    ("view-all-active-loans", "loans"),
    ("view-loan-guarantors", "loans"),
    ("release-guarantor", "loans"),
    ("restructure-loan", "loans"),
    ("process-loan-write-off", "loans"),
    ("track-write-off-recovery", "loans"),
    ("authorize-over-limit-transaction", "loans"),
    ("manage-collection-activities", "loans"),
    ("generate-arrears-reports", "loans"),
    ("view-arrears-by-amount-distribution", "loans"),
    ("view-arrears-by-days-distribution", "loans"),
    ("track-cit-movement", "loans"),
    ("request-cit-collection", "loans"),
    ("manage-cit-providers", "loans"),
    ("view-loan-portfolio-dashboard", "loans"),
    # Reports
    ("audit-trail-report", "reports"),
    ("generate-expense-report", "reports"),
    ("generate-hr-reports", "reports"),
    ("generate-usage-report", "reports"),
    ("track-reconciliation-sla", "reports"),
    # Treasury / finance
    ("generate-cash-position-report", "treasury"),
    ("generate-daily-cash-position", "treasury"),
    ("view-cash-flow-forecast", "treasury"),
    ("view-cash-management-dashboard", "treasury"),
    ("view-treasury-position", "treasury"),
    ("view-trends-and-forecasting", "treasury"),
    ("analyze-cash-trends", "treasury"),
    ("analyze-portfolio-risk", "reports"),
    # Transactions
    ("process-batch-payments", "transactions"),
    ("process-early-settlement-payment", "transactions"),
    ("process-inter-branch-transfer", "transactions"),
    ("initiate-online-payment", "transactions"),
    ("receive-payment-callback", "transactions"),
    ("view-transaction-history", "transactions"),
    ("calculate-early-settlement", "loans"),
    # Budgets
    ("track-budget-utilization", "budgets"),
    ("view-budget-vs-expense-overview", "budgets"),
    # Settings
    ("configure-institution-settings", "settings"),
    ("configure-gepg-payment-mode", "settings"),
    ("configure-luku-payment-mode", "settings"),
    ("configure-nbc-payment-mode", "settings"),
    ("configure-tips-payment-mode", "settings"),
    ("configure-password-policy", "settings"),
    ("configure-reminder-rules", "settings"),
    ("configure-plan-tiers", "settings"),
    ("configure-salary-structure", "settings"),
    ("manage-bank-accounts", "settings"),
    # Profile / auth
    ("change-password", "profile"),
    ("change-portal-password", "profile"),
    ("reset-password", "profile"),
    ("enable-two-factor-authentication", "profile"),
    ("disable-two-factor-authentication", "profile"),
    ("manage-recovery-codes", "profile"),
    ("logout-other-sessions", "profile"),
    ("view-active-sessions", "profile"),
    ("configure-notification-preferences", "settings"),
    ("set-language-and-timezone", "settings"),
    ("login-to-portal", "profile"),
    ("register-for-portal-access", "profile"),
    # Self-service / member portal
    ("view-member-dashboard", "self-service"),
    ("view-account-balances", "self-service"),
    ("request-statement", "self-service"),
    ("update-personal-information", "self-service"),
    ("update-contact-information", "self-service"),
    ("delete-my-account", "self-service"),
    ("view-self-service-dashboard", "self-service"),
    ("view-my-request-history", "self-service"),
    ("view-notifications", "self-service"),
    ("submit-inquiry-complaint", "self-service"),
]


def app_route_to_module(slug: str) -> str:
    """Return module for /app/<slug>. slug is the part after /app/."""
    slug = slug.strip().lower()
    for keyword, module in ROUTE_TO_MODULE:
        if keyword in slug or slug in keyword:
            return module
    return "app"  # fallback: keep under app if no mapping


def remap_line(line: str) -> str:
    """Remap a line like '- `/app/xxx`' to '- `/module/xxx`' preserving ✅ if present."""
    import re
    line_stripped = line.rstrip()
    # Match: "- " optional "✅ " then "`/app/slug`"
    match = re.match(r'^(- )(✅ )?`/app/([^`]+)`(\s*)$', line_stripped)
    if not match:
        return line
    dash, done, path_slug, suffix = match.groups()
    module = app_route_to_module(path_slug)
    new_path = f"/{module}/{path_slug}" if module != "app" else f"/app/{path_slug}"
    out = dash + (done or "") + f"`{new_path}`" + (suffix or "")
    return out + "\n"


if __name__ == "__main__":
    import sys
    for line in sys.stdin:
        sys.stdout.write(remap_line(line))
