// lib/accounting/accounting_module.dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import 'pages/accounting_overview_page.dart';
import 'pages/accounting_journal_page.dart';
import 'pages/accounting_reports_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);

class AccountingModule extends StatelessWidget {
  final int userId;
  const AccountingModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Container(
          color: _kBackground,
          child: TabBar(
            labelColor: _kPrimary,
            unselectedLabelColor: const Color(0xFF999999),
            indicatorColor: _kPrimary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: [
              Tab(text: sw ? 'Muhtasari' : 'Overview'),
              Tab(text: sw ? 'Ingizo' : 'Journal'),
              Tab(text: sw ? 'Ripoti' : 'Reports'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            AccountingOverviewPage(userId: userId),
            AccountingJournalPage(userId: userId),
            AccountingReportsPage(userId: userId),
          ]),
        ),
      ]),
    );
  }
}
