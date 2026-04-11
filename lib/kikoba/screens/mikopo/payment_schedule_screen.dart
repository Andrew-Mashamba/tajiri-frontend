/// Payment Schedule Screen
///
/// Displays loan repayment schedule with arrears warnings and payment history.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import '../../services/loan_service.dart';
import '../../DataStore.dart';
import '../../selectPaymentMethod.dart';
import 'package:intl/intl.dart';

class PaymentScheduleScreen extends StatefulWidget {
  final String applicationId;
  final String? loanTitle;

  const PaymentScheduleScreen({
    Key? key,
    required this.applicationId,
    this.loanTitle,
  }) : super(key: key);

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LoanSchedule>? _schedules;
  List<LoanPayment>? _payments;
  LoanArrears? _arrears;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        LoanService.getSchedule(widget.applicationId),
        LoanService.getArrears(widget.applicationId),
        LoanService.getPaymentHistory(widget.applicationId),
      ]);

      if (mounted) {
        setState(() {
          _schedules = results[0] as List<LoanSchedule>;
          _arrears = results[1] as LoanArrears;
          _payments = results[2] as List<LoanPayment>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Imeshindikana kupakia: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loanTitle ?? 'Ratiba ya Malipo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ratiba', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Malipo', icon: Icon(Icons.payments)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScheduleTab(),
                    _buildPaymentsTab(),
                  ],
                ),
      floatingActionButton: _schedules != null && _schedules!.any((s) => !s.isPaid)
          ? FloatingActionButton.extended(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.payment),
              label: const Text('Lipa Sasa'),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu Tena'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Arrears warning
          if (_arrears != null && _arrears!.hasArrears)
            _ArrearsWarningCard(arrears: _arrears!),

          // Summary card
          if (_schedules != null && _schedules!.isNotEmpty)
            _ScheduleSummaryCard(schedules: _schedules!),

          const SizedBox(height: 16),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Ratiba ya Malipo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // Schedule items
          if (_schedules != null)
            ...(_schedules!).map((s) => _ScheduleItemCard(schedule: s)),

          if (_schedules == null || _schedules!.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Hakuna ratiba ya malipo',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _payments == null || _payments!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Hakuna malipo yaliyofanywa',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary
                _PaymentsSummaryCard(payments: _payments!),
                const SizedBox(height: 16),

                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Historia ya Malipo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                // Payment items
                ...(_payments!).map((p) => _PaymentItemCard(payment: p)),
              ],
            ),
    );
  }

  void _showPaymentDialog() {
    // Calculate overdue amount from arrears or use first unpaid installment
    double paymentAmount = 0;
    if (_payments != null && _payments!.isNotEmpty) {
      final unpaid = _payments!.where((p) => p.status != 'paid').toList();
      if (unpaid.isNotEmpty) {
        paymentAmount = unpaid.first.amount;
      }
    }

    DataStore.paymentService = "rejesho";
    DataStore.paymentAmount = paymentAmount;
    DataStore.paidServiceId = widget.applicationId;
    DataStore.personPaidId = DataStore.currentUserId ?? '';
    DataStore.maelezoYaMalipo =
        "${DataStore.currentUserName} amelipa rejesho la mkopo, kiasi cha TZS ${paymentAmount.toStringAsFixed(0)}";

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const selectPaymentMethode()),
    );
  }
}

class _ArrearsWarningCard extends StatelessWidget {
  final LoanArrears arrears;

  const _ArrearsWarningCard({required this.arrears});

