import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DataStore.dart';
import '../pages/AdaPage.dart';
import '../pages/HisaPage.dart';
import '../pages/AkibaPage.dart';
import '../pages/MikopoPage.dart';
import '../pages/MyLoansListPage.dart';
import '../pages/MichangoPage.dart';
import '../pages/UongoziPage.dart';
import '../pages/UdhaminiWaMikopo.dart';
import 'FinanceSummaryCard.dart';

const _primaryBg = Color(0xFFFAFAFA);
const _primaryText = Color(0xFF1A1A1A);

class FinancialSummarySection extends StatelessWidget {
  const FinancialSummarySection({Key? key}) : super(key: key);

  NumberFormat get formatCurrency => NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _getPendingPaymentsCount(String type) {
    final payments = DataStore.getControlNumbers(type);
    return payments.where((p) => p['status'] == 'pending').length;
  }

  // Calculate total Ada paid by current member
  double _getTotalAdaPaid() {
    final adaList = DataStore.adaListList;
    if (adaList == null || adaList.isEmpty) return 0.0;
    final currentUserId = DataStore.currentUserId ?? '';

    double total = 0.0;
    for (var payment in adaList) {
      // Check if this payment belongs to current user
      final userId = payment['userId']?.toString() ?? payment['user_id']?.toString() ?? '';
      if (userId == currentUserId) {
        // Check if payment is completed/paid
        final status = payment['status']?.toString().toLowerCase() ?? '';
        if (status == 'paid' || status == 'completed' || status == 'success') {
          total += _parseValue(payment['amount'] ?? payment['kiasi']);
        }
      }
    }
    return total;
  }

  // Calculate total Hisa paid by current member
  double _getTotalHisaPaid() {
    final hisaList = DataStore.hisaList;
    if (hisaList == null || hisaList.isEmpty) return 0.0;
    final currentUserId = DataStore.currentUserId ?? '';

    double total = 0.0;
    for (var payment in hisaList) {
      // Check if this payment belongs to current user
      final userId = payment['userId']?.toString() ?? payment['user_id']?.toString() ?? '';
      if (userId == currentUserId) {
        // Check if payment is completed/paid
        final status = payment['status']?.toString().toLowerCase() ?? '';
        if (status == 'paid' || status == 'completed' || status == 'success') {
          total += _parseValue(payment['amount'] ?? payment['kiasi']);
        }
      }
    }
    return total;
  }

  // Calculate total Akiba paid by current member
  double _getTotalAkibaPaid() {
    final akibaList = DataStore.akibaList;
    if (akibaList == null || akibaList.isEmpty) return 0.0;
    final currentUserId = DataStore.currentUserId ?? '';

    double total = 0.0;
    for (var payment in akibaList) {
      // Check if this payment belongs to current user
      final userId = payment['userId']?.toString() ?? payment['user_id']?.toString() ?? '';
      if (userId == currentUserId) {
        // Check if payment is completed/paid
        final status = payment['status']?.toString().toLowerCase() ?? '';
        if (status == 'paid' || status == 'completed' || status == 'success') {
          total += _parseValue(payment['amount'] ?? payment['kiasi']);
        }
      }
    }
    return total;
  }

  // Get member's loans count
  int _getMemberLoansCount() {
    final loans = DataStore.mikopoList;
    if (loans == null || loans.isEmpty) return 0;
    final currentUserId = DataStore.currentUserId ?? '';
    return loans.where((loan) =>
      loan['userId']?.toString() == currentUserId ||
      loan['user_id']?.toString() == currentUserId ||
      loan['mkopajiId']?.toString() == currentUserId
    ).length;
  }

  // Get member's contributions count
  int _getMemberContributionsCount() {
    final contributions = DataStore.michangoList;
    if (contributions == null || contributions.isEmpty) return 0;
    final currentUserId = DataStore.currentUserId ?? '';
    return contributions.where((contrib) =>
      contrib['mchangiwaId']?.toString() == currentUserId ||
      contrib['userId']?.toString() == currentUserId
    ).length;
  }

  // Get count of pending guarantee requests for current member
  int _getPendingGuaranteeRequestsCount() {
    // This would typically come from an API call
    // For now, return 0 until the data is loaded from backend
    // In a real implementation, this could be stored in DataStore
    return 0;
  }

