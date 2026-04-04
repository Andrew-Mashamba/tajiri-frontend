import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DataStore.dart';

// Design Guidelines Colors (Monochrome)
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _cardBg = Color(0xFFFFFFFF);
const _primaryBg = Color(0xFFFAFAFA);
const _accentColor = Color(0xFF999999);
const _successColor = Color(0xFF4CAF50);
const _pendingColor = Color(0xFFFF9800);
const _iconBg = Color(0xFF1A1A1A);

class PaymentLinksWidget extends StatefulWidget {
  final String paymentType; // 'ada', 'hisa', or 'akiba'
  final String title;

  const PaymentLinksWidget({
    Key? key,
    required this.paymentType,
    required this.title,
  }) : super(key: key);

  @override
  State<PaymentLinksWidget> createState() => _PaymentLinksWidgetState();
}

class _PaymentLinksWidgetState extends State<PaymentLinksWidget> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'paid'
  int? _selectedMonth; // null = all months
  bool _isExpanded = false;

  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final currentYear = DateTime.now().year;

  List<dynamic> get _paymentData {
    return DataStore.getControlNumbers(widget.paymentType);
  }

  List<dynamic> get _filteredPayments {
    var payments = List.from(_paymentData);

    // Filter by status
    if (_selectedFilter == 'pending') {
      payments = payments.where((p) => p['status'] == 'pending').toList();
    } else if (_selectedFilter == 'paid') {
      payments = payments.where((p) => p['status'] == 'paid').toList();
    }

    // Filter by month
    if (_selectedMonth != null) {
      payments = payments
          .where((p) =>
              p['month'] == _selectedMonth && p['year'] == currentYear)
          .toList();
    }

    return payments;
  }

  int get _pendingCount {
    return _paymentData.where((p) => p['status'] == 'pending').length;
  }

  int get _paidCount {
    return _paymentData.where((p) => p['status'] == 'paid').length;
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Malipox ya ${widget.title}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_pendingCount yanayosubiri • $_paidCount yamelipwa',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _pendingColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _secondaryText,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),

            // Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  Row(
                    children: [
                      _buildFilterChip('Zote', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Zinazosubiri', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Zilizolipwa', 'paid'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Month filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMonthChip('Miezi yote', null),
                        const SizedBox(width: 8),
                        ...List.generate(12, (index) {
                          final month = index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildMonthChip(
                              _getMonthName(month),
                              month,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Payment list
            if (_filteredPayments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: _accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hakuna malipo',
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredPayments.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final payment = _filteredPayments[index];
                  return _buildPaymentItem(payment);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _iconBg : _primaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _iconBg : _accentColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : _secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthChip(String label, int? month) {
    final isSelected = _selectedMonth == month;
    return GestureDetector(
      onTap: () => setState(() => _selectedMonth = month),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _iconBg : _primaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _iconBg : _accentColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : _secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final isPaid = payment['status'] == 'paid';
    final month = payment['month'];
    final year = payment['year'];
    final amount = payment['amount'];
    final controlNumber = payment['control_number'];
    final paymentUrl = payment['payment_url'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (isPaid ? _successColor : _pendingColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getMonthAbbr(month),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPaid ? _successColor : _pendingColor,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${_getMonthName(month)} $year',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? _successColor : _pendingColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPaid ? 'Limelipwa' : 'Inasubiri',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            formatCurrency.format(double.tryParse(amount.toString()) ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Namba: $controlNumber',
            style: const TextStyle(
              fontSize: 11,
              color: _secondaryText,
            ),
          ),
        ],
      ),
      trailing: !isPaid && paymentUrl != null
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => _launchPaymentUrl(paymentUrl),
            )
          : null,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    return months[month - 1];
  }

  String _getMonthAbbr(int month) {
    const abbr = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return abbr[month - 1];
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imeshindwa kufungua link ya malipo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kosa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