  @override
  Widget build(BuildContext context) {
    final isDefaulted = arrears.isDefaulted;

    return Card(
      color: isDefaulted ? Colors.red.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDefaulted ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: isDefaulted ? Colors.red : Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  isDefaulted ? 'Mkopo Umechelewa Sana!' : 'Malipo Yamechelewa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDefaulted ? Colors.red : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Kiasi kilichochelewa',
              value: 'TSh ${_formatAmount(arrears.totalOverdue)}',
              valueColor: isDefaulted ? Colors.red : Colors.orange.shade800,
            ),
            _InfoRow(
              label: 'Installment zilizochelewa',
              value: arrears.overdueInstallments.toString(),
            ),
            _InfoRow(
              label: 'Siku zilizopita',
              value: '${arrears.daysOverdue} siku',
            ),
            if (arrears.penaltyAmount > 0)
              _InfoRow(
                label: 'Faini',
                value: 'TSh ${_formatAmount(arrears.penaltyAmount)}',
                valueColor: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

class _ScheduleSummaryCard extends StatelessWidget {
  final List<LoanSchedule> schedules;

  const _ScheduleSummaryCard({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final paid = schedules.where((s) => s.isPaid).length;
    final total = schedules.length;
    final totalPaid = schedules.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.paidAmount);
    final totalAmount = schedules.fold(0.0, (sum, s) => sum + s.totalAmount);

    // Find next due
    final nextDue = schedules.where((s) => !s.isPaid).toList();
    nextDue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final nextSchedule = nextDue.isNotEmpty ? nextDue.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Maendeleo', style: TextStyle(color: Colors.grey)),
                    Text(
                      '$paid / $total',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const Text('installment zimelipwa'),
                  ],
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: total > 0 ? paid / total : 0,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                      ),
                      Center(
                        child: Text(
                          '${((paid / total) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Umelipa:',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'TSh ${_formatAmount(totalPaid)} / ${_formatAmount(totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (nextSchedule != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: nextSchedule.isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextSchedule.isOverdue ? 'Imechelewa!' : 'Malipo yajayo:',
                          style: TextStyle(
                            fontSize: 12,
                            color: nextSchedule.isOverdue ? Colors.red : Colors.blue,
                          ),
                        ),
                        Text(
                          _formatDate(nextSchedule.dueDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: nextSchedule.isOverdue ? Colors.red : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'TSh ${_formatAmount(nextSchedule.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
}

class _ScheduleItemCard extends StatelessWidget {
  final LoanSchedule schedule;

  const _ScheduleItemCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final isPaid = schedule.isPaid;
    final isOverdue = schedule.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.shade100
              : isOverdue
                  ? Colors.red.shade100
                  : Colors.grey.shade100,
          child: Icon(
            isPaid ? Icons.check : isOverdue ? Icons.warning : Icons.calendar_today,
            color: isPaid ? Colors.green : isOverdue ? Colors.red : Colors.grey,
          ),
        ),
        title: Text('Installment #${schedule.installmentNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarehe: ${_formatDate(schedule.dueDate)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
                fontSize: 12,
              ),
            ),
            if (isOverdue)
              Text(
                'Imechelewa siku ${schedule.daysOverdue}',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TSh ${_formatAmount(schedule.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : isOverdue
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPaid ? 'Imelipwa' : isOverdue ? 'Imechelewa' : 'Inasubiri',
                style: TextStyle(
                  fontSize: 10,
                  color: isPaid ? Colors.green : isOverdue ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }
}

class _PaymentsSummaryCard extends StatelessWidget {
  final List<LoanPayment> payments;

  const _PaymentsSummaryCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final completedPayments = payments.where((p) => p.isCompleted).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.payments,
              label: 'Jumla Umelipa',
              value: 'TSh ${_formatAmount(totalPaid)}',
              color: Colors.green,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _SummaryItem(
              icon: Icons.receipt,
              label: 'Malipo',
              value: completedPayments.toString(),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _PaymentItemCard extends StatelessWidget {
  final LoanPayment payment;

  const _PaymentItemCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: payment.isCompleted
              ? Colors.green.shade100
              : payment.isPending
                  ? Colors.orange.shade100
                  : Colors.red.shade100,
          child: Icon(
            payment.isCompleted
                ? Icons.check
                : payment.isPending
                    ? Icons.hourglass_empty
                    : Icons.error,
            color: payment.isCompleted
                ? Colors.green
                : payment.isPending
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        title: Text('TSh ${_formatAmount(payment.amount)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payment.paymentMethod} - ${payment.reference}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              _formatDateTime(payment.paymentDate),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: payment.isCompleted
                ? Colors.green.withOpacity(0.1)
                : payment.isPending
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            payment.isCompleted
                ? 'Imekamilika'
                : payment.isPending
                    ? 'Inasubiri'
                    : 'Imeshindikana',
            style: TextStyle(
              fontSize: 10,
              color: payment.isCompleted
                  ? Colors.green
                  : payment.isPending
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
