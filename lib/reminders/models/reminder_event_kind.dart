// lib/reminders/models/reminder_event_kind.dart
//
/// Drives notification scheduling for aggregated reminders. Optional on API rows
/// (`event_kind` or `reminder_kind`); when absent, scheduling falls back to
/// [ReminderCategory] defaults.
abstract final class ReminderEventKind {
  static const String documentExpiry = 'document_expiry';

  static const String quoteValidUntil = 'quote_valid_until';
  static const String quoteStatus = 'quote_status';

  static const String invoiceUpcoming = 'invoice_upcoming';
  static const String invoiceOverdue = 'invoice_overdue';
  static const String invoicePaid = 'invoice_paid';

  static const String debtUpcoming = 'debt_upcoming';
  static const String debtOverdue = 'debt_overdue';

  static const String recurringInvoiceDue = 'recurring_invoice';
  static const String recurringExpense = 'recurring_expense';
  static const String revenueDigest = 'revenue_digest';
  static const String failedTransaction = 'failed_transaction';
  static const String crbPastDue = 'crb_past_due';
  static const String taxDeadline = 'tax_deadline';
  static const String employeeContract = 'employee_contract';

  static const String payrollDraft = 'payroll_draft';
  static const String payrollUnpaid = 'payroll_unpaid';

  static const String poDelivery = 'po_delivery';
  static const String poStatus = 'po_status';

  static const String tenderClosing = 'tender_closing';
  static const String tenderApplication = 'tender_application';
  static const String tenderOutcome = 'tender_outcome';

  static const String appointmentUpcoming = 'appointment_upcoming';
  static const String calendarEvent = 'calendar_event';

  /// Fire once ASAP (status changes, confirmations, failures).
  static const String immediate = 'immediate';
}
