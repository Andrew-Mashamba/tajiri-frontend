// lib/reminders/reminder_navigation.dart
// Opens business/calendar/tender modules for aggregated reminder deep-links
// (avoids relying on named routes that are not registered globally).
import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../business/biz_tab_wrapper.dart';
import '../business/pages/appointments_page.dart';
import '../business/pages/business_documents_page.dart';
import '../crb/crb.dart';
import '../team/team.dart' show EmployeesPage;
import '../expenses/expenses.dart';
import '../payroll/payroll.dart' show PayrollHomePage;
import '../suppliers/suppliers.dart';
import '../business/pages/quotes_page.dart';
import '../tax/tax.dart';
import '../calendar/calendar_module.dart';
import '../clients/pages/clients_businesses_page.dart';
import '../debts/debts.dart';
import '../income/pages/income_overview_page.dart';
import '../invoices/pages/invoices_page.dart';
import '../recurring/recurring.dart';
import '../revenue/pages/revenue_overview_page.dart';
import '../tenders/tenders_module.dart';
import '../projects/projects.dart' show ProjectsPage;
import '../transactions/pages/business_transactions_page.dart';
import '../orders/pages/incoming_orders_page.dart';
import 'models/reminder_models.dart';

/// Opens the screen for an aggregated [ReminderItem] using [profileUserId]
/// (Tajiri user / profile id — same as other profile-tab modules).
class ReminderNavigation {
  ReminderNavigation._();

  static void openSource(
    BuildContext context, {
    required ReminderItem item,
    required int profileUserId,
  }) {
    final route = item.sourceRoute?.trim();
    if (route == null || route.isEmpty) {
      final s = AppStringsScope.of(context);
      _toast(context, s?.remindersNoSourceScreen ?? 'No source screen');
      return;
    }

    final path = route.startsWith('/') ? route : '/$route';

    Widget? page;
    switch (path) {
      case '/calendar':
        page = CalendarModule(userId: profileUserId);
        break;
      case '/biz_tenders':
        page = TendersModule(userId: profileUserId);
        break;
      case '/biz_docs':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              BusinessDocumentsPage(userId: uid, businesses: all),
        );
        break;
      case '/biz_quotes':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? QuotesPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_invoices':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? InvoicesPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_transactions':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? BusinessTransactionsPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_revenue':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) => RevenueOverviewPage(
            userId: uid,
            businesses: all,
            featureBusinessId: fId,
          ),
        );
        break;
      case '/biz_income':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) => IncomeOverviewPage(
            userId: uid,
            businesses: all,
            featureBusinessId: fId,
          ),
        );
        break;
      case '/biz_recurring':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? RecurringInvoicesPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_debts':
        page = DebtsOverviewEntry(userId: profileUserId, embedInParent: false);
        break;
      case '/biz_expenses':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? ExpensesPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_tax':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              all.isNotEmpty ? TaxPage(businesses: all) : const SizedBox.shrink(),
        );
        break;
      case '/biz_credit':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? CreditReportPage(businessId: fId, standalone: true) : const SizedBox.shrink(),
        );
        break;
      case '/biz_employees':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? EmployeesPage(businesses: all) : const SizedBox.shrink(),
        );
        break;
      case '/biz_payroll':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? PayrollHomePage(businessId: fId, businesses: all) : const SizedBox.shrink(),
        );
        break;
      case '/biz_po':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? PurchaseOrdersPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/incoming-orders':
        page = IncomingOrdersPage(userId: profileUserId);
        break;
      case '/biz_suppliers':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? SuppliersPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_customers':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              all.isNotEmpty ? ClientsBusinessesPage(businesses: all) : const SizedBox.shrink(),
        );
        break;
      case '/biz_appointments':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? AppointmentsPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
      case '/biz_projects':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? ProjectsPage(businesses: all) : const SizedBox.shrink(),
        );
        break;
      default:
        page = null;
    }

    if (page == null) {
      final s = AppStringsScope.of(context);
      _toast(
        context,
        s?.remindersUnknownSourceRoute(path) ??
            'Source route not registered: $path',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page!),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