  // Get count of loans guaranteed by current member
  int _getGuaranteedLoansCount() {
    // This would typically come from an API call
    // For now, return 0 until the data is loaded from backend
    // In a real implementation, this could be stored in DataStore
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _primaryBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fedha Zangu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Taarifa za kifedha za mwanachama',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),

          // Ada Card
          FinanceSummaryCard(
            title: 'Ada Yangu',
            subtitle: 'Jumla ya malipo',
            icon: Icons.payments_rounded,
            iconColor: Colors.blue,
            amount: formatCurrency.format(_getTotalAdaPaid()),
            status: 'Kila mwezi: ${formatCurrency.format(_parseValue(DataStore.ada))}',
            pendingCount: _getPendingPaymentsCount('ada'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdaPage()),
              );
            },
          ),

          // Hisa Card
          FinanceSummaryCard(
            title: 'Hisa Zangu',
            subtitle: 'Jumla ya malipo',
            icon: Icons.pie_chart_rounded,
            iconColor: Colors.green,
            amount: formatCurrency.format(_getTotalHisaPaid()),
            status: 'Kila mwezi: ${formatCurrency.format(_parseValue(DataStore.Hisa))}',
            pendingCount: _getPendingPaymentsCount('hisa'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HisaPage()),
              );
            },
          ),

          // Akiba Card
          FinanceSummaryCard(
            title: 'Akiba Yangu',
            subtitle: 'Jumla ya malipo',
            icon: Icons.savings_rounded,
            iconColor: Colors.orange,
            amount: formatCurrency.format(_getTotalAkibaPaid()),
            status: DataStore.katiba != null && DataStore.katiba['akiba'] != null
                ? 'Kila mwezi: ${formatCurrency.format(_parseValue(DataStore.katiba['akiba']))}'
                : 'Kiasi cha mwezi haijawekwa',
            pendingCount: _getPendingPaymentsCount('akiba'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AkibaPage()),
              );
            },
          ),

          // Mikopo Yangu - View my loans
          FinanceSummaryCard(
            title: 'Mikopo Yangu',
            subtitle: 'Mikopo yangu hai na yanayosubiri',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.purple,
            amount: '${_getMemberLoansCount()} ${_getMemberLoansCount() == 1 ? "mkopo" : "mikopo"}',
            status: 'Bonyeza kuona orodha',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyLoansListPage()),
              );
            },
          ),

          // Omba Mkopo - Apply for new loan
          FinanceSummaryCard(
            title: 'Omba Mkopo',
            subtitle: 'Omba mkopo mpya',
            icon: Icons.add_card_rounded,
            iconColor: Colors.deepPurple,
            status: 'Bonyeza kuomba mkopo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MikopoPage()),
              );
            },
          ),

          // Udhamini wa Mikopo Card
          FinanceSummaryCard(
            title: 'Udhamini wa Mikopo',
            subtitle: 'Mikopo niliyodhamini',
            icon: Icons.verified_user_rounded,
            iconColor: Colors.indigo,
            amount: '${_getGuaranteedLoansCount()} ${_getGuaranteedLoansCount() == 1 ? "mkopo" : "mikopo"}',
            status: 'Bonyeza kuona maelezo',
            pendingCount: _getPendingGuaranteeRequestsCount(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UdhaminiWaMikopoPage()),
              );
            },
          ),

          // Michango Card
          FinanceSummaryCard(
            title: 'Michango Yangu',
            subtitle: 'Michango yangu maalum',
            icon: Icons.volunteer_activism_rounded,
            iconColor: Colors.red,
            amount: '${_getMemberContributionsCount()} ${_getMemberContributionsCount() == 1 ? "mchango" : "michango"}',
            status: 'Bonyeza kuona maelezo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MichangoPage()),
              );
            },
          ),

          // Uongozi Card
          FinanceSummaryCard(
            title: 'Shuguli za Uongozi',
            subtitle: 'Vikao, Maamuzi & Baraza',
            icon: Icons.gavel_rounded,
            iconColor: Colors.teal,
            status: 'Bonyeza kuona maelezo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UongoziPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
